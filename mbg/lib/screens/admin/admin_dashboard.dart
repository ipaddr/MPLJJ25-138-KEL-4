// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../../provider/user_provider.dart'; // Import UserProvider

import 'input_data_siswa_page.dart';
import 'distribusi_makanan_page.dart';
import 'laporan_konsumsi_page.dart';

class AdminDashboard extends StatefulWidget { // Ubah menjadi StatefulWidget
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String adminName = "Admin Sekolah"; // Default value
  String schoolName = "Nama Sekolah Anda"; // Default value
  bool isSchoolVerified = false; // Status verifikasi

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile();
  }

  Future<void> _fetchAdminProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.uid != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userProvider.uid).get();
        if (!mounted) return; // Check mounted

        if (userDoc.exists) {
          setState(() {
            adminName = userDoc.get('fullName') ?? "Admin Sekolah";
            schoolName = userDoc.get('schoolName') ?? "Nama Sekolah Anda";
            isSchoolVerified = userDoc.get('isSchoolVerified') ?? false; // Ambil status verifikasi
          });
        }
      } catch (e) {
        if (mounted) { // Check mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memuat profil admin: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _verifySchool() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userProvider.uid).update({
          'isSchoolVerified': true,
          'verifiedAt': Timestamp.now(),
        });
        if (!mounted) return; // Check mounted
        setState(() {
          isSchoolVerified = true;
        });
        if (mounted) { // Check mounted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sekolah berhasil diverifikasi!"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) { // Check mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memverifikasi sekolah: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Row
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage('assets/images/foto.png'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(adminName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Admin Sekolah", style: TextStyle(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.notifications_none),
            ],
          ),

          const SizedBox(height: 20),

          // Verifikasi Sekolah
          const Text("Verifikasi Sekolah", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true, // Tidak perlu diedit, hanya tampilkan
                  controller: TextEditingController(text: schoolName), // Tampilkan nama sekolah
                  decoration: InputDecoration(
                    hintText: "Nama Sekolah",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Tombol Verifikasi
              isSchoolVerified
                  ? Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.green),
                    )
                  : Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.warning, color: Colors.orange),
                        onPressed: _verifySchool, // Panggil fungsi verifikasi
                      ),
                    ),
            ],
          ),

          const SizedBox(height: 24),

          // Statistik (Ini masih dummy, perlu diupdate dari Firestore)
          const Text("Statistik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.people, "Siswa", "1,234", Colors.blue),
              _buildStatItem(Icons.restaurant, "Total diterima\n(Hari ini)", "892", Colors.green),
              _buildStatItem(Icons.pie_chart, "Total konsumsi\n(Mingguan)", "5,521", Colors.purple),
            ],
          ),

          const SizedBox(height: 32),

          // Menu
          const Text("Menu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          _buildMenuItem(context, Icons.school, "Input Data Siswa", "Kelola informasi siswa", Colors.blue.shade100, const InputDataSiswaPage()),
          _buildMenuItem(context, Icons.rice_bowl, "Distribusi Makanan", "Lacak distribusi harian", Colors.green.shade100, const DistribusiMakananPage()),
          _buildMenuItem(context, Icons.bar_chart, "Laporan Konsumsi", "Lihat statistik harian", Colors.purple.shade100, const LaporanKonsumsiPage()),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String subtitle, Color bgColor, Widget page) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: bgColor,
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}