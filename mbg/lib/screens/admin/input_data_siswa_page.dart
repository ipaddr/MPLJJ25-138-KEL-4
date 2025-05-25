import 'package:flutter/material.dart';

class InputDataSiswaPage extends StatelessWidget {
  const InputDataSiswaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController namaController = TextEditingController();
    final TextEditingController kelasController = TextEditingController();
    final TextEditingController nisController = TextEditingController();
    final TextEditingController keteranganController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Input Data Siswa")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: namaController, decoration: const InputDecoration(labelText: "Nama Siswa")),
            TextField(controller: kelasController, decoration: const InputDecoration(labelText: "Kelas")),
            TextField(controller: nisController, decoration: const InputDecoration(labelText: "Nomor Induk Siswa")),
            TextField(controller: keteranganController, decoration: const InputDecoration(labelText: "Keterangan")),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Kembali")),
                ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informasi umum tersimpan."))),
                  child: const Text("Simpan"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}