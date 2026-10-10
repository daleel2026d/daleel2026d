import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/app_controller.dart';
import '../services/app_localizations.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  static const String _privacyPolicyUrl =
      'https://www.termsfeed.com/live/9c75e2ad-f3db-4b08-8fb0-f67e0f633120';
  static const String _supportEmail = 'anad1990h@gmail.com';

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.surfaceCard(context),
      builder: (context) {
        final currentLocale = AppController.instance.locale;
        return Directionality(
          textDirection: AppStrings.direction(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.chooseLanguage(context),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.textMuted(context),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  title: 'العربية (Arabic)',
                  subtitle: AppStrings.langArabicSub(context),
                  isSelected: currentLocale?.languageCode == 'ar',
                  onTap: () {
                    AppController.instance.setLocale(const Locale('ar'));
                    Navigator.pop(context);
                    _showSnackBar('تم اختيار اللغة العربية');
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  title: 'English (الإنجليزية)',
                  subtitle: AppStrings.langEnglishSub(context),
                  isSelected: currentLocale?.languageCode == 'en',
                  onTap: () {
                    AppController.instance.setLocale(const Locale('en'));
                    Navigator.pop(context);
                    _showSnackBar('Language switched to English');
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  title: AppStrings.langSystem(context),
                  subtitle: AppStrings.isAr(context)
                      ? 'التعرف التلقائي على لغة الهاتف'
                      : 'Automatically follow device language',
                  isSelected: currentLocale == null,
                  onTap: () {
                    AppController.instance.setLocale(null);
                    Navigator.pop(context);
                    _showSnackBar(AppStrings.isAr(context)
                        ? 'تم ضبط اللغة تلقائياً حسب الهاتف'
                        : 'Language set to system default');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (AppColors.isDark(context)
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                  : AppColors.backgroundLight)
              : AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDark
                : AppColors.border(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected
                          ? (AppColors.isDark(context)
                              ? Colors.white
                              : AppColors.primaryDark)
                          : AppColors.textMain(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.isDark(context)
                    ? const Color(0xFF38BDF8)
                    : AppColors.primaryDark,
              ),
          ],
        ),
      ),
    );
  }

  void _showThemeBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.surfaceCard(context),
      builder: (context) {
        final currentMode = AppController.instance.themeMode;
        return Directionality(
          textDirection: AppStrings.direction(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.chooseAppearance(context),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.textMuted(context),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildThemeOption(
                  title: AppStrings.themeLight(context),
                  icon: Icons.light_mode_outlined,
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () {
                    AppController.instance.setThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                    _showSnackBar(AppStrings.isAr(context)
                        ? 'تم تفعيل الوضع الفاتح'
                        : 'Light mode enabled');
                  },
                ),
                const SizedBox(height: 8),
                _buildThemeOption(
                  title: AppStrings.themeDark(context),
                  icon: Icons.dark_mode_outlined,
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () {
                    AppController.instance.setThemeMode(ThemeMode.dark);
                    Navigator.pop(context);
                    _showSnackBar(AppStrings.isAr(context)
                        ? 'تم تفعيل الوضع الداكن'
                        : 'Dark mode enabled');
                  },
                ),
                const SizedBox(height: 8),
                _buildThemeOption(
                  title: AppStrings.themeSystem(context),
                  icon: Icons.brightness_auto_outlined,
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () {
                    AppController.instance.setThemeMode(ThemeMode.system);
                    Navigator.pop(context);
                    _showSnackBar(AppStrings.isAr(context)
                        ? 'تم ضبط المظهر تلقائياً حسب الهاتف'
                        : 'Appearance set to system default');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (AppColors.isDark(context)
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                  : AppColors.backgroundLight)
              : AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDark
                : AppColors.border(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (AppColors.isDark(context)
                      ? const Color(0xFF38BDF8)
                      : AppColors.primaryDark)
                  : AppColors.textMuted(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected
                      ? (AppColors.isDark(context)
                          ? Colors.white
                          : AppColors.primaryDark)
                      : AppColors.textMain(context),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.isDark(context)
                    ? const Color(0xFF38BDF8)
                    : AppColors.primaryDark,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse(_privacyPolicyUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          _showSnackBar(AppStrings.isAr(context)
              ? 'تعذر فتح الرابط'
              : 'Could not launch URL');
        }
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(AppStrings.isAr(context)
            ? 'تعذر فتح الرابط'
            : 'Could not launch URL');
      }
    }
  }

  void _showSupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.surfaceCard(context),
      builder: (context) {
        return Directionality(
          textDirection: AppStrings.direction(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.contactSupport(context),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.textMuted(context),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.supportTeamDesc(context),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted(context),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSupportOption(
                  icon: Icons.email_outlined,
                  color: AppColors.primaryDark,
                  title: AppStrings.emailSupport(context),
                  subtitle: _supportEmail,
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: _supportEmail,
                      queryParameters: {
                        'subject': AppStrings.isAr(context)
                            ? 'استفسار - تطبيق دليل مستقبلي'
                            : 'Inquiry - Future Guide App',
                      },
                    );
                    try {
                      if (!await launchUrl(emailUri)) {
                        _showSnackBar('Email: $_supportEmail');
                      }
                    } catch (_) {
                      _showSnackBar('Email: $_supportEmail');
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildSupportOption(
                  icon: Icons.feedback_outlined,
                  color: AppColors.accentBlue,
                  title: AppStrings.sendNote(context),
                  subtitle: AppStrings.sendNoteSub(context),
                  onTap: () {
                    Navigator.pop(context);
                    _showFeedbackDialog();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textMuted(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: AppStrings.direction(context),
          child: AlertDialog(
            backgroundColor: AppColors.surfaceCard(context),
            title: Text(
              AppStrings.sendNote(context),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain(context),
              ),
            ),
            content: TextField(
              controller: controller,
              maxLines: 4,
              style: TextStyle(color: AppColors.textMain(context)),
              decoration: InputDecoration(
                hintText: AppStrings.writeNoteHint(context),
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted(context),
                ),
                filled: true,
                fillColor: AppColors.inputFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppStrings.cancel(context),
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    final message = controller.text.trim();
                    final emailSubject = AppStrings.isAr(context)
                        ? 'ملاحظة واقتراح لتطبيق دليل مستقبلي'
                        : 'Feedback & Suggestion - Future Guide';
                    final successMsg = AppStrings.noteSentSuccess(context);
                    Navigator.pop(context);
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: _supportEmail,
                      queryParameters: {
                        'subject': emailSubject,
                        'body': message,
                      },
                    );
                    try {
                      await launchUrl(emailUri);
                    } catch (_) {}
                    if (mounted) {
                      _showSnackBar(successMsg);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(AppStrings.send(context)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Text(
            AppStrings.settings(context),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          leading: IconButton(
            icon: Icon(
              AppStrings.isAr(context)
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كارت الإعدادات الأربعة الرئيسية
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 1. اللغة
                    _buildSettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.primaryDark,
                      title: AppStrings.language(context),
                      subtitle:
                          AppController.instance.getLanguageName(context),
                      onTap: _showLanguageBottomSheet,
                    ),
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 20,
                      color: AppColors.border(context),
                    ),

                    // 2. المظهر
                    _buildSettingsTile(
                      icon: Icons.palette_outlined,
                      iconColor: const Color(0xFF7C3AED),
                      title: AppStrings.appearance(context),
                      subtitle: AppController.instance.getThemeName(context),
                      onTap: _showThemeBottomSheet,
                    ),
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 20,
                      color: AppColors.border(context),
                    ),

                    // 3. سياسة الخصوصية
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: const Color(0xFF059669),
                      title: AppStrings.privacyPolicy(context),
                      subtitle: AppStrings.privacyPolicyTerms(context),
                      onTap: _openPrivacyPolicy,
                    ),
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 20,
                      color: AppColors.border(context),
                    ),



                    // 4. التواصل مع الدعم
                    _buildSettingsTile(
                      icon: Icons.headset_mic_outlined,
                      iconColor: const Color(0xFFEA580C),
                      title: AppStrings.contactSupport(context),
                      subtitle: AppStrings.supportSubtitle(context),
                      onTap: _showSupportBottomSheet,
                    ),

                    if (FirebaseAuth.instance.currentUser != null) ...[
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 20,
                        color: AppColors.border(context),
                      ),
                      // 5. تسجيل الخروج
                      _buildSettingsTile(
                        icon: Icons.logout_rounded,
                        iconColor: Colors.red,
                        title: AppStrings.logOut(context),
                        subtitle: AppStrings.isAr(context)
                            ? 'تسجيل الخروج من الحساب الحالي'
                            : 'Sign out from current account',
                        onTap: _showSignOutDialog,
                        titleColor: Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // معلومات التطبيق
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lavenderCard(context),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 28,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.appTitle(context),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.version(context),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted(context),
                      ),
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

  Future<void> _showSignOutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: AppStrings.direction(context),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceCard(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                AppStrings.logOut(context),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain(context),
                ),
              ),
            ],
          ),
          content: Text(
            AppStrings.isAr(context)
                ? 'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟'
                : 'Are you sure you want to sign out of your account?',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppStrings.cancel(context),
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppStrings.logOut(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(AppStrings.loggedOutSuccess(context));
      }
    }
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: titleColor ?? AppColors.textMain(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
        ),
        trailing: Icon(
          AppStrings.isAr(context)
              ? Icons.arrow_back_ios_rounded
              : Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.textMuted(context),
        ),
      ),
    );
  }
}
