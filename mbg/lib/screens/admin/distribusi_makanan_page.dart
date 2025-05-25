import 'package:flutter/material.dart';

class DistribusiMakananPage extends StatefulWidget {
  const DistribusiMakananPage({super.key});

  @override
  State<DistribusiMakananPage> createState() => _DistribusiMakananPageState();
}

class _DistribusiMakananPageState extends State<DistribusiMakananPage> {
  String mode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Distribusi Makanan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: mode.isEmpty ? _buildSelection() : (mode == 'makanan' ? _buildVerifikasiMakanan() : _buildVerifikasiSiswa()),
      ),
    );
  }

  Widget _buildSelection() {
    return Column(
      children: [
        ElevatedButton(onPressed: () => setState(() => mode = 'makanan'), child: const Text("Verifikasi Makanan")),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => setState(() => mode = 'siswa'), child: const Text("Verifikasi Siswa")),
      ],
    );
  }

  Widget _buildVerifikasiMakanan() {
    return ListView(
      children: [
        const Text("Menu Hari Ini: 150 Porsi"),
        const Text("Karbohidrat: Nasi"),
        const Text("Protein: Ayam"),
        const Text("Sayur: Bayam"),
        const Text("Buah: Pisang"),
        const Text("Susu: UHT"),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: "Isi Kelas")),
        TextField(decoration: const InputDecoration(labelText: "Jumlah Siswa Hadir")),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Makanan sudah datang ke sekolah dan diterima."))),
          child: const Text("Konfirmasi"),
        ),
        ElevatedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan isi kritik/saran atas masalah."))),
          child: const Text("Laporan Masalah"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () => setState(() => mode = ''), child: const Text("Kembali")),
      ],
    );
  }

  Widget _buildVerifikasiSiswa() {
    final List<Map<String, dynamic>> siswa = [
      {"nama": "Emma Wilson", "makanPagi": false, "makanSiang": false},
      {"nama": "James Bone", "makanPagi": true, "makanSiang": false},
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: siswa.length,
            itemBuilder: (context, index) {
              final s = siswa[index];
              return Card(
                child: ListTile(
                  title: Text(s['nama']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        value: s['makanPagi'],
                        onChanged: (val) => setState(() => s['makanPagi'] = val),
                        title: const Text("Sudah makan pagi"),
                      ),
                      CheckboxListTile(
                        value: s['makanSiang'],
                        onChanged: (val) => setState(() => s['makanSiang'] = val),
                        title: const Text("Sudah makan siang"),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(onPressed: () => setState(() => mode = ''), child: const Text("Kembali")),
            ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data siswa berhasil dikirim."))), child: const Text("Kirim")),
          ],
        )
      ],
    );
  }
}