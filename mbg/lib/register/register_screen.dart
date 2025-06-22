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

  Widget _buildCustomTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.blue) : null,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDropdownField({
    required String label,
    required List<String> items,
    String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: "Pilih role",
              prefixIcon: const Icon(Icons.person_outline, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            value: value,
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          // Corrected line
          shadowColor: Colors.blue.shade200.withAlpha((255 * 0.5).round()),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: step == 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => setState(() => step = 1),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              step == 1 ? "Daftar Akun Baru" : "Informasi Akun",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step == 1
                  ? "Mari buat akun Anda dengan mengisi informasi dasar."
                  : "Hampir selesai! Buat password dan pilih role Anda.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),

            if (step == 1) ...[
              _buildCustomTextField(
                label: "Nama Lengkap",
                hint: "Contoh: Budi Santoso",
                controller: fullNameController,
                prefixIcon: Icons.person_outline,
              ),
              _buildCustomTextField(
                label: "Email",
                hint: "emailanda@contoh.com",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              _buildCustomTextField(
                label: "No. Handphone",
                hint: "0812xxxxxxxx",
                controller: phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 24),
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
              _buildCustomTextField(
                label: "Password",
                hint: "••••••••",
                controller: passwordController,
                obscureText: !showPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
              _buildCustomTextField(
                label: "Konfirmasi Password",
                hint: "••••••••",
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                ),
              ),
              _buildCustomDropdownField(
                label: "Pilih Role",
                items: roles,
                value: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                    schoolNisInputController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              if (selectedRole == 'Admin Sekolah' ||
                  selectedRole == 'Guru' ||
                  selectedRole == 'Tim Katering')
                _buildCustomTextField(
                  label: "Nama Sekolah",
                  hint: "Isi nama sekolah",
                  controller: schoolNisInputController,
                  prefixIcon: Icons.home_outlined,
                )
              else if (selectedRole == 'Orang Tua')
                _buildCustomTextField(
                  label: "NIS Anak",
                  hint: "Masukkan NIS anak",
                  controller: schoolNisInputController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.child_care_outlined,
                )
              else if (selectedRole == 'Dinas Pendidikan')
                _buildCustomTextField(
                  label: "Nama Dinas",
                  hint: "Isi nama dinas",
                  controller: schoolNisInputController,
                  prefixIcon: Icons.account_balance_outlined,
                ),
              const SizedBox(height: 24),
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
                    QuerySnapshot studentSnap = await FirebaseFirestore.instance
                        .collection('students')
                        .where('nis', isEqualTo: schoolNisInputController.text.trim())
                        .limit(1)
                        .get();

                    if (studentSnap.docs.isNotEmpty) {
                      userData['childIds'] = [studentSnap.docs.first.id];
                      userData['schoolId'] = studentSnap.docs.first['schoolId'];
                      userData['schoolName'] = studentSnap.docs.first['schoolName'];
                      userData['isApproved'] = false;
                      await FirebaseFirestore.instance.collection('parentApprovalRequests').add({
                        'parentId': userCredential.user!.uid,
                        'parentName': fullNameController.text.trim(),
                        'childId': studentSnap.docs.first.id,
                        'childNis': schoolNisInputController.text.trim(),
                        'schoolId': studentSnap.docs.first['schoolId'],
                        'schoolName': studentSnap.docs.first['schoolName'],
                        'status': 'pending',
                        'requestedAt': Timestamp.now(),
                      });
                    } else {
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "NIS anak tidak ditemukan di database manapun. Harap pastikan NIS benar atau hubungi Admin Sekolah.",
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      userData['childIds'] = [];
                      userData['isApproved'] = false;
                    }
                  } else if (selectedRole == 'Dinas Pendidikan') {
                    userData['dinasName'] =
                        schoolNisInputController.text.trim();
                  } else if (selectedRole == 'Tim Katering') {
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
                              "Nama sekolah tidak ditemukan. Tim Katering perlu didaftarkan ke sekolah yang sudah ada.",
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
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
            const SizedBox(height: 32),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text.rich(
                  TextSpan(
                    text: 'Sudah punya akun? ',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                    children: [
                      TextSpan(
                        text: 'Masuk',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}