import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/scholarship_model.dart';
import '../../widgets/custom_cached_image.dart';
import '../../main.dart';
import 'admin_scholarship_edit_screen.dart';

class AdminScholarshipsScreen extends StatefulWidget {
  const AdminScholarshipsScreen({super.key});

  @override
  State<AdminScholarshipsScreen> createState() =>
      _AdminScholarshipsScreenState();
}

class _AdminScholarshipsScreenState extends State<AdminScholarshipsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'إدارة المنح الدراسية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surfaceHeader(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة منحة جديدة',
            onPressed: () => _openScholarshipDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScholarshipDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة منحة جديدة'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم المنحة أو الدولة...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceCard(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Scholarship>>(
              stream: _firestoreService.getAllScholarships(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryDark),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                final scholarships = (snapshot.data ?? []).where((s) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return s.name.toLowerCase().contains(q) ||
                      s.country.toLowerCase().contains(q);
                }).toList();

                if (scholarships.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد منح دراسية مضافة',
                      style: TextStyle(color: AppColors.textMuted(context)),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: scholarships.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sch = scholarships[index];
                    return Card(
                      color: AppColors.surfaceCard(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppColors.border(context)),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lavenderCard(context),
                          ),
                          child: sch.imageUrl.isNotEmpty
                              ? CustomCachedImage(
                                  imageUrl: sch.imageUrl,
                                  width: 46,
                                  height: 46,
                                  borderRadius: BorderRadius.circular(23),
                                )
                              : const Icon(Icons.school, size: 24),
                        ),
                        title: Text(
                          sch.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${sch.country} • ${sch.fundingType} • انتهاء التقديم: ${sch.deadline}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.blueAccent, size: 20),
                              onPressed: () =>
                                  _openScholarshipDialog(scholarship: sch),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () => _confirmDelete(sch),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openScholarshipDialog({Scholarship? scholarship}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminScholarshipEditScreen(scholarship: scholarship),
      ),
    );
  }

  void _confirmDelete(Scholarship scholarship) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard(context),
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف منحة "${scholarship.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await _firestoreService.deleteScholarship(scholarship.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف المنحة بنجاح'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('فشل الحذف: $e')),
                );
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
