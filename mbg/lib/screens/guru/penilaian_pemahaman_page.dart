import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; //
import '../../provider/user_provider.dart'; //

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

  String komentar = "";

  List<Map<String, dynamic>> students = []; // Daftar siswa dari Firestore
  String? selectedStudentId; // ID siswa yang dipilih

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      QuerySnapshot studentSnapshot = await FirebaseFirestore.instance.collection('students').get();
      // Check mounted after await
      if (!mounted) return; //

      setState(() {
        students = studentSnapshot.docs.map((doc) => {
          'id': doc.id,
          'nama': doc.get('nama') ?? 'Nama Tidak Diketahui',
        }).toList();
        if (students.isNotEmpty) {
          selectedStudentId = students.first['id']; // Pilih siswa pertama secara default
        }
      });
    } catch (e) {
      // Check mounted in catch block
      if (!mounted) return; //
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat daftar siswa: $e"), backgroundColor: Colors.red),
      );
    }
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

            // Dropdown untuk memilih siswa
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
            ),
            const SizedBox(height: 20),

            // Perbaikan: Hapus .toList() jika tidak diperlukan oleh spread operator
            ...nilai.keys.map((kriteria) {
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
            }), // .toList() Dihapus di sini 
            const Text("Pengamatan guru", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Masukkan pengamatan anda di sini ...",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => komentar = value,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kembali"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Ambil context ke variabel lokal
                    final currentContext = context;

                    if (selectedStudentId == null) {
                      ScaffoldMessenger.of(currentContext).showSnackBar( // Gunakan currentContext
                        const SnackBar(content: Text("Silakan pilih siswa terlebih dahulu!"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    if (nilai.values.any((score) => score == 0)) {
                      ScaffoldMessenger.of(currentContext).showSnackBar( // Gunakan currentContext
                        const SnackBar(content: Text("Harap berikan nilai untuk semua kriteria!"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    try {
                      final user = Provider.of<UserProvider>(currentContext, listen: false); // Gunakan currentContext
                      await FirebaseFirestore.instance.collection('understandingAssessments').add({
                        'studentId': selectedStudentId,
                        'teacherId': user.uid,
                        'assessmentDate': Timestamp.now(),
                        'fokusSetelahMakan': nilai['Fokus setelah makan'],
                        'keaktifanDalamDiskusi': nilai['Keaktifan dalam diskusi'],
                        'kecepatanMemahami': nilai['Kecepatan memahami'],
                        'komentarGuru': komentar,
                      });

                      // Setelah await, cek mounted
                      if (!currentContext.mounted) return; //

                      showDialog(
                        context: currentContext, // Gunakan currentContext
                        builder: (ctx) => AlertDialog( // Gunakan ctx sebagai nama variabel context builder
                          title: const Text("Simpan Berhasil"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Penilaian untuk siswa: ${students.firstWhere((s) => s['id'] == selectedStudentId)['nama']}"),
                              Text("Nilai: ${nilai.toString()}"),
                              const SizedBox(height: 8),
                              Text("Komentar: $komentar"),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx), // Gunakan ctx
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );

                      setState(() {
                        nilai.forEach((key, value) => nilai[key] = 0);
                        komentar = "";
                      });
                    } catch (e) {
                      // Di catch block, cek mounted
                      if (!currentContext.mounted) return; //
                      ScaffoldMessenger.of(currentContext).showSnackBar( // Gunakan currentContext
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