# Makan Gizi Gratis (MBG)

Selamat datang di repositori proyek **Makan Gizi Gratis (MBG)**! Ini adalah aplikasi mobile yang dibangun dengan Flutter, dirancang untuk membantu pengelolaan dan pemantauan program penyediaan makanan bergizi di sekolah. MBG menghubungkan seluruh ekosistem sekolah, mulai dari admin, guru, orang tua, dinas pendidikan, hingga tim katering dalam satu platform. 

## ✨ Mengapa MBG?

MBG hadir untuk menjawab tantangan dalam program makan bergizi dengan menyediakan:
* **Transparansi Penuh**: Lacak setiap porsi makanan dari katering hingga ke tangan siswa.
* **Pemantauan Holistik**: Pantau status konsumsi makanan dan dampak nutrisi terhadap performa akademik dan pemahaman siswa.
* **Kolaborasi Tanpa Batas**: Hubungkan semua pemangku kepentingan dalam satu ekosistem digital.
* **Akses Informasi Cepat**: Dapatkan wawasan mendalam dan laporan instan kapan saja, di mana saja.

## 🌟 Fitur Unggulan

MBG didukung oleh fitur-fitur canggih yang disesuaikan untuk setiap peran:

### 👤 Autentikasi Multi-Peran & Manajemen Profil
MBG menawarkan pengalaman login yang aman dan terpersonalisasi.
* **Login & Registrasi Fleksibel**: Pengguna dapat mendaftar dan masuk dengan mudah, memilih peran spesifik mereka: Admin Sekolah, Guru, Orang Tua, Dinas Pendidikan, atau Tim Katering. 
* **UserProvider Global**: Menggunakan Provider, data autentikasi dan profil pengguna disinkronkan secara real-time di seluruh aplikasi, memastikan informasi yang selalu akurat. 

### 📊 Dashboard Interaktif untuk Setiap Peran

Setiap pengguna mendapatkan dashboard yang kaya fitur, dirancang untuk memaksimalkan produktivitas dan pemantauan:

#### 🏫 Admin Sekolah - Jantung Operasional Gizi
* **Status Sekolah**: Admin dapat melihat nama sekolah dan status verifikasi sekolah (Terverifikasi ✅, Menunggu Verifikasi ⏳, Verifikasi Ditolak ❌, atau Belum Mengajukan 📝). Admin juga dapat mengajukan permintaan verifikasi sekolah ke Dinas Pendidikan. 
* **Statistik**: Pantau jumlah total siswa dan total porsi makanan yang diterima sekolah setiap harinya. 
* **Manajemen Siswa Lengkap**:
    * **Input Data Siswa**: Mudah menambahkan siswa baru dengan detail lengkap seperti nama, kelas, NIS, dan catatan khusus (misalnya, alergi). Data ini terhubung langsung dengan sekolah admin. 
    * **Verifikasi Distribusi Makanan**: Catat penerimaan makanan dari katering dan pantau konsumsi makan pagi dan siang setiap siswa. Fitur pelaporan masalah juga tersedia jika ada kendala distribusi. 
* **Laporan Konsumsi**: Akses laporan konsumsi makanan siswa untuk mengidentifikasi siswa yang mungkin melewatkan jadwal makan. 
* **Persetujuan Akses Orang Tua**: Tinjau dan kelola permintaan akses data anak dari orang tua, memberikan persetujuan atau penolakan dengan mudah. 

#### 👩‍🏫 Guru - Pemantau Dampak Akademik dan Gizi
* **Evaluasi Nilai Akademik**: Input dan bandingkan nilai siswa (sebelum dan sesudah program MBG) untuk melihat peningkatan performa akademik. Visualisasi rata-rata peningkatan nilai membantu melacak kemajuan. 
* **Penilaian Pemahaman Harian**: Berikan penilaian cepat terhadap fokus, keaktifan diskusi, dan kecepatan memahami siswa setelah makan (skala 1-5), dilengkapi dengan kolom komentar observasi. Siswa yang sudah dinilai akan difilter secara otomatis. 
* **Rekap Mingguan**: Lihat rekapitulasi evaluasi mingguan dalam bentuk grafik batang untuk memantau tren performa kelas. 

#### 🍽️ Tim Katering - Penjamin Kualitas Makanan
* **Manajemen Menu Harian**: Masukkan dan perbarui detail menu makanan setiap hari, termasuk jumlah porsi, komposisi gizi (karbohidrat, protein, sayur, buah, susu). 
* **Quality Control**: Lakukan pemeriksaan kualitas makanan dan tambahkan komentar terkait menu yang disajikan. 
* **Siap Distribusi**: Setelah semua persiapan selesai dan kualitas terjamin, tandai makanan sebagai siap untuk didistribusikan, memicu notifikasi ke admin sekolah. 

