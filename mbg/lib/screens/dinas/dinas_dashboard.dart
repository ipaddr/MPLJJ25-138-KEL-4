import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import 'package:intl/intl.dart';
import '../admin/laporan_konsumsi_page.dart';
import 'dinas_school_verification_page.dart';
import '../guru/chatbot_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../login/login_screen.dart';

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
  List<FlSpot> evaluationSpots = [];

  @override
  void initState() {
    super.initState();
    _fetchDinasProfile();
    _fetchDinasStats();
    _fetchTeacherComments();
    _fetchEvaluationChartData();
  }

  Future<void> _fetchDinasProfile() async {
    final currentContext = context;
    final userProvider = Provider.of<UserProvider>(
      currentContext,
      listen: false,
    );
    String? uid = userProvider.uid;

    if (uid == null) return;

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!currentContext.mounted) return;

      if (userDoc.exists) {
        setState(() {
          dinasName = userDoc.get('fullName') ?? "Dinas Pendidikan";
        });
      }
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat profil dinas: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchDinasStats() async {
    final currentContext = context;
    try {
      QuerySnapshot schoolSnapshot =
          await FirebaseFirestore.instance.collection('schools').get();

      if (!currentContext.mounted) return;

      int tempTotalSchools = schoolSnapshot.docs.length;
      int tempVerifiedSchools = 0;
      for (var doc in schoolSnapshot.docs) {
        if (doc.data() != null &&
            (doc.data() as Map<String, dynamic>)['isVerified'] == true) {
          tempVerifiedSchools++;
        }
      }

      QuerySnapshot studentSnapshot =
          await FirebaseFirestore.instance.collection('students').get();
      if (!currentContext.mounted) return;
      int tempTotalStudents = studentSnapshot.docs.length;
      QuerySnapshot academicEvaluationsSnapshot =
          await FirebaseFirestore.instance.collection('academicEvaluations').get();
      if (!currentContext.mounted) return;

      int totalAcademicScores = 0;
      int academicScoreCount = 0;
      for (var doc in academicEvaluationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('afterMbgScore')) {
          totalAcademicScores += (data['afterMbgScore'] as int);
          academicScoreCount++;
        }
      }
      double tempAverageAcademicScore =
          academicScoreCount > 0 ? totalAcademicScores / academicScoreCount : 0.0;

      setState(() {
        totalSchools = tempTotalSchools;
        verifiedSchools = tempVerifiedSchools;
        totalStudents = tempTotalStudents;
        averageScore = tempAverageAcademicScore;
      });
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat statistik dinas: $e"),
            backgroundColor: Colors.red,
          ),
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
          .limit(10)
          .get();

      if (!currentContext.mounted) return;

      List<Map<String, dynamic>> fetchedComments = [];
      Map<String, String> schoolNamesCache = {};

      for (var doc in commentSnapshot.docs) {
        var commentData = doc.data() as Map<String, dynamic>;
        String schoolId = commentData['schoolId'] ?? '';

        String schoolNameDisplay;
        if (schoolId.isNotEmpty) {
          if (schoolNamesCache.containsKey(schoolId)) {
            schoolNameDisplay = schoolNamesCache[schoolId]!;
          } else {
            DocumentSnapshot schoolDoc =
                await FirebaseFirestore.instance.collection('schools').doc(schoolId).get();
            if (schoolDoc.exists) {
              schoolNameDisplay = schoolDoc.get('schoolName') ?? 'Sekolah Tidak Diketahui';
              schoolNamesCache[schoolId] = schoolNameDisplay;
            } else {
              schoolNameDisplay = 'Sekolah Tidak Ditemukan';
            }
          }
        } else {
          schoolNameDisplay = 'Sekolah Tidak Diketahui';
        }

        fetchedComments.add({
          'teacherId': commentData['teacherId'],
          'teacherName': commentData['teacherName'] ?? 'Guru',
          'schoolId': schoolId,
          'schoolName': schoolNameDisplay,
          'studentId': commentData['studentId'],
          'comment': commentData['comment'] ?? 'Tidak ada komentar',
          'commentedAt': commentData['commentedAt'],
        });
      }

      setState(() {
        teacherComments = fetchedComments;
      });
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat komentar guru: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchEvaluationChartData() async {
    final currentContext = context;
    try {
      QuerySnapshot evaluationSnapshot = await FirebaseFirestore.instance
          .collection('academicEvaluations')
          .orderBy('evaluationDate')
          .get();

      if (!currentContext.mounted) return;

      Map<String, List<int>> monthlyScores = {};

      for (var doc in evaluationSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        Timestamp timestamp = data['evaluationDate'] as Timestamp;
        DateTime date = timestamp.toDate();
        String monthKey = DateFormat('yyyy-MM').format(date);

        int score = data['afterMbgScore'] ?? 0;

        if (!monthlyScores.containsKey(monthKey)) {
          monthlyScores[monthKey] = [];
        }
        monthlyScores[monthKey]!.add(score);
      }

      List<FlSpot> tempSpots = [];
      List<String> sortedMonths = monthlyScores.keys.toList()..sort();

      for (int i = 0; i < sortedMonths.length; i++) {
        String month = sortedMonths[i];
        List<int> scores = monthlyScores[month]!;
        double avg =
            scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0.0;
        tempSpots.add(FlSpot(i.toDouble(), avg));
      }

      setState(() {
        evaluationSpots = tempSpots;
      });
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data grafik evaluasi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final currentContext = context;
    try {
      await FirebaseAuth.instance.signOut();
      if (!currentContext.mounted) return;
      Provider.of<UserProvider>(currentContext, listen: false).clearUser();
      Navigator.of(currentContext).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal logout: $e"), backgroundColor: Colors.red),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.indigo,
          ),
        ),
      ),
    );
  }

  Widget _grafikEvaluasi() {
    double maxY = 100;
    if (evaluationSpots.isNotEmpty) {
      double maxScore =
          evaluationSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      if (maxScore > maxY) {
        maxY = maxScore * 1.1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(
              (255 * 0.2).round(),
            ),
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
                return const FlLine(color: Color(0xff37434d), strokeWidth: 0.5);
              },
              getDrawingVerticalLine: (value) {
                return const FlLine(color: Color(0xff37434d), strokeWidth: 0.5);
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
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
                    if (evaluationSpots.isEmpty) {
                      return const Text('', style: style);
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        DateFormat(
                          'MMM',
                        ).format(DateTime(2024, value.toInt() + 1)),
                        style: style,
                      ),
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
            maxX: evaluationSpots.isNotEmpty ? evaluationSpots.length - 1.0 : 0,
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: evaluationSpots,
                isCurved: true,
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade200, Colors.indigo.shade800],
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
                      Colors.indigo.shade800.withAlpha(
                        (255 * 0.3).round(),
                      ),
                      Colors.indigo.shade200.withAlpha(
                        (255 * 0.3).round(),
                      ),
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
        title: const Text(
          "Dashboard Dinas Pendidikan",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.smart_toy, size: 28),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Text('!', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Selamat Datang, $dinasName",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Statistik",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _statTile(
              "Jumlah Sekolah Terdaftar",
              "$totalSchools",
              Icons.school,
            ),
            _statTile(
              "Jumlah Sekolah Terverifikasi",
              "$verifiedSchools",
              Icons.check_circle,
            ),
            _statTile("Total Siswa", "$totalStudents", Icons.people),
            _statTile(
              "Rata-rata Nilai Siswa",
              averageScore.toStringAsFixed(1),
              Icons.grade,
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DinasSchoolVerificationPage(),
                  ),
                );
              },
              icon: const Icon(Icons.verified_user, color: Colors.white),
              label: const Text(
                "Verifikasi Sekolah",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              "Grafik Evaluasi Siswa (Rata-Rata)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _grafikEvaluasi(),

            const SizedBox(height: 20),

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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.comment, color: Colors.indigo),
                    title: Text(
                      "${comment['teacherName'] ?? 'Guru'} dari ${comment['schoolName'] ?? 'Sekolah Tidak Diketahui'}",
                    ),
                    subtitle: Text(comment['comment'] ?? 'Tidak ada komentar'),
                    trailing: comment['commentedAt'] != null
                        ? Text(
                            DateFormat('dd/MM/yyyy').format(
                              (comment['commentedAt'] as Timestamp).toDate(),
                            ),
                          )
                        : const Text(''),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LaporanKonsumsiPage(),
                  ),
                );
              },
              icon: const Icon(Icons.description, color: Colors.white),
              label: const Text(
                "Lihat Laporan Konsumsi",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}