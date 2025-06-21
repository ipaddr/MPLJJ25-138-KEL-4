import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart'; // Import UserProvider
import '../screens/main_screen.dart'; // Import MainScreen

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});

  @override
  State<SplashScreen2> createState() => _SplashScreen2State();
}

class _SplashScreen2State extends State<SplashScreen2> {
  @override
  void initState() {
    super.initState();
    // Panggil fungsi untuk memeriksa user dan navigasi
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Langsung arahkan ke MainScreen setelah userProvider siap
    // UserProvider akan secara otomatis mendengarkan auth state changes
    // dan update role/data user.
    // Kita perlu menunggu sebentar untuk memastikan stream authStateChanges
    // dan stream dokumen user di UserProvider punya waktu untuk bekerja.

    // Menunggu hingga UserProvider selesai memuat data awal
    // Ini penting jika UserProvider melakukan fetching async di constructor/init
    await userProvider.initializeUser(); // Panggil fungsi inisialisasi yang akan kita buat di UserProvider

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue, // Warna latar belakang splash screen 2
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'Memuat data...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}