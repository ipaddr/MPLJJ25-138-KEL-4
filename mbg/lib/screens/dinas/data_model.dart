class EvaluasiSiswa {
  final String nama;
  final int nilai;
  final String komentar;

  EvaluasiSiswa({
    required this.nama,
    required this.nilai,
    required this.komentar,
  });
}

final List<EvaluasiSiswa> daftarEvaluasi = [
  EvaluasiSiswa(nama: "Zaki", nilai: 85, komentar: "Fokus meningkat"),
  EvaluasiSiswa(nama: "Alya", nilai: 88, komentar: "Aktif berdiskusi"),
  EvaluasiSiswa(nama: "Budi", nilai: 80, komentar: "Perlu pendampingan"),
];
