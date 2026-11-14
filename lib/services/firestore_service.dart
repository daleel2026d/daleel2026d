import '../models/university_model.dart';
import '../models/scholarship_model.dart';
import '../models/college_with_university.dart';
import '../models/opportunity_model.dart';
import '../models/training_center_model.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

/// غلاف خفيف ومتوافق لبيانات المستخدم القادمة من Supabase
class UserDocSnapshot {
  final String id;
  final Map<String, dynamic>? _data;

  const UserDocSnapshot({
    required this.id,
    Map<String, dynamic>? data,
  }) : _data = data;

  bool get exists => _data != null && _data.isNotEmpty;

  Map<String, dynamic>? data() => _data;
}

class FirestoreService {
  // ذاكرة تخزين مؤقت سريعة جداً لمنع تكرار جلب البيانات عند التنقل
  static List<University>? _cachedUniversities;

  List<University>? get cachedUniversities =>
      SupabaseService.cachedUniversities ?? _cachedUniversities;
  List<Scholarship>? get cachedScholarships =>
      SupabaseService.cachedScholarships;
  List<Opportunity>? get cachedOpportunities =>
      SupabaseService.cachedOpportunities;
  List<TrainingCenter>? get cachedTrainingCenters =>
      SupabaseService.cachedTrainingCenters;

  // ===== الجامعات =====

  Stream<List<University>> getAllUniversities() {
    return SupabaseService().streamUniversities();
  }

  Future<List<University>> fetchUniversitiesOnce() async {
    final supaList = await SupabaseService().getUniversities();
    if (supaList.isNotEmpty) {
      _cachedUniversities = supaList;
      return supaList;
    }
    return _cachedUniversities ?? <University>[];
  }

  Stream<University?> getUniversityById(String id) {
    return SupabaseService().streamUniversityById(id);
  }

  // ===== الفلترة الجديدة: كليات مطابقة =====

  static String _normalizeArabic(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  static bool _matchesTrack(String collegeCategory, String selectedTrack) {
    final normCol = _normalizeArabic(collegeCategory);
    final normTrack = _normalizeArabic(selectedTrack);

    if (normCol.isEmpty) return true;

    if (normCol.contains('مشترك') ||
        normCol.contains('عام') ||
        normCol.contains('كاف') ||
        normCol.contains('الكل')) {
      return true;
    }

    if (normTrack.contains('علم')) {
      return normCol.contains('علم') ||
          normCol.contains('احيائ') ||
          normCol.contains('تطبيق');
    } else if (normTrack.contains('ادب')) {
      return normCol.contains('ادب');
    }

    return normCol.contains(normTrack);
  }

  static bool _matchesCity(String uniCity, String selectedCity) {
    if (selectedCity.isEmpty ||
        selectedCity == 'كافة المحافظات' ||
        selectedCity.toLowerCase() == 'all') {
      return true;
    }

    final normUni = _normalizeArabic(uniCity);
    final normCity = _normalizeArabic(selectedCity);

    if (normUni.isEmpty) return true;
    if (normUni.contains(normCity) || normCity.contains(normUni)) return true;

    if ((normCity.contains('نينو') || normCity.contains('موصل')) &&
        (normUni.contains('نينو') || normUni.contains('موصل'))) {
      return true;
    }
    if ((normCity.contains('بابل') || normCity.contains('حل')) &&
        (normUni.contains('بابل') || normUni.contains('حل'))) {
      return true;
    }
    if ((normCity.contains('قار') || normCity.contains('ناصر')) &&
        (normUni.contains('قار') || normUni.contains('ناصر'))) {
      return true;
    }
    if ((normCity.contains('قادس') || normCity.contains('ديوان')) &&
        (normUni.contains('قادس') || normUni.contains('ديوان'))) {
      return true;
    }
    if ((normCity.contains('ميسان') || normCity.contains('عمار')) &&
        (normUni.contains('ميسان') || normUni.contains('عمار'))) {
      return true;
    }
    if ((normCity.contains('مثن') || normCity.contains('سماو')) &&
        (normUni.contains('مثن') || normUni.contains('سماو'))) {
      return true;
    }
    if ((normCity.contains('واسط') || normCity.contains('كوت')) &&
        (normUni.contains('واسط') || normUni.contains('كوت'))) {
      return true;
    }
    if ((normCity.contains('صلاح') || normCity.contains('تكريت')) &&
        (normUni.contains('صلاح') || normUni.contains('تكريت'))) {
      return true;
    }

    return false;
  }

  static bool _matchesUniversityType(String uniType, String selectedType) {
    if (selectedType.isEmpty ||
        selectedType == 'all' ||
        selectedType == 'الكل') {
      return true;
    }

    final normUni = _normalizeArabic(uniType);
    final normSel = _normalizeArabic(selectedType);

    if (normSel.contains('حك') || normSel.contains('gov')) {
      return normUni.contains('حك') || normUni.contains('gov');
    }
    if (normSel.contains('اهل') || normSel.contains('priv')) {
      return normUni.contains('اهل') || normUni.contains('priv');
    }

    return true;
  }

  Future<List<CollegeWithUniversity>> getMatchingColleges(
    String category,
    double studentGpa, {
    String? universityType,
    String? city,
  }) async {
    final allUnis = await fetchUniversitiesOnce();

    final List<CollegeWithUniversity> results = [];
    for (final uni in allUnis) {
      if (universityType != null &&
          !_matchesUniversityType(uni.type, universityType)) {
        continue;
      }
      if (city != null && !_matchesCity(uni.city, city)) {
        continue;
      }

      for (final college in uni.colleges) {
        final matchesBranch = _matchesTrack(college.category, category);
        final qualifiesGpa =
            college.minGpa == 0 || studentGpa >= college.minGpa;

        if (matchesBranch && qualifiesGpa) {
          results.add(CollegeWithUniversity(college: college, university: uni));
        }
      }
    }

    results.sort((a, b) => b.college.minGpa.compareTo(a.college.minGpa));
    return results;
  }

  // ===== المستخدمون والمفضلة والإعجابات (عبر جدول public.users في Supabase) =====

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await SupabaseService().updateUserFields(uid, data);
  }

