import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: Center(
        child: const Text(
          'Selamat datang di Aplikasi Makan Bergizi!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
