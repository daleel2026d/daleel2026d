import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/university_model.dart';
import '../../widgets/custom_cached_image.dart';
import '../../main.dart';
import 'admin_university_edit_screen.dart';

class AdminUniversitiesScreen extends StatefulWidget {
  const AdminUniversitiesScreen({super.key});

  @override
  State<AdminUniversitiesScreen> createState() =>
      _AdminUniversitiesScreenState();
}

class _AdminUniversitiesScreenState extends State<AdminUniversitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'إدارة الجامعات والكليات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surfaceHeader(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة جامعة جديدة',
            onPressed: () => _openUniversityDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUniversityDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة جامعة جديدة'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم الجامعة أو المدينة...',
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
            child: StreamBuilder<List<University>>(
              stream: _firestoreService.getAllUniversities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryDark),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                final unis = (snapshot.data ?? []).where((u) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return u.name.toLowerCase().contains(q) ||
                      u.city.toLowerCase().contains(q);
                }).toList();

                if (unis.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد جامعات مضافة',
                      style: TextStyle(color: AppColors.textMuted(context)),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: unis.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final uni = unis[index];
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
                          child: uni.logoUrl.isNotEmpty
                              ? CustomCachedImage(
                                  imageUrl: uni.logoUrl,
                                  width: 46,
                                  height: 46,
                                  borderRadius: BorderRadius.circular(23),
                                )
                              : const Icon(Icons.account_balance, size: 24),
                        ),
                        title: Text(
                          uni.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${uni.city} • ${uni.type} • ${uni.colleges.length} كليات',
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
                                  _openUniversityDialog(university: uni),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () => _confirmDelete(uni),
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

  void _openUniversityDialog({University? university}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUniversityEditScreen(university: university),
      ),
    );
  }

  void _confirmDelete(University university) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard(context),
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف جامعة "${university.name}"؟'),
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
                await _firestoreService.deleteUniversity(university.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الجامعة بنجاح'),
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
