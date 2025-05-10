import 'package:flutter/material.dart';
import 'Login/Login_Screen.dart'; // Sesuaikan dengan struktur folder

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Makan Bergizi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginScreen(), // pastikan LoginScreen adalah nama class-nya
    );
  }
}
