import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../provider/user_provider.dart';
import '../screens/main_screen.dart';
import 'lupa_password.dart';
import '../register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Login Aplikasi Makan Bergizi',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Pilih Role',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedRole,
                  items: roles
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Lupa Password?'),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedRole == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pilih role terlebih dahulu!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final currentContext = context;

                      try {
                        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );

                        if (!currentContext.mounted) return;

                        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

                        if (!currentContext.mounted) return;

                        if (userDoc.exists) {
                          // DEFINE userDataMap DI SINI
                          final userDataMap = userDoc.data() as Map<String, dynamic>?;

                          String? storedRole = userDataMap?['role'];
                          String? fullName = userDataMap?['fullName'];
                          String? schoolId = userDataMap?['schoolId'];
                          String? schoolName = userDataMap?['schoolName'];
                          String? profilePictureUrl = userDataMap?['profilePictureUrl'];
                          bool? isApproved = userDataMap?['isApproved'] ?? false; // Menggunakan ?? false untuk default
                          List<String> childIds = List<String>.from(userDataMap?['childIds'] ?? []);

                          if (storedRole == selectedRole) {
                            Provider.of<UserProvider>(currentContext, listen: false)
                                .setUser(
                                  userCredential.user!.uid,
                                  userCredential.user!.email,
                                  storedRole!,
                                  fullName: fullName,
                                  schoolId: schoolId,
                                  schoolName: schoolName,
                                  profilePictureUrl: profilePictureUrl,
                                  isApproved: isApproved,
                                  childIds: childIds,
                                );

                            if (!currentContext.mounted) return;
                            Navigator.pushReplacement(
                              currentContext,
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(),
                              ),
                            );
                          } else {
                            await FirebaseAuth.instance.signOut();
                            if (!currentContext.mounted) return;
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              const SnackBar(
                                content: Text('Role yang Anda pilih tidak cocok dengan akun ini.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          await FirebaseAuth.instance.signOut();
                          if (!currentContext.mounted) return;
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Data pengguna tidak ditemukan. Silakan hubungi admin.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        String message;
                        if (e.code == 'user-not-found') {
                          message = 'Email tidak terdaftar.';
                        } else if (e.code == 'wrong-password') {
                          message = 'Password salah.';
                        } else if (e.code == 'invalid-email') {
                          message = 'Format email tidak valid.';
                        } else {
                          message = 'Terjadi kesalahan saat login: ${e.message}';
                        }
                        if (!currentContext.mounted) return;
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(content: Text(message), backgroundColor: Colors.red),
                        );
                      } catch (e) {
                        if (!currentContext.mounted) return;
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(content: Text('Terjadi kesalahan tidak terduga: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: 'Belum punya akun? ',
                      children: [
                        TextSpan(
                          text: 'Register',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}