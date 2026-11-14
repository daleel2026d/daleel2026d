import 'package:flutter/material.dart';
import '../main.dart';
import '../services/app_localizations.dart';
import '../screens/tools/admission_chance_screen.dart';
import '../screens/tools/admission_checklist_screen.dart';
import '../screens/tools/tuition_calculator_screen.dart';
import '../screens/tools/student_wishlist_screen.dart';

class StudentToolsSection extends StatelessWidget {
  final double? currentAverage;
  final String? currentTrack;

  const StudentToolsSection({
    super.key,
    this.currentAverage,
    this.currentTrack,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = AppStrings.isAr(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 700;

    final List<_ToolItem> tools = [
      _ToolItem(
        title: AppStrings.toolAdmissionCalculator(context),
        subtitle: AppStrings.toolAdmissionCalculatorDesc(context),
        icon: Icons.calculate_rounded,
        color: const Color(0xFF0284C7),
        badgeText: isAr ? 'ذكي ومباشر' : 'Smart',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdmissionChanceScreen(
                initialGpa: currentAverage,
                initialTrack: currentTrack,
              ),
            ),
          );
        },
      ),
      _ToolItem(
        title: AppStrings.toolChecklist(context),
        subtitle: AppStrings.toolChecklistDesc(context),
        icon: Icons.checklist_rtl_rounded,
        color: const Color(0xFF10B981),
        badgeText: isAr ? 'أوفلاين' : 'Offline',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdmissionChecklistScreen(),
            ),
          );
        },
      ),
      _ToolItem(
        title: AppStrings.toolTuition(context),
        subtitle: AppStrings.toolTuitionDesc(context),
        icon: Icons.payments_rounded,
        color: const Color(0xFFF59E0B),
        badgeText: isAr ? 'تخفيضات' : 'Discounts',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TuitionCalculatorScreen(),
            ),
          );
        },
      ),
      _ToolItem(
        title: AppStrings.toolWishlist(context),
        subtitle: AppStrings.toolWishlistDesc(context),
        icon: Icons.playlist_add_check_circle_rounded,
        color: const Color(0xFFEC4899),
        badgeText: isAr ? 'رغباتي' : 'Wishlist',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StudentWishlistScreen(),
            ),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم مع أيقونة بارزة
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.studentToolsTitle(context),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    Text(
                      isAr
                          ? 'أدوات تفاعلية ذكية للقبول والتخطيط الجامعي'
                          : 'Interactive native tools for admission & planning',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // عرض الأدوات: شبكة على الآيباد والشاشات العريضة، وشريط أفقي متجاوب على الهواتف
        if (isTablet)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: tools.length,
              itemBuilder: (ctx, i) => _buildTabletToolCard(context, tools[i]),
            ),
          )
        else
          SizedBox(
            height: 148,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: tools.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) => _buildMobileToolCard(context, tools[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileToolCard(BuildContext context, _ToolItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted(context),
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletToolCard(BuildContext context, _ToolItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.badgeText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String badgeText;
  final VoidCallback onTap;

  _ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.badgeText,
    required this.onTap,
  });
}
