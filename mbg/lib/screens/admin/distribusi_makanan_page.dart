import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart'; // Pastikan path-nya benar

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

  @override
  void initState() {
    super.initState();
    _fetchDailyMenuAndDistribution();
  }

  Future<void> _fetchDailyMenuAndDistribution() async {
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(now);

    // Ambil context ke variabel lokal
    final currentContext = context;

    try {
      QuerySnapshot menuSnapshot = await FirebaseFirestore.instance
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
            const SnackBar(content: Text("Belum ada menu yang diinput untuk hari ini oleh Tim Katering."), backgroundColor: Colors.orange),
          );
        }
      }

      QuerySnapshot distSnapshot = await FirebaseFirestore.instance
          .collection('foodDistributions')
          .where('date', isEqualTo: todayFormatted)
          .limit(1)
          .get();

      if (!currentContext.mounted) return; // Check mounted after second await

      if (distSnapshot.docs.isNotEmpty) {
        setState(() {
          currentDistributionDocId = distSnapshot.docs.first.id;
          deliveryStatus = distSnapshot.docs.first.get('deliveryStatus') ?? "Pending";
          kelasController.text = distSnapshot.docs.first.get('kelasVerified') ?? '';
          hadirController.text = distSnapshot.docs.first.get('jumlahHadirVerified')?.toString() ?? '';
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
          SnackBar(content: Text("Gagal mengambil data menu atau distribusi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReportIssueDialog(BuildContext dialogContext) { // Gunakan nama berbeda untuk context di dalam dialog
    final TextEditingController issueController = TextEditingController();
    showDialog(
      context: dialogContext, // Gunakan dialogContext di sini
      builder: (context) { // context di sini adalah context internal builder, selalu valid saat builder dipanggil
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
              onPressed: () => Navigator.pop(context), // context di sini masih valid
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentContext = context; // Ambil context dari builder ke variabel lokal

                if (issueController.text.isNotEmpty && currentDistributionDocId != null) {
                  try {
                    await FirebaseFirestore.instance.collection('foodDistributions').doc(currentDistributionDocId).update({
                      'issueReport': issueController.text.trim(),
                      'reportedAt': Timestamp.now(),
                      'deliveryStatus': 'Bermasalah',
                      'reportedBy': Provider.of<UserProvider>(currentContext, listen: false).email, // Gunakan currentContext
                    });
                    
                    if (!currentContext.mounted) return; // Check mounted setelah await
                    
                    setState(() {
                      deliveryStatus = 'Bermasalah';
                    });
                    
                    if (currentContext.mounted) { // Check mounted sebelum snackbar/navigator
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(content: Text("Laporan masalah berhasil dikirim."), backgroundColor: Colors.green),
                      );
                      Navigator.pop(currentContext); // Gunakan currentContext
                    }
                  } catch (e) {
                    if (currentContext.mounted) { // Check mounted di catch
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(content: Text("Gagal mengirim laporan: $e"), backgroundColor: Colors.red),
                      );
                    }
                  }
                } else {
                  if (currentContext.mounted) { // Check mounted di else
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(content: Text("Isi laporan masalah dan pastikan data distribusi tersedia!"), backgroundColor: Colors.red),
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
        title: const Text("Distribusi Makanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: mode.isEmpty
            ? _buildSelection()
            : (mode == 'makanan' ? _buildVerifikasiMakanan() : _buildVerifikasiSiswa()),
      ),
    );
  }

  Widget _buildSelection() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOptionButton("Verifikasi Makanan", () => setState(() => mode = 'makanan')),
          _buildOptionButton("Verifikasi Siswa", () => setState(() => mode = 'siswa')),
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
      child: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVerifikasiMakanan() {
    final now = DateFormat("EEEE, d MMMM****", 'id_ID').format(DateTime.now());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const Text("Verifikasi Makanan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
              const SizedBox(width: 4),
              Text(now, style: const TextStyle(fontSize: 14, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Keterangan untuk menu hari ini :", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${currentMenu?['portions'] ?? 'N/A'} porsi",
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
              Expanded(child: _buildInputField("Jumlah siswa yang hadir", hadirController, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Delivery Status : ", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: deliveryStatus == "Pending"
                      ? Colors.yellow.shade100
                      : (deliveryStatus == "Diterima" ? Colors.green.shade100 : Colors.red.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(deliveryStatus, style: const TextStyle(color: Colors.black87)),
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
                  final currentContext = context; // Ambil context ke variabel lokal

                  if (currentDistributionDocId == null) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(content: Text("Data distribusi belum tersedia. Pastikan Tim Katering telah menandai siap."), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  if (kelasController.text.isEmpty || hadirController.text.isEmpty) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(content: Text("Harap isi Kelas dan Jumlah siswa yang hadir."), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  try {
                    await FirebaseFirestore.instance.collection('foodDistributions').doc(currentDistributionDocId).update({
                      'deliveryStatus': 'Diterima',
                      'kelasVerified': kelasController.text.trim(),
                      'jumlahHadirVerified': int.tryParse(hadirController.text.trim()) ?? 0,
                      'verifiedAt': Timestamp.now(),
                      // Gunakan currentContext untuk Provider
                      'verifiedBy': Provider.of<UserProvider>(currentContext, listen: false).email,
                    });
                    
                    if (!currentContext.mounted) return; // Check mounted setelah await
                    
                    setState(() {
                      deliveryStatus = 'Diterima';
                    });
                    
                    if (currentContext.mounted) { // Check mounted sebelum snackbar
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(content: Text("Makanan berhasil diterima. Status diperbarui."), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (currentContext.mounted) { // Check mounted di catch
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(content: Text("Gagal mengkonfirmasi distribusi: $e"), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text("Konfirmasi"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  _showReportIssueDialog(context); // context di sini valid karena langsung dipanggil
                },
                child: const Text("Laporan Masalah"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => setState(() => mode = ''), child: const Text("Kembali")),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifikasiSiswa() {
    // Bagian ini masih menggunakan data mock.
    // Implementasi Firestore untuk bagian ini akan lebih kompleks.
    // Anda perlu:
    // 1. Mengambil daftar siswa dari Firestore (koleksi 'students').
    // 2. Menampilkan daftar siswa, mungkin dalam ListView.builder.
    // 3. Untuk setiap siswa, ambil status 'Makan Pagi' dan 'Makan Siang' dari koleksi lain
    //    (misalnya 'dailyConsumption' yang mereferensikan siswa_id dan tanggal).
    // 4. Implementasikan logika untuk mengupdate status makan siswa ke Firestore
    //    saat switch di-toggle. Ini akan melibatkan query data berdasarkan tanggal dan studentId.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Column(
            children: [
              Text("Verifikasi Siswa", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                  SizedBox(width: 4),
                  Text("Selasa, 23 April 2025", style: TextStyle(fontSize: 14, color: Colors.blue)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text("Data Siswa", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage("assets/images/foto.png"),
                      radius: 30,
                    ),
                    SizedBox(height: 8),
                    Text("James Bone", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildToggleTile("Makan Pagi", Icons.settings, Colors.green.shade50, false),
              const SizedBox(height: 12),
              _buildToggleTile("Makan Siang", Icons.wb_sunny, Colors.orange.shade50, false),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRoundedButton("Sebelumnya", () => setState(() => mode = '')),
            _buildRoundedButton("Selanjutnya", () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data siswa berhasil dikirim.")))),
          ],
        )
      ],
    );
  }

  Widget _buildToggleTile(String label, IconData icon, Color color, bool isActive) {
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
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Switch(value: isActive, onChanged: (val) {
            // Logika onChanged di sini perlu untuk mengupdate status makan siswa di Firestore
            // Ini akan sangat bergantung pada bagaimana Anda mendesain model data konsumsi siswa
            // Misalnya: FirebaseFirestore.instance.collection('dailyConsumption').doc(siswaId_tanggal).update({...});
          })
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