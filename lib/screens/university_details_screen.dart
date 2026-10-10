import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/university_model.dart';
import '../models/post_model.dart';
import '../widgets/college_card.dart';
import '../widgets/custom_cached_image.dart';
import '../main.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../services/content_sanitizer.dart';

class UniversityDetailsScreen extends StatefulWidget {
  final University university;
  final int initialTabIndex; // 0=منشورات, 1=كليات, 2=فرص وبرامج

  const UniversityDetailsScreen({
    super.key,
    required this.university,
    this.initialTabIndex = 0,
  });

  @override
  State<UniversityDetailsScreen> createState() =>
      _UniversityDetailsScreenState();
}

class _UniversityDetailsScreenState extends State<UniversityDetailsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _checkFavorite();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkFavorite() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _firestoreService.getUserData(uid).listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final favs = List<String>.from(data['favorites'] ?? []);
        setState(() {
          _isFavorite = favs.contains(widget.university.id);
        });
      }
    });
  }

  Future<void> _toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.loginToFavoriteUni(context),
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
      return;
    }

    final previous = _isFavorite;
    setState(() => _isFavorite = !previous);

    try {
      await _firestoreService.toggleFavorite(
        uid,
        widget.university.id,
        previous,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isFavorite = previous);
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final rawPhone = widget.university.whatsapp.trim();
    if (rawPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.isAr(context)
                  ? 'لم تقم الجامعة بإضافة رقم واتساب للتواصل بعد'
                  : 'No WhatsApp number provided for this university yet',
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
      return;
    }

    // تنظيف وتنسيق الرقم الدولي
    var phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('07') && phone.length == 11) {
      phone = '964${phone.substring(1)}';
    } else if (phone.startsWith('7') && phone.length == 10) {
      phone = '964$phone';
    }

    final uniName = widget.university.name;
    final isAr = mounted ? AppStrings.isAr(context) : true;
    final message = Uri.encodeComponent(
      isAr
          ? 'مرحباً، أود الاستفسار بخصوص التقديم والتسجيل في $uniName'
          : 'Hello, I would like to inquire about admissions at $uniName',
    );
    final Uri waUri = Uri.parse('https://wa.me/$phone?text=$message');
    final Uri waAppUri =
        Uri.parse('whatsapp://send?phone=$phone&text=$message');

    try {
      if (await canLaunchUrl(waAppUri)) {
        await launchUrl(waAppUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUri, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.isAr(context)
                  ? 'تعذر فتح تطبيق واتساب'
                  : 'Could not open WhatsApp',
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
    }
  }

  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(
        '${widget.university.name} ${widget.university.city}');
    final Uri mapsUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _launchWebsite() async {
    final urlString = widget.university.websiteUrl.trim();
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.websiteNotAvailable(context),
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
      return;
    }
    final formattedUrl = urlString.startsWith('http')
        ? urlString
        : 'https://$urlString';
    final Uri url = Uri.parse(formattedUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.isAr(context)
                  ? 'تعذر فتح الرابط حالياً'
                  : 'Could not open website currently',
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
    }
  }

  void _showCoverPhotoPreview(String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomCachedImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  String _getEnglishName() {
    final name = widget.university.name;
    if (name.contains('المستقبل')) return 'Al-Mustaqbal University';
    if (name.contains('بغداد')) return 'University of Baghdad';
    if (name.contains('أهل البيت') || name.contains('اهل البيت')) {
      return 'Ahl Al-Bayt University';
    }
    if (name.contains('كربلاء')) return 'University of Kerbala';
    if (name.contains('الكوفة')) return 'University of Kufa';
    if (name.contains('بابل')) return 'University of Babylon';
    if (name.contains('المثنى')) return 'Al-Muthanna University';
    if (name.contains('البصرة')) return 'University of Basrah';
    if (name.contains('الموصل')) return 'University of Mosul';
    if (name.contains('النهرين')) return 'Al-Nahrain University';
    if (name.contains('التكنولوجية')) return 'University of Technology';
    if (name.contains('الأنبار') || name.contains('الانبار')) {
      return 'University of Anbar';
    }
    return '${widget.university.city} University';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isAr = AppStrings.isAr(context);

    final cleanCover =
        ContentSanitizer.sanitizeImageUrl(widget.university.coverImageUrl);
    final cleanLogo =
        ContentSanitizer.sanitizeImageUrl(widget.university.logoUrl);
    final coverImage = cleanCover.isNotEmpty ? cleanCover : cleanLogo;

    final typeText = widget.university.type.isNotEmpty
        ? (widget.university.type.contains('أهل') ||
                widget.university.type.contains('اهل')
            ? 'أهلية'
            : 'حكومية')
        : 'أهلية';

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.scaffoldBg(context)
            : const Color(0xFFF8FAFC),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. صورة الغلاف والشعار الدائري والمعلومات العلوية
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // قسم الغلاف والشعار المتراكب
                    SizedBox(
                      height: 270,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // صورة الغلاف الكبيرة
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 215,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                coverImage.isNotEmpty
                                    ? CustomCachedImage(
                                        imageUrl: coverImage,
                                        fit: BoxFit.cover,
                                        placeholderIcon: Icons.account_balance,
                                        iconSize: 50,
                                      )
                                    : Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topRight,
                                            end: Alignment.bottomLeft,
                                            colors: [
                                              Color(0xFF1E3A8A),
                                              Color(0xFF0F172A),
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.account_balance_rounded,
                                            size: 70,
                                            color: Colors.white24,
                                          ),
                                        ),
                                      ),

                                // تدرج خفيف لتحسين القراءة
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.45),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.25),
                                      ],
                                    ),
                                  ),
                                ),

                                // زر الرجوع العلوي
                                Positioned(
                                  top: MediaQuery.of(context).padding.top + 6,
                                  left: isAr ? null : 12,
                                  right: isAr ? 12 : null,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => Navigator.pop(context),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // زر المفضلة العلوي
                                Positioned(
                                  top: MediaQuery.of(context).padding.top + 6,
                                  left: isAr ? 12 : null,
                                  right: isAr ? null : 12,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _toggleFavorite,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Icon(
                                          _isFavorite
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: _isFavorite
                                              ? Colors.red
                                              : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // شارة "صورة الغلاف" على يسار الغلاف أسفل الصورة
                                Positioned(
                                  bottom: 12,
                                  left: 14,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          _showCoverPhotoPreview(coverImage),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.image_outlined,
                                              size: 13,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'صورة الغلاف',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // الشعار الدائري الكبير بالمنتصف المتراكب مع الغلاف
                          Positioned(
                            top: 155,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.14),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: CustomCachedImage(
                                    imageUrl: widget.university.logoUrl,
                                    width: 103,
                                    height: 103,
                                    fit: BoxFit.contain,
                                    placeholderIcon:
                                        Icons.account_balance_rounded,
                                    iconSize: 44,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // اسم الجامعة وعلامة التوثيق الزرقاء
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              widget.university.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F2942),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF0284C7),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),

                    // الاسم الإنجليزي للجامعة
                    Text(
                      _getEnglishName(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // شارات النوع والمحافظة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // شارة النوع
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'A* ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF38BDF8)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                typeText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // شارة المحافظة
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.university.city,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // النبذة والوصف
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.university.description.isNotEmpty
                            ? widget.university.description
                            : 'جامعة رائدة في العلوم والمعرفة، تساهم في بناء جيل واع ومؤهل لخدمة المجتمع.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.45,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // صف الأزرار التفاعلية الثلاثة
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          // 1. زر تواصل عبر واتساب (أخضر إذا وُجد رقم، وداكن إذا لم يُضف رقم)
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _openWhatsApp,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    gradient: widget.university.whatsapp.trim().isNotEmpty
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF25D366),
                                              Color(0xFF128C7E),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: widget.university.whatsapp.trim().isNotEmpty
                                        ? null
                                        : (isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFF334155)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: widget.university.whatsapp.trim().isNotEmpty
                                        ? null
                                        : Border.all(
                                            color: isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFF1E293B),
                                            width: 1,
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.university.whatsapp.trim().isNotEmpty
                                            ? const Color(0xFF25D366)
                                                .withValues(alpha: 0.35)
                                            : Colors.black.withValues(
                                                alpha: isDark ? 0.25 : 0.1),
                                        blurRadius: widget.university.whatsapp.trim().isNotEmpty
                                            ? 6
                                            : 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _WhatsAppIcon(
                                            size: 15,
                                            color: widget.university.whatsapp.trim().isNotEmpty
                                                ? Colors.white
                                                : Colors.white70,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'تواصل واتساب',
                                            style: TextStyle(
                                              color: widget.university.whatsapp.trim().isNotEmpty
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 2. زر الموقع الإلكتروني
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _launchWebsite,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard(context),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.04,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.language_rounded,
                                            size: 14,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'الموقع الإلكتروني',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF334155),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. زر الموقع الجغرافي
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _openMaps,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard(context),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.04,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: Color(0xFF0284C7),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'الموقع الجغرافي',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF334155),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // شريط التبويبات الثلاثة بتصميم كبسولة حديث (Modern Segmented Pill)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        indicator: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark
                                  .withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(
                            height: 38,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'المنشورات',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          Tab(
                            height: 38,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'الكليات والتخصصات',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          Tab(
                            height: 38,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'الفرص والبرامج',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsView(context),
              _buildCollegesView(context),
              _buildProgramsView(context),
            ],
          ),
        ),
      ),
    );
  }

  // 1. تبويب المنشورات
  Widget _buildPostsView(BuildContext context) {
    if (widget.university.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.newspaper_rounded,
                size: 56,
                color: AppColors.textMuted(context).withValues(alpha: 0.35),
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.isAr(context)
                    ? 'لا توجد منشورات أو إعلانات رسمية حالياً لهذه الجامعة'
                    : 'No official posts or announcements currently for this university',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      itemCount: widget.university.posts.length,
      itemBuilder: (context, index) {
        final post = widget.university.posts[index];
        return _buildSocialPostCard(context, post);
      },
    );
  }

  // بطاقة المنشور الاجتماعي
  Widget _buildSocialPostCard(BuildContext context, Post post) {
    final isDark = AppColors.isDark(context);
    final cleanPostImage = ContentSanitizer.sanitizeImageUrl(post.imageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس المنشور (شعار الجامعة، الاسم، علامة التوثيق، الوقت، زر الثلاث نقاط)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ثلاث نقاط خيارات على اليسار
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),

                // اسم الجامعة والتوقيت
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF0284C7),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.university.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F2942),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.public_rounded,
                          size: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.date.isNotEmpty ? post.date : '5 hours ago',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                // الشعار الدائري الصغير للجامعة
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: ClipOval(
                    child: CustomCachedImage(
                      imageUrl: widget.university.logoUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      placeholderIcon: Icons.account_balance,
                      iconSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // صورة المنشور بحواف دائرية (إذا توفرت)
          if (cleanPostImage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomCachedImage(
                  imageUrl: cleanPostImage,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.image_rounded,
                  iconSize: 40,
                ),
              ),
            ),

          // نص ووصف المنشور
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.title.isNotEmpty)
                  Text(
                    post.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF0F2942),
                      height: 1.35,
                    ),
                  ),
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // شريط أزرار التفاعل (إعجاب، تعليق، مشاركة)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Row(
              children: [
                // مشاركة
                InkWell(
                  onTap: () {},
                  child: Icon(
                    Icons.reply_rounded,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 18),

                // تعليق
                InkWell(
                  onTap: () {},
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 18),

                // إعجاب
                InkWell(
                  onTap: () {},
                  child: Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 19,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. تبويب الكليات والتخصصات
  Widget _buildCollegesView(BuildContext context) {
    if (widget.university.colleges.isEmpty) {
      return Center(
        child: Text(
          AppStrings.isAr(context)
              ? 'لا توجد كليات مضافة حالياً'
              : 'No colleges added currently',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      itemCount: widget.university.colleges.length,
      itemBuilder: (context, index) =>
          CollegeCard(college: widget.university.colleges[index]),
    );
  }

  // 3. تبويب الفرص والبرامج
  Widget _buildProgramsView(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'برنامج التبادل الأكاديمي والمنح',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'فرص دراسية وبرامج تدريبية لطلبة الجامعة',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'توفر ${widget.university.name} العديد من برامج الدعم والفرص التدريبية والشراكات الأكاديمية مع الجامعات والمراكز المعتمدة محلياً ودولياً.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'منح التفوق الأكاديمي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'خصومات وإعفاءات للطلبة الأوائل',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'خصومات تشجيعية ومنح دراسية للطلبة المتفوقين في امتحانات القبول والمراحل الدراسية المختلفة.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _WhatsAppIcon({
    this.size = 16,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhatsAppPainter(color: color),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  final Color color;

  _WhatsAppPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ViewBox is 448 x 512
    final double s = size.height / 512.0;
    final double dx = (size.width - 448.0 * s) / 2.0;

    canvas.save();
    canvas.translate(dx, 0);

    final path = Path()..fillType = PathFillType.evenOdd;
    path.moveTo(s * 380.9, s * 97.1);
    path.cubicTo(s * 339.0, s * 55.1, s * 283.2, s * 32.0, s * 223.9, s * 32.0);
    path.cubicTo(s * 101.5, s * 32.0, s * 1.9, s * 131.6, s * 1.9, s * 254.0);
    path.cubicTo(s * 1.9, s * 293.1, s * 12.1, s * 331.3, s * 31.5, s * 365.0);
    path.lineTo(s * 0.0, s * 480.0);
    path.lineTo(s * 117.7, s * 449.1);
    path.cubicTo(s * 150.1, s * 466.8, s * 186.6, s * 476.1, s * 223.8, s * 476.1);
    path.lineTo(s * 223.9, s * 476.1);
    path.cubicTo(s * 346.2, s * 476.1, s * 448.0, s * 376.5, s * 448.0, s * 254.1);
    path.cubicTo(s * 448.0, s * 194.8, s * 422.8, s * 139.1, s * 380.9, s * 97.1);
    path.close();

    path.moveTo(s * 223.9, s * 438.7);
    path.cubicTo(s * 190.7, s * 438.7, s * 158.2, s * 429.8, s * 129.9, s * 413.0);
    path.lineTo(s * 123.2, s * 409.0);
    path.lineTo(s * 53.4, s * 427.3);
    path.lineTo(s * 72.0, s * 359.2);
    path.lineTo(s * 67.6, s * 352.2);
    path.cubicTo(s * 49.1, s * 322.8, s * 39.4, s * 288.9, s * 39.4, s * 254.0);
    path.cubicTo(s * 39.4, s * 152.3, s * 122.2, s * 69.5, s * 224.0, s * 69.5);
    path.cubicTo(s * 273.3, s * 69.5, s * 319.6, s * 88.7, s * 354.4, s * 123.6);
    path.cubicTo(s * 389.2, s * 158.5, s * 410.6, s * 204.8, s * 410.5, s * 254.1);
    path.cubicTo(s * 410.5, s * 355.9, s * 325.6, s * 438.7, s * 223.9, s * 438.7);
    path.close();

    path.moveTo(s * 325.1, s * 300.5);
    path.cubicTo(s * 319.6, s * 297.7, s * 292.3, s * 284.3, s * 287.2, s * 282.5);
    path.cubicTo(s * 282.1, s * 280.6, s * 278.4, s * 279.7, s * 274.7, s * 285.3);
    path.cubicTo(s * 271.0, s * 290.9, s * 260.4, s * 303.3, s * 257.1, s * 307.1);
    path.cubicTo(s * 253.9, s * 310.8, s * 250.6, s * 311.3, s * 245.1, s * 308.5);
    path.cubicTo(s * 212.5, s * 292.2, s * 191.1, s * 279.4, s * 169.6, s * 242.5);
    path.cubicTo(s * 163.9, s * 232.7, s * 175.3, s * 233.4, s * 185.9, s * 212.2);
    path.cubicTo(s * 187.7, s * 208.5, s * 186.8, s * 205.3, s * 185.4, s * 202.5);
    path.cubicTo(s * 184.0, s * 199.7, s * 172.9, s * 172.4, s * 168.3, s * 161.3);
    path.cubicTo(s * 163.8, s * 150.5, s * 159.2, s * 152.0, s * 155.8, s * 151.8);
    path.cubicTo(s * 152.6, s * 151.6, s * 148.9, s * 151.6, s * 145.2, s * 151.6);
    path.cubicTo(s * 141.5, s * 151.6, s * 135.5, s * 153.0, s * 130.4, s * 158.5);
    path.cubicTo(s * 125.3, s * 164.1, s * 111.0, s * 177.5, s * 111.0, s * 204.8);
    path.cubicTo(s * 111.0, s * 232.1, s * 130.9, s * 258.5, s * 133.6, s * 262.2);
    path.cubicTo(s * 136.4, s * 265.9, s * 172.7, s * 321.9, s * 228.4, s * 346.0);
    path.cubicTo(s * 263.6, s * 361.2, s * 277.4, s * 362.5, s * 295.0, s * 359.9);
    path.cubicTo(s * 305.7, s * 358.3, s * 327.8, s * 346.5, s * 332.4, s * 333.5);
    path.cubicTo(s * 337.0, s * 320.5, s * 337.0, s * 309.4, s * 335.6, s * 307.1);
    path.cubicTo(s * 334.3, s * 304.6, s * 330.6, s * 303.2, s * 325.1, s * 300.5);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WhatsAppPainter oldDelegate) =>
      oldDelegate.color != color;
}
