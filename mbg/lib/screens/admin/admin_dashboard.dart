import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../provider/user_provider.dart';

import 'input_data_siswa_page.dart';
import 'distribusi_makanan_page.dart';
import 'laporan_konsumsi_page.dart';
import 'parent_approval_page.dart'; // Added this import

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String adminName = "Admin Sekolah";
  String schoolName = "Nama Sekolah Anda";
  bool isSchoolVerified = false; // This will now represent if a verification request has been sent
  String? profileImageUrl;
  int pendingApprovalCount = 0; // Added for notification count

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile();
    _listenToParentApprovalRequests(); // New listener for parent approval requests
  }

  // Listener for parent approval requests
  void _listenToParentApprovalRequests() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String? adminSchoolId = userProvider.schoolId; // Assuming schoolId is available in UserProvider

    if (adminSchoolId == null) return;

    FirebaseFirestore.instance
        .collection('parentApprovalRequests')
        .where('schoolId', isEqualTo: adminSchoolId) // Filter by admin's school
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        pendingApprovalCount = snapshot.docs.length;
      });
    });
  }

  Future<void> _fetchAdminProfile() async {
    final currentContext = context;

    final userProvider = Provider.of<UserProvider>(
      currentContext,
      listen: false,
    );
    if (userProvider.uid != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userProvider.uid)
            .get();

        if (!currentContext.mounted) return;

        if (userDoc.exists) {
          setState(() {
            adminName = userDoc.get('fullName') ?? "Admin Sekolah";
            schoolName = userDoc.get('schoolName') ?? "Nama Sekolah Anda";
            // Check for 'schoolVerificationStatus' if it exists, otherwise use 'isSchoolVerified'
            isSchoolVerified = userDoc.get('schoolVerificationStatus') == 'Menunggu Verifikasi' ||
                userDoc.get('isSchoolVerified') == true;
            profileImageUrl =
                (userDoc.data() as Map<String, dynamic>?)?['profilePictureUrl']
                    as String?;
          });
        }
      } catch (e) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text("Gagal memuat profil admin: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final currentContext = context;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (!currentContext.mounted) return;

    if (pickedFile != null) {
      final userProvider = Provider.of<UserProvider>(
        currentContext,
        listen: false,
      );
      String? uid = userProvider.uid;

      if (uid == null) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(
              content: Text("Pengguna tidak terautentikasi."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        String fileName = 'profile_pictures/$uid.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          await storageRef.putData(bytes);
        } else {
          File imageFile = File(pickedFile.path);
          await storageRef.putFile(imageFile);
        }

        String downloadUrl = await storageRef.getDownloadURL();

        if (!currentContext.mounted) return;

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'profilePictureUrl': downloadUrl,
        });

        if (!currentContext.mounted) return;

        setState(() {
          profileImageUrl = downloadUrl;
        });
        userProvider.updateProfilePictureUrl(downloadUrl);
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text("Foto profil berhasil diunggah!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text("Gagal mengunggah foto: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Modified to initiate school verification request to Dinas
  Future<void> _requestSchoolVerification() async {
    final currentContext = context;
    final userProvider = Provider.of<UserProvider>(currentContext, listen: false);
    String? uid = userProvider.uid;
    String? schoolId = userProvider.schoolId; // Assuming schoolId exists in UserProvider

    if (uid == null || schoolId == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text("ID Admin atau Sekolah tidak ditemukan."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      // Admin submits a verification request to Dinas Pendidikan.
      // The 'isSchoolVerified' status will be changed by Dinas later.
      // Here, we just mark that the Admin has submitted the request.
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'schoolVerificationStatus': 'Menunggu Verifikasi', // New status in Admin profile
        'verificationRequestedAt': Timestamp.now(),
      });

      // Optional: Create a document in a 'schoolVerificationRequests' collection
      // if Dinas needs to see them separately.
      // await FirebaseFirestore.instance.collection('schoolVerificationRequests').add({
      //   'schoolId': schoolId,
      //   'adminId': uid,
      //   'status': 'pending',
      //   'requestedAt': Timestamp.now(),
      // });

      if (!currentContext.mounted) return;
      setState(() {
        isSchoolVerified = true; // 'true' now means a request has been sent
      });
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text("Permintaan verifikasi sekolah berhasil dikirim ke Dinas Pendidikan!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal mengirim permintaan verifikasi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
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
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color bgColor,
    Widget page,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: bgColor,
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentProfileImage = profileImageUrl ?? userProvider.profilePictureUrl;

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
                    radius: 30,
                    backgroundImage:
                        currentProfileImage != null && currentProfileImage.isNotEmpty
                            ? NetworkImage(currentProfileImage) as ImageProvider
                            : const AssetImage('assets/images/foto.png'),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(adminName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text("Admin Sekolah", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                // Notification button for Parent Approval Requests
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ParentApprovalPage()), // Navigate to approval page
                    );
                  },
                  child: Stack(
                    children: [
                      const Icon(Icons.notifications_none, size: 28),
                      if (pendingApprovalCount > 0)
                        Positioned(
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              pendingApprovalCount.toString(),
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // School Verification
          const Text("Verifikasi Sekolah", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(text: schoolName),
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
              // Verification Button/Indicator
              // isSchoolVerified now indicates if a request has been sent
              isSchoolVerified
                  ? Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100, // Yellow for 'Pending Verification'
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Tooltip(
                        // Add Tooltip for explanation
                        message: "Permintaan verifikasi telah dikirim ke Dinas Pendidikan.",
                        child: Icon(Icons.pending, color: Colors.orange),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.gpp_maybe,
                            color: Colors.blue), // Icon to request verification
                        onPressed: _requestSchoolVerification, // Admin requests verification
                      ),
                    ),
            ],
          ),

          const SizedBox(height: 24),

          // Statistics (Dummy, will be filled later from Firestore)
          const Text("Statistik",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.people, "Siswa", "1,234", Colors.blue),
              _buildStatItem(Icons.restaurant, "Total diterima\n(Hari ini)",
                  "892", Colors.green),
              _buildStatItem(Icons.pie_chart, "Total konsumsi\n(Mingguan)",
                  "5,521", Colors.purple),
            ],
          ),

          const SizedBox(height: 32),

          // Admin Menu
          const Text("Menu",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          _buildMenuItem(
              context,
              Icons.school,
              "Input Data Siswa",
              "Kelola informasi siswa",
              Colors.blue.shade100,
              const InputDataSiswaPage()),
          _buildMenuItem(
              context,
              Icons.rice_bowl,
              "Distribusi Makanan",
              "Lacak distribusi harian",
              Colors.green.shade100,
              const DistribusiMakananPage()),
          _buildMenuItem(
              context,
              Icons.bar_chart,
              "Laporan Konsumsi",
              "Lihat statistik harian",
              Colors.purple.shade100,
              const LaporanKonsumsiPage()),
          _buildMenuItem(
            context,
            Icons.approval,
            "Permintaan Akses Orang Tua",
            "Setujui atau tolak permintaan akses orang tua",
            Colors.orange.shade100,
            const ParentApprovalPage(),
          ),
        ],
      ),
    );
  }
}