import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/training_center_model.dart';
import '../widgets/custom_cached_image.dart';
import '../main.dart';
import '../services/app_localizations.dart';
import 'training_center_details_screen.dart';

class TrainingCentersScreen extends StatefulWidget {
  const TrainingCentersScreen({super.key});

  @override
  State<TrainingCentersScreen> createState() => _TrainingCentersScreenState();
}

class _TrainingCentersScreenState extends State<TrainingCentersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Text(
            AppStrings.isAr(context)
                ? 'مراكز التدريب والمعاهد'
                : 'Training Centers & Institutes',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              AppStrings.isAr(context)
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // شريط البحث
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.isAr(context)
                      ? 'ابحث عن اسم المركز، الدورة، أو المدينة...'
                      : 'Search center, course, or city...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surfaceCard(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),

            // قائمة مراكز التدريب
            Expanded(
              child: StreamBuilder<List<TrainingCenter>>(
                stream: _firestoreService.getAllTrainingCenters(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C3AED),
                      ),
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
                        c.specialties.any((s) => s.toLowerCase().contains(q)) ||
                        c.colleges.any((col) => col.name.toLowerCase().contains(q));
                  }).toList();

                  if (centers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            size: 64,
                            color: AppColors.textMuted(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.isAr(context)
                                ? 'لا توجد مراكز تدريب مضافة حالياً'
                                : 'No training centers currently available',
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: centers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final center = centers[index];
                      return _buildTrainingCenterCard(context, center);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingCenterCard(BuildContext context, TrainingCenter center) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrainingCenterDetailsScreen(center: center),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة الغلاف أو البانر إن وجدت
              if (center.coverImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CustomCachedImage(
                    imageUrl: center.coverImageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.apartment_rounded,
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الرأس: الشعار + الاسم + المحافظة
                    Row(
                      children: [
                        CustomCachedImage(
                          imageUrl: center.imageUrl,
                          width: 48,
                          height: 48,
                          borderRadius: BorderRadius.circular(24),
                          placeholderIcon: Icons.apartment_rounded,
                          iconSize: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                center.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.5,
                                  color: AppColors.textMain(context),
                                ),
                              ),
                              if (center.location.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: Color(0xFF7C3AED),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      center.location,
                                      style: TextStyle(
                                        color: AppColors.textMuted(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // شارة المركز
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'مركز تدريب',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // النبذة
                    if (center.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        center.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textMuted(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // إحصائيات سريعة (الدورات + المنشورات)
                    Row(
                      children: [
                        _buildStatBadge(
                          icon: Icons.school_rounded,
                          text: '${center.colleges.length} دورات وأقسام',
                          color: const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 8),
                        _buildStatBadge(
                          icon: Icons.newspaper_rounded,
                          text: '${center.posts.length} منشورات',
                          color: const Color(0xFFEA580C),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              AppStrings.isAr(context)
                                  ? 'عرض التفاصيل'
                                  : 'View Details',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              AppStrings.isAr(context)
                                  ? Icons.arrow_back_ios_new_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: const Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
