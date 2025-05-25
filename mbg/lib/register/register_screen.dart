// register_screen.dart
import 'package:flutter/material.dart';
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

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final roleController = TextEditingController();

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
              _buildField("No. Handphone", "(+62) 1234-5678-9012", phoneController),
              _buildField("Asal Sekolah", "Isi nama sekolah", schoolController),
              const SizedBox(height: 32),
              _buildPrimaryButton("Selanjutnya", () => setState(() => step = 2)),
            ] else ...[
              _buildField("Username", "Buat username", usernameController),
              _buildPasswordField("Password", passwordController, showPassword, () => setState(() => showPassword = !showPassword)),
              _buildPasswordField("Konfirmasi Password", confirmPasswordController, showConfirmPassword, () => setState(() => showConfirmPassword = !showConfirmPassword)),
              _buildField("Pilih Role", "Pillih role", roleController),
              const SizedBox(height: 32),
              _buildPrimaryButton("Buat Akun", () {
                // TODO: Implement register logic
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }),
            ],
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () {
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