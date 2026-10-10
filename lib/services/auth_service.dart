import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // قائمة الإيميلات المصرح لها بالإدارة والتحكم في قاعدة البيانات
  static const List<String> adminEmails = [
    'daleel2026d@gmail.com',
  ];

  // التحقق هل المستخدم هو المدير
  static bool isAdmin(User? user) {
    if (user == null || user.email == null) return false;
    final email = user.email!.trim().toLowerCase();
    return adminEmails.map((e) => e.trim().toLowerCase()).contains(email);
  }

  // التحقق من الحساب الحالي
  bool get isCurrentUserAdmin => isAdmin(currentUser);

  // متابعة حالة تسجيل الدخول
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // تسجيل دخول بالإيميل والباسورد
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً';
    }
  }

  // تسجيل حساب جديد + حفظ بياناته الأساسية في Firestore
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'academicYear': '',
          'average': 0,
          'track': '',
          'role': 'student',
          'favorites': [],
          'savedOpportunities': [],
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً';
    }
  }

  // تسجيل الدخول أو إنشاء حساب عبر جوجل (Google Sign-In)
  Future<String?> signInWithGoogle() async {
    try {
      // فتح نافذة اختيار حسابات جوجل الموجودة بالجهاز
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // المستخدم تراجع أو أغلق نافذة الاختيار
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        if (!userDoc.exists) {
          // حساب جديد عبر جوجل: حفظ البيانات المبدئية
          await userDocRef.set({
            'name': user.displayName ?? googleUser.displayName ?? '',
            'email': user.email ?? googleUser.email,
            'academicYear': '',
            'average': 0,
            'track': '',
            'role': 'student',
            'favorites': [],
            'savedOpportunities': [],
          });
        }
      }

      return null; // نجاح
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'تعذر تسجيل الدخول باستخدام Google حالياً ($e)';
    }
  }

  // تسجيل خروج
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ترجمة أخطاء Firebase لرسائل عربية مفهومة
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم من قبل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'account-exists-with-different-credential':
        return 'يوجد حساب مسجل بالفعل ببيانات اعتماد مختلفة';
      case 'popup_closed_by_user':
      case 'canceled':
        return 'تم إلغاء تسجيل الدخول';
      default:
        return 'حدث خطأ، حاول مرة أخرى ($code)';
    }
  }
}