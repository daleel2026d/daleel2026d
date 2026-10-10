import 'package:flutter/material.dart';

class AppController extends ChangeNotifier {
  static final AppController instance = AppController._internal();
  AppController._internal();

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale; // null يعني اتباع لغة نظام الهاتف تلقائياً

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  String getThemeName(BuildContext context) {
    final isAr = isArabic(context);
    switch (_themeMode) {
      case ThemeMode.light:
        return isAr ? 'الوضع الفاتح' : 'Light Mode';
      case ThemeMode.dark:
        return isAr ? 'الوضع الداكن' : 'Dark Mode';
      case ThemeMode.system:
        return isAr ? 'تلقائي (حسب إعدادات الجهاز)' : 'System Default';
    }
  }

  String getLanguageName(BuildContext context) {
    final isAr = isArabic(context);
    if (_locale == null) {
      return isAr ? 'تلقائي (لغة الجهاز)' : 'System Default';
    }
    return _locale!.languageCode == 'ar' ? 'العربية' : 'English';
  }

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  bool isArabic(BuildContext context) {
    if (_locale != null) {
      return _locale!.languageCode == 'ar';
    }
    final systemLocale = Localizations.maybeLocaleOf(context) ??
        WidgetsBinding.instance.platformDispatcher.locale;
    return systemLocale.languageCode.toLowerCase() == 'ar';
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void setLocale(Locale? loc) {
    if (_locale != loc) {
      _locale = loc;
      notifyListeners();
    }
  }
}
