import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // PENTING!
import '../provider/user_provider.dart'; // ✅ path yang benar

// Import semua halaman dashboard
import 'admin/admin_dashboard.dart';
import 'guru/guru_dashboard.dart';
import 'orangtua/orangtua_dashboard.dart';
import 'dinas/dinas_dashboard.dart';
import 'katering/katering_dashboard.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<UserProvider>(context).role;

    List<Widget> pages;

    switch (userRole) {
      case 'Admin Sekolah':
        pages = [const AdminDashboard(), Placeholder(), Placeholder()];
        break;
      case 'Guru':
        pages = [const GuruDashboard(), Placeholder(), Placeholder()];
        break;
      case 'Orang Tua':
        pages = [const OrangTuaDashboard(), Placeholder(), Placeholder()];
        break;
      case 'Dinas Pendidikan':
        pages = [const DinasDashboard(), Placeholder(), Placeholder()];
        break;
      case 'Tim Katering':
        pages = [const KateringDashboard(), Placeholder(), Placeholder()];
        break;
      default:
        pages = [const Center(child: Text("Role tidak dikenali"))];
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Fitur"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Lainnya"),
        ],
      ),
    );
  }
}