import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_rating_dialog.dart';

class RatingService {
  static const String _keyOpenCount = 'rating_open_count';
  static const String _keyFirstOpenTime = 'rating_first_open_time';
  static const String _keyLastPromptTime = 'rating_last_prompt_time';
  static const String _keyHasRated = 'rating_has_rated';
  static const String _keyDismissCount = 'rating_dismiss_count';

  // معرّف التطبيق في متجر جوجل بلاي
  static const String _playStorePackageName = 'com.uni_guide_app';
  static const String _storeWebUrl =
      'https://play.google.com/store/apps/details?id=$_playStorePackageName';
  static const String _storeMarketUrl =
      'market://details?id=$_playStorePackageName';

  /// تسجيل فتح التطبيق وحساب عدد المرات
  static Future<void> recordAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentOpens = prefs.getInt(_keyOpenCount) ?? 0;
      await prefs.setInt(_keyOpenCount, currentOpens + 1);

      if (!prefs.containsKey(_keyFirstOpenTime)) {
        await prefs.setInt(
          _keyFirstOpenTime,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (_) {}
  }

  /// التحقق هل حان وقت إظهار نافذة التقييم التلقائية
  static Future<bool> shouldShowRatingPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. إذا كان المستخدم قد قيّم التطبيق سابقاً، لا تظهر نهائياً
      final hasRated = prefs.getBool(_keyHasRated) ?? false;
      if (hasRated) return false;

      // 2. إذا اختار "لاحقاً" أكثر من 3 مرات، نتوقف عن الإلحاح تماماً
      final dismissCount = prefs.getInt(_keyDismissCount) ?? 0;
      if (dismissCount >= 3) return false;

      // 3. يجب أن يكون قد فتح التطبيق 3 مرات على الأقل
      final openCount = prefs.getInt(_keyOpenCount) ?? 0;
      if (openCount < 3) return false;

      // 4. يجب أن يكون قد مضى يومان على الأقل منذ أول استخدام
      final firstOpenTimeMs = prefs.getInt(_keyFirstOpenTime);
      if (firstOpenTimeMs != null) {
        final daysSinceFirstOpen = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(firstOpenTimeMs))
            .inDays;
        if (daysSinceFirstOpen < 2) return false;
      }

      // 5. فترة التهدئة (Cooldown): إذا ظهرت له مسبقاً واختار "لاحقاً"، لا تظهر إلا بعد مرور 7 أيام كاملة
      final lastPromptMs = prefs.getInt(_keyLastPromptTime);
      if (lastPromptMs != null) {
        final daysSinceLastPrompt = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(lastPromptMs))
            .inDays;
        if (daysSinceLastPrompt < 7) return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// تسجيل أن المستخدم ضغط "لاحقاً" أو تجاهل النافذة
  static Future<void> markPromptDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentDismiss = prefs.getInt(_keyDismissCount) ?? 0;
      await prefs.setInt(_keyDismissCount, currentDismiss + 1);
      await prefs.setInt(
        _keyLastPromptTime,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// تسجيل أن المستخدم قام بالتقييم (فلن تظهر له مجدداً إطلاقاً)
  static Future<void> markAsRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasRated, true);
    } catch (_) {}
  }

  /// فتح صفحة التطبيق في متجر Google Play
  static Future<void> launchStoreListing() async {
    await markAsRated();
    try {
      final marketUri = Uri.parse(_storeMarketUrl);
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      final webUri = Uri.parse(_storeWebUrl);
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// فحص ذكي وإظهار نافذة التقييم إذا استوفى الشروط
  static Future<void> checkAndPromptRating(BuildContext context) async {
    final shouldShow = await shouldShowRatingPrompt();
    if (!shouldShow || !context.mounted) return;

    // تأخير طفيف (3 ثوانٍ) لضمان استقرار الشاشة وعدم مضايقة المستخدم فور الدخول
    await Future.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;

    showRatingDialog(context, isAutoPrompt: true);
  }

  /// إظهار نافذة التقييم (يمكن استدعاؤها تلقائياً أو يدوياً من الإعدادات)
  static void showRatingDialog(BuildContext context, {bool isAutoPrompt = false}) {
    showDialog(
      context: context,
      barrierDismissible: !isAutoPrompt,
      builder: (context) => AppRatingDialog(isAutoPrompt: isAutoPrompt),
    );
  }
}
