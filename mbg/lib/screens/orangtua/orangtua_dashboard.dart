import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import 'package:intl/intl.dart';
import '../guru/chatbot_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../login/login_screen.dart';

class OrangTuaDashboard extends StatefulWidget {
  const OrangTuaDashboard({super.key});

  @override
  State<OrangTuaDashboard> createState() => _OrangTuaDashboardState();
}

class _OrangTuaDashboardState extends State<OrangTuaDashboard> {
  final TextEditingController nisController = TextEditingController();
  final TextEditingController sekolahController = TextEditingController();

  Map<String, dynamic>? _pendingRequest;
  String parentName = "Nama Orang Tua";

  Map<String, dynamic>? childProfile;
  Map<String, Map<String, bool>> childDailyConsumption = {};
  bool _showChildDashboardButton = false;
  bool _isChildDashboardVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchParentProfile();
    _listenToPendingRequests();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.fullName != null) {
      parentName = userProvider.fullName!;
    }

    if (userProvider.isApproved == true &&
        userProvider.childIds != null &&
        userProvider.childIds!.isNotEmpty) {
      if (_pendingRequest != null && _pendingRequest!['status'] == 'pending') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("Permintaan akses disetujui! Silakan klik 'Lihat Dashboard Anak'."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
          setState(() {
            _pendingRequest = null;
            _showChildDashboardButton = true;
          });
        });
      } else if (!_isChildDashboardVisible) {
        setState(() {
          _showChildDashboardButton = true;
        });
      }
    } else {
      setState(() {
        _showChildDashboardButton = false;
        _isChildDashboardVisible = false;
      });
    }
  }

  void _listenToPendingRequests() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String? parentUid = userProvider.uid;

    if (parentUid == null) return;

    FirebaseFirestore.instance
        .collection('parentApprovalRequests')
        .where('parentId', isEqualTo: parentUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _pendingRequest = snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null;
      });
    });
  }

  Future<void> _fetchParentProfile() async {
    final currentContext = context;
    final userProvider = Provider.of<UserProvider>(currentContext, listen: false);
    String? uid = userProvider.uid;

    if (uid == null) return;

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!currentContext.mounted) return;

      if (userDoc.exists) {
        setState(() {
          parentName = userDoc.get('fullName') ?? "Nama Orang Tua";
        });
      }
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
              content: Text("Gagal memuat profil orang tua: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _requestAccess() async {
    final currentContext = context;
    final userProvider = Provider.of<UserProvider>(currentContext, listen: false);
    String? parentUid = userProvider.uid;

    if (parentUid == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
              content: Text("Anda harus login untuk mengajukan permintaan."),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (nisController.text.isEmpty || sekolahController.text.isEmpty) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
              content: Text("Harap isi NIS Anak dan Nama Sekolah."),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    String? studentIdToRequest;
    String? schoolIdOfStudent;

    try {
      QuerySnapshot schoolQuerySnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .where('schoolName', isEqualTo: sekolahController.text.trim())
          .limit(1)
          .get();

      if (schoolQuerySnapshot.docs.isEmpty) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(
                content: Text("Nama sekolah tidak ditemukan atau belum diverifikasi oleh Dinas."),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      schoolIdOfStudent = schoolQuerySnapshot.docs.first.id;

      QuerySnapshot studentQuerySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('nis', isEqualTo: nisController.text.trim())
          .where('schoolId', isEqualTo: schoolIdOfStudent)
          .limit(1)
          .get();

      if (studentQuerySnapshot.docs.isEmpty) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text("NIS anak tidak ditemukan di sekolah tersebut."), backgroundColor: Colors.red),
          );
        }
        return;
      }
      studentIdToRequest = studentQuerySnapshot.docs.first.id;

      await FirebaseFirestore.instance.collection('parentApprovalRequests').add({
        'parentId': parentUid,
        'childNis': nisController.text.trim(),
        'childId': studentIdToRequest,
        'schoolName': sekolahController.text.trim(),
        'schoolId': schoolIdOfStudent,
        'status': 'pending',
        'requestedAt': Timestamp.now(),
      });
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
            content: Text("Permintaan akses berhasil dikirim! Menunggu persetujuan Admin Sekolah."),
            backgroundColor: Colors.green),
      );
      setState(() {
        _pendingRequest = {
          'parentId': parentUid,
          'childNis': nisController.text.trim(),
          'childId': studentIdToRequest,
          'schoolName': sekolahController.text.trim(),
          'schoolId': schoolIdOfStudent,
          'status': 'pending',
          'requestedAt': Timestamp.now(),
        };
      });
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal mengajukan permintaan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchChildData(String childId) async {
    final currentContext = context;
    try {
      DocumentSnapshot childDoc =
          await FirebaseFirestore.instance.collection('students').doc(childId).get();
      if (!currentContext.mounted) return;

      if (childDoc.exists) {
        setState(() {
          childProfile = childDoc.data() as Map<String, dynamic>;
        });

        final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());
        DocumentSnapshot consumptionDoc = await FirebaseFirestore.instance
            .collection('dailyConsumptions')
            .doc('${childId}_$todayFormatted')
            .get();

        if (!currentContext.mounted) return;
        if (consumptionDoc.exists) {
          setState(() {
            childDailyConsumption[childId] = {
              'makanPagi': consumptionDoc.get('makanPagi') ?? false,
              'makanSiang': consumptionDoc.get('makanSiang') ?? false,
            };
          });
        } else {
          setState(() {
            childDailyConsumption[childId] = {
              'makanPagi': false,
              'makanSiang': false,
            };
          });
        }
      }
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal memuat data anak: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    final currentContext = context;
    try {
      await FirebaseAuth.instance.signOut();
      if (!currentContext.mounted) return;
      Provider.of<UserProvider>(currentContext, listen: false).clearUser();
      Navigator.of(currentContext).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal logout: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: userProvider.profilePictureUrl != null && userProvider.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(userProvider.profilePictureUrl!) as ImageProvider
                  : const AssetImage('assets/images/foto.png'),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('Orang Tua', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.smart_toy),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('!', style: TextStyle(fontSize: 8, color: Colors.white)),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotPage()),
              );
            },
            tooltip: 'Chatbot',
          ),
          const IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: null,
            tooltip: 'Notifikasi',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (!userProvider.isApproved!)
                _buildApprovalRequestFormWithDynamicStatus()
              else if (_showChildDashboardButton && !_isChildDashboardVisible)
                _buildApprovedMessageAndButton()
              else if (userProvider.childIds == null || userProvider.childIds!.isEmpty)
                _buildNoChildFound()
              else
                _buildChildDashboard(userProvider.childIds!.first),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalRequestFormWithDynamicStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ajukan Akses Data Anak',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('NIS Anak', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: nisController,
          decoration: InputDecoration(
            hintText: 'Masukkan NIS anak anda',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        const Text('Nama Sekolah', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: sekolahController,
          decoration: InputDecoration(
            hintText: 'Masukkan nama sekolah anak anda',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _requestAccess,
            child: const Text('Ajukan Akses', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: _pendingRequest != null
              ? Text(
                  "Status: Menunggu konfirmasi admin sekolah untuk NIS ${_pendingRequest!['childNis']}...",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                )
              : const Text(
                  "Status: Silakan ajukan akses data anak Anda.",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
        ),
      ],
    );
  }

  Widget _buildApprovedMessageAndButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Permintaan akses Anda telah disetujui!",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isChildDashboardVisible = true;
            });
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            if (userProvider.childIds != null && userProvider.childIds!.isNotEmpty) {
              _fetchChildData(userProvider.childIds!.first);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Lihat Dashboard Anak", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildNoChildFound() {
    return Column(
      children: const [
        Text("Anda sudah disetujui, tetapi belum ada data anak yang terhubung.", style: TextStyle(fontSize: 16)),
        SizedBox(height: 10),
        Text("Pastikan NIS anak Anda sudah terdaftar oleh Admin Sekolah.", style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildChildDashboard(String childId) {
    if (childProfile == null) {
      _fetchChildData(childId);
      return const Center(child: CircularProgressIndicator());
    }

    final String childName = childProfile?['nama'] ?? 'Anak Anda';
    final String childClass = childProfile?['kelas'] ?? 'N/A';
    final String childNisDisplay = childProfile?['nis'] ?? 'N/A';

    final todayFormatted = DateFormat('EEEE, d MMMM', 'id_ID').format(DateTime.now());
    final statusMakanPagi = childDailyConsumption[childId]?['makanPagi'] ?? false;
    final statusMakanSiang = childDailyConsumption[childId]?['makanSiang'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Data Anak: $childName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Kelas: $childClass", style: const TextStyle(fontSize: 16)),
        Text("NIS: $childNisDisplay", style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 20),

        const Text("Status Makan Hari Ini", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(todayFormatted, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),

        _buildMealStatusTile("Makan Pagi", Icons.breakfast_dining, statusMakanPagi),
        const SizedBox(height: 8),
        _buildMealStatusTile("Makan Siang", Icons.lunch_dining, statusMakanSiang),
        const SizedBox(height: 20),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMealStatusTile(String title, IconData icon, bool isEaten) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEaten ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isEaten ? Colors.green.shade800 : Colors.red.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            isEaten ? "Sudah Makan" : "Belum Makan",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isEaten ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }
}