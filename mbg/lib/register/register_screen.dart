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
  // Mengganti schoolNisInputController menjadi generic untuk input spesifik role
  final TextEditingController roleSpecificInputController = TextEditingController();

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
    roleSpecificInputController.dispose(); // Perubahan
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
          shadowColor: Colors.blue.shade200.withOpacity(0.5),
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
                    roleSpecificInputController.clear(); // Perubahan: clear controller
                  });
                },
              ),
              const SizedBox(height: 16),
              // Conditional input field based on selected role
              if (selectedRole == 'Admin Sekolah')
                _buildCustomTextField(
                  label: "Nama Sekolah",
                  hint: "Isi nama sekolah Anda",
                  controller: roleSpecificInputController,
                  prefixIcon: Icons.home_outlined,
                )
              else if (selectedRole == 'Guru' || selectedRole == 'Tim Katering') // Perubahan: Tambah 'Tim Katering'
                _buildCustomTextField(
                  label: "Kode Sekolah", // Perubahan: label menjadi Kode Sekolah
                  hint: "Masukkan kode sekolah Anda", // Perubahan: hint
                  controller: roleSpecificInputController,
                  prefixIcon: Icons.vpn_key_outlined, // Icon baru untuk kode
                )
              else if (selectedRole == 'Orang Tua')
                _buildCustomTextField(
                  label: "NIS Anak",
                  hint: "Masukkan NIS anak Anda",
                  controller: roleSpecificInputController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.child_care_outlined,
                )
              else if (selectedRole == 'Dinas Pendidikan')
                _buildCustomTextField(
                  label: "Nama Dinas",
                  hint: "Isi nama dinas Anda",
                  controller: roleSpecificInputController,
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

                // Perubahan: Validasi input berdasarkan role
                String fieldLabel = '';
                if (selectedRole == 'Admin Sekolah') {
                  fieldLabel = 'Nama Sekolah';
                } else if (selectedRole == 'Guru' || selectedRole == 'Tim Katering') { // Perubahan
                  fieldLabel = 'Kode Sekolah';
                } else if (selectedRole == 'Orang Tua') {
                  fieldLabel = 'NIS Anak';
                } else if (selectedRole == 'Dinas Pendidikan') {
                  fieldLabel = 'Nama Dinas';
                }

                if (roleSpecificInputController.text.isEmpty && selectedRole != 'Dinas Pendidikan') { // Dinas Pendidikan tidak perlu Kode Sekolah atau NIS
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
                  // Cek apakah email sudah terdaftar
                  final email = emailController.text.trim();
                  User? existingUser;
                  try {
                    existingUser = FirebaseAuth.instance.currentUser; // Cek jika sudah login
                    if (existingUser != null && existingUser.email == email) {
                      // Do nothing, user is already logged in with this email
                    } else {
                      // Try to fetch sign-in methods for the email
                      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
                      if (methods.isNotEmpty) {
                        // Email already exists, get the user
                        existingUser = (await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: passwordController.text.trim())).user; // Perlu login ulang
                      }
                    }
                  } on FirebaseAuthException catch (e) {
                      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
                          // Email not found or wrong password, continue with new registration
                      } else {
                          rethrow; // Re-throw other FirebaseAuthException
                      }
                  } catch (e) {
                      rethrow; // Re-throw other exceptions
                  }


                  UserCredential userCredential;
                  DocumentSnapshot? userDoc;
                  String? userId;

                  if (existingUser != null) {
                    userId = existingUser.uid;
                    userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
                  } else {
                    userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: email,
                      password: passwordController.text.trim(),
                    );
                    userId = userCredential.user!.uid;
                  }

                  if (!currentContext.mounted) return;

                  // Ambil data user yang sudah ada jika ada
                  Map<String, dynamic> userData;
                  List<String> existingRoles = [];

                  if (userDoc != null && userDoc.exists) {
                    userData = userDoc.data() as Map<String, dynamic>;
                    // Pastikan 'roles' adalah List<String>
                    if (userData.containsKey('roles') && userData['roles'] is List) {
                      existingRoles = List<String>.from(userData['roles']);
                    } else {
                      // Jika hanya ada 'role' tunggal dari versi lama, konversi ke list
                      if (userData.containsKey('role') && userData['role'] is String) {
                        existingRoles.add(userData['role']);
                      }
                    }
                    // Tambahkan role baru jika belum ada
                    if (!existingRoles.contains(selectedRole)) {
                      existingRoles.add(selectedRole!);
                    }
                  } else {
                    // Akun baru, inisialisasi dengan role pertama
                    userData = {
                      'fullName': fullNameController.text.trim(),
                      'email': email,
                      'phoneNumber': phoneController.text.trim(),
                      'roles': [selectedRole!], // Menggunakan 'roles' (plural)
                      'profilePictureUrl': '',
                      'schoolId': null,
                      'schoolName': null,
                      'childIds': [],
                      'isApproved': selectedRole == 'Admin Sekolah' || selectedRole == 'Dinas Pendidikan' ? true : false, // Admin Sekolah & Dinas Pendidikan langsung approved
                    };
                    existingRoles.add(selectedRole!);
                  }

                  // Logika spesifik role
                  if (selectedRole == 'Admin Sekolah') {
                    final schoolName = roleSpecificInputController.text.trim();
                    // Cek apakah sekolah dengan nama ini sudah ada dan diverifikasi
                    QuerySnapshot existingSchoolSnap = await FirebaseFirestore.instance.collection('schools')
                        .where('schoolName', isEqualTo: schoolName)
                        .limit(1)
                        .get();

                    if (existingSchoolSnap.docs.isNotEmpty) {
                      final schoolData = existingSchoolSnap.docs.first.data() as Map<String, dynamic>;
                      if (schoolData['isVerified'] == true) {
                        if (!currentContext.mounted) return;
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text("Nama sekolah ini sudah terdaftar dan diverifikasi. Silakan hubungi admin sekolah terkait untuk akses."),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        // Jika email sudah terdaftar dan sekolah terverifikasi, jangan biarkan mendaftar lagi sebagai Admin Sekolah
                        if (existingUser == null) { // If it's a new user trying to register as admin for an existing school
                            await FirebaseAuth.instance.currentUser?.delete(); // Delete the newly created user
                        }
                        return;
                      } else {
                         if (!currentContext.mounted) return;
                         ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text("Nama sekolah ini sudah terdaftar tapi belum diverifikasi. Harap tunggu verifikasi oleh Dinas Pendidikan."),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        // Jika sekolah belum terverifikasi, biarkan Admin Sekolah yang mendaftar awal tetap pada status pending
                        // atau arahkan untuk login jika sudah mendaftar
                        if (existingUser == null) { // If it's a new user trying to register as admin for an existing unverified school
                            await FirebaseAuth.instance.currentUser?.delete();
                        }
                        return;
                      }
                    }

                    // Buat dokumen sekolah baru dan permintaan verifikasi
                    DocumentReference schoolRef = await FirebaseFirestore.instance.collection('schools').add({
                      'schoolName': schoolName,
                      'address': '', // Tambahkan field address sesuai kebutuhan
                      'adminUserId': userId,
                      'isVerified': false,
                      'schoolCode': _generateSchoolCode(), // Generate kode sekolah
                      'registeredAt': Timestamp.now(),
                    });
                    userData['schoolId'] = schoolRef.id;
                    userData['schoolName'] = schoolName;

                    await FirebaseFirestore.instance.collection('schoolVerificationRequests').add({
                      'schoolId': schoolRef.id,
                      'schoolName': schoolName,
                      'adminUserId': userId,
                      'adminName': fullNameController.text.trim(),
                      'status': 'pending',
                      'requestedAt': Timestamp.now(),
                    });
                    userData['isApproved'] = false; // Admin Sekolah perlu menunggu verifikasi sekolah
                  } else if (selectedRole == 'Guru' || selectedRole == 'Tim Katering') { // Perubahan
                    final schoolCode = roleSpecificInputController.text.trim();
                    QuerySnapshot schoolSnap = await FirebaseFirestore.instance
                        .collection('schools')
                        .where('schoolCode', isEqualTo: schoolCode)
                        .where('isVerified', isEqualTo: true) // Hanya sekolah yang sudah terverifikasi
                        .limit(1)
                        .get();

                    if (schoolSnap.docs.isNotEmpty) {
                      final schoolData = schoolSnap.docs.first.data() as Map<String, dynamic>;
                      userData['schoolId'] = schoolSnap.docs.first.id;
                      userData['schoolName'] = schoolData['schoolName'];
                      userData['isApproved'] = true; // Guru/Tim Katering otomatis approved jika sekolah terverifikasi
                    } else {
                      if (!currentContext.mounted) return;
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Kode sekolah tidak valid atau sekolah belum diverifikasi oleh Dinas Pendidikan.",
                          ),
                          backgroundColor: Colors.red, // Ubah warna jadi merah karena kode tidak valid/belum verifikasi
                        ),
                      );
                      // Jika email baru, hapus user yang baru dibuat jika tidak valid
                      if (existingUser == null) {
                         await FirebaseAuth.instance.currentUser?.delete();
                      }
                      return;
                    }
                  } else if (selectedRole == 'Orang Tua') {
                    final nisAnak = roleSpecificInputController.text.trim();
                    QuerySnapshot studentSnap = await FirebaseFirestore.instance
                        .collection('students')
                        .where('nis', isEqualTo: nisAnak)
                        .limit(1)
                        .get();

                    if (studentSnap.docs.isNotEmpty) {
                      final studentData = studentSnap.docs.first.data() as Map<String, dynamic>;
                      userData['childIds'] = [studentSnap.docs.first.id];
                      userData['schoolId'] = studentData['schoolId'];
                      userData['schoolName'] = studentData['schoolName'];
                      userData['isApproved'] = false; // Orang Tua perlu persetujuan Admin Sekolah
                      await FirebaseFirestore.instance.collection('parentApprovalRequests').add({
                        'parentId': userId,
                        'parentName': fullNameController.text.trim(),
                        'childId': studentSnap.docs.first.id,
                        'childNis': nisAnak,
                        'schoolId': studentData['schoolId'],
                        'schoolName': studentData['schoolName'],
                        'status': 'pending',
                        'requestedAt': Timestamp.now(),
                      });
                    } else {
                      if (!currentContext.mounted) return;
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "NIS anak tidak ditemukan. Harap pastikan NIS benar atau hubungi Admin Sekolah.",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      // Jika email baru, hapus user yang baru dibuat jika NIS tidak valid
                      if (existingUser == null) {
                          await FirebaseAuth.instance.currentUser?.delete();
                      }
                      return;
                    }
                  } else if (selectedRole == 'Dinas Pendidikan') {
                    userData['dinasName'] = roleSpecificInputController.text.trim();
                    userData['isApproved'] = true; // Dinas Pendidikan langsung approved
                    // Tambahkan validasi unik untuk Dinas Pendidikan jika hanya boleh 1 akun
                    QuerySnapshot dinasSnap = await FirebaseFirestore.instance
                        .collection('users')
                        .where('roles', arrayContains: 'Dinas Pendidikan') // Cek jika ada role Dinas Pendidikan
                        .limit(1)
                        .get();
                    if (dinasSnap.docs.isNotEmpty && dinasSnap.docs.first.id != userId) {
                      if (!currentContext.mounted) return;
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(
                          content: Text("Akun Dinas Pendidikan sudah terdaftar. Hanya boleh satu."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      if (existingUser == null) {
                        await FirebaseAuth.instance.currentUser?.delete();
                      }
                      return;
                    }
                  }

                  // Final update ke Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .set(userData, SetOptions(merge: true)); // Menggunakan merge untuk update roles

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
                    message = 'Email sudah terdaftar. Jika Anda ingin menambahkan peran, silakan login dan tambahkan peran dari pengaturan.'; // Perubahan pesan
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

  // Fungsi untuk menggenerasi kode sekolah
  String _generateSchoolCode() {
    // Implementasi sederhana, bisa diganti dengan UUID atau kombinasi lain yang lebih robust
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < 6; i++) { // Misal 6 karakter
      code += chars[DateTime.now().microsecondsSinceEpoch % chars.length];
    }
    return code;
  }
}