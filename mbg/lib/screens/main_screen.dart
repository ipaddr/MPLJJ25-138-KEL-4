import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

// Import semua halaman dashboard
import 'admin/admin_dashboard.dart';
import 'guru/guru_dashboard.dart';
import 'orangtua/orangtua_dashboard.dart';
import 'dinas/dinas_dashboard.dart';
import 'katering/katering_dashboard.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<UserProvider>(context).role;

    Widget page;

    switch (userRole) {
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
        page = const Center(child: Text("Role tidak dikenali"));
    }

    return Scaffold(
      body: page,
    );
  }
}
