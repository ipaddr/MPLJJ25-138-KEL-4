import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int step = 1;
  bool showPassword = false;
  bool showConfirmPassword = false;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final schoolController = TextEditingController();

  final usernameController = TextEditingController(); // Ini bisa dihapus jika tidak digunakan
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final List<String> roles = [
    'Admin Sekolah',
    'Guru',
    'Orang Tua',
    'Dinas Pendidikan',
    'Tim Katering',
  ];
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Buat Akun",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            if (step == 1) ...[
              _buildField("Nama Lengkap", "Isi nama lengkap", fullNameController),
              _buildField("Email", "your@email.com", emailController),
              _buildField("No. Handphone", "012345678901", phoneController),
              _buildField("Asal Sekolah", "Isi nama sekolah", schoolController),
              const SizedBox(height: 32),
              _buildPrimaryButton("Selanjutnya", () {
                // Validasi dasar untuk step 1 sebelum lanjut
                if (fullNameController.text.isEmpty || emailController.text.isEmpty ||
                    phoneController.text.isEmpty || schoolController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Harap lengkapi semua data pada bagian ini!"), backgroundColor: Colors.red),
                  );
                  return;
                }
                setState(() => step = 2);
              }),
            ] else ...[
              // _buildField("Username", "Buat username", usernameController), // Dihapus jika tidak digunakan
              _buildPasswordField("Password", passwordController, showPassword, () => setState(() => showPassword = !showPassword)),
              _buildPasswordField("Konfirmasi Password", confirmPasswordController, showConfirmPassword, () => setState(() => showConfirmPassword = !showConfirmPassword)),
              _buildRoleDropdown(),
              const SizedBox(height: 32),
              _buildPrimaryButton("Buat Akun", () async {
                // Simpan context ke variabel lokal untuk digunakan di seluruh async gap
                final currentContext = context;

                if (selectedRole == null) {
                  ScaffoldMessenger.of(currentContext).showSnackBar( // Gunakan currentContext
                    const SnackBar(content: Text("Silakan pilih role!"), backgroundColor: Colors.red),
                  );
                  return;
                }

                if (passwordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(currentContext).showSnackBar( // Gunakan currentContext
                    const SnackBar(content: Text("Password dan konfirmasi password tidak sama!"), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  // Setelah await pertama, cek mounted
                  if (!currentContext.mounted) return;

                  await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                    'fullName': fullNameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                    'schoolName': schoolController.text.trim(),
                    'role': selectedRole,
                  });

                  // Setelah await kedua, cek mounted
                  if (!currentContext.mounted) return;

                  ScaffoldMessenger.of(currentContext).showSnackBar( // Gunakan currentContext
                    const SnackBar(content: Text("Akun berhasil dibuat! Silakan login."), backgroundColor: Colors.green),
                  );

                  if (!currentContext.mounted) return; // Cek sebelum navigasi
                  Navigator.pushReplacement(
                    currentContext, // Gunakan currentContext
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                } on FirebaseAuthException catch (e) {
                  String message;
                  if (e.code == 'weak-password') {
                    message = 'Password terlalu lemah.';
                  } else if (e.code == 'email-already-in-use') {
                    message = 'Email sudah terdaftar.';
                  } else {
                    message = 'Terjadi kesalahan saat registrasi: ${e.message}';
                  }
                  if (!currentContext.mounted) return; // Cek sebelum snackbar
                  ScaffoldMessenger.of(currentContext).showSnackBar( // Gunakan currentContext
                    SnackBar(content: Text(message), backgroundColor: Colors.red),
                  );
                } catch (e) {
                  if (!currentContext.mounted) return; // Cek sebelum snackbar
                  ScaffoldMessenger.of(currentContext).showSnackBar( // Gunakan currentContext
                    SnackBar(content: Text('Terjadi kesalahan tidak terduga: $e'), backgroundColor: Colors.red),
                  );
                }
              }),
            ],
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () {
                  // Ini adalah callback sinkronus, tidak perlu mounted check
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text.rich(
                  TextSpan(
                    text: 'Sudah punya akun? ',
                    children: [
                      TextSpan(
                        text: 'Masuk',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isVisible, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: !isVisible,
            decoration: InputDecoration(
              hintText: label,
              suffixIcon: IconButton(
                icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: toggle,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pilih Role", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: "Pilih role",
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            value: selectedRole,
            items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
            onChanged: (value) {
              setState(() {
                selectedRole = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return Center(
      child: SizedBox(
        width: 180,
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2962FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}