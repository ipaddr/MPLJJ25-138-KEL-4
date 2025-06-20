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
  final TextEditingController schoolNisInputController =
      TextEditingController();

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
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    schoolNisInputController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        leading:
            step ==
                    2
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => step = 1),
                )
                : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                step == 1
                    ? "Informasi Pribadi"
                    : "Buat Akun & Role",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (step == 1) ...[
              _buildField(
                "Nama Lengkap",
                "Isi nama lengkap",
                fullNameController,
              ),
              _buildField("Email", "your@email.com", emailController),
              _buildField("No. Handphone", "012345678901", phoneController),
              const SizedBox(height: 32),
              _buildPrimaryButton("Selanjutnya", () {
                if (fullNameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Harap lengkapi semua data pribadi!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                setState(() => step = 2);
              }),
            ] else ...[
              _buildPasswordField(
                "Password",
                passwordController,
                showPassword,
                () => setState(() => showPassword = !showPassword),
              ),
              _buildPasswordField(
                "Konfirmasi Password",
                confirmPasswordController,
                showConfirmPassword,
                () =>
                    setState(() => showConfirmPassword = !showConfirmPassword),
              ),
              _buildRoleDropdown(),
              const SizedBox(height: 20),
              if (selectedRole == 'Admin Sekolah' ||
                  selectedRole == 'Guru' ||
                  selectedRole == 'Tim Katering')
                _buildField(
                  "Nama Sekolah",
                  "Isi nama sekolah",
                  schoolNisInputController,
                )
              else if (selectedRole == 'Orang Tua')
                _buildField(
                  "NIS Anak",
                  "Masukkan NIS anak",
                  schoolNisInputController,
                )
              else if (selectedRole == 'Dinas Pendidikan')
                _buildField(
                  "Nama Dinas",
                  "Isi nama dinas",
                  schoolNisInputController,
                ),

              const SizedBox(height: 32),
              _buildPrimaryButton("Buat Akun", () async {
                final currentContext = context;

                if (selectedRole == null) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text("Silakan pilih role!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if ((selectedRole == 'Admin Sekolah' ||
                        selectedRole == 'Guru' ||
                        selectedRole == 'Tim Katering' ||
                        selectedRole == 'Orang Tua' ||
                        selectedRole == 'Dinas Pendidikan') &&
                    schoolNisInputController.text.isEmpty) {
                  String fieldLabel = '';
                  if (selectedRole == 'Admin Sekolah' ||
                      selectedRole == 'Guru' ||
                      selectedRole == 'Tim Katering') {
                    fieldLabel = 'Nama Sekolah';
                  } else if (selectedRole == 'Orang Tua') {
                    fieldLabel = 'NIS Anak';
                  } else if (selectedRole == 'Dinas Pendidikan') {
                    fieldLabel = 'Nama Dinas';
                  }
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text("Harap isi $fieldLabel."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (passwordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Password dan konfirmasi password tidak sama!",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                  if (!currentContext.mounted) return;

                  Map<String, dynamic> userData = {
                    'isApproved': selectedRole == 'Orang Tua' ? false : false,
                    'childIds': [],
                    'schoolId': null,
                    'schoolName': null,
                    'fullName': fullNameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                    'role': selectedRole,
                    'profilePictureUrl': '',
                  };

                  String? schoolIdToLink;

                  if (selectedRole == 'Admin Sekolah') {
                    userData['schoolName'] =
                        schoolNisInputController.text
                            .trim();
                    DocumentReference schoolRef = await FirebaseFirestore
                        .instance
                        .collection('schools')
                        .add({
                          'schoolName':
                              schoolNisInputController.text
                                  .trim(),
                          'address': '',
                          'adminUserId': userCredential.user!.uid,
                          'isVerified':
                              false,
                          'registeredAt': Timestamp.now(),
                        });
                    schoolIdToLink = schoolRef.id;
                    userData['schoolId'] =
                        schoolIdToLink;
                    await FirebaseFirestore.instance
                        .collection('schoolVerificationRequests')
                        .add({
                          'schoolId': schoolIdToLink,
                          'schoolName': schoolNisInputController.text.trim(),
                          'adminUserId': userCredential.user!.uid,
                          'adminName': fullNameController.text.trim(),
                          'status': 'pending',
                          'requestedAt': Timestamp.now(),
                        });
                  } else if (selectedRole == 'Guru') {
                    userData['schoolName'] =
                        schoolNisInputController.text
                            .trim();
                    QuerySnapshot schoolSnap =
                        await FirebaseFirestore.instance
                            .collection('schools')
                            .where(
                              'schoolName',
                              isEqualTo: schoolNisInputController.text.trim(),
                            )
                            .limit(1)
                            .get();
                    if (schoolSnap.docs.isNotEmpty) {
                      schoolIdToLink = schoolSnap.docs.first.id;
                      userData['schoolId'] = schoolIdToLink;
                    } else {
                      userData['schoolId'] =
                          null;
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Nama sekolah tidak ditemukan. Guru perlu didaftarkan ke sekolah yang sudah ada.",
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  } else if (selectedRole == 'Orang Tua') {
                    userData['childNisRequest'] =
                        schoolNisInputController.text
                            .trim();
                    userData['isApproved'] = false;
                    userData['childIds'] =
                        [];
                  } else if (selectedRole == 'Dinas Pendidikan') {
                    userData['dinasName'] =
                        schoolNisInputController.text.trim();
                  }

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userCredential.user!.uid)
                      .set(userData);

                  if (!currentContext.mounted) return;

                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text("Akun berhasil dibuat! Silakan login."),
                      backgroundColor: Colors.green,
                    ),
                  );

                  if (!currentContext.mounted) return;
                  Navigator.pushReplacement(
                    currentContext,
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
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isVisible,
    VoidCallback toggle,
  ) {
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          const Text(
            "Pilih Role",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: "Pilih role",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            value: selectedRole,
            items:
                roles
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() {
                selectedRole = value;
                schoolNisInputController
                    .clear();
                if (value == 'Orang Tua') {
                }
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
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
