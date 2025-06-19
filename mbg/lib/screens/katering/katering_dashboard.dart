import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../guru/chatbot_page.dart';

class KateringDashboard extends StatefulWidget {
  const KateringDashboard({super.key});

  @override
  State<KateringDashboard> createState() => _KateringDashboardState();
}

class _KateringDashboardState extends State<KateringDashboard> {
  bool qualityChecked = false;
  bool isReady = false;
  final commentController = TextEditingController();
  final portionsController = TextEditingController();
  final carbController = TextEditingController();
  final proteinController = TextEditingController();
  final veggieController = TextEditingController();
  final fruitController = TextEditingController();
  final milkController = TextEditingController();

  Map<String, dynamic>? dailyMenu;
  String? dailyMenuDocId;

  @override
  void initState() {
    super.initState();
    _fetchDailyMenu();
  }

  Future<void> _fetchDailyMenu() async {
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(now);
    final currentContext = context;

    try {
      QuerySnapshot menuSnapshot =
          await FirebaseFirestore.instance
              .collection('foodMenus')
              .where('date', isEqualTo: todayFormatted)
              .limit(1)
              .get();

      if (!currentContext.mounted) return;

      if (menuSnapshot.docs.isNotEmpty) {
        setState(() {
          dailyMenu = menuSnapshot.docs.first.data() as Map<String, dynamic>;
          dailyMenuDocId = menuSnapshot.docs.first.id;
          qualityChecked = dailyMenu?['qualityChecked'] ?? false;
          isReady = dailyMenu?['isReadyForDistribution'] ?? false;
          commentController.text = dailyMenu?['cateringComment'] ?? '';

          portionsController.text = dailyMenu?['portions']?.toString() ?? '';
          carbController.text = dailyMenu?['carbohydrate'] ?? '';
          proteinController.text = dailyMenu?['protein'] ?? '';
          veggieController.text = dailyMenu?['vegetable'] ?? '';
          fruitController.text = dailyMenu?['fruit'] ?? '';
          milkController.text = dailyMenu?['milk'] ?? '';
        });
      } else {
        setState(() {
          dailyMenu = null;
          dailyMenuDocId = null;
          qualityChecked = false;
          isReady = false;
          commentController.clear();
          portionsController.clear();
          carbController.clear();
          proteinController.clear();
          veggieController.clear();
          fruitController.clear();
          milkController.clear();
        });
      }
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat menu harian: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveOrUpdateDailyMenu() async {
    final currentContext = context;
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(now);

    if (portionsController.text.isEmpty ||
        carbController.text.isEmpty ||
        proteinController.text.isEmpty ||
        veggieController.text.isEmpty ||
        fruitController.text.isEmpty ||
        milkController.text.isEmpty) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text("Harap isi semua detail menu!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> menuData = {
        'date': todayFormatted,
        'portions': int.tryParse(portionsController.text.trim()) ?? 0,
        'carbohydrate': carbController.text.trim(),
        'protein': proteinController.text.trim(),
        'vegetable': veggieController.text.trim(),
        'fruit': fruitController.text.trim(),
        'milk': milkController.text.trim(),
        'qualityChecked': qualityChecked,
        'cateringComment': commentController.text.trim(),
        'isReadyForDistribution': isReady,
        'lastUpdatedByCatering': Timestamp.now(),
      };

      if (dailyMenuDocId != null) {
        await FirebaseFirestore.instance
            .collection('foodMenus')
            .doc(dailyMenuDocId)
            .update(menuData);
      } else {
        DocumentReference newDocRef = await FirebaseFirestore.instance
            .collection('foodMenus')
            .add(menuData);
        setState(() {
          dailyMenuDocId = newDocRef.id;
        });
      }

      if (!currentContext.mounted) return;

      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text("Menu berhasil disimpan/diperbarui!"),
          backgroundColor: Colors.green,
        ),
      );
      _fetchDailyMenu();
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan menu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markReadyForDistribution() async {
    final currentContext = context;
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(now);

    if (dailyMenuDocId == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text(
              "Harap input menu terlebih dahulu sebelum menandai siap.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (!qualityChecked || commentController.text.trim().isEmpty) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text("Harap lakukan Quality Check dan berikan komentar."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('foodMenus')
          .doc(dailyMenuDocId)
          .update({
            'isReadyForDistribution': true,
            'lastUpdatedByCatering': Timestamp.now(),
          });
      if (!currentContext.mounted) return;
      setState(() {
        isReady = true;
      });

      QuerySnapshot existingDist =
          await FirebaseFirestore.instance
              .collection('foodDistributions')
              .where('date', isEqualTo: todayFormatted)
              .limit(1)
              .get();

      if (!currentContext.mounted) return;

      if (existingDist.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('foodDistributions').add({
          'menuId': dailyMenuDocId,
          'date': todayFormatted,
          'totalPorsi': dailyMenu?['portions'],
          'deliveryStatus': 'Pending',
          'preparedByCatering': true,
          'createdAt': Timestamp.now(),
          'kelasVerified': '',
          'jumlahHadirVerified': 0,
          'issueReport': '',
        });
      } else {
        await FirebaseFirestore.instance
            .collection('foodDistributions')
            .doc(existingDist.docs.first.id)
            .update({
              'deliveryStatus': 'Pending',
              'preparedByCatering': true,
              'lastUpdatedByCatering': Timestamp.now(),
            });
      }

      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text("Makanan ditandai siap untuk didistribusikan!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Gagal menandai siap distribusi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateFormat("EEEE, d MMMM yyyy", 'id_ID').format(DateTime.now());

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      now,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatbotPage()),
                        );
                      },
                      child: Stack(
                        children: [
                          const Icon(Icons.smart_toy, size: 28),
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text('!', style: TextStyle(fontSize: 10, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.notifications_none, size: 28),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),

            if (dailyMenu == null)
              _buildInputMenuForm()
            else
              _buildDisplayMenuDetails(),

            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: qualityChecked,
                  onChanged: (val) {
                    setState(() {
                      qualityChecked = val ?? false;
                      if (!qualityChecked) {
                        isReady = false;
                      }
                    });
                    if (dailyMenuDocId != null) {
                      _saveOrUpdateDailyMenu();
                    }
                  },
                ),
                const Text("Quality Check"),
              ],
            ),

            const SizedBox(height: 8),
            const Text(
              "Komentar terkait makanan",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                controller: commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Masukkan pengamatan anda di sini ...",
                  border: InputBorder.none,
                ),
                onChanged: (_) {
                  setState(() {});
                  if (dailyMenuDocId != null) {
                    _saveOrUpdateDailyMenu();
                  }
                },
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isReady ? "Siap dibagikan" : "Proses Pengecekan",
                  style: TextStyle(
                    color: isReady ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      dailyMenu != null &&
                              qualityChecked &&
                              commentController.text.trim().isNotEmpty
                          ? _markReadyForDistribution
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isReady ? Colors.green : const Color(0xFF2962FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(isReady ? "Telah Siap" : "Tandai Siap"),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 150,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                  child: const Text(
                    "Kembali",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputMenuForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Input Menu Harian",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInputField(
          "Jumlah Porsi",
          portionsController,
          keyboardType: TextInputType.number,
        ),
        _buildInputField("Karbohidrat", carbController),
        _buildInputField("Protein", proteinController),
        _buildInputField("Sayur", veggieController),
        _buildInputField("Buah", fruitController),
        _buildInputField("Susu", milkController),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saveOrUpdateDailyMenu,
          child: const Text("Simpan Menu"),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDisplayMenuDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detail Menu Hari Ini",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${dailyMenu?['portions'] ?? 'N/A'} porsi",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Karbohidrat  : ${dailyMenu?['carbohydrate'] ?? 'N/A'}"),
              Text("Protein      : ${dailyMenu?['protein'] ?? 'N/A'}"),
              Text("Sayur        : ${dailyMenu?['vegetable'] ?? 'N/A'}"),
              Text("Buah         : ${dailyMenu?['fruit'] ?? 'N/A'}"),
              Text("Susu         : ${dailyMenu?['milk'] ?? 'N/A'}"),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed:
              _saveOrUpdateDailyMenu,
          child: const Text("Update Menu"),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: "Masukkan",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
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
}