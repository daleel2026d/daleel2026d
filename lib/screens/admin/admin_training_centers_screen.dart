import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/training_center_model.dart';
import '../../widgets/custom_cached_image.dart';
import '../../main.dart';
import 'admin_training_center_edit_screen.dart';

class AdminTrainingCentersScreen extends StatefulWidget {
  const AdminTrainingCentersScreen({super.key});

  @override
  State<AdminTrainingCentersScreen> createState() =>
      _AdminTrainingCentersScreenState();
}

class _AdminTrainingCentersScreenState
    extends State<AdminTrainingCentersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'إدارة مراكز التدريب',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surfaceHeader(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'إضافة مركز تدريب',
            onPressed: () => _openCenterDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCenterDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة مركز جديد'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم المركز أو المدينة...',
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
            child: StreamBuilder<List<TrainingCenter>>(
              stream: _firestoreService.getAllTrainingCenters(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryDark),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                final centers = (snapshot.data ?? []).where((c) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return c.name.toLowerCase().contains(q) ||
                      c.location.toLowerCase().contains(q) ||
                      c.specialties.any((s) => s.toLowerCase().contains(q));
                }).toList();

                if (centers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_center_outlined,
                          size: 64,
                          color: AppColors.textMuted(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد مراكز تدريب مضافة حالياً',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openCenterDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة أول مركز الآن'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: centers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final center = centers[index];
                    return Card(
                      color: AppColors.surfaceCard(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppColors.border(context)),
                      ),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.lavenderCard(context),
                              ),
                              child: center.imageUrl.isNotEmpty
                                  ? CustomCachedImage(
                                      imageUrl: center.imageUrl,
                                      width: 50,
                                      height: 50,
                                      borderRadius: BorderRadius.circular(25),
                                    )
                                  : const Icon(Icons.business, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    center.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (center.location.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          center.location,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (center.phone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'هاتف: ${center.phone}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textMuted(context),
                                      ),
                                    ),
                                  ],
                                  if (center.specialties.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: center.specialties
                                          .take(3)
                                          .map((s) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.lavenderCard(context),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  s,
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blueAccent, size: 20),
                                  onPressed: () =>
                                      _openCenterDialog(center: center),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () => _confirmDelete(center),
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
          ),
        ],
      ),
    );
  }

  void _openCenterDialog({TrainingCenter? center}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminTrainingCenterEditScreen(center: center),
      ),
    );
  }

  void _confirmDelete(TrainingCenter center) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard(context),
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف مركز التدريب "${center.name}"؟'),
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
                await _firestoreService.deleteTrainingCenter(center.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف مركز التدريب بنجاح'),
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
