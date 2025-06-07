import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'splash_screen1.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Makan Gizi Gratis',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const SplashScreen1(),
    );
  }
}