import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

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
                children: const [
                  Text("John Smith", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Admin Sekolah", style: TextStyle(color: Colors.grey)),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.smart_toy, color: Colors.blue),
              )
            ],
          ),

          const SizedBox(height: 24),

          // Statistik
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
          _buildMenuItem(Icons.school, "Input Data Siswa", "Kelola informasi siswa", Colors.blue.shade100),
          _buildMenuItem(Icons.rice_bowl, "Distribusi Makanan", "Lacak distribusi harian", Colors.green.shade100),
          _buildMenuItem(Icons.bar_chart, "Laporan Konsumsi", "Lihat statistik harian", Colors.purple.shade100),
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

  Widget _buildMenuItem(IconData icon, String title, String subtitle, Color bgColor) {
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
        onTap: () {}, // TODO: navigasi ke halaman terkait
      ),
    );
  }
}