  Future<void> toggleFavorite(
    String uid,
    String universityId,
    bool isFavorite,
  ) async {
    await SupabaseService().toggleUserArrayItem(
      uid: uid,
      fieldName: 'favorites',
      itemId: universityId,
      isCurrentlySaved: isFavorite,
    );
  }

  Future<void> toggleFavoriteScholarship(
    String uid,
    String scholarshipId,
    bool isSaved,
  ) async {
    await SupabaseService().toggleUserArrayItem(
      uid: uid,
      fieldName: 'savedScholarships',
      itemId: scholarshipId,
      isCurrentlySaved: isSaved,
    );
  }

  Future<void> toggleFavoriteTrainingCenter(
    String uid,
    String centerId,
    bool isSaved,
  ) async {
    await SupabaseService().toggleUserArrayItem(
      uid: uid,
      fieldName: 'savedTrainingCenters',
      itemId: centerId,
      isCurrentlySaved: isSaved,
    );
  }

  Future<void> toggleLikePost(
    String uid,
    String postKey,
    bool isLiked,
  ) async {
    await SupabaseService().toggleUserArrayItem(
      uid: uid,
      fieldName: 'likedPosts',
      itemId: postKey,
      isCurrentlySaved: isLiked,
    );
  }

  Future<void> toggleSavedOpportunity(
    String uid,
    String opportunityId,
    bool isSaved,
  ) async {
    await SupabaseService().toggleUserArrayItem(
      uid: uid,
      fieldName: 'savedOpportunities',
      itemId: opportunityId,
      isCurrentlySaved: isSaved,
    );
  }

  Stream<UserDocSnapshot> getUserData(String uid) {
    return SupabaseService().streamUserDataMap(uid).map(
      (data) => UserDocSnapshot(id: uid, data: data),
    );
  }

  // ===== المنح =====

  Stream<List<Scholarship>> getAllScholarships() {
    return SupabaseService().streamScholarships();
  }

  Future<List<Scholarship>> fetchScholarshipsOnce() async {
    return SupabaseService().getScholarships();
  }

  // ===== الفرص والفعاليات =====

  Stream<List<Opportunity>> getAllOpportunities() {
    return SupabaseService().streamOpportunities();
  }

  Future<List<Opportunity>> fetchOpportunitiesOnce() async {
    return SupabaseService().getOpportunities();
  }

  Stream<List<Opportunity>> getSavedOpportunities(List<String> savedIds) {
    return getAllOpportunities().map((opportunities) {
      return opportunities
          .where((opportunity) => savedIds.contains(opportunity.id))
          .toList();
    });
  }

