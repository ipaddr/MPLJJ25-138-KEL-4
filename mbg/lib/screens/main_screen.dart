import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mbg/provider/user_provider.dart';
import 'package:mbg/screens/admin/admin_dashboard.dart';
import 'package:mbg/screens/guru/guru_dashboard.dart';
import 'package:mbg/screens/orangtua/orangtua_dashboard.dart';
import 'package:mbg/screens/dinas/dinas_dashboard.dart';
import 'package:mbg/screens/katering/katering_dashboard.dart';
import '../login/login_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Tampilkan loading jika UserProvider masih dalam proses inisialisasi
        if (userProvider.isLoading || !userProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Jika tidak ada user yang login (uid null), arahkan ke LoginScreen
        if (userProvider.uid == null) {
          // Menggunakan Future.microtask untuk menunda navigasi
          // agar tidak terjadi error saat build
          Future.microtask(() {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(), // <--- Navigasi ke LoginScreen
              ),
            );
          });
          return const SizedBox.shrink(); // Tampilkan widget kosong sementara navigasi terjadi
        }

        // Jika ada user yang login, tentukan dashboard berdasarkan role
        Widget page;
        switch (userProvider.role) {
          case 'Admin Sekolah':
            page = const AdminDashboard();
            break;
          case 'Guru':
            page = const GuruDashboard();
            break;
          case 'Orang Tua':
            page = const OrangTuaDashboard();
            break;
          case 'Dinas Pendidikan':
            page = const DinasDashboard();
            break;
          case 'Tim Katering':
            page = const KateringDashboard();
            break;
          default:
            // Jika role tidak dikenal, juga arahkan ke LoginScreen atau halaman error
            Future.microtask(() {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(), // <--- Navigasi ke LoginScreen
                ),
              );
            });
            return const SizedBox.shrink(); // Tampilkan widget kosong sementara navigasi terjadi
        }
        return Scaffold(body: page);
      },
    );
  }
}