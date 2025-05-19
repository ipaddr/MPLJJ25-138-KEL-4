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

  double get safeAvgSebelum {
    final valid = siswa.where((s) => s['sebelum'] != null).toList();
    if (valid.isEmpty) return 0.1; // Minimal supaya chart nggak error
    final total = valid.map((s) => s['sebelum'] as int).fold(0, (a, b) => a + b);
    return total / valid.length;
  }

  double get safeAvgSesudah {
    final valid = siswa.where((s) => s['sesudah'] != null).toList();
    if (valid.isEmpty) return 0.1;
    final total = valid.map((s) => s['sesudah'] as int).fold(0, (a, b) => a + b);
    return total / valid.length;
  }

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
                        onChanged: (val) =>
                            setState(() => siswa[i]['sebelum'] = int.tryParse(val) ?? 0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        initialValue: siswa[i]['sesudah'].toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (val) =>
                            setState(() => siswa[i]['sesudah'] = int.tryParse(val) ?? 0),
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
            if (siswa.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  "Data kosong, menampilkan grafik dummy.",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  barGroups: siswa.isEmpty
                      ? [
                          BarChartGroupData(
                            x: 0,
                            barRods: [BarChartRodData(toY: 0.1, color: Colors.grey)],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [BarChartRodData(toY: 0.1, color: Colors.grey)],
                          ),
                        ]
                      : [
                          BarChartGroupData(
                            x: 0,
                            barRods: [BarChartRodData(toY: safeAvgSebelum, color: Colors.blue)],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [BarChartRodData(toY: safeAvgSesudah, color: Colors.blueAccent)],
                          ),
                        ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          return Text(value == 0 ? "Sebelum MBG" : "Sesudah MBG");
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: const Text("Kosongkan Data"),
                  onPressed: () {
                    setState(() {
                      siswa.clear();
                    });
                  },
                ),
                ElevatedButton(
                  child: const Text("Kembali"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}