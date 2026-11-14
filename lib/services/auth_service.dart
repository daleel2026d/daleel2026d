import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'supabase_service.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
  });
}

class AuthService {
  static final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();

  static const String webGoogleClientId =
      '415167030737-r2lrdhtbt94c9vm73tvjgp1sapdkc9os.apps.googleusercontent.com';

  GoogleSignIn? _googleSignInInstance;

  GoogleSignIn get _googleSignIn => _googleSignInInstance ??= GoogleSignIn(
        clientId: kIsWeb ? webGoogleClientId : null,
        scopes: const ['email', 'profile'],
      );

  // قائمة الإيميلات المصرح لها بالإدارة والتحكم في قاعدة البيانات
  static const List<String> adminEmails = [
    'daleel2026d@gmail.com',
  ];

  // التحقق هل المستخدم هو المدير
  static bool isAdmin(AppUser? user) {
    if (user == null || user.email == null) return false;
    final email = user.email!.trim().toLowerCase();
    return adminEmails.map((e) => e.trim().toLowerCase()).contains(email);
  }

  // التحقق من الحساب الحالي
  bool get isCurrentUserAdmin => isAdmin(currentUser);

  // المستخدم الحالي (متزامن وفوري من ذاكرة SupabaseService)
  AppUser? get currentUser {
    final session = SupabaseService.cachedUserSession;
    if (session != null) {
      final uid = (session['uid'] ?? '').trim();
      if (uid.isNotEmpty) {
        return AppUser(
          uid: uid,
          email: session['email'],
          displayName: session['displayName'],
        );
      }
    }
    if (SupabaseService.isConfigured) {
      try {
        final supaUser = SupabaseService.client.auth.currentUser;
        if (supaUser != null) {
          return AppUser(
            uid: supaUser.id,
            email: supaUser.email,
            displayName: supaUser.userMetadata?['name']?.toString(),
          );
        }
      } catch (_) {}
    }
    return null;
  }

  // متابعة حالة تسجيل الدخول بشكل تفاعلي وفوري
  Stream<AppUser?> get authStateChanges async* {
    yield currentUser;
    yield* _authController.stream;
  }

  static Future<void> _setActiveUser({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    await SupabaseService.saveUserSession(
      uid: uid,
      email: email,
      displayName: displayName,
    );
    if (!_authController.isClosed) {
      _authController.add(
        AppUser(
          uid: uid,
          email: email,
          displayName: displayName,
        ),
      );
    }
  }

  // تسجيل دخول بالإيميل والباسورد عبر قاعدة بيانات Supabase (public.users + Supabase Auth)
  Future<String?> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    if (password.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }

    try {
      final supaService = SupabaseService();

      // 1. البحث عن المستخدم في جدول public.users في Supabase
      final existingUser = await supaService.findUserByEmail(cleanEmail);

      // 2. محاولة المصادقة عبر Supabase Auth إن كان مسجلاً فيها
      String? authUid;
      String? authName;
      try {
        final res = await SupabaseService.client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        authUid = res.user?.id;
        authName = res.user?.userMetadata?['name']?.toString();
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        // إذا كان الحساب غير موجود في Supabase Auth لكنه موجود في جدول public.users (البيانات المرحلة)
        if (existingUser == null) {
          if (msg.contains('invalid login credentials')) {
            return 'البريد الإلكتروني أو كلمة المرور غير صحيحة، أو الحساب غير مسجل';
          }
          return _getErrorMessage(e.message);
        }
      } catch (_) {}

      if (existingUser != null) {
        final uid = (existingUser['id'] ?? '').toString().trim().isNotEmpty
            ? existingUser['id'].toString().trim()
            : (authUid ?? SupabaseService.generateId());
        final name = (existingUser['name'] ?? authName ?? '').toString();

        await _setActiveUser(
          uid: uid,
          email: cleanEmail,
          displayName: name,
        );
        return null;
      }

      if (authUid != null) {
        final displayName = authName ?? cleanEmail.split('@').first;
        await supaService.upsertUserData(authUid, {
          'id': authUid,
          'name': displayName,
          'email': cleanEmail,
          'academicYear': '',
          'average': 0,
          'track': '',
          'role': 'student',
          'favorites': <String>[],
          'savedOpportunities': <String>[],
          'likedPosts': <String>[],
          'savedTrainingCenters': <String>[],
        });
        await _setActiveUser(
          uid: authUid,
          email: cleanEmail,
          displayName: displayName,
        );
        return null;
      }

      return 'لا يوجد حساب بهذا البريد الإلكتروني، يرجى إنشاء حساب جديد';
    } catch (e) {
      return 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً';
    }
  }

  // تسجيل حساب جديد وحفظ بياناته مباشرة في جدول public.users في Supabase
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    if (password.length < 6) {
      return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
    }

    try {
      final supaService = SupabaseService();

      // التحقق مما إذا كان الإيميل مسجلاً مسبقاً في جدول public.users
      final existingUser = await supaService.findUserByEmail(cleanEmail);
      if (existingUser != null) {
        return 'هذا البريد الإلكتروني مستخدم من قبل';
      }

      String uid = SupabaseService.generateId();
      try {
        final res = await SupabaseService.client.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {'name': cleanName},
        );
        if (res.user != null && res.user!.id.isNotEmpty) {
          uid = res.user!.id;
        }
      } catch (_) {
        // المتابعة بحفظ المستخدم في جدول public.users في Supabase مباشرة
      }

