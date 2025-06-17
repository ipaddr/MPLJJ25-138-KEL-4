import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
// Hapus atau jadikan komentar import 'dart:math'; jika sudah tidak digunakan

class LaporanKonsumsiPage extends StatefulWidget {
  const LaporanKonsumsiPage({super.key});

  @override
  State<LaporanKonsumsiPage> createState() => _LaporanKonsumsiPageState();
}

class _LaporanKonsumsiPageState extends State<LaporanKonsumsiPage> {
  // Tipe data String sudah default non-nullable di Flutter dengan null-safety.
  // selectedFilter sudah non-nullable karena ada nilai default.
  String selectedFilter = 'Last 30 days';

  final List<String> filterOptions = ['Hari Ini', '7 Hari Terakhir', 'Last 30 days'];
  final List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  int totalSiswa = 0;
  int siswaTidakMakanHariIni = 0;
  List<int> dataTidakMakanMingguan = [];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
    // dataTidakMakanMingguan = [25, 45, 16, 25, 5]; // Baris ini harus dihapus jika Anda ingin data dinamis sepenuhnya
  }

  Future<void> _fetchReportData() async {
    try {
      // Pastikan context masih mounted sebelum menggunakan Provider
      if (!mounted) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      // currentUserRole akan selalu String karena userProvider.role adalah String non-nullable
      final String currentUserRole = userProvider.role; // 
      final String? adminSchoolId = userProvider.schoolId; // 

      QuerySnapshot studentSnapshot;
      // Logika untuk Admin Sekolah vs. Dinas Pendidikan
      if (currentUserRole == 'Admin Sekolah' && adminSchoolId != null) { // 
        studentSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('schoolId', isEqualTo: adminSchoolId)
            .get();
      } else {
        // Asumsi untuk Dinas Pendidikan (melihat semua siswa jika tidak ada schoolId spesifik)
        studentSnapshot = await FirebaseFirestore.instance.collection('students').get();
      }

      if (!mounted) return;

      setState(() {
        totalSiswa = studentSnapshot.docs.length;
      });

      final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());
      int tempSiswaTidakMakanHariIni = 0;

      for (var studentDoc in studentSnapshot.docs) {
        String studentId = studentDoc.id;
        DocumentSnapshot consumptionDoc = await FirebaseFirestore.instance
            .collection('dailyConsumptions')
            .doc('${studentId}_$todayFormatted')
            .get();

        if (!mounted) return;

        // Jika dokumen konsumsi tidak ada untuk hari ini, atau kedua makanPagi dan makanSiang false
        if (!consumptionDoc.exists ||
            (consumptionDoc.get('makanPagi') == false &&
                consumptionDoc.get('makanSiang') == false)) {
          tempSiswaTidakMakanHariIni++;
        }
      }

      setState(() {
        siswaTidakMakanHariIni = tempSiswaTidakMakanHariIni;
      });

      // --- Perbaikan untuk dataTidakMakanMingguan ---
      List<int> fetchedWeeklyNotEaten = [];
      // Mendapatkan data untuk 5 hari kerja terakhir
      for (int i = 0; i < 5; i++) {
        DateTime date = DateTime.now().subtract(Duration(days: i));
        // Lewati hari Sabtu dan Minggu jika grafik hanya untuk hari kerja
        if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
          continue; // Lompat ke iterasi berikutnya jika hari libur
        }

        final formattedDate = DateFormat('yyyy-MM-dd').format(date);
        int dailyNotEatenCount = 0;

        // Mendapatkan snapshot siswa yang relevan untuk hari ini
        QuerySnapshot studentsForDaySnapshot;
        if (currentUserRole == 'Admin Sekolah' && adminSchoolId != null) { // 
          studentsForDaySnapshot = await FirebaseFirestore.instance
              .collection('students')
              .where('schoolId', isEqualTo: adminSchoolId)
              .get();
        } else {
          studentsForDaySnapshot = await FirebaseFirestore.instance.collection('students').get();
        }
        if (!mounted) return;

        for (var studentDoc in studentsForDaySnapshot.docs) {
          String studentId = studentDoc.id;
          DocumentSnapshot dailyConsumptionForStudent = await FirebaseFirestore.instance
              .collection('dailyConsumptions')
              .doc('${studentId}_$formattedDate')
              .get();

          if (!mounted) return;

          if (!dailyConsumptionForStudent.exists ||
              (dailyConsumptionForStudent.get('makanPagi') == false &&
                  dailyConsumptionForStudent.get('makanSiang') == false)) {
            dailyNotEatenCount++;
          }
        }
        
        // Menambahkan ke awal list untuk menjaga urutan kronologis (hari paling lama di index 0)
        fetchedWeeklyNotEaten.insert(0, dailyNotEatenCount);
      }
      
      // Jika data kurang dari 5 hari kerja (misal di awal minggu), isi dengan 0
      while (fetchedWeeklyNotEaten.length < 5) {
        fetchedWeeklyNotEaten.insert(0, 0); // Tambahkan 0 di awal jika belum mencapai 5 hari
      }
      // Pastikan hanya 5 hari yang diambil (misal jika ada hari libur di tengah)
      if (fetchedWeeklyNotEaten.length > 5) {
        fetchedWeeklyNotEaten = fetchedWeeklyNotEaten.sublist(fetchedWeeklyNotEaten.length - 5);
      }

      setState(() {
        dataTidakMakanMingguan = fetchedWeeklyNotEaten;
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat laporan: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            const Text("Laporan Konsumsi", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatTile("Total Siswa", "$totalSiswa Orang"),
                _buildStatTile("Total siswa yang\ntidak makan hari ini", "$siswaTidakMakanHariIni Orang"),
              ],
            ),

            const SizedBox(height: 32),
            const Text("Total siswa yang tidak makan", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: selectedFilter,
              items: filterOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedFilter = val!),
              underline: Container(),
              borderRadius: BorderRadius.circular(12),
            ),

            const SizedBox(height: 16),
            Expanded( // Menggunakan Expanded agar ListView tidak unbound
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(dataTidakMakanMingguan.length, (index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 30,
                        height: dataTidakMakanMingguan[index].toDouble() * 3,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${dataTidakMakanMingguan[index]}",
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Pastikan index 'hari' tidak out of bounds
                      Text(index < hari.length ? hari[index] : '', style: const TextStyle(fontSize: 13, color: Colors.black54))
                    ],
                  );
                }),
              ),
            ),

            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRoundedButton("Kembali", Icons.arrow_back, () => Navigator.pop(context)),
                _buildRoundedButton("Export PDF", Icons.picture_as_pdf, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("PDF laporan berhasil diunduh (fitur ini masih mock).")),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildRoundedButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 140,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2962FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 1),
          ),
        ),
      ),
    );
  }
}