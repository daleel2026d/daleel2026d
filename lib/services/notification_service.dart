import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../models/university_model.dart';
import '../models/scholarship_model.dart';
import '../services/firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // جلب تدفق إشعارات المستخدم الحالي
  Stream<List<AppNotification>> getNotificationsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }
    return _firestoreService.getUserNotifications(uid);
  }

  // حساب عدد الإشعارات غير المقروءة
  Stream<int> getUnreadCountStream() {
    return getNotificationsStream().map((list) {
      return list.where((n) => !n.isRead).length;
    });
  }

  // فحص وتوليد إشعارات ذكية مبنية على معدل الطالب
  Future<void> checkGpaMatches(double gpa, String track) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || gpa <= 0) return;

    try {
      final matches = await _firestoreService.getMatchingColleges(
        track,
        gpa,
      );

      if (matches.isNotEmpty) {
        final top3 = matches.take(3).map((m) => m.college.name).join('، ');
        final notification = AppNotification(
          id: 'gpa_${gpa.toInt()}_${DateTime.now().day}',
          title: '🎯 كليات تناسب معدلك (${gpa.toStringAsFixed(1)})',
          body:
              'تم العثور على ${matches.length} كلية وقسم تقبل معدلك! منها: $top3. اضغط لاستعراض كافة الخيارات.',
          type: 'gpa_match',
          targetType: 'general',
          targetId: '',
          createdAt: DateTime.now(),
          isRead: false,
        );

        await _firestoreService.addNotification(uid, notification);
      }
    } catch (_) {}
  }

  // فحص وتوليد إشعارات تحديثات الجامعات المفضلة
  Future<void> notifyFavoriteUniversityUpdates(
    List<University> allUniversities,
    List<String> favoriteIds,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || favoriteIds.isEmpty) return;

    try {
      final favUnis =
          allUniversities.where((u) => favoriteIds.contains(u.id)).toList();

      for (var uni in favUnis) {
        if (uni.posts.isNotEmpty) {
          final latestPost = uni.posts.first;
          final notifId = 'fav_uni_${uni.id}_${latestPost.title.hashCode}';

          final notification = AppNotification(
            id: notifId,
            title: '🏛️ تحديث جديد من ${uni.name}',
            body: latestPost.title.isNotEmpty
                ? latestPost.title
                : latestPost.description,
            type: 'favorite_update',
            targetType: 'university',
            targetId: uni.id,
            createdAt: DateTime.now(),
            isRead: false,
          );

          await _firestoreService.addNotification(uid, notification);
        }
      }
    } catch (_) {}
  }

  // فحص وتوليد إشعارات المنح الدراسية الجديدة
  Future<void> notifyNewScholarships(List<Scholarship> scholarships) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || scholarships.isEmpty) return;

    try {
      for (var sch in scholarships.take(2)) {
        final notifId = 'sch_${sch.id}';
        final notification = AppNotification(
          id: notifId,
          title: '🎓 منحة دراسية متاحة: ${sch.name}',
          body:
              'الدولة: ${sch.country} • التمويل: ${sch.fundingType}. التقديم متاح الآن!',
          type: 'new_scholarship',
          targetType: 'scholarship',
          targetId: sch.id,
          createdAt: DateTime.now(),
          isRead: false,
        );

        await _firestoreService.addNotification(uid, notification);
      }
    } catch (_) {}
  }

  // تمييز إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.markNotificationAsRead(uid, notificationId);
  }

  // تمييز كل الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.markAllNotificationsAsRead(uid);
  }

  // حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.deleteNotification(uid, notificationId);
  }

  // مسح جميع الإشعارات
  Future<void> clearAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.clearAllNotifications(uid);
  }
}
