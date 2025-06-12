import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import 'package:intl/intl.dart';

class RekapMingguanPage extends StatefulWidget {
  const RekapMingguanPage({super.key});

  @override
  State<RekapMingguanPage> createState() => _RekapMingguanPageState();
}

class _RekapMingguanPageState extends State<RekapMingguanPage> {
  List<double> actualNilaiHarian = [];
  List<String> hariMingguIni = [];

  @override
  void initState() {
    super.initState();
    _fetchWeeklyEvaluationData();
  }

  Future<void> _fetchWeeklyEvaluationData() async {
    final currentContext = context;

    final userProvider = Provider.of<UserProvider>(
      currentContext,
      listen: false,
    );
    if (userProvider.uid == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text(
              "Pengguna tidak terautentikasi untuk laporan mingguan.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(
        Duration(days: now.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(
        const Duration(days: 6),
      );

      Map<String, List<int>> dailyScores = {};
      List<String> tempHariMingguIni = [];
      List<double> tempNilaiHarian = [];
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final formattedDate = DateFormat('yyyy-MM-dd').format(date);
        final dayName = DateFormat(
          'EEE',
          'id_ID',
        ).format(date);
        tempHariMingguIni.add(dayName);
        dailyScores[formattedDate] = [];
      }

      QuerySnapshot evaluationSnapshot =
          await FirebaseFirestore.instance
              .collection('academicEvaluations')
              .where('teacherId', isEqualTo: userProvider.uid)
              .where(
                'evaluationDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
              )
              .where(
                'evaluationDate',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek),
              )
              .get();

      if (!currentContext.mounted) return;
      for (var doc in evaluationSnapshot.docs) {
        var evalData = doc.data() as Map<String, dynamic>;
        Timestamp timestamp = evalData['evaluationDate'] as Timestamp;
        DateTime date = timestamp.toDate();
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);
        int score = evalData['afterMbgScore'] ?? 0;

        dailyScores[formattedDate]?.add(score);
      }
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final formattedDate = DateFormat('yyyy-MM-dd').format(date);
        List<int> scores = dailyScores[formattedDate] ?? [];
        double avgScore =
            scores.isNotEmpty
                ? scores.reduce((a, b) => a + b) / scores.length
                : 0.0;
        tempNilaiHarian.add(avgScore);
      }

      setState(() {
        actualNilaiHarian = tempNilaiHarian;
        hariMingguIni = tempHariMingguIni;
      });
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat rekap mingguan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rekap Evaluasi Mingguan")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Peningkatan Nilai",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1.5,
                child: BarChart(
                  BarChartData(
                    barGroups: List.generate(
                      actualNilaiHarian.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: actualNilaiHarian[index],
                            color:
                                Colors.blue[(index + 1) * 100] ?? Colors.blue,
                          ),
                        ],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(hariMingguIni[value.toInt()]),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
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
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text("Fitur Tidak Tersedia"),
                              content: const Text(
                                "Export PDF dinonaktifkan untuk menjaga performa perangkat.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}