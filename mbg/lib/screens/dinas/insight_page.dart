import 'package:flutter/material.dart';

class InsightPage extends StatelessWidget {
  const InsightPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dataInsight = [
      {
        "judul": "Rata-rata Kenaikan Nilai",
        "nilai": "+6 poin",
        "ikon": Icons.trending_up,
        "warna": Colors.green,
      },
      {
        "judul": "Fokus Siswa",
        "nilai": "Meningkat 72%",
        "ikon": Icons.visibility,
        "warna": Colors.blue,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Insight AI"), backgroundColor: Colors.teal),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dataInsight.length,
        itemBuilder: (context, index) {
          final data = dataInsight[index];
          return Card(
            child: ListTile(
              leading: Icon(data["ikon"], color: data["warna"]),
              title: Text(data["judul"]),
              subtitle: Text(data["nilai"]),
            ),
          );
        },
      ),
    );
  }
}
