// lib/screens/guru/guru_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Tetap butuh ini untuk mobile/desktop
import 'package:flutter/foundation.dart' show kIsWeb; // Tambahkan ini!

import '../../provider/user_provider.dart';

import 'evaluasi_nilai_page.dart';
import 'penilaian_pemahaman_page.dart';
import 'rekap_mingguan_page.dart';

class GuruDashboard extends StatefulWidget {
  const GuruDashboard({super.key});

  @override
  State<GuruDashboard> createState() => _GuruDashboardState();
}

class _GuruDashboardState extends State<GuruDashboard> {
  String guruName = "Nama Guru";
  String guruRoleDisplay = "Guru";
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchGuruProfile();
  }

  Future<void> _fetchGuruProfile() async {
    final currentContext = context; // Capture context here

    final userProvider = Provider.of<UserProvider>(currentContext, listen: false); 
    if (userProvider.uid != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userProvider.uid).get();
        
        if (!currentContext.mounted) return;

        if (userDoc.exists) {
          setState(() {
            guruName = userDoc.get('fullName') ?? "Nama Guru";
            guruRoleDisplay = userDoc.get('role') ?? "Guru";
            // Ambil profilePictureUrl dengan aman
            profileImageUrl = (userDoc.data() as Map<String, dynamic>?)?['profilePictureUrl'] as String?; 
          });
        }
      } catch (e) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text("Gagal memuat profil guru: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final currentContext = context; // Capture context here

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (!currentContext.mounted) return; // Check mounted after first await

    if (pickedFile != null) {
      // Ambil userProvider dan UID setelah memastikan context masih mounted
      final userProvider = Provider.of<UserProvider>(currentContext, listen: false);
      String? uid = userProvider.uid;

      if (uid == null) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text("Pengguna tidak terautentikasi."), backgroundColor: Colors.red),
          );
        }
        return;
      }

      try {
        String fileName = 'profile_pictures/$uid.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        if (kIsWeb) {
          // Logika untuk platform web (browser)
          // Di web, image_picker mengembalikan XFile tanpa path yang bisa digunakan oleh dart:io.File.
          // Kita perlu membaca konten file sebagai bytes.
          final bytes = await pickedFile.readAsBytes();
          await storageRef.putData(bytes); // Upload bytes
        } else {
          // Logika untuk platform mobile (Android/iOS) atau desktop
          // Di platform native, XFile memiliki path yang bisa digunakan untuk membuat File object.
          // Menghapus '!' karena path dijamin ada di sini.
          File imageFile = File(pickedFile.path); 
          await storageRef.putFile(imageFile); // Upload File
        }

        String downloadUrl = await storageRef.getDownloadURL();

        if (!currentContext.mounted) return; // Check mounted after Firebase Storage operations

        // Update URL di Firestore user document
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'profilePictureUrl': downloadUrl,
        });

        if (!currentContext.mounted) return; // Check mounted before setState and UI operations

        // Update state dan UserProvider
        setState(() {
          profileImageUrl = downloadUrl;
        });
        userProvider.updateProfilePictureUrl(downloadUrl); // Update di provider
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text("Foto profil berhasil diunggah!"), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text("Gagal mengunggah foto: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // PENTING: Pindahkan method helper ini ke luar method build, di dalam class _GuruDashboardState
  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: CircleAvatar(
          backgroundColor: iconColor.withAlpha((255 * 0.1).round()),
          child: Icon(icon, color: iconColor),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentProfileImage = userProvider.profilePictureUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: currentProfileImage != null && currentProfileImage.isNotEmpty
                        ? NetworkImage(currentProfileImage) as ImageProvider
                        : const AssetImage('assets/images/guru_profile.jpg'),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guruName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(guruRoleDisplay, style: const TextStyle(color: Colors.grey)),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.smart_toy, size: 32, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            title: "Evaluasi Nilai Akademik",
            subtitle: "Tinjau dan perbarui nilai siswa",
            icon: Icons.school,
            iconColor: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EvaluasiNilaiPage())),
          ),
          _buildMenuItem(
            context,
            title: "Penilaian Pemahaman",
            subtitle: "Lacak pemahaman siswa",
            icon: Icons.menu_book,
            iconColor: Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PenilaianPemahamanPage())),
          ),
          _buildMenuItem(
            context,
            title: "Rekap Mingguan",
            subtitle: "Melihat ringkasan kinerja kelas",
            icon: Icons.show_chart,
            iconColor: Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RekapMingguanPage())),
          ),
        ],
      ),
    );
  }
}