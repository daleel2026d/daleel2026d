import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/university_model.dart';
import '../models/college_with_university.dart';
import '../widgets/university_card.dart';
import '../widgets/matched_college_card.dart';
import '../main.dart';
import 'login_screen.dart';
import 'university_details_screen.dart';

class _FilterOption {
  final String value;
  final String labelAr;
  final String labelEn;

  const _FilterOption({
    required this.value,
    required this.labelAr,
    required this.labelEn,
  });

  String getLabel(BuildContext context) =>
      AppStrings.isAr(context) ? labelAr : labelEn;
}

class UniversitiesScreen extends StatefulWidget {
  final String? track;
  final double? studentAverage;
  final String? initialUniversityType;
  final String? initialCity;

  const UniversitiesScreen({
    super.key,
    this.track,
    this.studentAverage,
    this.initialUniversityType,
    this.initialCity,
  });

  @override
  State<UniversitiesScreen> createState() => _UniversitiesScreenState();
}

class _UniversitiesScreenState extends State<UniversitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  List<String> _favoriteIds = [];
  late String _selectedUniversityFilter;
  late String _selectedCityFilter;
  String _searchQuery = '';

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

  final List<_FilterOption> _filterOptions = const [
    _FilterOption(value: 'all', labelAr: 'الكل', labelEn: 'All'),
    _FilterOption(value: 'private', labelAr: 'أهلية', labelEn: 'Private'),
    _FilterOption(value: 'government', labelAr: 'حكومية', labelEn: 'Government'),
  ];

  bool get _isFilterMode =>
      widget.track != null &&
      widget.track!.isNotEmpty &&
      widget.studentAverage != null;

  @override
  void initState() {
    super.initState();
    _selectedUniversityFilter = widget.initialUniversityType ?? 'all';
    _selectedCityFilter = widget.initialCity ?? 'كافة المحافظات';
    _listenToFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _listenToFavorites() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _firestoreService.getUserData(uid).listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(
          () => _favoriteIds = List<String>.from(data['favorites'] ?? []),
        );
      }
    });
  }

  Future<void> _toggleFavorite(String universityId) async {
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
          action: SnackBarAction(
            label: AppStrings.login(context),
            textColor: Colors.amberAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }
    final isFav = _favoriteIds.contains(universityId);

    setState(() {
      if (isFav) {
        _favoriteIds.remove(universityId);
      } else {
        _favoriteIds.add(universityId);
      }
    });

    try {
      await _firestoreService.toggleFavorite(uid, universityId, isFav);
    } catch (_) {
      if (mounted) {
        setState(() {
          if (isFav) {
            _favoriteIds.add(universityId);
          } else {
            _favoriteIds.remove(universityId);
          }
        });
      }
    }
  }

  bool _matchesUniversityFilter(University university) {
    // 1. فلتر نوع الجامعة
    final normalizedType = university.type.trim().toLowerCase();

    bool typeMatches = true;
    switch (_selectedUniversityFilter) {
      case 'government':
        typeMatches = normalizedType.contains('حك') ||
            normalizedType.contains('government') ||
            normalizedType.contains('gov');
        break;
      case 'private':
        typeMatches = normalizedType.contains('أهل') ||
            normalizedType.contains('اهل') ||
            normalizedType.contains('خاص') ||
            normalizedType.contains('private') ||
            normalizedType.contains('priv');
        break;
      case 'all':
      default:
        typeMatches = true;
    }

    if (!typeMatches) return false;

    // 2. فلتر المحافظة
    if (_selectedCityFilter.isNotEmpty &&
        _selectedCityFilter != 'كافة المحافظات' &&
        _selectedCityFilter != 'جميع المحافظات' &&
        _selectedCityFilter.toLowerCase() != 'all') {
      final normUniCity = university.city.trim().toLowerCase();
      final normCity = _selectedCityFilter.trim().toLowerCase();
      if (!normUniCity.contains(normCity) && !normCity.contains(normUniCity)) {
        return false;
      }
    }

    // 3. فلتر البحث النصي
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      final nameMatches = university.name.toLowerCase().contains(q);
      final cityMatches = university.city.toLowerCase().contains(q);
      final collegeMatches = university.colleges.any((c) =>
          c.name.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q));
      if (!nameMatches && !cityMatches && !collegeMatches) {
        return false;
      }
    }

    return true;
  }

  void _showCityPicker() {
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
                        final isSelected = _selectedCityFilter == gov;
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
                            gov == 'كافة المحافظات' ? 'جميع المحافظات' : gov,
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
                            setState(() => _selectedCityFilter = gov);
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

  // شريط البحث: خانة البحث على اليمين، وزر "مركز البحث" على اليسار
  Widget _buildSearchBar(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isAr = AppStrings.isAr(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // 1. يظهر على اليمين: خانة البحث
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(
                    color: AppColors.textMain(context),
                    fontSize: 12.5,
                  ),
                  decoration: InputDecoration(
                    hintText: isAr
                        ? 'ابحث عن جامعة أو تخصص...'
                        : 'Search university or major...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF94A3B8),
                      fontSize: 11.5,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    border: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : Icon(
                            Icons.search_rounded,
                            color: isDark
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF0284C7),
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 2. يظهر على اليسار: زر "مركز البحث"
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showCityPicker,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAr ? 'مركز البحث' : 'Search Hub',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // أزرار الفلترة المنحنية مع ظهور زر "جميع المحافظات" بجانب أزرار (الكل، أهلية، حكومية)
  Widget _buildUniversityFilterBar() {
    final isDark = AppColors.isDark(context);
    final isAr = AppStrings.isAr(context);

    final isCityActive = _selectedCityFilter != 'كافة المحافظات' &&
        _selectedCityFilter != 'جميع المحافظات';

    final cityLabel = !isCityActive
        ? (isAr ? 'جميع المحافظات' : 'All Governorates')
        : _selectedCityFilter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          // أزرار (الكل، أهلية، حكومية) بتصميم منحني وكبسولي
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: _filterOptions.map((option) {
                  final isSelected =
                      _selectedUniversityFilter == option.value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _selectedUniversityFilter = option.value),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryDark
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          option.getLabel(context),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMain(context),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // زر المحافظة المنحني المكتوب عليه "جميع المحافظات" بجانب الأزرار
          InkWell(
            onTap: _showCityPicker,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isCityActive
                    ? AppColors.primaryDark.withValues(alpha: 0.1)
                    : AppColors.surfaceCard(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCityActive
                      ? AppColors.primaryDark.withValues(alpha: 0.5)
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: isCityActive
                        ? (isDark
                            ? const Color(0xFF38BDF8)
                            : AppColors.primaryDark)
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 95),
                    child: Text(
                      cityLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCityActive
                            ? (isDark
                                ? const Color(0xFF38BDF8)
                                : AppColors.primaryDark)
                            : AppColors.textMain(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        // شريط علوي نظيف ومكتوب عليه "الجامعات" على اليمين فقط
        appBar: AppBar(
          title: Align(
            alignment: Alignment.centerRight,
            child: Text(
              AppStrings.isAr(context) ? 'الجامعات' : 'Universities',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: AppColors.textMain(context),
              ),
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.surfaceCard(context),
          foregroundColor: AppColors.textMain(context),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: _isFilterMode
            ? _buildFilteredCollegesView()
            : _buildBrowseAllUniversitiesView(),
      ),
    );
  }

  // عرض جميع الجامعات
  Widget _buildBrowseAllUniversitiesView() {
    return Column(
      children: [
        // 1. شريط البحث (زر مركز البحث على اليمين وخانة البحث على اليسار)
        _buildSearchBar(context),

        // 2. أزرار الفلترة المنحنية مع زر "جميع المحافظات" بجانبها
        _buildUniversityFilterBar(),

        // 3. شبكة كروت الجامعات (عرض جميع الجامعات)
        Expanded(
          child: StreamBuilder<List<University>>(
            stream: _firestoreService.getAllUniversities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryDark),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '${snapshot.error}',
                    style: TextStyle(color: AppColors.textMain(context)),
                  ),
                );
              }

              final universities = snapshot.data ?? [];
              if (universities.isEmpty) {
                return Center(
                  child: Text(
                    AppStrings.isAr(context)
                        ? 'لا توجد جامعات مضافة حالياً'
                        : 'No universities added currently',
                    style: TextStyle(color: AppColors.textMuted(context)),
                  ),
                );
              }

              final filteredUniversities =
                  universities.where(_matchesUniversityFilter).toList();

              if (filteredUniversities.isEmpty) {
                return Center(
                  child: Text(
                    AppStrings.noUniversitiesFound(context),
                    style: TextStyle(color: AppColors.textMuted(context)),
                  ),
                );
              }

              // عرض جميع الجامعات المطابقة
              final displayedUniversities = filteredUniversities;
              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
              final childAspectRatio = screenWidth > 900 ? 0.85 : (screenWidth > 600 ? 0.83 : 0.81);

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: displayedUniversities.length,
                itemBuilder: (context, index) {
                  final uni = displayedUniversities[index];
                  return UniversityCard(
                    university: uni,
                    isFavorite: _favoriteIds.contains(uni.id),
                    onFavoriteTap: () => _toggleFavorite(uni.id),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UniversityDetailsScreen(university: uni),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // عرض الكليات المطابقة للمعدل
  Widget _buildFilteredCollegesView() {
    return Column(
      children: [
        _buildUniversityFilterBar(),
        Expanded(
          child: FutureBuilder<List<CollegeWithUniversity>>(
            future: _firestoreService.getMatchingColleges(
              widget.track!,
              widget.studentAverage!,
              universityType: _selectedUniversityFilter,
              city: _selectedCityFilter,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryDark),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '${snapshot.error}',
                    style: TextStyle(color: AppColors.textMain(context)),
                  ),
                );
              }

              final matches = snapshot.data ?? [];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  AppColors.primaryDark.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.school_rounded,
                                size: 16,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.track} • ${widget.studentAverage}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${matches.length} ${AppStrings.isAr(context) ? "كلية مطابقة" : "matching colleges"}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (matches.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: AppColors.textMuted(context),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppStrings.noCollegesFound(context),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final item = matches[index];
                          return MatchedCollegeCard(
                            item: item,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UniversityDetailsScreen(
                                  university: item.university,
                                  initialTabIndex: 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