  Stream<List<Opportunity>> getOpportunitiesByType(String type) {
    return getAllOpportunities().map((opportunities) {
      return opportunities
          .where((opportunity) => opportunity.type == type)
          .toList();
    });
  }

  // ===== مراكز التدريب =====

  Stream<List<TrainingCenter>> getAllTrainingCenters() {
    return SupabaseService().streamTrainingCenters();
  }

  Future<List<TrainingCenter>> fetchTrainingCentersOnce() async {
    return SupabaseService().getTrainingCenters();
  }

  // ===== إدارة لوحة التحكم (CRUD عبر Supabase) =====

  // 1. الجامعات
  Future<void> addUniversity(Map<String, dynamic> data) async {
    _cachedUniversities = null;
    await SupabaseService().addUniversity(data);
  }

  Future<void> updateUniversity(String id, Map<String, dynamic> data) async {
    _cachedUniversities = null;
    await SupabaseService().updateUniversity(id, data);
  }

  Future<void> deleteUniversity(String id) async {
    _cachedUniversities = null;
    await SupabaseService().deleteUniversity(id);
  }

  Stream<List<University>> getUniversitiesManagedBy(String email) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return Stream.value([]);
    return getAllUniversities().map((list) {
      return list
          .where((uni) => uni.managerEmail.trim().toLowerCase() == cleanEmail)
          .toList();
    });
  }

  // 2. المنح الدراسية
  Future<void> addScholarship(Map<String, dynamic> data) async {
    await SupabaseService().addScholarship(data);
  }

  Future<void> updateScholarship(String id, Map<String, dynamic> data) async {
    await SupabaseService().updateScholarship(id, data);
  }

  Future<void> deleteScholarship(String id) async {
    await SupabaseService().deleteScholarship(id);
  }

  // 3. الفرص والفعاليات
  Future<void> addOpportunity(Map<String, dynamic> data) async {
    await SupabaseService().addOpportunity(data);
  }

  Future<void> updateOpportunity(String id, Map<String, dynamic> data) async {
    await SupabaseService().updateOpportunity(id, data);
  }

  Future<void> deleteOpportunity(String id) async {
    await SupabaseService().deleteOpportunity(id);
  }

  // 4. مراكز التدريب
  Future<void> addTrainingCenter(Map<String, dynamic> data) async {
    await SupabaseService().addTrainingCenter(data);
  }

  Future<void> updateTrainingCenter(String id, Map<String, dynamic> data) async {
    await SupabaseService().updateTrainingCenter(id, data);
  }

  Future<void> deleteTrainingCenter(String id) async {
    await SupabaseService().deleteTrainingCenter(id);
  }

  Stream<List<TrainingCenter>> getTrainingCentersManagedBy(String email) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return Stream.value([]);
    return getAllTrainingCenters().map((list) {
      return list
          .where(
            (center) => center.managerEmail.trim().toLowerCase() == cleanEmail,
          )
          .toList();
    });
  }

  // 5. إعدادات مديري مراكز التدريب (الحد الأقصى 10 إيميلات في Supabase)
  Stream<List<String>> getTrainingCenterManagersStream() {
    return SupabaseService().streamTrainingCenterManagers();
  }

  Future<List<String>> fetchTrainingCenterManagersOnce() async {
    return SupabaseService().getTrainingCenterManagers();
  }

  Future<void> saveTrainingCenterManagers(List<String> emails) async {
    await SupabaseService().saveTrainingCenterManagers(emails);
  }

  // ===== نظام الإشعارات (Notifications) =====

  Stream<List<AppNotification>> getUserNotifications(String uid) {
    return SupabaseService().streamUserNotifications(uid);
  }

  Future<void> addNotification(
    String uid,
    AppNotification notification,
  ) async {
    await SupabaseService().addUserNotification(uid, notification);
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    await SupabaseService().markUserNotificationAsRead(uid, notificationId);
  }

  Future<void> markAllNotificationsAsRead(String uid) async {
    await SupabaseService().markAllUserNotificationsAsRead(uid);
  }

  Future<void> deleteNotification(String uid, String notificationId) async {
    await SupabaseService().deleteUserNotification(uid, notificationId);
  }

  Future<void> clearAllNotifications(String uid) async {
    await SupabaseService().clearAllUserNotifications(uid);
  }
}
