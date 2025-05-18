import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class RekapMingguanPage extends StatelessWidget {
  const RekapMingguanPage({super.key});

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
                    barRods: [BarChartRodData(toY: nilaiHarian[index], color: Colors.blue[(index + 1) * 100]!)])),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(hari[value.toInt()]),
                        );
                      }),
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
                  onPressed: () async {
                    final doc = pw.Document();
                    doc.addPage(
                      pw.Page(
                        build: (pw.Context context) => pw.Center(
                          child: pw.Text("Export Data Rekap Nilai Mingguan"),
                        ),
                      ),
                    );
                    await Printing.sharePdf(bytes: await doc.save(), filename: 'rekap_mingguan.pdf');
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Export PDF"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}