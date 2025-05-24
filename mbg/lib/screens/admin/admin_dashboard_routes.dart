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

class LaporanKonsumsiPage extends StatefulWidget {
  const LaporanKonsumsiPage({super.key});

  @override
  State<LaporanKonsumsiPage> createState() => _LaporanKonsumsiPageState();
}

class _LaporanKonsumsiPageState extends State<LaporanKonsumsiPage> {
  String selectedFilter = 'Hari Ini';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laporan Konsumsi")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: selectedFilter,
              items: ['Hari Ini', '7 Hari Terakhir', '30 Hari Terakhir'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedFilter = val!),
            ),
            const SizedBox(height: 16),
            const Text("Total Siswa: 1200"),
            const Text("Tidak Makan Hari Ini: 75"),
            const Text("Tidak Makan Senin-Jumat: 125"),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Kembali")),
                ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Laporan PDF berhasil diunduh."))),
                  child: const Text("Export PDF"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}