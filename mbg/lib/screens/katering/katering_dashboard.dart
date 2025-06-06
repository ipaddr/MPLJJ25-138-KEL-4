import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KateringDashboard extends StatefulWidget {
  const KateringDashboard({super.key});

  @override
  State<KateringDashboard> createState() => _KateringDashboardState();
}

class _KateringDashboardState extends State<KateringDashboard> {
  bool qualityChecked = false;
  bool isReady = false;
  final commentController = TextEditingController();

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
                child: const Text("1,234 porsi", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Karbohidrat   : Nasi"),
                  Text("Protein       : Ayam Goreng"),
                  Text("Sayur         : Sayur Bening"),
                  Text("Buah          : Pisang"),
                  Text("Susu          : Kotak"),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: qualityChecked,
                  onChanged: (val) => setState(() => qualityChecked = val ?? false),
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
                onChanged: (_) => setState(() {}),
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
                  onPressed: commentController.text.trim().isEmpty
                      ? null
                      : () => setState(() => isReady = true),
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