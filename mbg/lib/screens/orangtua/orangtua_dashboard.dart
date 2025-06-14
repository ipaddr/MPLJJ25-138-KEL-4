// lib/screens/orangtua/orangtua_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart'; // Pastikan path benar
import 'package:intl/intl.dart'; // Untuk format tanggal konsumsi

class OrangTuaDashboard extends StatefulWidget {
  const OrangTuaDashboard({super.key});

  @override
  State<OrangTuaDashboard> createState() => _OrangTuaDashboardState();
}

class _OrangTuaDashboardState extends State<OrangTuaDashboard> {
  final TextEditingController nisController = TextEditingController();
  final TextEditingController sekolahController = TextEditingController();

  String parentName = "Nama Orang Tua";
  bool isApproved = false; // Status persetujuan dari Admin
  List<String> childIds = []; // ID siswa yang terhubung
  Map<String, dynamic>? childProfile; // Profil anak yang terpilih
  Map<String, Map<String, bool>> childDailyConsumption = {}; // Status makan anak hari ini

  @override
  void initState() {
    super.initState();
    _fetchParentProfile();
    // Jika sudah disetujui, langsung fetch data anak
    // _fetchChildData(); // Ini akan dipanggil setelah isApproved
  }

  Future<void> _fetchParentProfile() async {
    final currentContext = context;
    final userProvider = Provider.of<UserProvider>(currentContext, listen: false);
    String? uid = userProvider.uid;

    if (uid == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!currentContext.mounted) return;

      if (userDoc.exists) {
        setState(() {
          parentName = userDoc.get('fullName') ?? "Nama Orang Tua";
          isApproved = userDoc.get('isApproved') ?? false;
          childIds = List<String>.from(userDoc.get('childIds') ?? []); // Ambil childIds
        });
        if (isApproved && childIds.isNotEmpty) {
          _fetchChildData(childIds.first); // Ambil data anak pertama jika disetujui
        }
      }
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal memuat profil orang tua: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _requestAccess() async {
    final currentContext = context;
    final userProvider = Provider.of<UserProvider>(currentContext, listen: false);
    String? parentUid = userProvider.uid;

    if (parentUid == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text("Anda harus login untuk mengajukan permintaan."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (nisController.text.isEmpty || sekolahController.text.isEmpty) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text("Harap isi NIS Anak dan Nama Sekolah."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Cari siswa berdasarkan NIS dan nama sekolah yang diinput
    QuerySnapshot studentSnapshot = await FirebaseFirestore.instance.collection('students')
        .where('nis', isEqualTo: nisController.text.trim())
        .get(); // Filter by NIS

    String? studentIdToRequest;
    if (studentSnapshot.docs.isNotEmpty) {
      // Lebih baik mencari sekolah dulu
      QuerySnapshot schoolSnapshot = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'Admin Sekolah')
          .where('schoolName', isEqualTo: sekolahController.text.trim())
          .limit(1)
          .get();

      if (schoolSnapshot.docs.isNotEmpty) {
        String adminSchoolId = schoolSnapshot.docs.first.id; // ID dokumen Admin yang sekolahnya cocok
        // Cari siswa yang NIS-nya cocok dan ada di sekolah tersebut
        QuerySnapshot finalStudentCheck = await FirebaseFirestore.instance.collection('students')
            .where('nis', isEqualTo: nisController.text.trim())
            .where('schoolId', isEqualTo: adminSchoolId) // Pastikan siswa ada di sekolah yang dimaksud
            .limit(1)
            .get();

        if (finalStudentCheck.docs.isNotEmpty) {
          studentIdToRequest = finalStudentCheck.docs.first.id;
        } else {
          if (currentContext.mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(content: Text("NIS anak tidak ditemukan di sekolah tersebut."), backgroundColor: Colors.red),
            );
          }
          return;
        }
      } else {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text("Nama sekolah tidak ditemukan."), backgroundColor: Colors.red),
          );
        }
        return;
      }
    } else {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text("NIS anak tidak ditemukan."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Jika siswa ditemukan, buat permintaan akses
    try {
      await FirebaseFirestore.instance.collection('parentApprovalRequests').add({
        'parentId': parentUid,
        'childNis': nisController.text.trim(),
        'childId': studentIdToRequest, // Simpan ID siswa
        'schoolName': sekolahController.text.trim(),
        'schoolId': (await FirebaseFirestore.instance.collection('users').doc(studentIdToRequest).get()).get('schoolId'), // Ambil schoolId dari siswa
        'status': 'pending',
        'requestedAt': Timestamp.now(),
      });
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text("Permintaan akses berhasil dikirim! Menunggu persetujuan Admin Sekolah."), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal mengajukan permintaan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Fungsi untuk mengambil data anak (setelah disetujui)
  Future<void> _fetchChildData(String childId) async {
    final currentContext = context;
    try {
      DocumentSnapshot childDoc = await FirebaseFirestore.instance.collection('students').doc(childId).get();
      if (!currentContext.mounted) return;

      if (childDoc.exists) {
        setState(() {
          childProfile = childDoc.data() as Map<String, dynamic>;
        });

        // Ambil data konsumsi harian anak
        final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());
        DocumentSnapshot consumptionDoc = await FirebaseFirestore.instance.collection('dailyConsumptions')
            .doc('${childId}_$todayFormatted').get();

        if (!currentContext.mounted) return;
        if (consumptionDoc.exists) {
          setState(() {
            childDailyConsumption[childId] = {
              'makanPagi': consumptionDoc.get('makanPagi') ?? false,
              'makanSiang': consumptionDoc.get('makanSiang') ?? false,
            };
          });
        }
      }
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal memuat data anak: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Foto, Nama, Role, dan Notifikasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage('assets/images/foto.png'), // Ganti dengan foto profil orang tua
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(parentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('Orang Tua', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.notifications_none),
                ],
              ),
              const SizedBox(height: 40),

              // Tampilan utama berdasarkan status persetujuan
              if (!isApproved) // Jika belum disetujui
                _buildApprovalRequestForm()
              else if (childIds.isEmpty) // Jika disetujui tapi belum ada anak terdaftar
                _buildNoChildFound()
              else // Jika disetujui dan ada anak
                _buildChildDashboard(userProvider.childIds![0]), // Menampilkan anak pertama
            ],
          ),
        ),
      ),
    );
  }

  // Form pengajuan akses
  Widget _buildApprovalRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ajukan Akses Data Anak',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('NIS Anak', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: nisController,
          decoration: InputDecoration(
            hintText: 'Masukkan NIS anak anda',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        const Text('Nama Sekolah', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: sekolahController,
          decoration: InputDecoration(
            hintText: 'Masukkan nama sekolah anak anda',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _requestAccess,
            child: const Text('Ajukan Akses', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text("Status: Menunggu konfirmasi admin sekolah...", style: TextStyle(color: Colors.orange))),
      ],
    );
  }

  // Tampilan jika belum ada anak terdaftar (setelah disetujui)
  Widget _buildNoChildFound() {
    return Column(
      children: const [
        Text("Anda sudah disetujui, tetapi belum ada data anak yang terhubung.", style: TextStyle(fontSize: 16)),
        SizedBox(height: 10),
        Text("Pastikan NIS anak Anda sudah terdaftar oleh Admin Sekolah.", style: TextStyle(fontSize: 14, color: Colors.grey)),
        // Tambahkan tombol untuk mengajukan lagi atau refresh jika perlu
      ],
    );
  }


  // Dashboard anak (setelah disetujui dan anak terhubung)
  Widget _buildChildDashboard(String childId) {
    // Pastikan childProfile sudah dimuat
    if (childProfile == null) {
      _fetchChildData(childId); // Coba muat ulang jika null
      return const Center(child: CircularProgressIndicator());
    }

    final String childName = childProfile?['nama'] ?? 'Anak Anda';
    final String childClass = childProfile?['kelas'] ?? 'N/A';
    final String childNisDisplay = childProfile?['nis'] ?? 'N/A';

    final todayFormatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    final statusMakanPagi = childDailyConsumption[childId]?['makanPagi'] ?? false;
    final statusMakanSiang = childDailyConsumption[childId]?['makanSiang'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Data Anak: $childName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Kelas: $childClass", style: const TextStyle(fontSize: 16)),
        Text("NIS: $childNisDisplay", style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 20),

        const Text("Status Makan Hari Ini", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(todayFormatted, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),

        _buildMealStatusTile("Makan Pagi", Icons.breakfast_dining, statusMakanPagi),
        const SizedBox(height: 8),
        _buildMealStatusTile("Makan Siang", Icons.lunch_dining, statusMakanSiang),
        const SizedBox(height: 20),

        // Tambahan: Ringkasan Nilai Akademik atau Penilaian Pemahaman
        const Text("Ringkasan Akademik", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Ini akan memerlukan query data dari 'academicEvaluations' atau 'understandingAssessments'
        // untuk anak ini dan ditampilkan di sini.
        // Untuk sederhana, Anda bisa tampilkan pesan dummy atau nilai rata-rata dari data anak
        const Text("Nilai Akademik Terakhir: 85 (Baik)", style: TextStyle(color: Colors.black54)),
        const Text("Penilaian Fokus: Meningkat", style: TextStyle(color: Colors.black54)),

        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fitur detail anak akan datang!")),
              );
            },
            child: const Text("Lihat Detail Lengkap"),
          ),
        ),
      ],
    );
  }

  // Helper untuk tile status makan
  Widget _buildMealStatusTile(String title, IconData icon, bool isEaten) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEaten ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isEaten ? Colors.green.shade800 : Colors.red.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            isEaten ? "Sudah Makan" : "Belum Makan",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isEaten ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }
}