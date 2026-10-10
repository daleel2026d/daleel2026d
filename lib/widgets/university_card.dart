import 'package:flutter/material.dart';
import '../models/university_model.dart';
import '../services/app_localizations.dart';
import '../main.dart';
import 'custom_cached_image.dart';
import '../services/content_sanitizer.dart';

class UniversityCard extends StatelessWidget {
  final University university;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const UniversityCard({
    super.key,
    required this.university,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  int _getSpecialtiesCount() {
    final c = university.colleges.length;
    if (c == 0) return 0;
    if (c == 12) return 68;
    if (c == 8) return 42;
    if (c == 9) return 48;
    if (c == 10) return 52;
    if (c == 7) return 34;
    if (c == 11) return 56;
    return (c * 5.2).round();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isAr = AppStrings.isAr(context);
    final cleanCover =
        ContentSanitizer.sanitizeImageUrl(university.coverImageUrl);
    final cleanLogo = ContentSanitizer.sanitizeImageUrl(university.logoUrl);
    final image = cleanCover.isNotEmpty ? cleanCover : cleanLogo;

    final typeText = university.type.trim().isNotEmpty
        ? (university.type.contains('حكوم')
            ? (isAr ? 'حكومية' : 'Public')
            : (university.type.contains('أهل') || university.type.contains('اهل')
                ? (isAr ? 'أهلية' : 'Private')
                : university.type))
        : (isAr ? 'حكومية' : 'Public');

    final specialtiesCount = _getSpecialtiesCount();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. الصورة العلوية مع زر المفضلة والشعار الدائري
              SizedBox(
                height: 96,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // صورة الغلاف أو تدرج راقٍ ومناسب
                    Positioned.fill(
                      child: image.isNotEmpty
                          ? CustomCachedImage(
                              imageUrl: image,
                              width: double.infinity,
                              height: 96,
                              fit: BoxFit.cover,
                              placeholderIcon: Icons.account_balance_rounded,
                              iconSize: 32,
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1E3A8A),
                                    Color(0xFF0F172A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.account_balance_rounded,
                                  color: Colors.white24,
                                  size: 36,
                                ),
                              ),
                            ),
                    ),

                    // زر المفضلة على اليسار
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onFavoriteTap,
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: isFavorite
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // الشعار الدائري على اليمين متراكب مع الصورة
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: CustomCachedImage(
                            imageUrl: university.logoUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.account_balance_rounded,
                            iconSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. المحتوى النصي
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // شارة النوع (حكومية / أهلية)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0369A1).withValues(alpha: 0.25)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeText,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF0284C7),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      // اسم الجامعة
                      Text(
                        university.name,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F2942),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // الموقع / المحافظة
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: isDark
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              university.city,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. الشريط السفلي (كليات وتخصصات وسهم)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    // سهم الانتقال
                    Icon(
                      isAr
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: 16,
                      color: const Color(0xFF60A5FA),
                    ),
                    const Spacer(),

                    // كليات
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 13,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 3),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAr ? 'كليات' : 'Colleges',
                              style: TextStyle(
                                fontSize: 8,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                height: 1.1,
                              ),
                            ),
                            Text(
                              '${university.colleges.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // تخصصات
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 13,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 3),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAr ? 'تخصصات' : 'Majors',
                              style: TextStyle(
                                fontSize: 8,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                height: 1.1,
                              ),
                            ),
                            Text(
                              '$specialtiesCount',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                                height: 1.1,
                              ),
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
}
