import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telematics_sdk_example/services/user.dart';
import 'package:telematics_sdk_example/services/telematics_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:telematics_sdk/telematics_sdk.dart';

class UnifiedAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TelematicsService _telematicsService = TelematicsService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final TrackingApi _trackingApi = TrackingApi();

  final String instanceId = "ee050880-86db-4502-9e82-366da9e3d4de";
  final String instanceKey = "b0fafb2a-bd86-408e-87f5-cce93619be2c";

  // Converts Firebase User to custom AppUser
  AppUser? _userFromFirebaseUser(User? user) {
    return user != null ? AppUser(uid: user.uid) : null;
  }

  // Register with email, password, and user details for telematics
  Future<AppUser?> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String clientId,
  }) async {
    try {
      // Firebase Authentication to create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      // Register user in telematics system
      TokenResponse tokenResponse = await _telematicsService.registerUser(
        // firstName: firstName,
        // lastName: lastName,
        // phone: phone,
        email: email,
        // clientId: clientId,
      );

      // Store telematics tokens and username in Firebase database linked to the user's UID
      if (firebaseUser != null) {
        await _database.ref('userTokens/${firebaseUser.uid}').set({
          'deviceToken': tokenResponse.deviceToken,
          'accessToken': tokenResponse.accessToken,
          'refreshToken': tokenResponse.refreshToken,
        });
      }

      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Register with email, password, and user details for telematics
  Future<AppUser?> registerPatient(
      {required String email,
      required String password,
      required String gender,
      required String birthday,
      required String physician,
      required String physicianID}) async {
    try {
      // Firebase Authentication to create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      // Register user in telematics system
      TokenResponse tokenResponse = await _telematicsService.registerUser(
        // firstName: "",
        email: email,
      );

      // Store telematics tokens and username in Firebase database linked to the user's UID
      if (firebaseUser != null) {
        await _database.ref('patients/${firebaseUser.uid}').set({
          'deviceToken': tokenResponse.deviceToken,
          'accessToken': tokenResponse.accessToken,
          'refreshToken': tokenResponse.refreshToken,
          'gender': gender,
          'birthday': birthday,
          'email': email,
          'physician': physician,
          'physicianID': physicianID
        });
      }

      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  late final String? selectedPhysicianUid;

  Future<List<DropdownMenuItem<String>>> getPhysicianDropdownItems() async {
    List<DropdownMenuItem<String>> items = [];
    DatabaseReference ref = FirebaseDatabase.instance.ref('physicians');

    // Only proceed if the user is authenticated
    // User? currentUser = FirebaseAuth.instance.currentUser;
    // if (currentUser != null) {
    try {
      DatabaseEvent event = await ref.once();
      Map<dynamic, dynamic> physicians =
          event.snapshot.value as Map<dynamic, dynamic>;
      physicians.forEach((key, value) {
        String fullName = '${value['firstName']} ${value['lastName']}';
        items.add(
          DropdownMenuItem(
            value: key,
            child: Text(fullName),
          ),
        );
      });
    } catch (e) {
      print(e.toString());
      // Handle errors or return an empty list
    }
    // } else {
    //   // Handle the case where the user is not authenticated
    // }
    return items;
  }

  Future<List<DropdownMenuItem<String>>> getPhysicianDropdownMenu(
      String currentPhysicianId) async {
    List<DropdownMenuItem<String>> items = [];
    DatabaseReference ref = FirebaseDatabase.instance.ref('physicians');

    // Only proceed if the user is authenticated
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DatabaseEvent event = await ref.once();
        Map<dynamic, dynamic> physicians =
            event.snapshot.value as Map<dynamic, dynamic>;
        physicians.forEach((key, value) {
          String firstName = value['firstName'] ?? '';
          String lastName = value['lastName'] ?? '';
          String fullName = '$firstName $lastName'.trim();
          items.add(
            DropdownMenuItem(
              value: key,
              child: Text(fullName),
            ),
          );
        });

        // Find the currently selected physician's UID and set it
        selectedPhysicianUid = currentPhysicianId;
      } catch (e) {
        print(e.toString());
      }
    } else {
      print('No authenticated user found.');
    }

    return items;
  }

  Future<Map<String, String>> getPatients() async {
    //  List<String> ids = [];
    List<String> emails = [];
    List<String> accessTokens = [];
    // List<String> scores = [];
    Map<String, String> patientList = <String, String>{};

    DatabaseReference ref = FirebaseDatabase.instance.ref('patients');
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      String uid = currentUser.uid;
      try {
        DatabaseEvent event = await ref.once();
        Map<dynamic, dynamic> patients =
            event.snapshot.value as Map<dynamic, dynamic>;

        // patients.forEach((key, value) {
        patients.forEach((key, value) async {
          // String fullName = '${value['firstName']} ${value['lastName']}';
          // String patientID = '$key';
          String patientAT = '${value['accessToken']}';
          String patientEmail = '${value['email']}';
          // String score = await fetchSummarySafetyScore(
          //     "2024-01-01", "2024-10-10", value);
          if ('${value['physicianID']}' == uid) {
            // print(patientID);
            //    print(patientEmail);
            // ids.add(patientID);
            // scores.add(score);
            accessTokens.add(patientAT);
            emails.add(patientEmail);
          }
        });

        // patientList = Map.fromIterables(scores, accessTokens);

        patientList = Map.fromIterables(emails, accessTokens);

        // patientList = Map.fromIterables(ids, accessTokens);
        //  patientList = Map.fromIterables(ids, emails);
      } catch (e) {
        print(e.toString());
        // Handle errors or return an empty list
      }
    } else {
      // Handle the case where the user is not authenticated
    }

    return patientList;
  }

  Future<AppUser?> registerPhysician({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String npi,
    required String organizationName,
    required String phone,
  }) async {
    try {
      // Firebase Authentication to create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      // Store telematics tokens and username in Firebase database linked to the user's UID
      if (firebaseUser != null) {
        await _database.ref('physicians/${firebaseUser.uid}').set({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'npi': npi,
          'organizationName': organizationName,
          'phone': phone,
        });
      }

      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<AppUser?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Get Device token (Firebase side)
  Future<String?> getDeviceTokenForUser(String? uid, bool isNewUser) async {
    if (uid == null) {
      print("UID is null. Cannot retrieve device token.");
      return null;
    }

    DatabaseReference dbRef = FirebaseDatabase.instance.ref('patients/$uid');

    try {
      DataSnapshot snapshot = await dbRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && data.containsKey('deviceToken')) {
          final String? deviceToken = data['deviceToken'];
          print("Device token for UID $uid is: $deviceToken");
          login(deviceToken);
          if (isNewUser) {
            _trackingApi.showPermissionWizard(
                enableAggressivePermissionsWizard: false,
                enableAggressivePermissionsWizardPage: true);
          } else {}
          initializeAndStartTracking(deviceToken!);
          return deviceToken;
        } else {
          print("Device token not found for UID $uid.");
        }
      } else {
        print("Snapshot does not exist for UID $uid.");
      }
    } catch (e) {
      print(
          "An error occurred while trying to fetch device token for UID $uid: $e");
    }

    return null;
  }

  Future<String?> getPhysician(String? uid) async {
    if (uid == null) {
      print("UID is null. Cannot retrieve Physician.");
      return null;
    }

    DatabaseReference dbRef = FirebaseDatabase.instance.ref('patients/$uid');

    try {
      DataSnapshot snapshot = await dbRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && data.containsKey('physician')) {
          final String? physician = data['physician'];
          print("Physician for UID $uid is: $physician");
          return physician;
        } else {
          print("Physician not found for UID $uid.");
        }
      } else {
        print("Snapshot does not exist for UID $uid.");
      }
    } catch (e) {
      print(
          "An error occurred while trying to fetch physician for UID $uid: $e");
    }

    return null;
  }

  // Future<void>

  // Method to login to Damoov
  Future<void> login(String? userId) async {
    var url = Uri.parse('https://user.telematicssdk.com/v1/Auth/Login');

    var headers = {
      'accept': 'application/json',
      'InstanceId': 'ee050880-86db-4502-9e82-366da9e3d4de',
      'content-type': 'application/json',
    };

    var body = jsonEncode({
      'LoginFields': {"Devicetoken": userId},
      'Password': 'b0fafb2a-bd86-408e-87f5-cce93619be2c'
    });

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      print('Response data: ${response.body}');
    } else {
      // If the server did not return a 200 OK response,
      print(
          'Failed to login, status code: ${response.statusCode}, body: ${response.body}');
      throw Exception(
          'Failed to load data, status code: ${response.statusCode}');
    }

    print("Login here");
  }

  // Method to reset passsword (Firebase side)
  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print("Password reset email sent to $email");
    } catch (e) {
      print("Failed to send password reset email: $e");
      // Handle the error appropriately
    }
  }

  // Method to change the current user's email
  Future<void> changeEmail(String newEmail) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updateEmail(newEmail);
        print("Email updated successfully to $newEmail");
      } catch (e) {
        print("Failed to update email: $e");
        // Handle the error appropriately
      }
    } else {
      print("No user is currently signed in.");
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  AppUser? getCurrentAppUser() {
    return _userFromFirebaseUser(_auth.currentUser);
  }

  Future<void> addPhysician(String physician) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _database
          .ref('patients/${user.uid}')
          .update({'physician': physician});
    }
  }

  Future<void> addBirthday(String birthday) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _database
          .ref('patients/${user.uid}')
          .update({'birthday': birthday});
    }
  }

  // Future<String> getBirthday() async {
  //    User? user = _auth.currentUser;
  //   // String birthday;
  //    if (user != null) {
  //     await
  //      _database
  //         .ref('patients/${user.uid}/birthday').get();
  //         // .get({'birthday'});
  //   }
  //   return null;
  // }

  // Method to change the current user's password
  Future<void> changePassword(String newPassword) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updatePassword(newPassword);
        print("Password updated successfully.");
      } catch (e) {
        print("Failed to update password: $e");
        // Handle the error appropriately
      }
    } else {
      print("No user is currently signed in.");
    }
  }

  Future<String> fetchSummarySafetyScore(
      String startDate, String endDate, String authToken) async {
    var client = http.Client();
    String statistics = '';
    try {
      var url =
          Uri.parse('https://api.telematicssdk.com/indicators/v2/Scores/safety')
              .replace(queryParameters: {
        'StartDate': startDate,
        'EndDate': endDate,
      });

      final response = await client.get(
        url,
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $authToken',
        },
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data["Result"] != null) {
          statistics = data["Result"]["SafetyScore"].toString();
        } else {
          statistics = "n/a";
        }
      } else {
        print(
            'Failed to fetch daily statistics, status code: ${response.statusCode}, response: ${response.body}');
      }
    } catch (e) {
      print('Error fetching daily statistics: $e');
    } finally {
      client.close();
    }
    return statistics;
  }

  // accumulated totals
  Future<List<String>> fetchStatistics(String authToken) async {
    var client = http.Client();

    List<String> statistics = [];
    String tripCount = "";
    String totalMiles = "";
    String drivingTime = "";
    try {
      var url = Uri.parse(
          'https://api.telematicssdk.com/indicators/v2/statistics?startDate=2024-01-31&endDate=2024-12-31');
      final response = await client.get(
        url,
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data["Result"] != null) {
          tripCount = data["Result"]["DriverTripsCount"].toString();
          totalMiles = data["Result"]["MileageMile"].toString();
          drivingTime = data["Result"]["DrivingTime"].toString();
        } else {
          tripCount = "n/a";
          totalMiles = "n/a";
          drivingTime = "n/a";
        }
        statistics.add(tripCount);
        statistics.add(totalMiles);
        statistics.add(drivingTime);
      } else {
        print(
            'Failed to fetch daily statistics, status code: ${response.statusCode}, response: ${response.body}');
      }
    } catch (e) {
      print('Error fetching daily statistics: $e');
    } finally {
      client.close();
    }
    return statistics;
  }

  // accumulated scores
  Future<List<String>> fetchScores(String authToken) async {
    var client = http.Client();
    List<String> scores = [];
    String accelerationScore = "";
    String brakingScore = "";
    String speedingScore = "";
    String corneringScore = "";
    String phoneScore = "";
    try {
      var url = Uri.parse(
          'https://api.telematicssdk.com/indicators/v2/Scores/safety?startDate=2024-01-31&endDate=2024-12-31');

      final response = await client.get(
        url,
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $authToken',
        },
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data["Result"] != null) {
          accelerationScore = data["Result"]["AccelerationScore"].toString();
          brakingScore = data["Result"]["BrakingScore"].toString();
          speedingScore = data["Result"]["SpeedingScore"].toString();
          corneringScore = data["Result"]["CorneringScore"].toString();
          phoneScore = data["Result"]["PhoneUsageScore"].toString();
        } else {
          accelerationScore = "n/a";
          brakingScore = "n/a";
          speedingScore = "n/a";
          corneringScore = "n/a";
          phoneScore = "n/a";
        }
        scores.add(accelerationScore);
        scores.add(brakingScore);
        scores.add(speedingScore);
        scores.add(corneringScore);
        scores.add(phoneScore);
      } else {
        print(
            'Failed to fetch daily statistics, status code: ${response.statusCode}, response: ${response.body}');
      }
    } catch (e) {
      print('Error fetching daily statistics: $e');
    } finally {
      client.close();
    }
    return scores;
  }

  Future<List<List<String>>> fetchTrips(String authToken, int tripCount) async {
    List<List<String>> trips = [];
    List<String> startDates = [];
    List<String> endDates = [];
    List<String> locations = [];
    List<String> mileages = [];

    List<String> driveDuration = [];
    List<String> avgSpeeds = [];
    List<String> scores = [];
    String startTime = "";
    String endTime = "";

    try {
      final response = await http.post(
        Uri.parse('https://api.telematicssdk.com/trips/get/v1/'),
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'authorization': 'Bearer $authToken'
        },
        body: jsonEncode({
          'StartDate': '2024-01-20T09:46:59.265Z',
          'EndDate': '2024-09-20T09:46:59.265Z',
          'IncludeDetails': true,
          'IncludeStatistics': true,
          'IncludeScores': true,
          'Locale': 'EN',
          'UnitSystem': 'Si',
          'SortBy': 'StartDateUtc',
          'Paging': {'Page': 1, 'Count': 10, 'IncludePagingInfo': true}
        }),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data["Result"] != null) {
          for (int i = 0; i < tripCount; i++) {
            List<String> rawStartDate = data["Result"]['Trips'][i]['Data']
                    ['StartDate']
                .toString()
                .split("T");
            List<String> t = rawStartDate[1].split("-");

            int startHour = int.parse(t[0].substring(0, 2));
            if (startHour > 12) {
              startHour = startHour - 12;
              startTime = rawStartDate[0].substring(5, 7) +
                  "-" +
                  rawStartDate[0].substring(8, 10) +
                  "-" +
                  rawStartDate[0].substring(0, 4) +
                  " " +
                  startHour.toString() +
                  t[0].substring(2, 8) +
                  " PM";
            } else {
              startTime = rawStartDate[0].substring(5, 7) +
                  "-" +
                  rawStartDate[0].substring(8, 10) +
                  "-" +
                  rawStartDate[0].substring(0, 4) +
                  " " +
                  startHour.toString() +
                  t[0].substring(2, 8) +
                  " AM";
            }

            startDates.add(startTime);

            //  List<String> rawEndDate = data["Result"]['Trips'][i]['Data']['EndDate']
            //     .toString()
            //     .split("T");
            //     print(rawEndDate[1]);
            // List<String> endT = rawEndDate[1].split("-");
            // int endHour = int.parse(endT[0].substring(0, 2));
            // // print(endHour);
            // if (endHour > 12) {
            //   endHour = endHour- 12;
            //   endTime = rawEndDate[0].substring(5, 7) +
            //       "-" +
            //       rawEndDate[0].substring(8, 10) +
            //       "-" +
            //       rawEndDate[0].substring(0, 4) +
            //       " " +
            //       endHour.toString() +
            //       t[0].substring(2, 8) +
            //       " PM";
            // } else {
            //   endTime = rawEndDate[0].substring(5, 7) +
            //       "-" +
            //       rawEndDate[0].substring(8, 10) +
            //       "-" +
            //       rawEndDate[0].substring(0, 4) +
            //       " " +
            //       endHour.toString() +
            //       t[0].substring(2, 8) +
            //       " AM";
            // }
            // print(endTime);
            // endDates.add(endTime);

            endDates.add("End Date: " +
                data["Result"]['Trips'][i]['Data']['EndDate'].toString());

            locations.add(data["Result"]['Trips'][i]['Data']['Addresses']
                        ['Start']['Full']
                    .toString() +
                " to " +
                data["Result"]['Trips'][i]['Data']['Addresses']['End']['Full']
                    .toString());

            mileages.add("Mileage (km/h): " +
                data["Result"]['Trips'][i]['Statistics']['Mileage'].toString());
            driveDuration.add("Duration of Drive (min): " +
                data["Result"]['Trips'][i]['Statistics']['DurationMinutes']
                    .toString());
            avgSpeeds.add("Average Speed: " +
                data["Result"]['Trips'][i]['Statistics']['AverageSpeed']
                    .toString());
            scores.add(
                "Scores: " + data["Result"]['Trips'][i]['Scores'].toString());
          }
        }
        trips.add(startDates);
        trips.add(endDates);
        trips.add(locations);

        trips.add(mileages);
        trips.add(driveDuration);
        trips.add(avgSpeeds);
        trips.add(scores);
      } else {
        print(
            'Failed to fetch daily statistics, status code: ${response.statusCode}, response: ${response.body}');
      }
    } catch (e) {
      print('Error fetching daily statistics: $e');
    }

    // return scores;
    return trips;
  }

  // Method to initialize and start tracking with the given device token
  Future<void> initializeAndStartTracking(String deviceToken) async {
    try {
      // Set the device token
      await _trackingApi.setDeviceID(deviceId: deviceToken);
      // Enable sdk
      await _trackingApi.setEnableSdk(enable: true);
      // enable high frequency
      await _trackingApi.enableHF(value: true);
      // turn off disable tracking
      await _trackingApi.setDisableTracking(value: false);
    } catch (e) {
      print("Error initializing and starting tracking: $e");
    }
  }
}
