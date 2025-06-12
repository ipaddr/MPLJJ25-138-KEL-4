import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'data_model.dart';
import 'laporan_page.dart';
import 'insight_page.dart';

class DinasDashboard extends StatelessWidget {
  const DinasDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Dashboard Dinas Pendidikan"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Tambahkan logika logout
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Statistik",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _statTile("Jumlah Sekolah", "120", Icons.school),
            _statTile("Jumlah Siswa", "25.000", Icons.people),
            _statTile("Rata-rata Nilai", "82.5", Icons.grade),

            const SizedBox(height: 20),
            const Text(
              "Grafik Evaluasi Siswa",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _grafikEvaluasi(),

            const SizedBox(height: 20),
            const Text(
              "Komentar Guru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...daftarEvaluasi.map(
              (e) => Card(
                child: ListTile(
                  leading: const Icon(Icons.comment, color: Colors.indigo),
                  title: Text(e.nama),
                  subtitle: Text(e.komentar),
                ),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LaporanPage()),
                );
              },
              icon: const Icon(Icons.description),
              label: const Text("Lihat Laporan Evaluasi"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InsightPage()),
                );
              },
              icon: const Icon(Icons.insights),
              label: const Text("Lihat Insight AI"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _grafikEvaluasi() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                daftarEvaluasi.length,
                (i) => FlSpot(i.toDouble(), daftarEvaluasi[i].nilai.toDouble()),
              ),
              isCurved: true,
              barWidth: 4,
              color:
                  Colors.indigo.shade500, // Perbaikan: Menggunakan satu warna
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
