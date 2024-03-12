import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// import 'package:telematics_sdk_example/screens/title_screen.dart';
import 'package:telematics_sdk_example/screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TelematicsSDK Example',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xff627CB2),
          onPrimary: Colors.black,
          secondary: Color(0xffD3A94A),
          onSecondary: Colors.black,
          tertiary: Color(0xff1A2B4E),
          error: Colors.red,
          onError: Colors.white,
          background: Colors.white,
          onBackground: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomeScreen(),
    );
  }
}
