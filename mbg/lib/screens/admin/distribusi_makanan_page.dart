import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';

class DistribusiMakananPage extends StatefulWidget {
  const DistribusiMakananPage({super.key});

  @override
  State<DistribusiMakananPage> createState() => _DistribusiMakananPageState();
}

class _DistribusiMakananPageState extends State<DistribusiMakananPage> {
  String mode = '';
  final TextEditingController kelasController = TextEditingController();
  final TextEditingController hadirController = TextEditingController();

  Map<String, dynamic>? currentMenu;
  String? currentDistributionDocId;
  String deliveryStatus = "Pending";

  List<Map<String, dynamic>> listedStudents =
      []; // Data siswa yang akan ditampilkan
  Map<String, Map<String, bool>> studentConsumptionStatus =
      {}; // {studentId: {'pagi': true, 'siang': false}}

  @override
  void initState() {
    super.initState();
    _fetchDailyMenuAndDistribution();
    _fetchStudentsForVerification(); // Panggil ini untuk mengambil data siswa
  }

  Future<void> _fetchStudentsForVerification() async {
    final currentContext = context; // Capture context

    try {
      QuerySnapshot studentSnapshot =
          await FirebaseFirestore.instance.collection('students').get();
      if (!currentContext.mounted) return;

      List<Map<String, dynamic>> tempStudents = [];
      Map<String, Map<String, bool>> tempConsumptionStatus = {};

      for (var doc in studentSnapshot.docs) {
        String studentId = doc.id;
        String studentName = doc.get('nama') ?? 'Nama Tidak Diketahui';

        // Ambil status konsumsi untuk siswa ini dan hari ini
        final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());
        DocumentSnapshot consumptionDoc =
            await FirebaseFirestore.instance
                .collection(
                  'dailyConsumptions',
                ) // Koleksi baru untuk menyimpan status konsumsi harian
                .doc(
                  '${studentId}_$todayFormatted',
                ) // ID Dokumen: studentId_tanggal
                .get();

        if (!currentContext.mounted) return;

        bool makanPagi = false;
        bool makanSiang = false;

        if (consumptionDoc.exists) {
          makanPagi = consumptionDoc.get('makanPagi') ?? false;
          makanSiang = consumptionDoc.get('makanSiang') ?? false;
        }

        tempStudents.add({'id': studentId, 'nama': studentName});
        tempConsumptionStatus[studentId] = {
          'pagi': makanPagi,
          'siang': makanSiang,
        };
      }

      setState(() {
        listedStudents = tempStudents;
        studentConsumptionStatus = tempConsumptionStatus;
      });
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data siswa untuk verifikasi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi untuk mengupdate status makan siswa
  Future<void> _updateStudentConsumption(
    String studentId,
    String mealType,
    bool status,
  ) async {
    final currentContext = context; // Capture context
    final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // Buat atau update dokumen di koleksi 'dailyConsumptions'
      await FirebaseFirestore.instance
          .collection('dailyConsumptions')
          .doc('${studentId}_$todayFormatted')
          .set(
            {
              'studentId': studentId,
              'date': todayFormatted,
              'makanPagi':
                  mealType == 'pagi'
                      ? status
                      : (studentConsumptionStatus[studentId]?['pagi'] ?? false),
              'makanSiang':
                  mealType == 'siang'
                      ? status
                      : (studentConsumptionStatus[studentId]?['siang'] ??
                          false),
              'lastUpdated': Timestamp.now(),
            },
            SetOptions(
              merge: true,
            ), // Gunakan merge agar tidak menimpa field lain jika ada
          );
      if (!currentContext.mounted) return;

      setState(() {
        studentConsumptionStatus[studentId]?[mealType] = status;
      });
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              "Status makan siswa ${mealType.toUpperCase()} berhasil diperbarui!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal memperbarui status makan siswa: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchDailyMenuAndDistribution() async {
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(now);

    // Ambil context ke variabel lokal
    final currentContext = context;

    try {
      QuerySnapshot menuSnapshot =
          await FirebaseFirestore.instance
              .collection('foodMenus')
              .where('date', isEqualTo: todayFormatted)
              .limit(1)
              .get();

      if (!currentContext.mounted) return; // Check mounted after first await

      if (menuSnapshot.docs.isNotEmpty) {
        setState(() {
          currentMenu = menuSnapshot.docs.first.data() as Map<String, dynamic>;
        });
      } else {
        setState(() {
          currentMenu = null;
        });
        // Check mounted before using ScaffoldMessenger
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(
              content: Text(
                "Belum ada menu yang diinput untuk hari ini oleh Tim Katering.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      QuerySnapshot distSnapshot =
          await FirebaseFirestore.instance
              .collection('foodDistributions')
              .where('date', isEqualTo: todayFormatted)
              .limit(1)
              .get();

      if (!currentContext.mounted) return; // Check mounted after second await

      if (distSnapshot.docs.isNotEmpty) {
        setState(() {
          currentDistributionDocId = distSnapshot.docs.first.id;
          deliveryStatus =
              distSnapshot.docs.first.get('deliveryStatus') ?? "Pending";
          kelasController.text =
              distSnapshot.docs.first.get('kelasVerified') ?? '';
          hadirController.text =
              distSnapshot.docs.first.get('jumlahHadirVerified')?.toString() ??
              '';
        });
      } else {
        setState(() {
          currentDistributionDocId = null;
          deliveryStatus = "Pending";
        });
      }
    } catch (e) {
      // Check mounted before using ScaffoldMessenger in catch block
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal mengambil data menu atau distribusi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Lokasi: di dalam class _DistribusiMakananPageState
  void _showReportIssueDialog(BuildContext dialogContext) {
    // Gunakan nama berbeda untuk context di dalam dialog
    final TextEditingController issueController = TextEditingController();
    showDialog(
      context: dialogContext, // Gunakan dialogContext di sini
      builder: (context) {
        // context di sini adalah context internal builder, selalu valid saat builder dipanggil
        return AlertDialog(
          title: const Text("Laporan Masalah"),
          content: TextField(
            controller: issueController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Jelaskan masalahnya...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  () => Navigator.pop(context), // context di sini masih valid
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentContext =
                    context; // Ambil context dari builder ke variabel lokal

                if (issueController.text.isNotEmpty &&
                    currentDistributionDocId != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('foodDistributions')
                        .doc(currentDistributionDocId)
                        .update({
                          'issueReport': issueController.text.trim(),
                          'reportedAt': Timestamp.now(),
                          'deliveryStatus': 'Bermasalah',
                          'reportedBy':
                              Provider.of<UserProvider>(
                                currentContext,
                                listen: false,
                              ).email, // Gunakan currentContext
                        });

                    // PERBAIKAN: Tambahkan kurung kurawal di sini
                    if (!currentContext.mounted) {
                      return;
                    }

                    setState(() {
                      deliveryStatus = 'Bermasalah';
                    });

                    if (currentContext.mounted) {
                      // Check mounted sebelum snackbar/navigator
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(
                          content: Text("Laporan masalah berhasil dikirim."),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(currentContext); // Gunakan currentContext
                    }
                  } catch (e) {
                    if (currentContext.mounted) {
                      // Check mounted di catch
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Text("Gagal mengirim laporan: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  if (currentContext.mounted) {
                    // Check mounted di else
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Isi laporan masalah dan pastikan data distribusi tersedia!",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text("Kirim"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Distribusi Makanan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            mode.isEmpty
                ? _buildSelection()
                : (mode == 'makanan'
                    ? _buildVerifikasiMakanan()
                    : _buildVerifikasiSiswa()),
      ),
    );
  }

  Widget _buildSelection() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOptionButton(
            "Verifikasi Makanan",
            () => setState(() => mode = 'makanan'),
          ),
          _buildOptionButton(
            "Verifikasi Siswa",
            () => setState(() => mode = 'siswa'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String title, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      ),
      onPressed: onTap,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVerifikasiMakanan() {
    final now = DateFormat("EEEE, d MMMM yyyy", 'id_ID').format(DateTime.now());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const Text(
            "Verifikasi Makanan",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                now,
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Keterangan untuk menu hari ini :",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${currentMenu?['portions'] ?? 'N/A'} porsi",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Karbohidrat : ${currentMenu?['carbohydrate'] ?? 'N/A'}"),
                Text("Protein     : ${currentMenu?['protein'] ?? 'N/A'}"),
                Text("Sayur       : ${currentMenu?['vegetable'] ?? 'N/A'}"),
                Text("Buah        : ${currentMenu?['fruit'] ?? 'N/A'}"),
                Text("Susu        : ${currentMenu?['milk'] ?? 'N/A'}"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildInputField("Kelas", kelasController)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  "Jumlah siswa yang hadir",
                  hadirController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Delivery Status : ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      deliveryStatus == "Pending"
                          ? Colors.yellow.shade100
                          : (deliveryStatus == "Diterima"
                              ? Colors.green.shade100
                              : Colors.red.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  deliveryStatus,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  final currentContext =
                      context; // Ambil context ke variabel lokal

                  if (currentDistributionDocId == null) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Data distribusi belum tersedia. Pastikan Tim Katering telah menandai siap.",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (kelasController.text.isEmpty ||
                      hadirController.text.isEmpty) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Harap isi Kelas dan Jumlah siswa yang hadir.",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  try {
                    await FirebaseFirestore.instance
                        .collection('foodDistributions')
                        .doc(currentDistributionDocId)
                        .update({
                          'deliveryStatus': 'Diterima',
                          'kelasVerified': kelasController.text.trim(),
                          'jumlahHadirVerified':
                              int.tryParse(hadirController.text.trim()) ?? 0,
                          'verifiedAt': Timestamp.now(),
                          // Gunakan currentContext untuk Provider
                          'verifiedBy':
                              Provider.of<UserProvider>(
                                currentContext,
                                listen: false,
                              ).email,
                        });

                    // PERBAIKAN: Tambahkan kurung kurawal di sini
                    if (!currentContext.mounted) {
                      return;
                    }

                    setState(() {
                      deliveryStatus = 'Diterima';
                    });

                    if (currentContext.mounted) {
                      // Check mounted sebelum snackbar
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Makanan berhasil diterima. Status diperbarui.",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (currentContext.mounted) {
                      // Check mounted di catch
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Text("Gagal mengkonfirmasi distribusi: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Konfirmasi"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  _showReportIssueDialog(
                    context,
                  ); // context di sini valid karena langsung dipanggil
                },
                child: const Text("Laporan Masalah"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => mode = ''),
            child: const Text("Kembali"),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: "Masukkan",
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifikasiSiswa() {
    final now = DateFormat("EEEE, d MMMM yyyy", 'id_ID').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              const Text(
                "Verifikasi Siswa",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),

                  Text(
                    now,
                    style: const TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            "Daftar Siswa",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child:
              listedStudents.isEmpty
                  ? const Center(
                    child: Text("Tidak ada data siswa untuk verifikasi."),
                  )
                  : ListView.builder(
                    itemCount: listedStudents.length,
                    itemBuilder: (context, index) {
                      final student = listedStudents[index];
                      final studentId = student['id'] as String;
                      final studentName = student['nama'] as String;
                      final statusPagi =
                          studentConsumptionStatus[studentId]?['pagi'] ?? false;
                      final statusSiang =
                          studentConsumptionStatus[studentId]?['siang'] ??
                          false;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundImage: AssetImage(
                                      "assets/images/foto.png",
                                    ),
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    studentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildToggleTile(
                                "Makan Pagi",
                                Icons.settings,
                                Colors.green.shade50,
                                statusPagi,
                                (val) => _updateStudentConsumption(
                                  studentId,
                                  'pagi',
                                  val,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildToggleTile(
                                "Makan Siang",
                                Icons.wb_sunny,
                                Colors.orange.shade50,
                                statusSiang,
                                (val) => _updateStudentConsumption(
                                  studentId,
                                  'siang',
                                  val,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRoundedButton("Kembali", () => setState(() => mode = '')),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleTile(
    String label,
    IconData icon,
    Color color,
    bool isActive,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
          ), // Gunakan onChanged dari parameter
        ],
      ),
    );
  }

  Widget _buildRoundedButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 140,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2962FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 1),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}