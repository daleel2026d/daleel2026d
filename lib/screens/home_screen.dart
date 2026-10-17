import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../models/university_model.dart';
import '../models/scholarship_model.dart';
import '../models/opportunity_model.dart';
import '../models/training_center_model.dart';
import '../models/post_model.dart';
import '../services/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_cached_image.dart';
import 'universities_screen.dart';
import 'scholarships_opportunities_screen.dart';
import 'profile_screen.dart';
import 'university_details_screen.dart';
import 'scholarship_details_screen.dart';
import 'opportunity_details_screen.dart';
import 'training_center_details_screen.dart';
import 'notifications_screen.dart';
import '../services/rating_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    // تسجيل جلسة فتح التطبيق والتحقق من التقييم التلقائي وفق القواعد المحددة
    RatingService.recordAppOpen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RatingService.checkAndPromptRating(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.direction(context),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          // 1. إذا كان المستخدم في أي تبويب آخر، يعود للرئيسية أولاً
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
            return;
          }

          // 2. إذا كان في الرئيسية، يضغط رجوع مرة ثانية للخروج
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppStrings.pressAgainToExit(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                duration: const Duration(seconds: 2),
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

          // تم الضغط مرتين خلال ثانيتين -> خروج من التطبيق
          SystemNavigator.pop();
        },
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBg(context),
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              _HomeContent(),
              UniversitiesScreen(),
              ScholarshipsOpportunitiesScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            height: 62,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: AppStrings.navHome(context),
              ),
              NavigationDestination(
                icon: const Icon(Icons.school_outlined),
                selectedIcon: const Icon(Icons.school_rounded),
                label: AppStrings.navUniversities(context),
              ),
              NavigationDestination(
                icon: const Icon(Icons.card_giftcard_outlined),
                selectedIcon: const Icon(Icons.card_giftcard_rounded),
                label: AppStrings.navScholarships(context),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: AppStrings.navProfile(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final TextEditingController _averageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedTrack = 'علمي';
  String _selectedType = 'all';
  String _selectedCity = 'كافة المحافظات';
  bool _isLoading = false;

  static const List<String> _iraqGovernorates = [
    'كافة المحافظات',
    'بغداد',
    'البصرة',
    'نينوى',
    'أربيل',
    'النجف الأشرف',
    'كربلاء المقدسة',
    'كركوك',
    'الأنبار',
    'بابل',
    'ديالى',
    'ذي قار',
    'السليمانية',
    'دهوك',
    'واسط',
    'صلاح الدين',
    'ميسان',
    'المثنى',
    'القادسية',
  ];

  List<University> _defaultUniversities = [];
  List<Map<String, dynamic>> _recentPosts = [];
  List<String> _likedPostKeys = [];
  bool _isPostsLoading = true;

  StreamSubscription? _trainingCentersSub;
  StreamSubscription? _universitiesSub;
  StreamSubscription? _scholarshipsSub;
  StreamSubscription? _opportunitiesSub;

  @override
  void initState() {
    super.initState();
    _loadDefaultData();
    _listenToLikedPosts();
    _listenToDataChanges();
  }

  void _listenToDataChanges() {
    _trainingCentersSub = _firestoreService.getAllTrainingCenters().listen((_) {
      _loadDefaultData();
    });
    _universitiesSub = _firestoreService.getAllUniversities().listen((_) {
      _loadDefaultData();
    });
    _scholarshipsSub = _firestoreService.getAllScholarships().listen((_) {
      _loadDefaultData();
    });
    _opportunitiesSub = _firestoreService.getAllOpportunities().listen((_) {
      _loadDefaultData();
    });
  }

  void _listenToLikedPosts() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _firestoreService.getUserData(uid).listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _likedPostKeys = List<String>.from(data['likedPosts'] ?? []);
        });
      }
    });
  }

  Future<void> _toggleLikePost(String postKey) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.isAr(context)
                ? 'يرجى تسجيل الدخول للإعجاب بالمنشور'
                : 'Please log in to like this post',
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

    final isLiked = _likedPostKeys.contains(postKey);

    // تحديث تفاؤلي فوري في الواجهة (Optimistic UI Update)
    setState(() {
      if (isLiked) {
        _likedPostKeys.remove(postKey);
      } else {
        _likedPostKeys.add(postKey);
      }
    });

    try {
      await _firestoreService.toggleLikePost(uid, postKey, isLiked);
    } catch (_) {
      if (mounted) {
        setState(() {
          if (isLiked) {
            _likedPostKeys.add(postKey);
          } else {
            _likedPostKeys.remove(postKey);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _trainingCentersSub?.cancel();
    _universitiesSub?.cancel();
    _scholarshipsSub?.cancel();
    _opportunitiesSub?.cancel();
    _averageController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultData() async {
    try {
      final results = await Future.wait([
        _firestoreService.fetchUniversitiesOnce(),
        _firestoreService.fetchScholarshipsOnce(),
        _firestoreService.fetchOpportunitiesOnce(),
        _firestoreService.fetchTrainingCentersOnce(),
      ]);

      final allUniversities = results[0] as List<University>;
      final allScholarships = results[1] as List<Scholarship>;
      final allOpportunities = results[2] as List<Opportunity>;
      final allTrainingCenters = results[3] as List<TrainingCenter>;

      final List<Map<String, dynamic>> extracted = [];

      // 1. منشورات الجامعات والكليات
      for (var uni in allUniversities) {
        for (var post in uni.posts) {
          extracted.add({
            'post': post,
            'type': 'university',
            'name': uni.name,
            'logoUrl': uni.logoUrl,
            'location': uni.city.isNotEmpty ? uni.city : 'العراق',
            'badgeText': 'جامعة / كلية',
            'badgeColor': const Color(0xFF0284C7),
            'placeholderIcon': Icons.account_balance_rounded,
            'entity': uni,
          });
        }
      }

      // 2. منشورات المنح الدراسية
      for (var sch in allScholarships) {
        for (var post in sch.posts) {
          extracted.add({
            'post': post,
            'type': 'scholarship',
            'name': sch.name,
            'logoUrl': sch.imageUrl,
            'location': sch.country.isNotEmpty ? sch.country : 'منحة دراسية',
            'badgeText': 'منحة دراسية',
            'badgeColor': const Color(0xFFEA580C),
            'placeholderIcon': Icons.school_rounded,
            'entity': sch,
          });
        }
      }

      // 3. منشورات الفرص والفعاليات
      for (var opp in allOpportunities) {
        for (var post in opp.posts) {
          extracted.add({
            'post': post,
            'type': 'opportunity',
            'name': opp.title,
            'logoUrl': opp.imageUrl,
            'location': opp.location.isNotEmpty
                ? opp.location
                : (opp.attendance.isNotEmpty ? opp.attendance : 'أونلاين'),
            'badgeText': 'فرصة وفعالية',
            'badgeColor': const Color(0xFF10B981),
            'placeholderIcon': Icons.event_rounded,
            'entity': opp,
          });
        }
      }

      // 4. منشورات مراكز التدريب
      for (var center in allTrainingCenters) {
        for (var post in center.posts) {
          extracted.add({
            'post': post,
            'type': 'training_center',
            'name': center.name,
            'logoUrl': center.imageUrl,
            'location':
                center.location.isNotEmpty ? center.location : 'مركز تدريب',
            'badgeText': 'مركز تدريب',
            'badgeColor': const Color(0xFF7C3AED),
            'placeholderIcon': Icons.apartment_rounded,
            'entity': center,
          });
        }
      }

      extracted.sort((a, b) {
        final aDate = _parsePostDate((a['post'] as Post).date);
        final bDate = _parsePostDate((b['post'] as Post).date);
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _defaultUniversities = allUniversities.take(12).toList();
          _recentPosts = extracted.take(30).toList();
          _isPostsLoading = false;
        });
      }

      // فحص وتوليد إشعارات ذكية
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          final favs = List<String>.from(data['favorites'] ?? []);
          NotificationService()
              .notifyFavoriteUniversityUpdates(allUniversities, favs);
          NotificationService().notifyNewScholarships(allScholarships);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPostsLoading = false);
      }
    }
  }

  DateTime _parsePostDate(String date) {
    final clean = date.trim();
    if (clean.isEmpty) return DateTime.now();
    try {
      final normalized = clean.replaceAll('/', '-');
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) return parsed;
      final parts = normalized.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else if (parts[2].length == 4) {
          return DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}
    return DateTime.now();
  }

  Future<void> _searchColleges() async {
    if (_averageController.text.trim().isEmpty) {
      _showSnackBar(AppStrings.enterAverageFirst(context));
      return;
    }

    final double? average = double.tryParse(_averageController.text.trim());
    if (average == null) {
      _showSnackBar(AppStrings.enterValidNumber(context));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'average': average,
            'track': _selectedTrack,
            'city': _selectedCity,
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      // فحص وتوليد إشعار ذكي بمطابقة المعدل
      NotificationService().checkGpaMatches(average, _selectedTrack);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UniversitiesScreen(
              track: _selectedTrack,
              studentAverage: average,
              initialUniversityType: _selectedType,
              initialCity: _selectedCity,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppStrings.errorFetching(context));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  void _navigateToAllResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniversitiesScreen(
          initialUniversityType: _selectedType,
          initialCity: _selectedCity,
        ),
      ),
    );
  }

  void _openUniversity(University uni, {int tabIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UniversityDetailsScreen(university: uni, initialTabIndex: tabIndex),
      ),
    );
  }

  void _showGovernoratePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredGovernorates = _iraqGovernorates
                .where((g) => g.contains(searchQuery.trim()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_city_rounded,
                              color: AppColors.primaryDark,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.selectGovernorate(context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain(context),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                          color: AppColors.textMuted(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: TextField(
                      onChanged: (val) =>
                          setModalState(() => searchQuery = val),
                      style: TextStyle(
                          color: AppColors.textMain(context), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: AppStrings.isAr(context)
                            ? 'ابحث عن محافظة...'
                            : 'Search governorate...',
                        hintStyle: TextStyle(
                            color: AppColors.textMuted(context), fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: AppColors.inputFill(context),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.border(context)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: filteredGovernorates.length,
                      separatorBuilder: (context, index) => Divider(
                        color: AppColors.border(context).withValues(alpha: 0.5),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final gov = filteredGovernorates[index];
                        final isSelected = _selectedCity == gov;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          tileColor: isSelected
                              ? AppColors.primaryDark.withValues(alpha: 0.08)
                              : Colors.transparent,
                          leading: Icon(
                            gov == 'كافة المحافظات'
                                ? Icons.public_rounded
                                : Icons.location_on_outlined,
                            color: isSelected
                                ? (AppColors.isDark(context)
                                    ? const Color(0xFF38BDF8)
                                    : AppColors.primaryDark)
                                : AppColors.textMuted(context),
                            size: 20,
                          ),
                          title: Text(
                            gov,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (AppColors.isDark(context)
                                      ? const Color(0xFF38BDF8)
                                      : AppColors.primaryDark)
                                  : AppColors.textMain(context),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF059669),
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            setState(() => _selectedCity = gov);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrackDropdownButton() {
    return PopupMenuButton<String>(
      initialValue: _selectedTrack,
      onSelected: (val) => setState(() => _selectedTrack = val),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.surfaceCard(context),
      elevation: 8,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'علمي',
          child: Row(
            children: [
              const Icon(Icons.science_rounded,
                  size: 20, color: Color(0xFF0284C7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.trackScientific(context),
                  style: TextStyle(
                    fontWeight: _selectedTrack == 'علمي'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: AppColors.textMain(context),
                  ),
                ),
              ),
              if (_selectedTrack == 'علمي')
                const Icon(Icons.check_rounded,
                    size: 18, color: Color(0xFF0284C7)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'أدبي',
          child: Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  size: 20, color: Color(0xFFD97706)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.trackLiterary(context),
                  style: TextStyle(
                    fontWeight: _selectedTrack == 'أدبي'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: AppColors.textMain(context),
                  ),
                ),
              ),
              if (_selectedTrack == 'أدبي')
                const Icon(Icons.check_rounded,
                    size: 18, color: Color(0xFFD97706)),
            ],
          ),
        ),
      ],
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _selectedTrack == 'علمي'
                      ? Icons.science_rounded
                      : Icons.menu_book_rounded,
                  size: 18,
                  color: _selectedTrack == 'علمي'
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedTrack == 'علمي'
                      ? AppStrings.trackScientific(context)
                      : AppStrings.trackLiterary(context),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
              ],
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textMuted(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdownButton() {
    String typeLabel;
    IconData typeIcon;
    Color typeColor;

    if (_selectedType == 'government') {
      typeLabel = AppStrings.filterGovernment(context);
      typeIcon = Icons.account_balance_rounded;
      typeColor = const Color(0xFF059669);
    } else if (_selectedType == 'private') {
      typeLabel = AppStrings.filterPrivate(context);
      typeIcon = Icons.school_rounded;
      typeColor = const Color(0xFF8B5CF6);
    } else {
      typeLabel = AppStrings.governmentAndPrivate(context);
      typeIcon = Icons.domain_rounded;
      typeColor = const Color(0xFF6366F1);
    }

    return PopupMenuButton<String>(
      initialValue: _selectedType,
      onSelected: (val) => setState(() => _selectedType = val),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.surfaceCard(context),
      elevation: 8,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'all',
          child: Row(
            children: [
              const Icon(Icons.domain_rounded,
                  size: 20, color: Color(0xFF6366F1)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.governmentAndPrivate(context),
                  style: TextStyle(
                    fontWeight: _selectedType == 'all'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: AppColors.textMain(context),
                  ),
                ),
              ),
              if (_selectedType == 'all')
                const Icon(Icons.check_rounded,
                    size: 18, color: Color(0xFF6366F1)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'government',
          child: Row(
            children: [
              const Icon(Icons.account_balance_rounded,
                  size: 20, color: Color(0xFF059669)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.filterGovernment(context),
                  style: TextStyle(
                    fontWeight: _selectedType == 'government'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: AppColors.textMain(context),
                  ),
                ),
              ),
              if (_selectedType == 'government')
                const Icon(Icons.check_rounded,
                    size: 18, color: Color(0xFF059669)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'private',
          child: Row(
            children: [
              const Icon(Icons.school_rounded,
                  size: 20, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.filterPrivate(context),
                  style: TextStyle(
                    fontWeight: _selectedType == 'private'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: AppColors.textMain(context),
                  ),
                ),
              ),
              if (_selectedType == 'private')
                const Icon(Icons.check_rounded,
                    size: 18, color: Color(0xFF8B5CF6)),
            ],
          ),
        ),
      ],
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  typeIcon,
                  size: 18,
                  color: typeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
              ],
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textMuted(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openPostEntity(String type, dynamic entity) {
    if (type == 'university' && entity is University) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              UniversityDetailsScreen(university: entity, initialTabIndex: 0),
        ),
      );
    } else if (type == 'scholarship' && entity is Scholarship) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ScholarshipDetailsScreen(scholarship: entity, initialTabIndex: 0),
        ),
      );
    } else if (type == 'opportunity' && entity is Opportunity) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OpportunityDetailsScreen(opportunity: entity, initialTabIndex: 0),
        ),
      );
    } else if (type == 'training_center' && entity is TrainingCenter) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TrainingCenterDetailsScreen(center: entity, initialTabIndex: 0),
        ),
      );
    }
  }

  Widget _postCard(Map<String, dynamic> item) {
    final post = item['post'] as Post;
    final String type = item['type'] as String;
    final String name = item['name'] as String;
    final String logoUrl = item['logoUrl'] as String;
    final String location = item['location'] as String;
    final String badgeText = item['badgeText'] as String;
    final Color badgeColor = item['badgeColor'] as Color;
    final IconData placeholderIcon = item['placeholderIcon'] as IconData;
    final dynamic entity = item['entity'];

    final postKey = '${name}_${post.title}_${post.date}';
    final isLiked = _likedPostKeys.contains(postKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPostEntity(type, entity),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس المنشور (Header)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    CustomCachedImage(
                      imageUrl: logoUrl,
                      width: 42,
                      height: 42,
                      borderRadius: BorderRadius.circular(21),
                      placeholderIcon: placeholderIcon,
                      iconSize: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (post.date.isNotEmpty) ...[
                                Text(
                                  post.date,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted(context),
                                  ),
                                ),
                                if (location.isNotEmpty)
                                  Text(
                                    ' • ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted(context),
                                    ),
                                  ),
                              ],
                              if (location.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    location,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // عنوان المنشور
              if (post.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
                  child: Text(
                    post.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain(context),
                    ),
                  ),
                ),

              // نص المنشور
              if (post.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                  child: Text(
                    post.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textMain(context).withValues(alpha: 0.9),
                    ),
                  ),
                ),

              // الصورة الكبيرة في وسط المنشور (Large Media Photo)
              if (post.imageUrl.isNotEmpty)
                CustomCachedImage(
                  imageUrl: post.imageUrl,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.image_rounded,
                  iconSize: 36,
                ),

              // شريط الإجراءات السفلي
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _toggleLikePost(postKey),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 19,
                              color: isLiked
                                  ? Colors.red
                                  : AppColors.textMuted(context),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isLiked
                                  ? (AppStrings.isAr(context)
                                      ? 'معجب به'
                                      : 'Liked')
                                  : (AppStrings.isAr(context)
                                      ? 'إعجاب'
                                      : 'Like'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isLiked
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isLiked
                                    ? Colors.red
                                    : AppColors.textMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          AppStrings.viewDetails(context),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          AppStrings.isAr(context)
                              ? Icons.arrow_back_ios_rounded
                              : Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: badgeColor,
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadDefaultData,
        color: AppColors.primaryDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 100,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/home_header.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
                        StreamBuilder<int>(
                          stream: NotificationService().getUnreadCountStream(),
                          builder: (context, snapshot) {
                            final unreadCount = snapshot.data ?? 0;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 15,
                                              minHeight: 15,
                                            ),
                                            child: Text(
                                              unreadCount > 9
                                                  ? '+9'
                                                  : '$unreadCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.enterAverage(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _averageController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: AppColors.textMain(context)),
                  decoration: InputDecoration(
                    hintText: '85.6',
                    hintStyle: TextStyle(color: AppColors.textMuted(context)),
                    filled: true,
                    fillColor: AppColors.inputFill(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // عنوان اختر فرع الدراسة ومقابله زر المحافظة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.selectTrack(context),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    // زر المحافظة (18 محافظة)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showGovernoratePicker,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedCity != 'كافة المحافظات'
                                ? AppColors.primaryDark.withValues(alpha: 0.1)
                                : AppColors.lavenderCard(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedCity != 'كافة المحافظات'
                                  ? AppColors.primaryDark.withValues(alpha: 0.5)
                                  : AppColors.border(context),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: _selectedCity != 'كافة المحافظات'
                                    ? (AppColors.isDark(context)
                                        ? const Color(0xFF38BDF8)
                                        : AppColors.primaryDark)
                                    : AppColors.textMuted(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedCity,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedCity != 'كافة المحافظات'
                                      ? (AppColors.isDark(context)
                                          ? const Color(0xFF38BDF8)
                                          : AppColors.primaryDark)
                                      : AppColors.textMain(context),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 16,
                                color: AppColors.textMuted(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // صف الأزرار المدمجة: الفرع (علمي/أدبي) + النوع (حكومي/أهلي)
                Row(
                  children: [
                    Expanded(
                      child: _buildTrackDropdownButton(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTypeDropdownButton(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _searchColleges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            AppStrings.search(context),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                if (_defaultUniversities.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.availableUniversities(context),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textMain(context),
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToAllResults,
                        child: Text(
                          AppStrings.viewAll(context),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.isDark(context)
                                ? const Color(0xFF38BDF8)
                                : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _defaultUniversities.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final uni = _defaultUniversities[index];
                        return InkWell(
                          onTap: () => _openUniversity(uni),
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 76,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceCard(context),
                                    border: Border.all(
                                      color: AppColors.border(context),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CustomCachedImage(
                                    imageUrl: uni.logoUrl,
                                    width: 56,
                                    height: 56,
                                    borderRadius: BorderRadius.circular(28),
                                    placeholderIcon: Icons.account_balance_rounded,
                                    iconSize: 24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  uni.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain(context),
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                if (_isPostsLoading) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ] else if (_recentPosts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.latestPosts(context),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textMain(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentPosts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _recentPosts[index];
                      return _postCard(item);
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      AppStrings.isAr(context)
                          ? 'لا توجد منشورات متاحة حالياً'
                          : 'No posts available currently',
                      style: TextStyle(color: AppColors.textMuted(context)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
}
}
