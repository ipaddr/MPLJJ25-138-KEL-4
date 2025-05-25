import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DistribusiMakananPage extends StatefulWidget {
  const DistribusiMakananPage({super.key});

  @override
  State<DistribusiMakananPage> createState() => _DistribusiMakananPageState();
}

class _DistribusiMakananPageState extends State<DistribusiMakananPage> {
  String mode = '';
  bool statusDikirim = false;
  final TextEditingController kelasController = TextEditingController();
  final TextEditingController hadirController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Distribusi Makanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: mode.isEmpty ? _buildSelection() : (mode == 'makanan' ? _buildVerifikasiMakanan() : _buildVerifikasiSiswa()),
      ),
    );
  }

  Widget _buildSelection() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOptionButton("Verifikasi Makanan", () => setState(() => mode = 'makanan')),
          _buildOptionButton("Verifikasi Siswa", () => setState(() => mode = 'siswa')),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String title, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      ),
      onPressed: onTap,
      child: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVerifikasiMakanan() {
    final now = DateFormat("EEEE, d MMMM yyyy", 'id_ID').format(DateTime.now());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const Text("Verifikasi Makanan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
              const SizedBox(width: 4),
              Text(now, style: const TextStyle(fontSize: 14, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Keterangan untuk menu hari ini :", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text("1,234 porsi", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Karbohidrat : Nasi"),
                Text("Protein     : Ayam Goreng"),
                Text("Sayur       : Sayur Bening"),
                Text("Buah        : Pisang"),
                Text("Susu        : Kotak"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildInputField("Kelas", kelasController)),
              const SizedBox(width: 16),
              Expanded(child: _buildInputField("Jumlah siswa yang hadir", hadirController)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Delivery Status : ", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("Pending", style: TextStyle(color: Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Makanan berhasil diterima oleh Tim Katering."))),
                child: const Text("Konfirmasi"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan isi laporan masalah/kritik."))),
                child: const Text("Laporan Masalah"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => setState(() => mode = ''), child: const Text("Kembali")),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Masukkan",
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifikasiSiswa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Column(
            children: [
              Text("Verifikasi Siswa", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                  SizedBox(width: 4),
                  Text("Selasa, 23 April 2025", style: TextStyle(fontSize: 14, color: Colors.blue)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text("Data Siswa", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage("assets/images/foto.png"),
                      radius: 30,
                    ),
                    const SizedBox(height: 8),
                    const Text("James Bone", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildToggleTile("Makan Pagi", Icons.settings, Colors.green.shade50, false),
              const SizedBox(height: 12),
              _buildToggleTile("Makan Siang", Icons.wb_sunny, Colors.orange.shade50, false),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRoundedButton("Sebelumnya", () => setState(() => mode = '')),
            _buildRoundedButton("Selanjutnya", () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data siswa berhasil dikirim.")))),
          ],
        )
      ],
    );
  }

  Widget _buildToggleTile(String label, IconData icon, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Switch(value: isActive, onChanged: (val) {})
        ],
      ),
    );
  }

  Widget _buildRoundedButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 140,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2962FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 1),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}