import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan email untuk reset password',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final currentContext = context; 

                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (!currentContext.mounted) return; 

                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(
                        content: Text('Link reset dikirim ke $email. Silakan cek email Anda.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } on FirebaseAuthException catch (e) {
                    String message;
                    if (e.code == 'user-not-found') {
                      message = 'Tidak ada pengguna dengan email tersebut.';
                    } else {
                      message = 'Gagal mengirim link reset: ${e.message}';
                    }
                    
                    if (!currentContext.mounted) return;

                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    if (!currentContext.mounted) return;

                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(
                        content: Text('Terjadi kesalahan tidak terduga: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Email tidak boleh kosong!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Kirim Link Reset'),
            ),
          ],
        ),
      ),
    );
  }
}