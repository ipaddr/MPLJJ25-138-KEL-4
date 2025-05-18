import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EvaluasiNilaiPage extends StatefulWidget {
  const EvaluasiNilaiPage({super.key});

  @override
  State<EvaluasiNilaiPage> createState() => _EvaluasiNilaiPageState();
}

class _EvaluasiNilaiPageState extends State<EvaluasiNilaiPage> {
  List<Map<String, dynamic>> siswa = [
    {"nama": "Emma Wilson", "sebelum": 85, "sesudah": 90},
    {"nama": "James Bone", "sebelum": 78, "sesudah": 82},
  ];

  int get avgSebelum => siswa.map((s) => s['sebelum'] as int).reduce((a, b) => a + b) ~/ siswa.length;
  int get avgSesudah => siswa.map((s) => s['sesudah'] as int).reduce((a, b) => a + b) ~/ siswa.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Evaluasi Nilai Akademik")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Rekam kinerja sebelum dan sesudah makan", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(),
              children: [
                const TableRow(children: [
                  Padding(padding: EdgeInsets.all(8), child: Text("Siswa/Siswi")),
                  Center(child: Text("Sebelum MBG")),
                  Center(child: Text("Sesudah MBG")),
                  Center(child: Text("Beda Nilai")),
                ]),
                for (int i = 0; i < siswa.length; i++)
                  TableRow(children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text(siswa[i]['nama'])),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        initialValue: siswa[i]['sebelum'].toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setState(() => siswa[i]['sebelum'] = int.tryParse(val) ?? 0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        initialValue: siswa[i]['sesudah'].toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setState(() => siswa[i]['sesudah'] = int.tryParse(val) ?? 0),
                      ),
                    ),
                    Center(
                      child: Text(
                        "+${siswa[i]['sesudah'] - siswa[i]['sebelum']}",
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ]),
              ],
            ),
            const SizedBox(height: 12),
            const Text("Rata-Rata Nilai", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: avgSebelum.toDouble(), color: Colors.blue)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: avgSesudah.toDouble(), color: Colors.blueAccent)]),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) {
                      return Text(value == 0 ? "Sebelum MBG" : "Sesudah MBG");
                    }),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                child: const Text("Kembali"),
                onPressed: () => Navigator.pop(context),
              ),
            )
          ],
        ),
      ),
    );
  }
}