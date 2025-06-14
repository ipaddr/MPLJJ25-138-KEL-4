import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import FlChart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import 'package:intl/intl.dart';

// Import halaman laporan dan insight jika ada
import '../admin/laporan_konsumsi_page.dart'; // Contoh, ganti jika ada halaman khusus dinas
// import 'insight_page.dart'; // Jika ada

class DinasDashboard extends StatefulWidget {
  const DinasDashboard({super.key});

  @override
  State<DinasDashboard> createState() => _DinasDashboardState();
}

class _DinasDashboardState extends State<DinasDashboard> {
  String dinasName = "Nama Dinas";
  int totalSchools = 0;
  int verifiedSchools = 0;
  int totalStudents = 0;
  double averageScore = 0.0;
  List<Map<String, dynamic>> teacherComments = [];

  @override
  void initState() {
    super.initState();
    _fetchDinasProfile();
    _fetchDinasStats();
    _fetchTeacherComments();
  }

  Future<void> _fetchDinasProfile() async {
    final currentContext = context;
    final userProvider = Provider.of<UserProvider>(currentContext, listen: false);
    String? uid = userProvider.uid;

    if (uid != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (!currentContext.mounted) return;

        if (userDoc.exists) {
          setState(() {
            dinasName = userDoc.get('fullName') ?? "Dinas Pendidikan";
          });
        }
      } catch (e) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text("Gagal memuat profil dinas: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _fetchDinasStats() async {
    final currentContext = context;
    try {
      // Fetch Schools Data: Count users with 'Admin Sekolah' role and 'schoolName' field
      QuerySnapshot schoolSnapshot = await FirebaseFirestore.instance
          .collection('schools') // Ambil dari koleksi 'schools'
          .get();

      if (!currentContext.mounted) return;

      int tempTotalSchools = schoolSnapshot.docs.length;
      int tempVerifiedSchools = 0;
      for (var doc in schoolSnapshot.docs) {
        if (doc.data() != null && (doc.data() as Map<String, dynamic>)['isVerified'] == true) {
          tempVerifiedSchools++;
        }
      }

      // Fetch Total Students Data
      QuerySnapshot studentSnapshot =
          await FirebaseFirestore.instance.collection('students').get();
      if (!currentContext.mounted) return;
      int tempTotalStudents = studentSnapshot.docs.length;

      // Fetch Average Score from 'understandingAssessments'
      QuerySnapshot understandingAssessmentsSnapshot = await FirebaseFirestore.instance
          .collection('understandingAssessments')
          .get();
      if (!currentContext.mounted) return;

      int totalScores = 0;
      int scoreCount = 0;
      for (var doc in understandingAssessmentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('fokusSetelahMakan')) {
          totalScores += (data['fokusSetelahMakan'] as int);
          scoreCount++;
        }
        if (data.containsKey('keaktifanDalamDiskusi')) {
          totalScores += (data['keaktifanDalamDiskusi'] as int);
          scoreCount++;
        }
        if (data.containsKey('kecepatanMemahami')) {
          totalScores += (data['kecepatanMemahami'] as int);
          scoreCount++;
        }
      }
      double tempAverageScore = scoreCount > 0 ? totalScores / scoreCount : 0.0;

      setState(() {
        totalSchools = tempTotalSchools;
        verifiedSchools = tempVerifiedSchools;
        totalStudents = tempTotalStudents;
        averageScore = tempAverageScore;
      });
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal memuat statistik dinas: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchTeacherComments() async {
    final currentContext = context;
    try {
      QuerySnapshot commentSnapshot = await FirebaseFirestore.instance
          .collection('teacherComments')
          .orderBy('commentedAt', descending: true)
          .limit(10) // Ambil 10 komentar terbaru
          .get();

      if (!currentContext.mounted) return;

      setState(() {
        teacherComments = commentSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal memuat komentar guru: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _statTile(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
        ),
      ),
    );
  }

  Widget _grafikEvaluasi() {
    // Ini masih menggunakan data dummy untuk grafik.
    // Jika Anda ingin grafik ini menampilkan data evaluasi siswa sesungguhnya
    // (misal, rata-rata nilai per sekolah atau per bulan),
    // Anda perlu memproses data academicEvaluations lebih lanjut.
    final List<FlSpot> spots = [
      const FlSpot(0, 70), // Jan
      const FlSpot(1, 75), // Feb
      const FlSpot(2, 80), // Mar
      const FlSpot(3, 82), // Apr
      const FlSpot(4, 78), // May
      const FlSpot(5, 85), // Jun
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((255 * 0.2).round()), // <<< PERBAIKAN DI SINI
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: Color(0xff37434d),
                  strokeWidth: 0.5,
                );
              },
              getDrawingVerticalLine: (value) {
                return const FlLine(
                  color: Color(0xff37434d),
                  strokeWidth: 0.5,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false), // Perbaikan: 'showNull' diganti 'showTitles: false'
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false), // Perbaikan: 'showNull' diganti 'showTitles: false'
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    const style = TextStyle(
                      color: Color(0xff68737d),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    );
                    Widget text;
                    switch (value.toInt()) {
                      case 0:
                        text = const Text('Jan', style: style);
                        break;
                      case 1:
                        text = const Text('Feb', style: style);
                        break;
                      case 2:
                        text = const Text('Mar', style: style);
                        break;
                      case 3:
                        text = const Text('Apr', style: style);
                        break;
                      case 4:
                        text = const Text('Mei', style: style);
                        break;
                      case 5:
                        text = const Text('Jun', style: style);
                        break;
                      default:
                        text = const Text('', style: style);
                        break;
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: text,
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const style = TextStyle(
                      color: Color(0xff67727d),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    );
                    return Text(value.toInt().toString(), style: style);
                  },
                  reservedSize: 40,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
            minX: 0,
            maxX: spots.length - 1.0,
            minY: 0,
            maxY: 100, // Assuming scores are out of 100
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade200,
                    Colors.indigo.shade800,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade800.withAlpha((255 * 0.3).round()), // <<< PERBAIKAN DI SINI
                      Colors.indigo.shade200.withAlpha((255 * 0.3).round()), // <<< PERBAIKAN DI SINI
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Dashboard Dinas Pendidikan", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logout berhasil!"), backgroundColor: Colors.green),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Selamat Datang, $dinasName",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 20),

            // --- Statistik Section ---
            const Text(
              "Statistik",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _statTile("Jumlah Sekolah Terdaftar", "$totalSchools", Icons.school),
            _statTile("Jumlah Sekolah Terverifikasi", "$verifiedSchools", Icons.check_circle),
            _statTile("Total Siswa", "$totalStudents", Icons.people),
            _statTile("Rata-rata Nilai Siswa", averageScore.toStringAsFixed(1), Icons.grade),

            const SizedBox(height: 20),

            // --- Grafik Evaluasi Siswa Section ---
            const Text(
              "Grafik Evaluasi Siswa (Rata-Rata)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _grafikEvaluasi(),

            const SizedBox(height: 20),

            // --- Komentar Guru Terbaru Section ---
            const Text(
              "Komentar Guru Terbaru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (teacherComments.isEmpty)
              const Center(child: Text("Tidak ada komentar guru terbaru."))
            else
              ...teacherComments.map(
                (comment) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: const Icon(Icons.comment, color: Colors.indigo),
                    title: Text(
                        "${comment['teacherName'] ?? 'Guru'} dari ${comment['schoolName'] ?? 'Sekolah Tidak Diketahui'}"),
                    subtitle: Text(comment['comment'] ?? 'Tidak ada komentar'),
                    trailing: comment['commentedAt'] != null
                        ? Text(DateFormat('dd/MM/yyyy').format((comment['commentedAt'] as Timestamp).toDate()))
                        : const Text(''),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // --- Navigation Buttons ---
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LaporanKonsumsiPage()), // Contoh navigasi
                );
              },
              icon: const Icon(Icons.description, color: Colors.white),
              label: const Text("Lihat Laporan Evaluasi", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Halaman Insight AI belum diimplementasikan.")),
                );
              },
              icon: const Icon(Icons.insights, color: Colors.white),
              label: const Text("Lihat Insight AI", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}