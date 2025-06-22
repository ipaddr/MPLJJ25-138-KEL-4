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
        if (userProvider.isLoading || !userProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final currentContext = context;
        if (userProvider.uid == null) {
          Future.microtask(() {
            if (currentContext.mounted) {
              Navigator.of(currentContext).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            }
          });
          return const SizedBox.shrink();
        }
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
            Future.microtask(() {
              if (currentContext.mounted) {
                Navigator.of(currentContext).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            });
            return const SizedBox.shrink();
        }
        return Scaffold(body: page);
      },
    );
  }
}