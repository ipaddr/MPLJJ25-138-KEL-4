import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import 'package:intl/intl.dart';

class ParentApprovalPage extends StatefulWidget {
  const ParentApprovalPage({super.key});

  @override
  State<ParentApprovalPage> createState() => _ParentApprovalPageState();
}

class _ParentApprovalPageState extends State<ParentApprovalPage> {
  String? _adminUid;
  String? _adminSchoolId;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  void _loadAdminInfo() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _adminUid = userProvider.uid;
    _adminSchoolId = userProvider.schoolId;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    String? currentAdminSchoolId = userProvider.schoolId ?? _adminSchoolId;

    if (currentAdminSchoolId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Permintaan Akses Orang Tua")),
        body: const Center(child: Text("Data sekolah Admin tidak ditemukan. Tidak dapat memuat permintaan.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Permintaan Akses Orang Tua"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parentApprovalRequests')
            .where('schoolId', isEqualTo: currentAdminSchoolId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Tidak ada permintaan akses orang tua yang tertunda."));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index].data() as Map<String, dynamic>;
              String requestId = requests[index].id;
              String parentId = request['parentId'] ?? 'N/A';
              String childId = request['childId'] ?? 'N/A'; // Ini adalah ID dokumen siswa
              String childNis = request['childNis'] ?? 'N/A';
              String schoolName = request['schoolName'] ?? 'N/A';
              Timestamp requestedAt = request['requestedAt'] ?? Timestamp.now();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Permintaan dari Orang Tua ID: $parentId", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("NIS Anak: $childNis"),
                      Text("Nama Sekolah: $schoolName"),
                      Text("Diminta pada: ${DateFormat('dd-MM-yyyy HH:mm').format(requestedAt.toDate())}"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => _processRequest(requestId, parentId, childId, 'approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text("Setujui"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _processRequest(requestId, parentId, childId, 'rejected'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text("Tolak"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _processRequest(String requestId, String parentId, String childId, String status) async {
    final currentContext = context;
    String? adminUid = _adminUid;
    String? adminSchoolId = _adminSchoolId;

    if (adminUid == null || adminSchoolId == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text("Admin tidak terautentikasi atau ID sekolah tidak ditemukan."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      // Update status permintaan di koleksi parentApprovalRequests
      await FirebaseFirestore.instance.collection('parentApprovalRequests').doc(requestId).update({
        'status': status,
        'processedByAdminId': adminUid,
        'processedAt': Timestamp.now(),
      });

      if (status == 'approved') {
        // Jika disetujui, tambahkan childId ke array childIds di profil Orang Tua
        // Dan tambahkan parentId ke array parentIds di dokumen siswa
        if (childId != 'N/A') {
          // Periksa apakah studentIdToUpdateParent adalah ID yang valid dari siswa yang terdaftar di Firestore
          DocumentSnapshot actualStudentDoc = await FirebaseFirestore.instance.collection('students').doc(childId).get();
          if (!currentContext.mounted) return;

          if (actualStudentDoc.exists) {
            await FirebaseFirestore.instance.collection('students').doc(childId).update({
              'parentIds': FieldValue.arrayUnion([parentId]),
            });

            // Perbarui status isApproved dan childIds di dokumen user Orang Tua
            await FirebaseFirestore.instance.collection('users').doc(parentId).update({
              'isApproved': true,
              'childIds': FieldValue.arrayUnion([childId]),
            });

            // Perbarui UserProvider untuk UI
            if (currentContext.mounted) {
              Provider.of<UserProvider>(currentContext, listen: false).updateApprovalStatus(true);
              Provider.of<UserProvider>(currentContext, listen: false).addChildId(childId);
            }
          } else {
            if (currentContext.mounted) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(content: Text("Peringatan: ID Siswa tidak ditemukan di database. Approval dilakukan, tapi data anak tidak terhubung."), backgroundColor: Colors.orange),
              );
            }
          }
        } else {
          if (currentContext.mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(content: Text("Peringatan: ID Siswa dalam permintaan tidak valid ('N/A'). Approval dilakukan, tapi data anak tidak terhubung."), backgroundColor: Colors.orange),
            );
          }
        }
      } else { // Jika status == 'rejected'
        // Set isApproved menjadi false dan hapus childId dari array childIds di profil Orang Tua
        await FirebaseFirestore.instance.collection('users').doc(parentId).update({
          'isApproved': false,
          'childIds': FieldValue.arrayRemove([childId]), // Hapus childId jika ada
        });

        // Hapus parentId dari dokumen siswa jika ada
        if (childId != 'N/A') {
          DocumentSnapshot actualStudentDoc = await FirebaseFirestore.instance.collection('students').doc(childId).get();
          if (actualStudentDoc.exists) {
            await FirebaseFirestore.instance.collection('students').doc(childId).update({
              'parentIds': FieldValue.arrayRemove([parentId]),
            });
          }
        }
        
        // Perbarui UserProvider untuk UI
        if (currentContext.mounted) {
          Provider.of<UserProvider>(currentContext, listen: false).updateApprovalStatus(false);
          Provider.of<UserProvider>(currentContext, listen: false).removeChildId(childId);
        }
      }
      
      if (!currentContext.mounted) return;

      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text("Permintaan berhasil di$status!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal memproses permintaan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}