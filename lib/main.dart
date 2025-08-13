import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloc Splash Screen Demo',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
