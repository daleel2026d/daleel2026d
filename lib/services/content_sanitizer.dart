class ContentSanitizer {
  /// يتحقق من صحة رابط الصورة وينقي أي روابط صور تجريبية أو وهمية (Placeholders)
  static String sanitizeImageUrl(dynamic url) {
    if (url == null) return '';
    final str = url.toString().trim();
    if (str.isEmpty) return '';

    final lower = str.toLowerCase();
    // فحص الروابط الوهمية الشائعة
    if (lower.contains('placeholder') ||
        lower.contains('dummyimage') ||
        lower.contains('placehold.it') ||
        lower.contains('placekitten') ||
        lower.contains('loremflickr') ||
        lower.contains('sample-image') ||
        lower.contains('example.com')) {
      return '';
    }

    if (!lower.startsWith('http://') &&
        !lower.startsWith('https://') &&
        !lower.startsWith('assets/')) {
      return '';
    }

    return str;
  }

  /// يتحقق من صحة الروابط الخارجية وينقي أي روابط تجريبية مثل example.com
  static String sanitizeLink(dynamic url) {
    if (url == null) return '';
    final str = url.toString().trim();
    if (str.isEmpty) return '';

    final lower = str.toLowerCase();
    if (lower.contains('example.com') ||
        lower.contains('example.org') ||
        lower.contains('example.net') ||
        lower.contains('test.com') ||
        lower == 'http://' ||
        lower == 'https://' ||
        lower == '#' ||
        lower == 'javascript:void(0)') {
      return '';
    }

    return str;
  }

  /// يتحقق من صحة النصوص وينقي أي نصوص نائبة أو وهمية
  static String sanitizeText(dynamic text, {String fallback = ''}) {
    if (text == null) return fallback;
    final str = text.toString().trim();
    if (str.isEmpty) return fallback;

    final lower = str.toLowerCase();
    if (lower == '---' ||
        lower == '--' ||
        lower == 'null' ||
        lower == 'undefined' ||
        lower.contains('lorem ipsum')) {
      return fallback;
    }

    return str;
  }
}
