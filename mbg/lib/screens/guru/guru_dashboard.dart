import 'package:flutter/material.dart';

class GuruDashboard extends StatelessWidget {
  const GuruDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage('assets/images/guru_profile.jpg'), // Ganti sesuai path gambar
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Sarah Parker", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Guru Kelas 5", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                Stack(
                  children: [
                    const Icon(Icons.notifications_none, size: 28),
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('3', style: TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Robot Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.smart_toy, size: 32, color: Colors.blue),
            ),
          ),

          const SizedBox(height: 24),
          const Text("Menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Menu cards
          _buildMenuItem(
            context,
            title: "Evaluasi Nilai Akademik",
            subtitle: "Tinjau dan perbarui nilai siswa",
            icon: Icons.school,
            iconColor: Colors.blue,
          ),
          _buildMenuItem(
            context,
            title: "Penilaian Pemahaman",
            subtitle: "Lacak pemahaman siswa",
            icon: Icons.menu_book,
            iconColor: Colors.green,
          ),
          _buildMenuItem(
            context,
            title: "Rekap Mingguan",
            subtitle: "Melihat ringkasan kinerja kelas",
            icon: Icons.show_chart,
            iconColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        onTap: () {
          // TODO: navigasi ke halaman terkait
        },
      ),
    );
  }
}