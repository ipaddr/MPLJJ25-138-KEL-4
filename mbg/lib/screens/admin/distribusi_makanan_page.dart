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
  // bool statusDikirim = false; // Tidak lagi dibutuhkan karena status diambil dari Firestore
  final TextEditingController kelasController = TextEditingController();
  final TextEditingController hadirController = TextEditingController();

  // Variabel untuk data menu dan distribusi dari Firestore
  Map<String, dynamic>? currentMenu;
  String? currentDistributionDocId; // ID dokumen distribusi yang sedang diproses
  String deliveryStatus = "Pending"; // Status default, akan diupdate dari Firestore

  @override
  void initState() {
    super.initState();
    _fetchDailyMenuAndDistribution(); // Panggil fungsi untuk mengambil data saat initState
  }

  // Fungsi untuk mengambil data menu harian dan status distribusi dari Firestore
  Future<void> _fetchDailyMenuAndDistribution() async {
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(now); // Format tanggal untuk query

    try {
      // Ambil menu hari ini dari koleksi 'foodMenus'
      QuerySnapshot menuSnapshot = await FirebaseFirestore.instance
          .collection('foodMenus')
          .where('date', isEqualTo: todayFormatted) // Asumsi field 'date' di Firestore adalah string 'yyyy-MM-dd'
          .limit(1)
          .get();

      if (menuSnapshot.docs.isNotEmpty) {
        setState(() {
          currentMenu = menuSnapshot.docs.first.data() as Map<String, dynamic>;
        });
      } else {
        // Handle jika tidak ada menu hari ini (misal: tampilkan pesan atau biarkan null)
        setState(() {
          currentMenu = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Belum ada menu yang diinput untuk hari ini oleh Tim Katering."), backgroundColor: Colors.orange),
        );
      }

      // Ambil dokumen distribusi untuk hari ini (per school/class jika ada, atau per tanggal jika sederhana)
      // Untuk penyederhanaan, kita akan mencari dokumen distribusi yang relevan dengan menu hari ini
      // yang mungkin sudah dibuat oleh Tim Katering atau oleh Admin sebelumnya.
      QuerySnapshot distSnapshot = await FirebaseFirestore.instance
          .collection('foodDistributions')
          .where('date', isEqualTo: todayFormatted)
          .limit(1) // Asumsi ada satu entri distribusi per hari untuk sekolah ini
          .get();

      if (distSnapshot.docs.isNotEmpty) {
        setState(() {
          currentDistributionDocId = distSnapshot.docs.first.id;
          deliveryStatus = distSnapshot.docs.first.get('deliveryStatus') ?? "Pending"; // Ambil status dari Firestore
          kelasController.text = distSnapshot.docs.first.get('kelasVerified') ?? ''; // Ambil nilai kelas yang sudah diverifikasi
          hadirController.text = distSnapshot.docs.first.get('jumlahHadirVerified')?.toString() ?? ''; // Ambil jumlah hadir
        });
      } else {
        // Jika belum ada dokumen distribusi, bisa buat baru (opsional, tergantung alur bisnis)
        // Atau biarkan kosong, dan tombol konfirmasi akan mencoba membuat entri baru.
        setState(() {
          currentDistributionDocId = null;
          deliveryStatus = "Pending";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil data menu atau distribusi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Fungsi untuk menampilkan dialog laporan masalah
  void _showReportIssueDialog(BuildContext context) {
    final TextEditingController issueController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (issueController.text.isNotEmpty && currentDistributionDocId != null) {
                  try {
                    await FirebaseFirestore.instance.collection('foodDistributions').doc(currentDistributionDocId).update({
                      'issueReport': issueController.text.trim(),
                      'reportedAt': Timestamp.now(),
                      'deliveryStatus': 'Bermasalah', // Ubah status jika ada masalah
                      'reportedBy': Provider.of<UserProvider>(context, listen: false).email, // Siapa yang melaporkan
                    });
                    setState(() {
                      deliveryStatus = 'Bermasalah'; // Update UI
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Laporan masalah berhasil dikirim."), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context); // Tutup dialog
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal mengirim laporan: $e"), backgroundColor: Colors.red),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Isi laporan masalah dan pastikan data distribusi tersedia!"), backgroundColor: Colors.red),
                  );
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
        // Menampilkan tampilan berdasarkan 'mode'
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
    final now = DateFormat("EEEE, d MMMM yyyy", 'id_ID').format(DateTime.now());

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
            // Tampilkan jumlah porsi dari Firestore
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
                // Tampilkan detail menu dari Firestore
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
              Expanded(child: _buildInputField("Jumlah siswa yang hadir", hadirController, keyboardType: TextInputType.number)), // Tambah keyboardType
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
                  // Sesuaikan warna berdasarkan status
                  color: deliveryStatus == "Pending"
                      ? Colors.yellow.shade100
                      : (deliveryStatus == "Diterima" ? Colors.green.shade100 : Colors.red.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(deliveryStatus, style: const TextStyle(color: Colors.black87)), // Tampilkan status dari state
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async { // Jadikan async
                  if (currentDistributionDocId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Data distribusi belum tersedia. Pastikan Tim Katering telah menandai siap."), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  if (kelasController.text.isEmpty || hadirController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
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
                      'verifiedBy': Provider.of<UserProvider>(context, listen: false).email, // Simpan siapa yang memverifikasi
                    });
                    setState(() {
                      deliveryStatus = 'Diterima'; // Update UI state
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Makanan berhasil diterima. Status diperbarui."), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal mengkonfirmasi distribusi: $e"), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text("Konfirmasi"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  _showReportIssueDialog(context); // Panggil fungsi dialog
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

  // Tambahkan parameter keyboardType
  Widget _buildInputField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType, // Gunakan keyboardType
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
    // Bagian ini masih menggunakan data mock
    // Untuk mengintegrasikan dengan Firebase, Anda perlu:
    // 1. Mengambil daftar siswa dari Firestore (koleksi 'students').
    // 2. Menampilkan daftar siswa.
    // 3. Untuk setiap siswa, ambil status 'Makan Pagi' dan 'Makan Siang' dari koleksi lain (misalnya 'dailyConsumption').
    // 4. Implementasikan logika untuk mengupdate status makan siswa ke Firestore saat switch di-toggle.
    // Ini akan melibatkan query data berdasarkan tanggal dan studentId.

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
                  Text("Selasa, 23 April 2025", style: TextStyle(fontSize: 14, color: Colors.blue)), // Tanggal ini juga bisa diambil dinamis
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
              // Toggle tile ini perlu mengambil dan menyimpan status makan per siswa
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