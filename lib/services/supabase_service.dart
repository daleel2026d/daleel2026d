import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/university_model.dart';
import '../models/scholarship_model.dart';
import '../models/opportunity_model.dart';
import '../models/training_center_model.dart';
import '../models/notification_model.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://fzcnivrukmrkokitaupz.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6Y25pdnJ1a21ya29raXRhdXB6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwOTIxNDMsImV4cCI6MjEwODY2ODE0M30.O9eEFd4TWRVsCYWrjBvCkWfc0R6JxP_tePsH_VIipnU';

  static bool get isConfigured =>
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'ضع_مفتاح_anon_هنا' &&
      !supabaseAnonKey.contains('ضع_');

  static SupabaseClient get client => Supabase.instance.client;

  // مفاتيح التخزين المحلي الدائم (Disk Cache) لفتح التطبيق بسرعة فائقة (0ms)
  static const String _kCacheUniversities = 'supa_cache_universities_v1';
  static const String _kCacheScholarships = 'supa_cache_scholarships_v1';
  static const String _kCacheOpportunities = 'supa_cache_opportunities_v1';
  static const String _kCacheTrainingCenters = 'supa_cache_training_centers_v1';
  static const String _kCacheTcManagers = 'supa_cache_tc_managers_v1';
  static const String _kCacheCurrentUserSession =
      'supa_current_user_session_v1';
  static const String _kCacheUserDataPrefix = 'supa_cache_user_data_v1_';
  static const String _kCacheSavedScholarshipsPrefix =
      'supa_cache_saved_scholarships_v1_';
  static const String _kCacheNotificationsPrefix =
      'supa_cache_notifications_v1_';

  // الأعمدة المعتمدة في جدول public.users في Supabase
  static const Set<String> _allowedUserColumns = {
    'id',
    'created_at',
    'favorites',
    'academicYear',
    'role',
    'name',
    'email',
    'average',
    'track',
    'city',
    'savedOpportunities',
    'likedPosts',
    'savedTrainingCenters',
  };

  // Broadcast controllers for instant reactive UI updates on CRUD changes or background sync
  static final StreamController<List<University>> _universitiesController =
      StreamController<List<University>>.broadcast();
  static List<University>? _cachedUniversities;
  static String? _lastUniversitiesJson;
  static bool _isSyncingUniversities = false;

  static final StreamController<List<Scholarship>> _scholarshipsController =
      StreamController<List<Scholarship>>.broadcast();
  static List<Scholarship>? _cachedScholarships;
  static String? _lastScholarshipsJson;
  static bool _isSyncingScholarships = false;

  static final StreamController<List<Opportunity>> _opportunitiesController =
      StreamController<List<Opportunity>>.broadcast();
  static List<Opportunity>? _cachedOpportunities;
  static String? _lastOpportunitiesJson;
  static bool _isSyncingOpportunities = false;

  static final StreamController<List<TrainingCenter>>
      _trainingCentersController =
      StreamController<List<TrainingCenter>>.broadcast();
  static List<TrainingCenter>? _cachedTrainingCenters;
  static String? _lastTrainingCentersJson;
  static bool _isSyncingTrainingCenters = false;

  // كاش مديري مراكز التدريب
  static final StreamController<List<String>> _tcManagersController =
      StreamController<List<String>>.broadcast();
  static List<String>? _cachedTcManagers;

  // كاش جلسة المستخدم الحالي وبياناته في الذاكرة (RAM + Disk)
  static Map<String, String?>? _cachedUserSession;
  static final Map<String, Map<String, dynamic>> _cachedUserDataByUid = {};
  static final Map<String, List<String>> _cachedSavedScholarshipsByUid = {};
  static final Map<String, StreamController<Map<String, dynamic>?>>
      _userControllers = {};
  static final Map<String, List<AppNotification>> _cachedNotificationsByUid =
      {};
  static final Map<String, StreamController<List<AppNotification>>>
      _notificationControllers = {};

  // الوصول الفوري المتزامن للبيانات المخزنة في الذاكرة
  static List<University>? get cachedUniversities => _cachedUniversities;
  static List<Scholarship>? get cachedScholarships => _cachedScholarships;
  static List<Opportunity>? get cachedOpportunities => _cachedOpportunities;
  static List<TrainingCenter>? get cachedTrainingCenters =>
      _cachedTrainingCenters;
  static Map<String, String?>? get cachedUserSession => _cachedUserSession;
  static Map<String, dynamic>? getCachedUserData(String uid) =>
      _cachedUserDataByUid[uid];

  /// توليد معرف فريد من 20 حرفاً
  static String generateId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(20, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// تنظيف الخريطة من أي قيم غير قابلة للتحويل إلى JSON في Supabase
  static Map<String, dynamic> _sanitizeDataForSupabase(
    Map<String, dynamic> data,
  ) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      final val = entry.value;
      if (val != null && val.runtimeType.toString().contains('FieldValue')) {
        continue;
      }
      result[entry.key] = val;
    }
    return result;
  }

  /// تهيئة Supabase وتحميل الكاش المحلي بالتوازي فورياً قبل تشغيل واجهة التطبيق
  static Future<void> initialize() async {
    if (!isConfigured) {
      await _loadLocalDiskCache();
      return;
    }

    try {
      await Future.wait([
        _loadLocalDiskCache(),
        Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseAnonKey,
        ),
      ]);

      // إذا كان هناك مستخدم مسجل في Supabase Auth ولم يكن محفوظاً في الجلسة المحلية، نزامنه
      final supaAuthUser = client.auth.currentUser;
      if (_cachedUserSession == null && supaAuthUser != null) {
        _cachedUserSession = {
          'uid': supaAuthUser.id,
          'email': supaAuthUser.email,
          'displayName': supaAuthUser.userMetadata?['name']?.toString(),
        };
      }

      debugPrint('✅ Supabase initialized successfully!');

      // إذا كان الكاش فارغاً (أول زيارة للموقع أو التطبيق) نبدأ الجلب فوراً بدون تأخير، وإلا نؤجل المزامنة الخلفية 800ms
      if (_cachedUniversities == null || _cachedUniversities!.isEmpty) {
        unawaited(syncAllInBackground());
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          unawaited(syncAllInBackground());
        });
      }
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
    }
  }

  /// استرجاع الكاش المحلي من ذاكرة الهاتف عند إقلاع التطبيق
  static Future<void> _loadLocalDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. تحميل جلسة المستخدم الحالي وبياناته المحفوظة محلياً
      final sessionJson = prefs.getString(_kCacheCurrentUserSession);
      if (sessionJson != null && sessionJson.isNotEmpty) {
        final decoded = Map<String, dynamic>.from(
          jsonDecode(sessionJson) as Map,
        );
        final uid = (decoded['uid'] ?? '').toString().trim();
        if (uid.isNotEmpty) {
          _cachedUserSession = {
            'uid': uid,
            'email': decoded['email']?.toString(),
            'displayName': decoded['displayName']?.toString(),
          };

          final savedSch =
              prefs.getStringList('$_kCacheSavedScholarshipsPrefix$uid') ??
              <String>[];
          _cachedSavedScholarshipsByUid[uid] = savedSch;

          final userJson = prefs.getString('$_kCacheUserDataPrefix$uid');
          if (userJson != null && userJson.isNotEmpty) {
            final rawMap = Map<String, dynamic>.from(
              jsonDecode(userJson) as Map,
            );
            _cachedUserDataByUid[uid] = _normalizeUserRow(
              rawMap,
              savedScholarships: savedSch,
            );
          }

          final notifJson = prefs.getString('$_kCacheNotificationsPrefix$uid');
          if (notifJson != null && notifJson.isNotEmpty) {
            final rawNotifs = jsonDecode(notifJson) as List<dynamic>;
            _cachedNotificationsByUid[uid] = rawNotifs.map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return AppNotification.fromMap(
                (map['id'] ?? '').toString(),
                map,
              );
            }).toList();
          }
        }
      }

      // 2. تحميل كاش الجامعات
      final uniJson = prefs.getString(_kCacheUniversities);
      if (uniJson != null && uniJson.isNotEmpty) {
        _lastUniversitiesJson = uniJson;
        final decoded = jsonDecode(uniJson) as List<dynamic>;
        _cachedUniversities = decoded.map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          final id = (map['id'] ?? '').toString();
          return University.fromMap(id, map);
        }).toList();
      }

      // 3. تحميل كاش المنح الدراسية
      final schJson = prefs.getString(_kCacheScholarships);
      if (schJson != null && schJson.isNotEmpty) {
        _lastScholarshipsJson = schJson;
        final decoded = jsonDecode(schJson) as List<dynamic>;
        _cachedScholarships = decoded.map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          final id = (map['id'] ?? '').toString();
          return Scholarship.fromMap(id, map);
        }).toList();
      }

      // 4. تحميل كاش الفرص
      final oppJson = prefs.getString(_kCacheOpportunities);
      if (oppJson != null && oppJson.isNotEmpty) {
        _lastOpportunitiesJson = oppJson;
        final decoded = jsonDecode(oppJson) as List<dynamic>;
        _cachedOpportunities = decoded.map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          final id = (map['id'] ?? '').toString();
          return Opportunity.fromMap(id, map);
        }).toList();
      }

      // 5. تحميل كاش مراكز التدريب
      final tcJson = prefs.getString(_kCacheTrainingCenters);
      if (tcJson != null && tcJson.isNotEmpty) {
        _lastTrainingCentersJson = tcJson;
        final decoded = jsonDecode(tcJson) as List<dynamic>;
        _cachedTrainingCenters = decoded
            .map((row) => Map<String, dynamic>.from(row as Map))
            .where((map) {
              final id = (map['id'] ?? '').toString();
              return id.isNotEmpty &&
                  !id.startsWith('_') &&
                  id != 'settings' &&
                  id != 'managers_settings';
            })
            .map((map) {
              final id = (map['id'] ?? '').toString();
              return TrainingCenter.fromMap(id, map);
            })
            .toList();
      }

      // 6. تحميل كاش مديري مراكز التدريب
      final tcMgrs = prefs.getStringList(_kCacheTcManagers);
      if (tcMgrs != null) {
        _cachedTcManagers = tcMgrs;
      }
    } catch (e) {
      debugPrint('⚠️ خطأ غير مؤثر أثناء قراءة الكاش المحلي: $e');
    }
  }

  /// مزامنة جميع البيانات في الخلفية وتحديث الواجهة فقط إذا وُجدت تعديلات جديدة
  static Future<void> syncAllInBackground() async {
    final service = SupabaseService();
    final futures = <Future<void>>[
      service._syncUniversitiesInBackground(),
      service._syncScholarshipsInBackground(),
      service._syncOpportunitiesInBackground(),
      service._syncTrainingCentersInBackground(),
    ];
    final currentUid = _cachedUserSession?['uid'];
    if (currentUid != null && currentUid.isNotEmpty) {
      futures.add(service.getUserDataMap(currentUid, forceRefresh: true));
    }
    await Future.wait(futures);
  }

  static Future<void> _saveToDiskCache(String key, String jsonStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  // ================= 0. إدارة المستخدمين (public.users) =================

  /// حفظ جلسة المستخدم الحالية محلياً وفي الذاكرة
  static Future<void> saveUserSession({
    required String uid,
    String? email,
    String? displayName,
  }) async {
    _cachedUserSession = {
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kCacheCurrentUserSession,
        jsonEncode(_cachedUserSession),
      );
    } catch (_) {}
  }

  /// مسح جلسة المستخدم الحالية عند تسجيل الخروج
  static Future<void> clearUserSession() async {
    _cachedUserSession = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCacheCurrentUserSession);
    } catch (_) {}
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  /// تطبيع بيانات المستخدم القادمة من Supabase بحيث تتوافق مع كافة الشاشات (مثل تحويل average إلى double)
  static Map<String, dynamic> _normalizeUserRow(
    Map<String, dynamic> raw, {
    List<String>? savedScholarships,
  }) {
    final uid = (raw['id'] ?? '').toString();
    final rawAvg = raw['average'];
    double parsedAvg = 0.0;
    if (rawAvg is num) {
      parsedAvg = rawAvg.toDouble();
    } else if (rawAvg != null) {
      parsedAvg = double.tryParse(rawAvg.toString().trim()) ?? 0.0;
    }

    final schList =
        savedScholarships ??
        _cachedSavedScholarshipsByUid[uid] ??
        _toStringList(raw['savedScholarships']);

    return {
      'id': uid,
      'name': (raw['name'] ?? '').toString(),
      'email': (raw['email'] ?? '').toString(),
      'academicYear': (raw['academicYear'] ?? '').toString(),
      'role': (raw['role'] ?? 'student').toString(),
      'average': parsedAvg,
      'track': (raw['track'] ?? '').toString(),
      'city': (raw['city'] ?? '').toString(),
      'favorites': _toStringList(raw['favorites']),
      'savedOpportunities': _toStringList(raw['savedOpportunities']),
      'likedPosts': _toStringList(raw['likedPosts']),
      'savedTrainingCenters': _toStringList(raw['savedTrainingCenters']),
      'savedScholarships': schList,
    };
  }

  /// تجهيز بيانات المستخدم للإرسال إلى جدول public.users في Supabase
  static Map<String, dynamic> _prepareUserPayloadForSupabase(
    Map<String, dynamic> data,
  ) {
    final sanitized = _sanitizeDataForSupabase(data);
    final payload = <String, dynamic>{};

    for (final entry in sanitized.entries) {
      if (!_allowedUserColumns.contains(entry.key)) continue;
      if (entry.key == 'average') {
        final val = entry.value;
        if (val is num) {
          payload['average'] =
              val == val.roundToDouble() ? val.toInt().toString() : val.toString();
        } else {
          payload['average'] = (val ?? '0').toString();
        }
      } else {
        payload[entry.key] = entry.value;
      }
    }
    return payload;
  }

  static void _notifyUserListeners(String uid, Map<String, dynamic>? data) {
    final controller = _userControllers[uid];
    if (controller != null && !controller.isClosed) {
      controller.add(data);
    }
  }

  static Future<void> _cacheUserDataLocally(
    String uid,
    Map<String, dynamic> normalizedData,
  ) async {
    _cachedUserDataByUid[uid] = normalizedData;
    _notifyUserListeners(uid, normalizedData);
    await _saveToDiskCache(
      '$_kCacheUserDataPrefix$uid',
      jsonEncode(normalizedData),
    );
  }

  /// البحث عن مستخدم في جدول public.users بواسطة البريد الإلكتروني
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    if (!isConfigured) return null;
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;

    try {
      final response = await client
          .from('users')
          .select()
          .ilike('email', cleanEmail);

      final rows = (response as List<dynamic>)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();

      if (rows.isEmpty) return null;

      // إذا وجد أكثر من سجل لنفس الإيميل، نختار السجل الأغنى بالبيانات (المفضلة أو المعدل أو الاسم)
      Map<String, dynamic> bestRow = rows.first;
      int bestScore = -1;
      for (final row in rows) {
        int score = 0;
        final favs = _toStringList(row['favorites']);
        final opps = _toStringList(row['savedOpportunities']);
        final avg =
            double.tryParse((row['average'] ?? '0').toString().trim()) ?? 0;
        final name = (row['name'] ?? '').toString().trim();
        if (favs.isNotEmpty) score += 10 + favs.length;
        if (opps.isNotEmpty) score += 5 + opps.length;
        if (avg > 0) score += 4;
        if (name.isNotEmpty) score += 2;
        if (score > bestScore) {
          bestScore = score;
          bestRow = row;
        }
      }

      final uid = (bestRow['id'] ?? '').toString();
      final normalized = _normalizeUserRow(bestRow);
      if (uid.isNotEmpty) {
        await _cacheUserDataLocally(uid, normalized);
      }
      return normalized;
    } catch (e) {
      debugPrint('❌ Supabase findUserByEmail error: $e');
      return null;
    }
  }

  /// جلب بيانات المستخدم من الكاش أو من جدول public.users في Supabase
  Future<Map<String, dynamic>?> getUserDataMap(
    String uid, {
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return null;
    if (!forceRefresh && _cachedUserDataByUid.containsKey(uid)) {
      return _cachedUserDataByUid[uid];
    }
    if (!isConfigured) return _cachedUserDataByUid[uid];

    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', uid)
          .limit(1);

      final rows = response as List<dynamic>;
      if (rows.isNotEmpty) {
        final raw = Map<String, dynamic>.from(rows.first as Map);
        final normalized = _normalizeUserRow(raw);
        await _cacheUserDataLocally(uid, normalized);
        return normalized;
      }

      // إذا لم يوجد بنفس الـ uid وكان لدينا إيميل المستخدم في الجلسة، نبحث بالإيميل
      final sessionEmail = _cachedUserSession?['email'];
      if (sessionEmail != null && sessionEmail.isNotEmpty) {
        final byEmail = await findUserByEmail(sessionEmail);
        if (byEmail != null) {
          await _cacheUserDataLocally(uid, byEmail);
          return byEmail;
        }
      }

      return _cachedUserDataByUid[uid];
    } catch (e) {
      debugPrint('❌ Supabase getUserDataMap error: $e');
      return _cachedUserDataByUid[uid];
    }
  }

  /// بث مباشر لبيانات المستخدم: يعرض الكاش في 0ms ثم يزامن من Supabase ويستمع لأي تحديث فوري
  Stream<Map<String, dynamic>?> streamUserDataMap(String uid) async* {
    _userControllers.putIfAbsent(
      uid,
      () => StreamController<Map<String, dynamic>?>.broadcast(),
    );

    final cached = _cachedUserDataByUid[uid];
    if (cached != null) {
      yield cached;
      unawaited(getUserDataMap(uid, forceRefresh: true));
    } else {
      final fresh = await getUserDataMap(uid, forceRefresh: true);
      if (fresh != null) {
        yield fresh;
      } else {
        // إنشاء كائن افتراضي سريع إذا كان المستخدم مسجلاً ولكن لم تُحفظ وثيقته بعد
        final fallback = _normalizeUserRow({
          'id': uid,
          'name': _cachedUserSession?['displayName'] ?? '',
          'email': _cachedUserSession?['email'] ?? '',
          'role': 'student',
          'average': 0,
          'track': '',
          'favorites': <String>[],
          'savedOpportunities': <String>[],
          'likedPosts': <String>[],
          'savedTrainingCenters': <String>[],
        });
        await _cacheUserDataLocally(uid, fallback);
        yield fallback;
      }
    }

    yield* _userControllers[uid]!.stream;
  }

  /// إضافة أو استبدال بيانات مستخدم في جدول public.users في Supabase
  Future<void> upsertUserData(String uid, Map<String, dynamic> data) async {
    final merged = <String, dynamic>{
      ...?_cachedUserDataByUid[uid],
      ...data,
      'id': uid,
    };
    final normalized = _normalizeUserRow(merged);
    await _cacheUserDataLocally(uid, normalized);

    if (!isConfigured) return;
    try {
      final payload = _prepareUserPayloadForSupabase(normalized);
      payload['id'] = uid;
      await client.from('users').upsert(payload);
    } catch (e) {
      debugPrint('❌ Supabase upsertUserData error: $e');
    }
  }

  /// تحديث حقول معينة للمستخدم في الكاش الفوري وفي جدول public.users في Supabase
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    final current =
        _cachedUserDataByUid[uid] ??
        await getUserDataMap(uid) ??
        <String, dynamic>{'id': uid};

    final updatedMap = <String, dynamic>{
      ...current,
      ...fields,
      'id': uid,
    };
    final normalized = _normalizeUserRow(updatedMap);
    await _cacheUserDataLocally(uid, normalized);

    if (!isConfigured) return;
    try {
      final payload = _prepareUserPayloadForSupabase(fields);
      if (payload.isEmpty) return;

      final res = await client
          .from('users')
          .update(payload)
          .eq('id', uid)
          .select();

      if ((res as List).isEmpty) {
        final fullPayload = _prepareUserPayloadForSupabase(normalized);
        fullPayload['id'] = uid;
        await client.from('users').upsert(fullPayload);
      }
    } catch (e) {
      debugPrint('❌ Supabase updateUserFields error: $e');
    }
  }

  /// إضافة أو إزالة عنصر من قوائم المستخدم (المفضلة، الإعجابات، الفرص، المراكز، المنح)
  Future<void> toggleUserArrayItem({
    required String uid,
    required String fieldName,
    required String itemId,
    required bool isCurrentlySaved,
  }) async {
    final current =
        _cachedUserDataByUid[uid] ??
        await getUserDataMap(uid) ??
        _normalizeUserRow({'id': uid});

    final list = List<String>.from(_toStringList(current[fieldName]));
    if (isCurrentlySaved) {
      list.remove(itemId);
    } else if (!list.contains(itemId)) {
      list.add(itemId);
    }

    if (fieldName == 'savedScholarships') {
      _cachedSavedScholarshipsByUid[uid] = list;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('$_kCacheSavedScholarshipsPrefix$uid', list);
      } catch (_) {}
      final updated = _normalizeUserRow(current, savedScholarships: list);
      await _cacheUserDataLocally(uid, updated);
      return;
    }

    await updateUserFields(uid, {fieldName: list});
  }

  /// حذف بيانات المستخدم من جدول public.users في Supabase ومن الكاش المحلي
  Future<void> deleteUserData(String uid) async {
    _cachedUserDataByUid.remove(uid);
    _cachedSavedScholarshipsByUid.remove(uid);
    _notifyUserListeners(uid, null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_kCacheUserDataPrefix$uid');
      await prefs.remove('$_kCacheSavedScholarshipsPrefix$uid');
      await prefs.remove('$_kCacheNotificationsPrefix$uid');
    } catch (_) {}

    if (!isConfigured) return;
    try {
      await client.from('users').delete().eq('id', uid);
    } catch (e) {
      debugPrint('❌ Supabase deleteUserData error: $e');
    }
  }

  // ================= 1. الجامعات (Universities) =================

  /// جلب قائمة الجامعات (من الكاش الفوري أو الشبكة)
  Future<List<University>> getUniversities({bool forceRefresh = false}) async {
    if (!isConfigured) return _cachedUniversities ?? [];
    if (!forceRefresh &&
        _cachedUniversities != null &&
        _cachedUniversities!.isNotEmpty) {
      return _cachedUniversities!;
    }
    try {
      final response = await client
          .from('universities')
          .select()
          .order('name', ascending: true);

      final rawList = response as List<dynamic>;
      final encoded = jsonEncode(rawList);
      if (encoded != _lastUniversitiesJson) {
        _lastUniversitiesJson = encoded;
        unawaited(_saveToDiskCache(_kCacheUniversities, encoded));
      }

      final list = rawList.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final id = (map['id'] ?? '').toString();
        return University.fromMap(id, map);
      }).toList();

      _cachedUniversities = list;
      return list;
    } catch (e) {
      debugPrint('❌ Supabase getUniversities error: $e');
      return _cachedUniversities ?? [];
    }
  }

  Future<void> _syncUniversitiesInBackground({bool forceNotify = false}) async {
    if (_isSyncingUniversities && !forceNotify) return;
    _isSyncingUniversities = true;
    try {
      final prevJson = _lastUniversitiesJson;
      final fresh = await getUniversities(forceRefresh: true);
      final changed = forceNotify || (_lastUniversitiesJson != prevJson);
      if (changed && !_universitiesController.isClosed) {
        _universitiesController.add(fresh);
      }
    } finally {
      _isSyncingUniversities = false;
    }
  }

  /// البث المباشر لتحديثات الجامعات: يعرض الكاش فوراً (0ms) ثم يحدث في الخلفية
  Stream<List<University>> streamUniversities() async* {
    if (_cachedUniversities != null && _cachedUniversities!.isNotEmpty) {
      yield _cachedUniversities!;
      unawaited(_syncUniversitiesInBackground());
    } else if (isConfigured) {
      yield await getUniversities(forceRefresh: true);
    } else {
      yield [];
    }
    yield* _universitiesController.stream;
  }

  /// بث بيانات جامعة واحدة حسب المعرف
  Stream<University?> streamUniversityById(String id) {
    return streamUniversities().map((list) {
      for (final u in list) {
        if (u.id == id) return u;
      }
      return null;
    });
  }

  Future<void> addUniversity(Map<String, dynamic> data) async {
    final payload = _sanitizeDataForSupabase(data);
    final id = (payload['id']?.toString().trim().isNotEmpty == true)
        ? payload['id'].toString().trim()
        : generateId();
    payload['id'] = id;

    await client.from('universities').upsert(payload);
    await _syncUniversitiesInBackground(forceNotify: true);
  }

  Future<void> updateUniversity(String id, Map<String, dynamic> data) async {
    final payload = _sanitizeDataForSupabase(data);
    final updated = await client
        .from('universities')
        .update(payload)
        .eq('id', id)
        .select();

    if ((updated as List).isEmpty) {
      payload['id'] = id;
      await client.from('universities').upsert(payload);
    }
    await _syncUniversitiesInBackground(forceNotify: true);
  }

  Future<void> deleteUniversity(String id) async {
    await client.from('universities').delete().eq('id', id);
    await _syncUniversitiesInBackground(forceNotify: true);
  }

  // ================= 2. المنح الدراسية (Scholarships) =================

  Future<List<Scholarship>> getScholarships({bool forceRefresh = false}) async {
    if (!isConfigured) return _cachedScholarships ?? [];
    if (!forceRefresh &&
        _cachedScholarships != null &&
        _cachedScholarships!.isNotEmpty) {
      return _cachedScholarships!;
    }
    try {
      final response = await client
          .from('scholarships')
          .select()
          .order('created_at', ascending: false);

      final rawList = response as List<dynamic>;
      final encoded = jsonEncode(rawList);
      if (encoded != _lastScholarshipsJson) {
        _lastScholarshipsJson = encoded;
        unawaited(_saveToDiskCache(_kCacheScholarships, encoded));
      }

      final list = rawList.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final id = (map['id'] ?? '').toString();
        return Scholarship.fromMap(id, map);
      }).toList();

      _cachedScholarships = list;
      return list;
    } catch (e) {
      debugPrint('❌ Supabase getScholarships error: $e');
      return _cachedScholarships ?? [];
    }
  }

  Future<void> _syncScholarshipsInBackground({bool forceNotify = false}) async {
    if (_isSyncingScholarships && !forceNotify) return;
    _isSyncingScholarships = true;
    try {
      final prevJson = _lastScholarshipsJson;
      final fresh = await getScholarships(forceRefresh: true);
      final changed = forceNotify || (_lastScholarshipsJson != prevJson);
      if (changed && !_scholarshipsController.isClosed) {
        _scholarshipsController.add(fresh);
      }
    } finally {
      _isSyncingScholarships = false;
    }
  }

  Stream<List<Scholarship>> streamScholarships() async* {
    if (_cachedScholarships != null && _cachedScholarships!.isNotEmpty) {
      yield _cachedScholarships!;
      unawaited(_syncScholarshipsInBackground());
    } else if (isConfigured) {
      yield await getScholarships(forceRefresh: true);
    } else {
      yield [];
    }
    yield* _scholarshipsController.stream;
  }

  Future<void> addScholarship(Map<String, dynamic> data) async {
    final payload = _sanitizeDataForSupabase(data);
    final id = (payload['id']?.toString().trim().isNotEmpty == true)
        ? payload['id'].toString().trim()
        : generateId();
    payload['id'] = id;

    await client.from('scholarships').upsert(payload);
    await _syncScholarshipsInBackground(forceNotify: true);
  }

  Future<void> updateScholarship(String id, Map<String, dynamic> data) async {
    final payload = _sanitizeDataForSupabase(data);
    final updated = await client
        .from('scholarships')
        .update(payload)
        .eq('id', id)
        .select();

    if ((updated as List).isEmpty) {
      payload['id'] = id;
      await client.from('scholarships').upsert(payload);
    }
    await _syncScholarshipsInBackground(forceNotify: true);
  }

  Future<void> deleteScholarship(String id) async {
    await client.from('scholarships').delete().eq('id', id);
    await _syncScholarshipsInBackground(forceNotify: true);
  }

  // ================= 3. الفرص والفعاليات (Opportunities) =================

  Future<List<Opportunity>> getOpportunities({
    bool forceRefresh = false,
  }) async {
    if (!isConfigured) return _cachedOpportunities ?? [];
    if (!forceRefresh &&
        _cachedOpportunities != null &&
        _cachedOpportunities!.isNotEmpty) {
      return _cachedOpportunities!;
    }
    try {
      final response = await client
          .from('opportunities')
          .select()
          .order('created_at', ascending: false);

      final rawList = response as List<dynamic>;
      final encoded = jsonEncode(rawList);
      if (encoded != _lastOpportunitiesJson) {
        _lastOpportunitiesJson = encoded;
        unawaited(_saveToDiskCache(_kCacheOpportunities, encoded));
      }

      final list = rawList.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final id = (map['id'] ?? '').toString();
        return Opportunity.fromMap(id, map);
      }).toList();

      _cachedOpportunities = list;
      return list;
    } catch (e) {
      debugPrint('❌ Supabase getOpportunities error: $e');
      return _cachedOpportunities ?? [];
    }
  }

  Future<void> _syncOpportunitiesInBackground({
    bool forceNotify = false,
  }) async {
    if (_isSyncingOpportunities && !forceNotify) return;
    _isSyncingOpportunities = true;
    try {
      final prevJson = _lastOpportunitiesJson;
      final fresh = await getOpportunities(forceRefresh: true);
      final changed = forceNotify || (_lastOpportunitiesJson != prevJson);
      if (changed && !_opportunitiesController.isClosed) {
        _opportunitiesController.add(fresh);
      }
    } finally {
      _isSyncingOpportunities = false;
    }
  }

  Stream<List<Opportunity>> streamOpportunities() async* {
    if (_cachedOpportunities != null && _cachedOpportunities!.isNotEmpty) {
      yield _cachedOpportunities!;
      unawaited(_syncOpportunitiesInBackground());
    } else if (isConfigured) {
      yield await getOpportunities(forceRefresh: true);
    } else {
      yield [];
    }
    yield* _opportunitiesController.stream;
  }

  Future<void> addOpportunity(Map<String, dynamic> data) async {
    final payload = _sanitizeDataForSupabase(data);
    final id = (payload['id']?.toString().trim().isNotEmpty == true)
        ? payload['id'].toString().trim()
        : generateId();
    payload['id'] = id;

    await client.from('opportunities').upsert(payload);
    await _syncOpportunitiesInBackground(forceNotify: true);
  }

  Future<void> updateOpportunity(String id, Map<String, dynamic> data) async {
    final payload = _sanitizeDataForSupabase(data);
    final updated = await client
        .from('opportunities')
        .update(payload)
        .eq('id', id)
        .select();

    if ((updated as List).isEmpty) {
      payload['id'] = id;
      await client.from('opportunities').upsert(payload);
    }
    await _syncOpportunitiesInBackground(forceNotify: true);
  }

  Future<void> deleteOpportunity(String id) async {
    await client.from('opportunities').delete().eq('id', id);
    await _syncOpportunitiesInBackground(forceNotify: true);
  }

  // ================= 4. مراكز التدريب (Training Centers) =================

  Future<List<TrainingCenter>> getTrainingCenters({
    bool forceRefresh = false,
  }) async {
    if (!isConfigured) return _cachedTrainingCenters ?? [];
    if (!forceRefresh &&
        _cachedTrainingCenters != null &&
        _cachedTrainingCenters!.isNotEmpty) {
      return _cachedTrainingCenters!;
    }
    try {
      final response = await client
          .from('training_centers')
          .select()
          .order('name', ascending: true);

      final rawList = response as List<dynamic>;
      final encoded = jsonEncode(rawList);
      if (encoded != _lastTrainingCentersJson) {
        _lastTrainingCentersJson = encoded;
        unawaited(_saveToDiskCache(_kCacheTrainingCenters, encoded));
      }

      // تحديث كاش مديري مراكز التدريب أيضاً إذا كان السجل موجوداً ضمن النتائج
      for (final row in rawList) {
        final map = Map<String, dynamic>.from(row as Map);
        if ((map['id'] ?? '').toString() == '_managers_settings') {
          final mgrs = _toStringList(map['managerEmails'])
              .map((e) => e.trim().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toList();
          _cachedTcManagers = mgrs;
          if (!_tcManagersController.isClosed) {
            _tcManagersController.add(mgrs);
          }
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList(_kCacheTcManagers, mgrs);
          } catch (_) {}
        }
      }

      final list = rawList
          .map((row) => Map<String, dynamic>.from(row as Map))
          .where((map) {
            final id = (map['id'] ?? '').toString();
            return id.isNotEmpty &&
                !id.startsWith('_') &&
                id != 'settings' &&
                id != 'managers_settings';
          })
          .map((map) {
            final id = (map['id'] ?? '').toString();
            return TrainingCenter.fromMap(id, map);
          })
          .toList();

      _cachedTrainingCenters = list;
      return list;
    } catch (e) {
      debugPrint('❌ Supabase getTrainingCenters error: $e');
      return _cachedTrainingCenters ?? [];
    }
  }

  Future<void> _syncTrainingCentersInBackground({
    bool forceNotify = false,
  }) async {
    if (_isSyncingTrainingCenters && !forceNotify) return;
    _isSyncingTrainingCenters = true;
    try {
      final prevJson = _lastTrainingCentersJson;
      final fresh = await getTrainingCenters(forceRefresh: true);
      final changed = forceNotify || (_lastTrainingCentersJson != prevJson);
      if (changed && !_trainingCentersController.isClosed) {
        _trainingCentersController.add(fresh);
      }
    } finally {
      _isSyncingTrainingCenters = false;
    }
  }

  Stream<List<TrainingCenter>> streamTrainingCenters() async* {
    if (_cachedTrainingCenters != null && _cachedTrainingCenters!.isNotEmpty) {
      yield _cachedTrainingCenters!;
      unawaited(_syncTrainingCentersInBackground());
    } else if (isConfigured) {
      yield await getTrainingCenters(forceRefresh: true);
    } else {
      yield [];
    }
    yield* _trainingCentersController.stream;
  }

  Future<void> addTrainingCenter(Map<String, dynamic> data) async {
    final payload = _sanitizeDataForSupabase(data);
    final id = (payload['id']?.toString().trim().isNotEmpty == true)
        ? payload['id'].toString().trim()
        : generateId();
    payload['id'] = id;

    await client.from('training_centers').upsert(payload);
    await _syncTrainingCentersInBackground(forceNotify: true);
  }

  Future<void> updateTrainingCenter(
    String id,
    Map<String, dynamic> data,
  ) async {
    final payload = _sanitizeDataForSupabase(data);
    final updated = await client
        .from('training_centers')
        .update(payload)
        .eq('id', id)
        .select();

    if ((updated as List).isEmpty) {
      payload['id'] = id;
      await client.from('training_centers').upsert(payload);
    }
    await _syncTrainingCentersInBackground(forceNotify: true);
  }

  Future<void> deleteTrainingCenter(String id) async {
    await client.from('training_centers').delete().eq('id', id);
    await _syncTrainingCentersInBackground(forceNotify: true);
  }

  // ===== 5. إعدادات مديري مراكز التدريب (_managers_settings) =====

  Future<List<String>> getTrainingCenterManagers({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedTcManagers != null) {
      return _cachedTcManagers!;
    }
    if (!isConfigured) return _cachedTcManagers ?? <String>[];

    try {
      final response = await client
          .from('training_centers')
          .select()
          .eq('id', '_managers_settings')
          .limit(1);

      final rows = response as List<dynamic>;
      if (rows.isNotEmpty) {
        final map = Map<String, dynamic>.from(rows.first as Map);
        final mgrs = _toStringList(map['managerEmails'])
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();
        _cachedTcManagers = mgrs;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(_kCacheTcManagers, mgrs);
        } catch (_) {}
        return mgrs;
      }
    } catch (e) {
      debugPrint('❌ Supabase getTrainingCenterManagers error: $e');
    }
    return _cachedTcManagers ?? <String>[];
  }

  Stream<List<String>> streamTrainingCenterManagers() async* {
    if (_cachedTcManagers != null) {
      yield _cachedTcManagers!;
      unawaited(
        getTrainingCenterManagers(forceRefresh: true).then((fresh) {
          if (!_tcManagersController.isClosed) {
            _tcManagersController.add(fresh);
          }
        }),
      );
    } else {
      yield await getTrainingCenterManagers(forceRefresh: true);
    }
    yield* _tcManagersController.stream;
  }

  Future<void> saveTrainingCenterManagers(List<String> emails) async {
    final cleaned = emails
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .take(10)
        .toList();

    _cachedTcManagers = cleaned;
    if (!_tcManagersController.isClosed) {
      _tcManagersController.add(cleaned);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kCacheTcManagers, cleaned);
    } catch (_) {}

    if (!isConfigured) return;
    await client.from('training_centers').upsert({
      'id': '_managers_settings',
      'managerEmails': cleaned,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ===== 6. نظام الإشعارات السريع (Cached Notifications) =====

  static Future<void> _saveNotificationsToDisk(
    String uid,
    List<AppNotification> list,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        list
            .map(
              (n) => {
                'id': n.id,
                'title': n.title,
                'body': n.body,
                'type': n.type,
                'targetType': n.targetType,
                'targetId': n.targetId,
                'createdAt': n.createdAt.toIso8601String(),
                'isRead': n.isRead,
              },
            )
            .toList(),
      );
      await prefs.setString('$_kCacheNotificationsPrefix$uid', encoded);
    } catch (_) {}
  }

  static void _notifyNotificationListeners(
    String uid,
    List<AppNotification> list,
  ) {
    final controller = _notificationControllers[uid];
    if (controller != null && !controller.isClosed) {
      controller.add(List<AppNotification>.from(list));
    }
  }

  Stream<List<AppNotification>> streamUserNotifications(String uid) async* {
    _notificationControllers.putIfAbsent(
      uid,
      () => StreamController<List<AppNotification>>.broadcast(),
    );

    if (!_cachedNotificationsByUid.containsKey(uid)) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final notifJson = prefs.getString('$_kCacheNotificationsPrefix$uid');
        if (notifJson != null && notifJson.isNotEmpty) {
          final rawNotifs = jsonDecode(notifJson) as List<dynamic>;
          _cachedNotificationsByUid[uid] = rawNotifs.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return AppNotification.fromMap((map['id'] ?? '').toString(), map);
          }).toList();
        } else {
          _cachedNotificationsByUid[uid] = <AppNotification>[];
        }
      } catch (_) {
        _cachedNotificationsByUid[uid] = <AppNotification>[];
      }
    }

    final current = _cachedNotificationsByUid[uid] ?? <AppNotification>[];
    current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield List<AppNotification>.from(current);
    yield* _notificationControllers[uid]!.stream;
  }

  Future<void> addUserNotification(
    String uid,
    AppNotification notification,
  ) async {
    final list = List<AppNotification>.from(
      _cachedNotificationsByUid[uid] ?? <AppNotification>[],
    );
    final id =
        notification.id.isNotEmpty ? notification.id : generateId();
    final existingIdx = list.indexWhere((n) => n.id == id);
    final item = AppNotification(
      id: id,
      title: notification.title,
      body: notification.body,
      type: notification.type,
      targetType: notification.targetType,
      targetId: notification.targetId,
      createdAt: notification.createdAt,
      isRead: existingIdx >= 0 ? list[existingIdx].isRead : notification.isRead,
    );

    if (existingIdx >= 0) {
      list[existingIdx] = item;
    } else {
      list.insert(0, item);
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cachedNotificationsByUid[uid] = list;
    _notifyNotificationListeners(uid, list);
    await _saveNotificationsToDisk(uid, list);
  }

  Future<void> markUserNotificationAsRead(
    String uid,
    String notificationId,
  ) async {
    final list = List<AppNotification>.from(
      _cachedNotificationsByUid[uid] ?? <AppNotification>[],
    );
    bool changed = false;
    for (int i = 0; i < list.length; i++) {
      if (list[i].id == notificationId && !list[i].isRead) {
        final old = list[i];
        list[i] = AppNotification(
          id: old.id,
          title: old.title,
          body: old.body,
          type: old.type,
          targetType: old.targetType,
          targetId: old.targetId,
          createdAt: old.createdAt,
          isRead: true,
        );
        changed = true;
      }
    }
    if (changed) {
      _cachedNotificationsByUid[uid] = list;
      _notifyNotificationListeners(uid, list);
      await _saveNotificationsToDisk(uid, list);
    }
  }

  Future<void> markAllUserNotificationsAsRead(String uid) async {
    final list = (_cachedNotificationsByUid[uid] ?? <AppNotification>[])
        .map(
          (old) => AppNotification(
            id: old.id,
            title: old.title,
            body: old.body,
            type: old.type,
            targetType: old.targetType,
            targetId: old.targetId,
            createdAt: old.createdAt,
            isRead: true,
          ),
        )
        .toList();
    _cachedNotificationsByUid[uid] = list;
    _notifyNotificationListeners(uid, list);
    await _saveNotificationsToDisk(uid, list);
  }

  Future<void> deleteUserNotification(
    String uid,
    String notificationId,
  ) async {
    final list = List<AppNotification>.from(
      _cachedNotificationsByUid[uid] ?? <AppNotification>[],
    )..removeWhere((n) => n.id == notificationId);
    _cachedNotificationsByUid[uid] = list;
    _notifyNotificationListeners(uid, list);
    await _saveNotificationsToDisk(uid, list);
  }

  Future<void> clearAllUserNotifications(String uid) async {
    _cachedNotificationsByUid[uid] = <AppNotification>[];
    _notifyNotificationListeners(uid, const <AppNotification>[]);
    await _saveNotificationsToDisk(uid, const <AppNotification>[]);
  }
}
