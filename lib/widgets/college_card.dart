import 'package:flutter/material.dart';
import '../models/college_model.dart';
import '../models/university_model.dart';
import '../services/app_localizations.dart';
import '../main.dart';
import '../screens/tools/student_wishlist_screen.dart';

class CollegeCard extends StatelessWidget {
  final College college;
  final University? university;
  final bool showGpa;

  const CollegeCard({
    super.key,
    required this.college,
    this.university,
    this.showGpa = true,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = AppStrings.isAr(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_rounded,
                color: AppColors.isDark(context)
                    ? const Color(0xFF38BDF8)
                    : AppColors.primaryDark,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      college.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppStrings.major(context)}: ${college.category.isNotEmpty ? college.category : (isAr ? "كافة الفروع" : "All Branches")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (showGpa && college.minGpa > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${AppStrings.schoolAverage(context)} ${college.minGpa}',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (university != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // زر الإضافة للرغبات
                TextButton.icon(
                  icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                  label: Text(
                    isAr ? 'إضافة لرغباتي' : 'Add to Wishlist',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  onPressed: () async {
                    await StudentWishlistService.addChoice(
                      collegeName: college.name,
                      universityName: university!.name,
                      minGpa: college.minGpa,
                      city: university!.city,
                      type: university!.type,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr
                                ? 'تمت إضافة ${college.name} إلى استمارة رغباتك'
                                : 'Added to your wishlist',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
