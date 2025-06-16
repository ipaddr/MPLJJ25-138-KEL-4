import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';

class PenilaianPemahamanPage extends StatefulWidget {
  const PenilaianPemahamanPage({super.key});

  @override
  State<PenilaianPemahamanPage> createState() => _PenilaianPemahamanPageState();
}

class _PenilaianPemahamanPageState extends State<PenilaianPemahamanPage> {
  final Map<String, int> nilai = {
    "Fokus setelah makan": 0,
    "Keaktifan dalam diskusi": 0,
    "Kecepatan memahami": 0,
  };

  final TextEditingController _komentarController = TextEditingController();

  List<Map<String, dynamic>> students = [];
  String? selectedStudentId;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String? guruSchoolId = userProvider.schoolId;

      if (guruSchoolId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ID Sekolah Guru tidak ditemukan."), backgroundColor: Colors.red),
        );
        return;
      }

      // Fetch students belonging to the teacher's school
      QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('schoolId', isEqualTo: guruSchoolId) // Filter students by schoolId
          .get();

      if (!mounted) return;

      setState(() {
        students = studentSnapshot.docs.map((doc) => {
              'id': doc.id,
              'nama': doc.get('nama') ?? 'Nama Tidak Diketahui',
            }).toList();
        _filterAssessedStudents(); // Filter students who already have an assessment for today
        if (students.isNotEmpty) {
          selectedStudentId = students.first['id'];
        } else {
          selectedStudentId = null; // No students left to assess
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat daftar siswa: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _filterAssessedStudents() async {
    if (students.isEmpty) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? guruUid = userProvider.uid;
    if (guruUid == null) return;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    List<String> assessedStudentIds = [];

    try {
      QuerySnapshot assessmentSnapshot = await FirebaseFirestore.instance
          .collection('understandingAssessments')
          .where('teacherId', isEqualTo: guruUid)
          .where('assessmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('assessmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      for (var doc in assessmentSnapshot.docs) {
        assessedStudentIds.add(doc.get('studentId'));
      }

      setState(() {
        students.removeWhere((student) => assessedStudentIds.contains(student['id']));
        if (selectedStudentId != null && assessedStudentIds.contains(selectedStudentId)) {
          selectedStudentId = students.isNotEmpty ? students.first['id'] : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memfilter siswa yang sudah dinilai: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _resetForm() {
    setState(() {
      nilai.forEach((key, value) => nilai[key] = 0);
      _komentarController.clear();
      // The selected student will be updated by _filterAssessedStudents
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Penilaian Pemahaman")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Penilaian Kinerja Harian", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Pilih Siswa',
                border: OutlineInputBorder(),
              ),
              value: selectedStudentId,
              items: students.map<DropdownMenuItem<String>>((student) {
                return DropdownMenuItem<String>(
                  value: student['id'],
                  child: Text(student['nama']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStudentId = value;
                });
              },
              isExpanded: true,
              hint: students.isEmpty
                  ? const Text("Semua siswa sudah dinilai hari ini.")
                  : const Text("Pilih Siswa"),
            ),
            const SizedBox(height: 20),
            if (students.isEmpty && selectedStudentId == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    "Semua siswa sudah dinilai untuk hari ini atau belum ada siswa terdaftar.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (selectedStudentId != null)
              Expanded(
                child: ListView(
                  children: [
                    ...nilai.keys.map((kriteria) { // Hapus .toList() di sini
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(kriteria, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(5, (index) {
                              int score = index + 1;
                              return ChoiceChip(
                                label: Text(score.toString()),
                                selected: nilai[kriteria] == score,
                                onSelected: (_) {
                                  setState(() {
                                    nilai[kriteria] = score;
                                  });
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                    const Text("Pengamatan guru", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _komentarController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Masukkan pengamatan anda di sini ...",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Controller secara langsung memanage value, tidak perlu update string `komentar` di sini
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kembali"),
                ),
                ElevatedButton(
                  onPressed: selectedStudentId == null ? null : () async {
                    final currentContext = context;

                    if (selectedStudentId == null) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(content: Text("Silakan pilih siswa terlebih dahulu!"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    if (nilai.values.any((score) => score == 0)) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(content: Text("Harap berikan nilai untuk semua kriteria!"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    try {
                      final userProvider = Provider.of<UserProvider>(currentContext, listen: false);
                      String? guruUid = userProvider.uid;
                      String? guruSchoolId = userProvider.schoolId;
                      String? guruFullName = userProvider.fullName;

                      if (guruUid == null || guruSchoolId == null) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(content: Text("Profil Guru tidak lengkap (UID/SchoolID)."), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      // Simpan penilaian ke understandingAssessments
                      await FirebaseFirestore.instance.collection('understandingAssessments').add({
                        'studentId': selectedStudentId,
                        'teacherId': guruUid,
                        'schoolId': guruSchoolId,
                        'assessmentDate': Timestamp.now(),
                        'fokusSetelahMakan': nilai['Fokus setelah makan'],
                        'keaktifanDalamDiskusi': nilai['Keaktifan dalam diskusi'],
                        'kecepatanMemahami': nilai['Kecepatan memahami'],
                        'komentarGuru': _komentarController.text,
                      });

                      // Simpan komentar guru ke koleksi teacherComments
                      if (_komentarController.text.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('teacherComments').add({
                          'teacherId': guruUid,
                          'teacherName': guruFullName ?? "Guru", // Use full name if available
                          'schoolId': guruSchoolId,
                          'studentId': selectedStudentId,
                          'comment': _komentarController.text,
                          'commentedAt': Timestamp.now(),
                        });
                      }

                      if (!currentContext.mounted) return;

                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(content: Text("Penilaian berhasil disimpan!"), backgroundColor: Colors.green),
                      );

                      _resetForm();
                      await _fetchStudents(); // Refresh student list
                    } catch (e) {
                      if (!currentContext.mounted) return;
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(content: Text("Gagal menyimpan penilaian: $e"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}