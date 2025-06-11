import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Hapus atau jadikan komentar jika tidak digunakan
// import 'package:provider/provider.dart'; // Hapus atau jadikan komentar jika tidak digunakan
// import '../../provider/user_provider.dart'; // Hapus atau jadikan komentar jika tidak digunakan

class RekapMingguanPage extends StatefulWidget {
  const RekapMingguanPage({super.key});

  @override
  State<RekapMingguanPage> createState() => _RekapMingguanPageState();
}

class _RekapMingguanPageState extends State<RekapMingguanPage> {
  final List<double> nilaiHarian = const [60, 75, 70, 85, 90, 95, 98];
  final List<String> hari = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rekap Evaluasi Mingguan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Peningkatan Nilai", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(7, (index) => BarChartGroupData(
                    x: index,
                    barRods: [BarChartRodData(
                      toY: nilaiHarian[index],
                      color: Colors.blue[(index + 1) * 100] ?? Colors.blue,
                    )])),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(hari[value.toInt()]),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kembali"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Fitur Tidak Tersedia"),
                        content: const Text("Export PDF dinonaktifkan untuk menjaga performa perangkat."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Export PDF"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}