#### 🏛️ Dinas Pendidikan - Pengawas Kualitas Pendidikan
* **Statistik Nasional/Regional**: Dapatkan gambaran umum tentang jumlah sekolah terdaftar dan terverifikasi, total siswa, dan rata-rata nilai akademik di seluruh wilayah tanggung jawab. 
* **Verifikasi Sekolah**: Otoritas tertinggi untuk menyetujui atau menolak permintaan verifikasi sekolah yang diajukan oleh admin sekolah. 
* **Grafik Tren Evaluasi Siswa**: Visualisasikan tren rata-rata nilai evaluasi siswa setiap bulannya. 
* **Monitor Komentar Guru**: Lihat pengamatan dan komentar terbaru dari guru-guru di berbagai sekolah untuk mendapatkan wawasan langsung. 
* **Laporan Konsumsi**: Akses laporan konsumsi makanan secara keseluruhan untuk analisis kebijakan. 

#### 👨‍👩‍👧 Orang Tua - Transparansi Nutrisi Anak
* **Permintaan Akses Mudah**: Ajukan permintaan akses ke data nutrisi dan performa anak hanya dengan memasukkan NIS dan nama sekolah. 
* **Status Real-time**: Pantau status permintaan akses, menunggu konfirmasi dari admin sekolah. 
* **Dashboard Anak**: Setelah disetujui, orang tua dapat melihat profil lengkap anak mereka (nama, kelas, NIS) dan status makan pagi serta makan siang anak mereka untuk hari ini (Sudah Makan ✅ atau Belum Makan ❌). 

### 🤖 Chatbot Gizi AI - Asisten Pintar Anda
Chatbot ini siap menjawab pertanyaan seputar nutrisi, kesehatan, atau detail program makan gizi gratis. Ini adalah asisten pribadi Anda untuk informasi gizi yang akurat! 

## 🛠️ Teknologi yang Digunakan

MBG dibangun dengan teknologi modern untuk performa optimal dan kemudahan pengembangan:
* **Flutter**: Framework UI terkemuka dari Google untuk membangun aplikasi mobile *native* yang indah dan cepat di Android dan iOS dari satu codebase. 
* **Firebase**: Fondasi *backend* yang kuat:
    * **Authentication**: Manajemen pengguna yang aman dan terukur. 
    * **Cloud Firestore**: Database NoSQL *real-time* untuk penyimpanan dan sinkronisasi data yang efisien. 
    * **Firebase Storage**: Penyimpanan file cloud yang tangguh untuk gambar profil dan media lainnya. 
* **Provider**: Solusi manajemen *state* yang direkomendasikan Flutter untuk aplikasi berskala besar. 
* **`intl`**: Internasionalisasi dan lokalisasi, termasuk format tanggal (`id_ID`) untuk pengalaman pengguna yang lebih baik. 
* **`fl_chart`**: Pustaka grafik yang fleksibel dan ekspresif untuk visualisasi data yang menawan. 
* **`flutter_dotenv`**: Mengamankan kredensial sensitif dengan memuat variabel lingkungan dari file `.env`. 
* **`google_generative_ai`**: Integrasi langsung dengan model AI canggih Gemini untuk fungsionalitas chatbot. 

## 🚀 Instalasi dan Setup (Cepat dan Mudah!)

Ikuti langkah-langkah sederhana ini untuk menjalankan MBG di lingkungan lokal Anda:

1.  **Kloning Repositori:**
    ```bash
    git clone <URL_REPOSITORI_ANDA> # Ganti dengan URL repositori Anda
    cd MakanGiziGratis
    ```

2.  **Instal Dependensi Flutter:**
    ```bash
    flutter pub get
    ```

3.  **Setup Firebase Project:**
    * Buka [Firebase Console](https://console.firebase.google.com/) dan buat proyek Firebase baru.
    * Tambahkan aplikasi Android dan iOS ke proyek Anda.
    * Unduh file konfigurasi Firebase: `google-services.json` untuk Android (tempatkan di `android/app/`) dan `GoogleService-Info.plist` untuk iOS (tempatkan di `ios/Runner/`).
    * Aktifkan layanan Firebase yang diperlukan di konsol Anda:
        * **Firestore**: Mulai database dalam mode *production* atau *test* dan atur aturan keamanannya.
        * **Authentication**: Aktifkan metode *Sign-in provider* "Email/Password".
        * **Cloud Storage**: Buat bucket penyimpanan dan atur aturan keamanannya.
    * Pastikan aturan keamanan Firestore dan Storage Anda memungkinkan operasi baca/tulis yang diperlukan oleh aplikasi (misalnya, membuat pengguna, membaca data sekolah, mengunggah gambar).

4.  **Konfigurasi Variabel Lingkungan (Environment Variables):**
    * Buat file baru bernama `.env` di *root* direktori proyek Anda (sejajar dengan `pubspec.yaml`).
    * Tambahkan kunci API Anda ke dalam file `.env` ini.
        ```plaintext
        GEMINI_API_KEY=PASTE_KUNCI_API_GEMINI_ANDA_DI_SINI
        ```
    * Pastikan file `.env` telah terdaftar di `pubspec.yaml` di bawah bagian `flutter: assets:` seperti ini:
        ```yaml
        flutter:
          uses-material-design: true
          assets:
            - assets/images/prabowo_gibran.png
            - .env # Pastikan baris ini ada
        ```

5.  **Jalankan Aplikasi:**
    ```bash
    flutter run
    ```
