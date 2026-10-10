import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/opportunity_model.dart';
import '../../widgets/custom_cached_image.dart';
import '../../main.dart';
import 'admin_opportunity_edit_screen.dart';

class AdminOpportunitiesScreen extends StatefulWidget {
  const AdminOpportunitiesScreen({super.key});

  @override
  State<AdminOpportunitiesScreen> createState() =>
      _AdminOpportunitiesScreenState();
}

class _AdminOpportunitiesScreenState extends State<AdminOpportunitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'إدارة الفرص والفعاليات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surfaceHeader(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة فرصة جديدة',
            onPressed: () => _openOpportunityDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openOpportunityDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة فرصة جديدة'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم الفرصة أو الجهة المنظمة...',
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
            child: StreamBuilder<List<Opportunity>>(
              stream: _firestoreService.getAllOpportunities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryDark),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                final opps = (snapshot.data ?? []).where((o) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return o.title.toLowerCase().contains(q) ||
                      o.organizer.toLowerCase().contains(q) ||
                      o.type.toLowerCase().contains(q);
                }).toList();

                if (opps.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد فرص مضافة',
                      style: TextStyle(color: AppColors.textMuted(context)),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: opps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final opp = opps[index];
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
                          child: opp.imageUrl.isNotEmpty
                              ? CustomCachedImage(
                                  imageUrl: opp.imageUrl,
                                  width: 46,
                                  height: 46,
                                  borderRadius: BorderRadius.circular(23),
                                )
                              : const Icon(Icons.event, size: 24),
                        ),
                        title: Text(
                          opp.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${opp.organizer} • ${opp.type} • ${opp.attendance}',
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
                                  _openOpportunityDialog(opportunity: opp),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () => _confirmDelete(opp),
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

  void _openOpportunityDialog({Opportunity? opportunity}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminOpportunityEditScreen(opportunity: opportunity),
      ),
    );
  }

  void _confirmDelete(Opportunity opportunity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard(context),
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف فرصة "${opportunity.title}"؟'),
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
                await _firestoreService.deleteOpportunity(opportunity.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الفرصة بنجاح'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل الحذف: $e')),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
