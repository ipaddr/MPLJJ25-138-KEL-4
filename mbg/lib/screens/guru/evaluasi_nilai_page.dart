import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';

class EvaluasiNilaiPage extends StatefulWidget {
  const EvaluasiNilaiPage({super.key});

  @override
  State<EvaluasiNilaiPage> createState() => _EvaluasiNilaiPageState();
}

class _EvaluasiNilaiPageState extends State<EvaluasiNilaiPage> {
  List<Map<String, dynamic>> siswa = []; // Ini akan diisi dari Firestore

  @override
  void initState() {
    super.initState();
    _fetchStudentsAndEvaluations();
  }

  Future<void> _fetchStudentsAndEvaluations() async {
    try {
      // Ambil semua siswa (Admin Sekolah menginput siswa)
      QuerySnapshot studentSnapshot =
          await FirebaseFirestore.instance.collection('students').get();
      // Check mounted after first await
      if (!mounted) return; //

      List<Map<String, dynamic>> fetchedSiswa = [];

      for (var doc in studentSnapshot.docs) {
        String studentId = doc.id;
        String studentName = doc.get('nama') ?? 'Nama Tidak Diketahui';

        // Ambil evaluasi akademik untuk siswa ini
        QuerySnapshot evaluationSnapshot =
            await FirebaseFirestore.instance
                .collection('academicEvaluations')
                .where('studentId', isEqualTo: studentId)
                .orderBy(
                  'evaluationDate',
                  descending: true,
                ) // Ambil yang terbaru
                .limit(1)
                .get();

        // Check mounted after each evaluation fetch inside loop
        if (!mounted) return; //

        int beforeScore = 0;
        int afterScore = 0;

        if (evaluationSnapshot.docs.isNotEmpty) {
          var evalData =
              evaluationSnapshot.docs.first.data() as Map<String, dynamic>;
          beforeScore = evalData['beforeMbgScore'] ?? 0;
          afterScore = evalData['afterMbgScore'] ?? 0;
        }

        fetchedSiswa.add({
          'id': studentId,
          'nama': studentName,
          'sebelum': beforeScore,
          'sesudah': afterScore,
        });
      }

      // Check mounted before setState
      if (!mounted) return; //
      setState(() {
        siswa = fetchedSiswa;
      });
    } catch (e) {
      // Check mounted in catch block
      if (!mounted) return; //
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memuat data siswa dan evaluasi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double get safeAvgSebelum {
    final valid = siswa.where((s) => s['sebelum'] != null).toList();
    if (valid.isEmpty) return 0.1;
    final total = valid
        .map((s) => s['sebelum'] as int)
        .fold(0, (a, b) => a + b);
    return total / valid.length;
  }

  double get safeAvgSesudah {
    final valid = siswa.where((s) => s['sesudah'] != null).toList();
    if (valid.isEmpty) return 0.1;
    final total = valid
        .map((s) => s['sesudah'] as int)
        .fold(0, (a, b) => a + b);
    return total / valid.length;
  }

  // Fungsi untuk update nilai ke Firestore
  Future<void> _updateStudentEvaluation(
    String studentId,
    int newBeforeScore,
    int newAfterScore,
  ) async {
    final currentContext = context; // Ambil context ke variabel lokal

    try {
      final userProvider = Provider.of<UserProvider>(
        currentContext,
        listen: false,
      );
      if (userProvider.uid == null) {
        if (!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text("Pengguna tidak terautentikasi."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      QuerySnapshot existingEval =
          await FirebaseFirestore.instance
              .collection('academicEvaluations')
              .where('studentId', isEqualTo: studentId)
              .where('teacherId', isEqualTo: userProvider.uid)
              .get();

      if (!currentContext.mounted) return;

      if (existingEval.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('academicEvaluations')
            .doc(existingEval.docs.first.id)
            .update({
              'beforeMbgScore': newBeforeScore,
              'afterMbgScore': newAfterScore,
              'evaluationDate': Timestamp.now(),
            });
      } else {
        await FirebaseFirestore.instance.collection('academicEvaluations').add({
          'studentId': studentId,
          'teacherId': userProvider.uid,
          'beforeMbgScore': newBeforeScore,
          'afterMbgScore': newAfterScore,
          'evaluationDate': Timestamp.now(),
        });
      }

      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text("Nilai berhasil diperbarui!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text("Gagal memperbarui nilai: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Evaluasi Nilai Akademik")),
      body: SingleChildScrollView(
        // Bungkus seluruh Padding dengan SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Rekam kinerja sebelum dan sesudah makan",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              // Hapus Expanded di sini karena SingleChildScrollView sudah di atas
              // child: SingleChildScrollView( // Ini akan ada di dalam SingleChildScrollView utama
              // scrollDirection: Axis.vertical,
              // child: Table(...),
              // ),
              Table(
                // Tidak perlu Expanded jika SingleChildScrollView membungkus keseluruhan body
                border: TableBorder.all(),
                children: [
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Siswa/Siswi"),
                      ),
                      Center(child: Text("Sebelum MBG")),
                      Center(child: Text("Sesudah MBG")),
                      Center(child: Text("Beda Nilai")),
                    ],
                  ),
                  if (siswa.isEmpty)
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("Tidak ada siswa terdaftar"),
                        ),
                        SizedBox(),
                        SizedBox(),
                        SizedBox(),
                      ],
                    )
                  else
                    for (int i = 0; i < siswa.length; i++)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(siswa[i]['nama']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextFormField(
                              initialValue: siswa[i]['sebelum'].toString(),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                int newScore = int.tryParse(val) ?? 0;
                                setState(() {
                                  siswa[i]['sebelum'] = newScore;
                                });
                                _updateStudentEvaluation(
                                  siswa[i]['id'],
                                  newScore,
                                  siswa[i]['sesudah'],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextFormField(
                              initialValue: siswa[i]['sesudah'].toString(),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                int newScore = int.tryParse(val) ?? 0;
                                setState(() {
                                  siswa[i]['sesudah'] = newScore;
                                });
                                _updateStudentEvaluation(
                                  siswa[i]['id'],
                                  siswa[i]['sebelum'],
                                  newScore,
                                );
                              },
                            ),
                          ),
                          Center(
                            child: Text(
                              "${siswa[i]['sesudah'] - siswa[i]['sebelum'] >= 0 ? '+' : ''}${siswa[i]['sesudah'] - siswa[i]['sebelum']}",
                              style: TextStyle(
                                color:
                                    (siswa[i]['sesudah'] -
                                                siswa[i]['sebelum']) >=
                                            0
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Rata-Rata Nilai",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1.5,
                child: BarChart(
                  BarChartData(
                    barGroups:
                        siswa.isEmpty
                            ? [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(toY: 0.1, color: Colors.grey),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(toY: 0.1, color: Colors.grey),
                                ],
                              ),
                            ]
                            : [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: safeAvgSebelum,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: safeAvgSesudah,
                                    color: Colors.blueAccent,
                                  ),
                                ],
                              ),
                            ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            return Text(
                              value == 0 ? "Sebelum MBG" : "Sesudah MBG",
                            );
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
                    child: const Text("Kosongkan Data (Mock)"),
                    onPressed: () {
                      setState(() {
                        siswa.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Data di UI dikosongkan. Untuk menghapus di Firebase, Anda perlu implementasi.",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
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
      ),
    );
  }
}