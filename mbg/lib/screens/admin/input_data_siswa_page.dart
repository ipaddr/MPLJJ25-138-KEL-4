import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InputDataSiswaPage extends StatelessWidget {
  const InputDataSiswaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final namaController = TextEditingController();
    final kelasController = TextEditingController();
    final nisController = TextEditingController();
    final keteranganController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Text(
                    "Input Data Siswa",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1C),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Masukkan informasi dan detail siswa",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Informasi Umum",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildInput("Nama Siswa", namaController),
            _buildInput("Kelas", kelasController),
            _buildInput("Nomor Induk Siswa", nisController),

            const SizedBox(height: 24),
            _buildInput(
              "Keterangan tentang siswa (misal : alergi, dll)",
              keteranganController,
              isMultiline: true,
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRoundedButton(
                  context,
                  "Kembali",
                  onTap: () => Navigator.pop(context),
                ),
                _buildRoundedButton(
                  context,
                  "Simpan",
                  onTap: () async {
                    final currentContext = context;

                    if (namaController.text.isEmpty ||
                        kelasController.text.isEmpty ||
                        nisController.text.isEmpty) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Harap isi semua kolom informasi umum!",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance.collection('students').add({
                        'nama': namaController.text.trim(),
                        'kelas': kelasController.text.trim(),
                        'nis': nisController.text.trim(),
                        'keterangan': keteranganController.text.trim(),
                        'createdAt': Timestamp.now(),
                      });

                      if (!currentContext.mounted) return;

                      namaController.clear();
                      kelasController.clear();
                      nisController.clear();
                      keteranganController.clear();

                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(
                          content: Text("Data siswa berhasil disimpan!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!currentContext.mounted) return;

                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Text("Gagal menyimpan data: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: isMultiline ? 4 : 1,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedButton(
    BuildContext context,
    String text, {
    required VoidCallback onTap,
  }) {
    return Container(
      width: 140,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        color: const Color(0xFF2962FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}