      await supaService.upsertUserData(uid, {
        'id': uid,
        'name': cleanName,
        'email': cleanEmail,
        'academicYear': '',
        'average': 0,
        'track': '',
        'role': 'student',
        'favorites': <String>[],
        'savedOpportunities': <String>[],
        'likedPosts': <String>[],
        'savedTrainingCenters': <String>[],
      });

      await _setActiveUser(
        uid: uid,
        email: cleanEmail,
        displayName: cleanName,
      );
      return null;
    } catch (e) {
      return 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً';
    }
  }

  // تسجيل الدخول أو إنشاء حساب عبر البريد المرتبط بـ Google مباشرة في قاعدة بيانات Supabase
  Future<String?> signInWithGoogleEmail({
    required String email,
    String? displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return 'يرجى إدخال بريد إلكتروني صحيح (Gmail)';
    }

    try {
      final supaService = SupabaseService();
      final existingUser = await supaService.findUserByEmail(cleanEmail);

      if (existingUser != null) {
        final uid = (existingUser['id'] ?? '').toString().trim().isNotEmpty
            ? existingUser['id'].toString().trim()
            : SupabaseService.generateId();
        final resolvedName = (existingUser['name'] ?? '').toString().trim();
        final finalName = resolvedName.isNotEmpty
            ? resolvedName
            : (displayName?.trim().isNotEmpty == true
                  ? displayName!.trim()
                  : cleanEmail.split('@').first);

        if (resolvedName.isEmpty && finalName.isNotEmpty) {
          await supaService.updateUserFields(uid, {'name': finalName});
        }

        await _setActiveUser(
          uid: uid,
          email: cleanEmail,
          displayName: finalName,
        );
        return null;
      }

      // إذا كان مستخدماً جديداً، ننشئ له سجلاً جديداً في جدول public.users في Supabase
      final newUid = SupabaseService.generateId();
      final finalName = (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : cleanEmail.split('@').first;

      await supaService.upsertUserData(newUid, {
        'id': newUid,
        'name': finalName,
        'email': cleanEmail,
        'academicYear': '',
        'average': 0,
        'track': '',
        'role': 'student',
        'favorites': <String>[],
        'savedOpportunities': <String>[],
        'likedPosts': <String>[],
        'savedTrainingCenters': <String>[],
      });

      await _setActiveUser(
        uid: newUid,
        email: cleanEmail,
        displayName: finalName,
      );
      return null;
    } catch (e) {
      return 'تعذر تسجيل الدخول عبر قاعدة البيانات حالياً ($e)';
    }
  }

  // تسجيل الدخول عبر حساب جوجل (يفتح قائمة حسابات Google الموجودة على الهاتف ويربطها مع جدول public.users في Supabase)
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // المستخدم ألغى الاختيار
      }

      return await signInWithGoogleEmail(
        email: googleUser.email,
        displayName: googleUser.displayName,
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('popup_closed') ||
          errStr.contains('canceled') ||
          errStr.contains('cancelled') ||
          errStr.contains('access_denied')) {
        return null;
      }
      return 'تعذر فتح حسابات Google تلقائياً ($e)';
    }
  }

  // تسجيل خروج
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    try {
      await SupabaseService.client.auth.signOut();
    } catch (_) {}
    await SupabaseService.clearUserSession();
    if (!_authController.isClosed) {
      _authController.add(null);
    }
  }

  // حذف الحساب نهائياً من جدول public.users في Supabase ومن الجلسة الحالية
  Future<String?> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        return 'لم يتم العثور على حساب نشط لتسجيل الخروج منه';
      }
      final uid = user.uid;

      // 1. حذف بيانات المستخدم من جدول public.users في Supabase
      await SupabaseService().deleteUserData(uid);

      // 2. تسجيل الخروج ومسح الجلسة
      await signOut();
      return null;
    } catch (e) {
      return 'تعذر إتمام عملية حذف الحساب حالياً ($e)';
    }
  }

  // ترجمة رسائل الخطأ للعربية
  String _getErrorMessage(String code) {
    final lower = code.toLowerCase();
    if (lower.contains('user-not-found') || lower.contains('user not found')) {
      return 'لا يوجد حساب بهذا البريد الإلكتروني';
    }
    if (lower.contains('wrong-password') ||
        lower.contains('invalid-credential') ||
        lower.contains('invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (lower.contains('email-already-in-use') ||
        lower.contains('already registered')) {
      return 'هذا البريد الإلكتروني مستخدم من قبل';
    }
    if (lower.contains('weak-password')) {
      return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
    }
    if (lower.contains('invalid-email')) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    if (lower.contains('network')) {
      return 'تعذر الاتصال بالإنترنت، يرجى التحقق من الشبكة';
    }
    if (lower.contains('too-many-requests') || lower.contains('rate limit')) {
      return 'تم إجراء محاولات كثيرة، يرجى الانتظار قليلاً ثم المحاولة مجدداً';
    }
    return 'حدث خطأ، حاول مرة أخرى ($code)';
  }
}
