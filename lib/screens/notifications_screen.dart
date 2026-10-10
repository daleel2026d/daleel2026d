import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../main.dart';
import 'university_details_screen.dart';
import 'scholarship_details_screen.dart';
import 'opportunity_details_screen.dart';
import 'training_center_details_screen.dart';
import 'universities_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedFilter = 'all'; // all, gpa, favorites, scholarships

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'gpa_match':
        return Icons.ads_click_rounded;
      case 'favorite_update':
        return Icons.favorite_rounded;
      case 'new_scholarship':
        return Icons.school_rounded;
      case 'new_post':
        return Icons.article_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'gpa_match':
        return const Color(0xFF0284C7);
      case 'favorite_update':
        return const Color(0xFFE11D48);
      case 'new_scholarship':
        return const Color(0xFFEA580C);
      case 'new_post':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF10B981);
    }
  }

  Future<void> _handleNotificationTap(AppNotification notif) async {
    // تمييز الإشعار كمقروء
    await _notificationService.markAsRead(notif.id);

    if (!mounted) return;

    if (notif.targetType == 'university' && notif.targetId.isNotEmpty) {
      final unis = await _firestoreService.fetchUniversitiesOnce();
      final match = unis.where((u) => u.id == notif.targetId).firstOrNull;
      if (match != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UniversityDetailsScreen(university: match),
          ),
        );
        return;
      }
    } else if (notif.targetType == 'scholarship' &&
        notif.targetId.isNotEmpty) {
      final scholarships = await _firestoreService.fetchScholarshipsOnce();
      final match =
          scholarships.where((s) => s.id == notif.targetId).firstOrNull;
      if (match != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScholarshipDetailsScreen(scholarship: match),
          ),
        );
        return;
      }
    } else if (notif.targetType == 'opportunity' &&
        notif.targetId.isNotEmpty) {
      final opps = await _firestoreService.fetchOpportunitiesOnce();
      final match = opps.where((o) => o.id == notif.targetId).firstOrNull;
      if (match != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OpportunityDetailsScreen(opportunity: match),
          ),
        );
        return;
      }
    } else if (notif.targetType == 'training_center' &&
        notif.targetId.isNotEmpty) {
      final centers = await _firestoreService.fetchTrainingCentersOnce();
      final match = centers.where((c) => c.id == notif.targetId).firstOrNull;
      if (match != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrainingCenterDetailsScreen(center: match),
          ),
        );
        return;
      }
    } else if (notif.type == 'gpa_match') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const UniversitiesScreen(),
        ),
      );
    }
  }

  String _formatDate(DateTime dt, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final isAr = AppStrings.isAr(context);

    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      if (mins <= 1) return isAr ? 'الآن' : 'Just now';
      return isAr ? 'منذ $mins دقيقة' : '$mins mins ago';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return isAr ? 'منذ $hours ساعة' : '$hours hrs ago';
    } else if (diff.inDays < 7) {
      final days = diff.inDays;
      return isAr ? 'منذ $days أيام' : '$days days ago';
    } else {
      return '${dt.year}/${dt.month}/${dt.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppStrings.isAr(context);

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'مركز الإشعارات' : 'Notifications',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: (value) async {
                if (value == 'read_all') {
                  await _notificationService.markAllAsRead();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAr
                              ? 'تم تعيين جميع الإشعارات كمقروءة'
                              : 'All marked as read',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.isDark(context)
                            ? const Color(0xFF1E293B)
                            : AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } else if (value == 'clear_all') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surfaceCard(context),
                      title: Text(
                        isAr ? 'مسح كل الإشعارات' : 'Clear all notifications',
                        style: TextStyle(
                          color: AppColors.textMain(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        isAr
                            ? 'هل أنت متأكد من مسح جميع الإشعارات؟'
                            : 'Are you sure you want to clear all notifications?',
                        style: TextStyle(color: AppColors.textMuted(context)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            isAr ? 'إلغاء' : 'Cancel',
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            isAr ? 'مسح' : 'Clear',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _notificationService.clearAll();
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.done_all_rounded,
                        size: 18,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAr
                            ? 'تعيين الكل كمقروء'
                            : 'Mark all as read',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_sweep_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? 'مسح جميع الإشعارات' : 'Clear all',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // أزرار الفلترة العلوية (Filter Tabs)
            Container(
              color: AppColors.surfaceCard(context),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(
                      id: 'all',
                      label: isAr ? 'الكل' : 'All',
                      icon: Icons.notifications_none_rounded,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      id: 'gpa',
                      label: isAr ? 'تناسب معدلي 🎯' : 'GPA Matches 🎯',
                      icon: Icons.ads_click_rounded,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      id: 'favorites',
                      label: isAr ? 'مفضلاتي 💖' : 'Favorites 💖',
                      icon: Icons.favorite_border_rounded,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      id: 'scholarships',
                      label: isAr ? 'المنح والإعلانات 🎓' : 'Scholarships 🎓',
                      icon: Icons.school_outlined,
                    ),
                  ],
                ),
              ),
            ),

            // قائمة الإشعارات
            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream: _notificationService.getNotificationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDark,
                      ),
                    );
                  }

                  final allNotifs = snapshot.data ?? [];

                  // تصفية الإشعارات حسب التبويب
                  final filteredNotifs = allNotifs.where((n) {
                    if (_selectedFilter == 'gpa') {
                      return n.type == 'gpa_match';
                    } else if (_selectedFilter == 'favorites') {
                      return n.type == 'favorite_update';
                    } else if (_selectedFilter == 'scholarships') {
                      return n.type == 'new_scholarship' ||
                          n.type == 'new_post';
                    }
                    return true;
                  }).toList();

                  if (filteredNotifs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard(context),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppColors.border(context)),
                            ),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAr
                                ? 'لا توجد إشعارات في هذا القسم'
                                : 'No notifications in this category',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAr
                                ? 'ستصلك تنبيهات فورية عند وجود كليات تناسب معدلك أو تحديثات جديدة'
                                : 'You will receive instant alerts for matching GPA and favorite updates',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = filteredNotifs[index];
                      final iconColor = _getNotificationColor(notif.type);
                      final iconData = _getNotificationIcon(notif.type);

                      return Dismissible(
                        key: Key(notif.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          _notificationService.deleteNotification(notif.id);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: notif.isRead
                                ? AppColors.surfaceCard(context)
                                : (AppColors.isDark(context)
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF0F9FF)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: notif.isRead
                                  ? AppColors.border(context)
                                  : const Color(0xFF38BDF8).withValues(alpha: 0.5),
                              width: notif.isRead ? 1 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _handleNotificationTap(notif),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // أيقونة الإشعار الملونة
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: iconColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        iconData,
                                        color: iconColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // محتوى الإشعار
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: TextStyle(
                                                    fontWeight: notif.isRead
                                                        ? FontWeight.bold
                                                        : FontWeight.w800,
                                                    fontSize: 14,
                                                    color: AppColors.textMain(
                                                        context),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!notif.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFF0284C7),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.body,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              height: 1.4,
                                              color: AppColors.textMuted(
                                                  context),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDate(
                                                    notif.createdAt, context),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted(
                                                          context)
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                              Icon(
                                                isAr
                                                    ? Icons.arrow_back_ios_rounded
                                                    : Icons.arrow_forward_ios_rounded,
                                                size: 11,
                                                color: iconColor,
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
      ),
    );
  }

  Widget _filterChip({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == id;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = id),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryDark
              : AppColors.lavenderCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDark
                : AppColors.border(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textMain(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textMain(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
