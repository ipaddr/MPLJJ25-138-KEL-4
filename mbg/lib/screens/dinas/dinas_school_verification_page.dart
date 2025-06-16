import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DinasSchoolVerificationPage extends StatefulWidget {
  const DinasSchoolVerificationPage({super.key});

  @override
  State<DinasSchoolVerificationPage> createState() => _DinasSchoolVerificationPageState();
}

class _DinasSchoolVerificationPageState extends State<DinasSchoolVerificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verifikasi Sekolah"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schoolVerificationRequests')
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
            return const Center(child: Text("Tidak ada permintaan verifikasi sekolah yang tertunda."));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index].data() as Map<String, dynamic>;
              String requestId = requests[index].id;
              String schoolId = request['schoolId'] ?? 'N/A';
              String schoolName = request['schoolName'] ?? 'N/A';
              String adminName = request['adminName'] ?? 'Admin Tidak Diketahui';
              Timestamp requestedAt = request['requestedAt'] ?? Timestamp.now();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Sekolah: $schoolName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Diajukan oleh Admin: $adminName"),
                      Text("ID Sekolah: $schoolId"),
                      Text("Diminta pada: ${DateFormat('dd-MM-yyyy HH:mm').format(requestedAt.toDate())}"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => _processSchoolVerification(requestId, schoolId, 'approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text("Setujui"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _processSchoolVerification(requestId, schoolId, 'rejected'),
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

  Future<void> _processSchoolVerification(String requestId, String schoolId, String status) async {
    final currentContext = context;
    try {
      // Update status in schoolVerificationRequests
      await FirebaseFirestore.instance.collection('schoolVerificationRequests').doc(requestId).update({
        'status': status,
        'processedAt': Timestamp.now(),
      });

      // Update isVerified in the actual schools collection
      await FirebaseFirestore.instance.collection('schools').doc(schoolId).update({
        'isVerified': status == 'approved', // Set to true if approved, false otherwise
      });

      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text("Permintaan verifikasi berhasil di$status!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text("Gagal memproses permintaan verifikasi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}