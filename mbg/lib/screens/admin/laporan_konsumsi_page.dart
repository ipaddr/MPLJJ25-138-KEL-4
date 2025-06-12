import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LaporanKonsumsiPage extends StatefulWidget {
  const LaporanKonsumsiPage({super.key});

  @override
  State<LaporanKonsumsiPage> createState() => _LaporanKonsumsiPageState();
}

class _LaporanKonsumsiPageState extends State<LaporanKonsumsiPage> {
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
    dataTidakMakanMingguan = [25, 45, 16, 25, 5]; 
  }

  Future<void> _fetchReportData() async {
    try {      
      QuerySnapshot studentSnapshot = await FirebaseFirestore.instance.collection('students').get();
      if (!mounted) return; 

      setState(() {
        totalSiswa = studentSnapshot.docs.length;
      });

      final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());
      QuerySnapshot distributionSnapshot = await FirebaseFirestore.instance
          .collection('foodDistributions')
          .where('date', isEqualTo: todayFormatted)
          .get();
      if (!mounted) return; 

      int currentDayNotEaten = 0;
      if (distributionSnapshot.docs.isNotEmpty) {
        currentDayNotEaten = 25; 
      }
      setState(() {
        siswaTidakMakanHariIni = currentDayNotEaten;
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
            SizedBox(
              height: 180, 
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
                      Text(hari[index], style: const TextStyle(fontSize: 13, color: Colors.black54)) 
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