import 'package:flutter/material.dart';

class PenilaianPemahamanPage extends StatefulWidget {
  const PenilaianPemahamanPage({super.key});

  @override
  State<PenilaianPemahamanPage> createState() => _PenilaianPemahamanPageState();
}

class _PenilaianPemahamanPageState extends State<PenilaianPemahamanPage> {
  final Map<String, int> nilai = {
    "Fokus setelah makan": 0,
    "Keaktifan dalam diskusi": 0,
    "Kecepatan memahami": 0,
  };

  String komentar = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Penilaian Pemahaman")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Penilaian Kinerja Harian", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ...nilai.keys.map((kriteria) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kriteria, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(5, (index) {
                      int score = index + 1;
                      return ChoiceChip(
                        label: Text(score.toString()),
                        selected: nilai[kriteria] == score,
                        onSelected: (_) {
                          setState(() {
                            nilai[kriteria] = score;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
            const Text("Pengamatan guru", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Masukkan pengamatan anda di sini ...",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => komentar = value,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kembali"),
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Simpan Berhasil"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Nilai: ${nilai.toString()}"),
                            const SizedBox(height: 8),
                            Text("Komentar: $komentar"),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("Simpan"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
} 