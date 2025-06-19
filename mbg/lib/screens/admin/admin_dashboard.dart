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
import 'parent_approval_page.dart';
import '../guru/chatbot_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String adminName = "Admin Sekolah";
  String schoolName = "Nama Sekolah Anda";
  bool isSchoolVerified = false;
  String? profileImageUrl;
  int pendingApprovalCount = 0;
  String schoolVerificationStatus = "Belum Mengajukan";

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile();
    _listenToParentApprovalRequests();
    _listenToSchoolVerificationStatus();
  }

  void _listenToParentApprovalRequests() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String? adminSchoolId = userProvider.schoolId;

    if (adminSchoolId == null) return;

    FirebaseFirestore.instance
        .collection('parentApprovalRequests')
        .where('schoolId', isEqualTo: adminSchoolId)
        .where('status', isEqualTo: 'pending') 
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        pendingApprovalCount = snapshot.docs.length;
      });
    });
  }

  void _listenToSchoolVerificationStatus() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String? adminSchoolId = userProvider.schoolId;

    if (adminSchoolId == null) return;
    FirebaseFirestore.instance
        .collection('schools')
        .doc(adminSchoolId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists) {
        setState(() {
          isSchoolVerified = snapshot.get('isVerified') ?? false;
        });
      } else {
        setState(() {
          isSchoolVerified = false;
        });
      }
    });

    FirebaseFirestore.instance
        .collection('schoolVerificationRequests')
        .where('schoolId', isEqualTo: adminSchoolId)
        .orderBy('requestedAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.docs.isNotEmpty) {
        String status = snapshot.docs.first.get('status') ?? "Belum Mengajukan";
        setState(() {
          schoolVerificationStatus = status;
        });
      } else {
        setState(() {
          schoolVerificationStatus = "Belum Mengajukan";
        });
      }
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
            profileImageUrl =
                (userDoc.data() as Map<String, dynamic>?)?['profilePictureUrl']
                    as String?;
          });
        }
      } catch (e) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text("Gagal memuat profil admin: $e"), backgroundColor: Colors.red),
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
                backgroundColor: Colors.red),
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
              backgroundColor: Colors.green),
        );
      } catch (e) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
                content: Text("Gagal mengunggah foto: $e"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _requestSchoolVerification() async {
    final currentContext = context;
    final userProvider = Provider.of<UserProvider>(currentContext, listen: false);
    String? uid = userProvider.uid;
    String? schoolId = userProvider.schoolId;
    String? currentSchoolName = userProvider.schoolName;

    if (uid == null || schoolId == null || currentSchoolName == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text("ID Admin, Sekolah, atau Nama Sekolah tidak ditemukan. Pastikan Anda sudah terdaftar sebagai Admin Sekolah dengan nama sekolah."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      QuerySnapshot existingRequest = await FirebaseFirestore.instance.collection('schoolVerificationRequests')
          .where('schoolId', isEqualTo: schoolId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text("Permintaan verifikasi sudah ada dan sedang menunggu proses."), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('schoolVerificationRequests').add({
        'schoolId': schoolId,
        'schoolName': currentSchoolName,
        'adminUserId': uid,
        'adminName': adminName,
        'status': 'pending',
        'requestedAt': Timestamp.now(),
      });

      if (!currentContext.mounted) return;
      setState(() {
        schoolVerificationStatus = 'pending';
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
    Color verificationColor;
    IconData verificationIcon;
    String verificationMessage;

    if (isSchoolVerified) {
      verificationColor = Colors.green.shade100;
      verificationIcon = Icons.check_circle;
      verificationMessage = "Sekolah Terverifikasi";
    } else if (schoolVerificationStatus == 'pending') {
      verificationColor = Colors.orange.shade100;
      verificationIcon = Icons.pending;
      verificationMessage = "Menunggu Verifikasi";
    } else if (schoolVerificationStatus == 'rejected') {
      verificationColor = Colors.red.shade100;
      verificationIcon = Icons.cancel;
      verificationMessage = "Verifikasi Ditolak";
    } else {
      verificationColor = Colors.blue.shade100;
      verificationIcon = Icons.gpp_maybe;
      verificationMessage = "Ajukan Verifikasi";
    }

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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatbotPage()),
                        );
                      },
                      child: Stack(
                        children: [
                          const Icon(Icons.smart_toy, size: 28),
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text('!', style: TextStyle(fontSize: 10, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ParentApprovalPage()),
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
              ],
            ),
          ),

          const SizedBox(height: 20),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: verificationColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isSchoolVerified
                    ? Tooltip(
                        message: "Sekolah ini telah diverifikasi oleh Dinas Pendidikan.",
                        child: Icon(verificationIcon, color: Colors.green.shade800),
                      )
                    : IconButton(
                        icon: Icon(verificationIcon, color: verificationIcon == Icons.gpp_maybe ? Colors.blue.shade800 : (verificationIcon == Icons.pending ? Colors.orange.shade800 : Colors.red.shade800)),
                        onPressed: schoolVerificationStatus == 'pending' || schoolVerificationStatus == 'approved'
                            ? null
                            : _requestSchoolVerification,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              verificationMessage,
              style: TextStyle(
                color: verificationIcon == Icons.gpp_maybe ? Colors.blue.shade800 : (verificationIcon == Icons.pending ? Colors.orange.shade800 : (verificationIcon == Icons.cancel ? Colors.red.shade800 : Colors.green.shade800)),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),


          const SizedBox(height: 24),
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