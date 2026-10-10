import 'package:flutter/material.dart';
import '../models/college_with_university.dart';
import '../services/app_localizations.dart';
import '../main.dart';
import 'custom_cached_image.dart';

class MatchedCollegeCard extends StatelessWidget {
  final CollegeWithUniversity item;
  final VoidCallback onTap;

  const MatchedCollegeCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final college = item.college;
    final uni = item.university;
    final image = uni.coverImageUrl.isNotEmpty
        ? uni.coverImageUrl
        : uni.logoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. رأس الكارت (Header)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  CustomCachedImage(
                    imageUrl: uni.logoUrl,
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.circular(21),
                    placeholderIcon: Icons.school_rounded,
                    iconSize: 20,
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
                            fontSize: 15,
                            color: AppColors.textMain(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${uni.name} • ${uni.city}',
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // شارة المعدل الأخضر
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.isAr(context) ? 'الحد الأدنى' : 'Min GPA',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${college.minGpa}%',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. الصورة الكبيرة في الوسط (Large Media Photo with Cache)
            Stack(
              children: [
                CustomCachedImage(
                  imageUrl: image,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.account_balance_rounded,
                  iconSize: 44,
                ),

                // شارة الفرع (علمي / أدبي / عام)
                if (college.category.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: AppStrings.isAr(context) ? 10 : null,
                    left: AppStrings.isAr(context) ? null : 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        college.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 3. الوصف والشريط السفلي
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (college.description.isNotEmpty) ...[
                    Text(
                      college.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textMain(context).withValues(alpha: 0.85),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lavenderCard(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Text(
                          uni.type.isNotEmpty ? uni.type : 'جامعة معتمدة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.isAr(context)
                                ? 'عرض التفاصيل'
                                : 'View Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.isDark(context)
                                  ? const Color(0xFF38BDF8)
                                  : AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            AppStrings.isAr(context)
                                ? Icons.arrow_back_ios_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: AppColors.isDark(context)
                                ? const Color(0xFF38BDF8)
                                : AppColors.primaryDark,
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
    );
  }
}
