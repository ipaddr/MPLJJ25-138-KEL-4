import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KateringDashboard extends StatefulWidget {
  const KateringDashboard({super.key});

  @override
  State<KateringDashboard> createState() => _KateringDashboardState();
}

class _KateringDashboardState extends State<KateringDashboard> {
  bool qualityChecked = false;
  bool isReady = false;
  final commentController = TextEditingController();

  Map<String, dynamic>? dailyMenu;
  String? dailyMenuDocId; // ID dokumen menu hari ini

  @override
  void initState() {
    super.initState();
    _fetchDailyMenu();
  }

  Future<void> _fetchDailyMenu() async {
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(now);

    try {
      // Ambil menu hari ini
      QuerySnapshot menuSnapshot = await FirebaseFirestore.instance
          .collection('foodMenus')
          .where('date', isEqualTo: todayFormatted)
          .limit(1)
          .get();

      if (menuSnapshot.docs.isNotEmpty) {
        setState(() {
          dailyMenu = menuSnapshot.docs.first.data() as Map<String, dynamic>;
          dailyMenuDocId = menuSnapshot.docs.first.id;
          qualityChecked = dailyMenu?['qualityChecked'] ?? false;
          isReady = dailyMenu?['isReadyForDistribution'] ?? false;
          commentController.text = dailyMenu?['cateringComment'] ?? '';
        });
      } else {
        // Jika belum ada menu hari ini, Tim Katering mungkin perlu menginputnya.
        // Untuk demo cepat, kita bisa tampilkan pesan atau sediakan form input menu baru.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Belum ada menu yang diinput untuk hari ini."), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat menu harian: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Fungsi untuk menyimpan/mengupdate status menu
  Future<void> _updateMenuStatus() async {
    if (dailyMenuDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada menu yang aktif untuk diupdate."), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('foodMenus').doc(dailyMenuDocId).update({
        'qualityChecked': qualityChecked,
        'cateringComment': commentController.text.trim(),
        'isReadyForDistribution': isReady,
        'lastUpdatedByCatering': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Status menu berhasil diperbarui!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memperbarui status menu: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateFormat("EEEE, d MMMM yyyy", 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 6),
                Text(now, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 32),

            const Text("Keterangan untuk menu hari ini :", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${dailyMenu?['portions'] ?? 'N/A'} porsi", // Tampilkan porsi dari Firestore
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Karbohidrat  : ${dailyMenu?['carbohydrate'] ?? 'N/A'}"),
                  Text("Protein      : ${dailyMenu?['protein'] ?? 'N/A'}"),
                  Text("Sayur        : ${dailyMenu?['vegetable'] ?? 'N/A'}"),
                  Text("Buah         : ${dailyMenu?['fruit'] ?? 'N/A'}"),
                  Text("Susu         : ${dailyMenu?['milk'] ?? 'N/A'}"),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: qualityChecked,
                  onChanged: (val) {
                    setState(() {
                      qualityChecked = val ?? false;
                      if (!qualityChecked) {
                        isReady = false; // Jika quality un-checked, tidak siap
                      }
                    });
                    _updateMenuStatus(); // Update status ke Firestore
                  },
                ),
                const Text("Quality Check"),
              ],
            ),

            const SizedBox(height: 8),
            const Text("Komentar terkait makanan", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                controller: commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Masukkan pengamatan anda di sini ...",
                  border: InputBorder.none,
                ),
                onChanged: (_) {
                  // Ini memicu rebuild untuk mengecek apakah tombol "Tandai Siap" aktif
                  setState(() {});
                },
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isReady ? "Siap dibagikan" : "Proses Pengecekan",
                  style: TextStyle(
                    color: isReady ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: qualityChecked && commentController.text.trim().isNotEmpty
                      ? () async {
                          setState(() {
                            isReady = true;
                          });
                          await _updateMenuStatus(); // Update status siap ke Firestore
                          // Opsional: Buat dokumen di foodDistributions yang menandakan menu siap didistribusikan
                          // untuk hari ini, yang nanti akan diverifikasi oleh Admin.
                          await FirebaseFirestore.instance.collection('foodDistributions').add({
                            'menuId': dailyMenuDocId,
                            'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            'totalPorsi': dailyMenu?['portions'],
                            'deliveryStatus': 'Pending', // Awalnya pending dari sisi katering
                            'preparedByCatering': true,
                            'createdAt': Timestamp.now(),
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReady ? Colors.green : const Color(0xFF2962FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(isReady ? "Telah Siap" : "Tandai Siap"),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 150,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                  child: const Text("Kembali", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}