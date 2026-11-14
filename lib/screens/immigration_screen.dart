import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/immigration_country_model.dart';
import '../services/app_localizations.dart';

class ImmigrationScreen extends StatefulWidget {
  const ImmigrationScreen({super.key});

  @override
  State<ImmigrationScreen> createState() => _ImmigrationScreenState();
}

class _ImmigrationScreenState extends State<ImmigrationScreen> {
  final List<ImmigrationCountry> _allCountries =
      ImmigrationCountry.getAllCountries();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _gpaInputController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'ausbildung', 'points', 'skilled', 'nomad'
  String _selectedGpaFilter = 'all'; // 'all', '60', '65', '70'
  double? _userGpa;
  bool _onlyShowMatchingUserGpa = false;

  @override
  void dispose() {
    _searchController.dispose();
    _gpaInputController.dispose();
    super.dispose();
  }

  List<ImmigrationCountry> get _filteredCountries {
    return _allCountries.where((country) {
      // 1. تصفية البحث النصي (الاسم العربي، الإنجليزي، البرامج، التخصصات)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchName = country.nameAr.toLowerCase().contains(q) ||
            country.nameEn.toLowerCase().contains(q);
        final matchCategory = country.categoryAr.toLowerCase().contains(q);
        final matchFields = country.inDemandFields.any(
          (f) => f.toLowerCase().contains(q),
        );
        final matchPrograms = country.mainPrograms.any(
          (p) => p.toLowerCase().contains(q),
        );

        if (!matchName && !matchCategory && !matchFields && !matchPrograms) {
          return false;
        }
      }

      // 2. تصفية التصنيف / نوع البرنامج
      if (_selectedCategory != 'all') {
        if (country.categoryTag != _selectedCategory) {
          return false;
        }
      }

      // 3. تصفية الحد الأدنى للمعدل الثابت
      if (_selectedGpaFilter == '60' && country.minRequiredGpa > 60.0) {
        return false;
      }
      if (_selectedGpaFilter == '65' && country.minRequiredGpa > 65.0) {
        return false;
      }
      if (_selectedGpaFilter == '70' && country.minRequiredGpa > 70.0) {
        return false;
      }

      // 4. تصفية مطابقة معدل المستخدم المدخل
      if (_onlyShowMatchingUserGpa && _userGpa != null) {
        if (_userGpa! < country.minRequiredGpa) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _applyUserGpa() {
    final text = _gpaInputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _userGpa = null;
        _onlyShowMatchingUserGpa = false;
      });
      return;
    }

    final parsed = double.tryParse(text);
    if (parsed != null && parsed >= 0 && parsed <= 100) {
      setState(() {
        _userGpa = parsed;
        _onlyShowMatchingUserGpa = true;
      });
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.isAr(context)
                ? 'يرجى إدخال معدل صحيح بين 50 و 100'
                : 'Please enter a valid average between 50 and 100',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearUserGpa() {
    setState(() {
      _userGpa = null;
      _onlyShowMatchingUserGpa = false;
      _gpaInputController.clear();
    });
  }

  Future<void> _launchPortalUrl(String urlStr) async {
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.isAr(context)
                  ? 'تعذر فتح الرابط الرسمي حالياً'
                  : 'Could not open official portal link',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final filtered = _filteredCountries;

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flight_takeoff_rounded, size: 22),
              const SizedBox(width: 8),
              Text(
                AppStrings.isAr(context)
                    ? 'دليل الهجرة الدولي'
                    : 'Global Immigration Guide',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: CustomScrollView(
          slivers: [
            // 1. بطاقة الهيدر الترحيبية ومطابقة المعدل
            SliverToBoxAdapter(
              child: _buildHeaderCard(context, isDark),
            ),

            // 2. شريط البحث
            SliverToBoxAdapter(
              child: _buildSearchBar(context, isDark),
            ),

            // 3. أزرار تصفية البرامج والتصنيفات
            SliverToBoxAdapter(
              child: _buildFilterChips(context, isDark),
            ),

            // 4. شريط عدد النتائج وحالة المطابقة
            SliverToBoxAdapter(
              child: _buildResultsSummaryBar(context, filtered.length),
            ),

            // 5. قائمة بطاقات الدول
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(context),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final country = filtered[index];
                      return _buildCountryCard(context, country, isDark);
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 1. بطاقة الهيدر الترحيبية وحاسبة مطابقة المعدل =====
  Widget _buildHeaderCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.isAr(context)
                          ? 'الدول التي تطلب مهاجرين'
                          : 'Countries Seeking Immigrants',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.isAr(context)
                          ? 'استكشف شروط القبول والمعدل المطلوب والمهن الشحيحة'
                          : 'Explore minimum required GPA, pathways & in-demand jobs',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // حاسبة مطابقة المعدل الفوري
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0B1120).withValues(alpha: 0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryDark,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.isAr(context)
                          ? 'فحص مطابقة معدلك مع الدول:'
                          : 'Check countries matching your GPA:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _gpaInputController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: AppStrings.isAr(context)
                                ? 'مثال: 75.5'
                                : 'e.g. 75.5',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade100,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _applyUserGpa(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyUserGpa,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppStrings.isAr(context) ? 'مطابقة' : 'Match',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    if (_userGpa != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: _clearUserGpa,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: AppStrings.isAr(context)
                            ? 'إلغاء التصفية بالمعدل'
                            : 'Clear GPA Filter',
                        color: Colors.redAccent,
                      ),
                    ],
                  ],
                ),
                if (_userGpa != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppStrings.isAr(context)
                                ? 'معدلك (${_userGpa!.toStringAsFixed(1)}%) مؤهل لـ ${_filteredCountries.length} دولة معروضة أدناه!'
                                : 'Your GPA (${_userGpa!.toStringAsFixed(1)}%) qualifies for ${_filteredCountries.length} countries below!',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== 2. شريط البحث =====
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: AppColors.textMain(context),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.isAr(context)
              ? 'ابحث باسم الدولة، التخصص المطلوب، أو البرنامج...'
              : 'Search country, profession, or program...',
          hintStyle: TextStyle(
            color: AppColors.textMuted(context),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textMuted(context),
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceCard(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  // ===== 3. رقائق التصفية السريعة (برامج ومعدلات) =====
  Widget _buildFilterChips(BuildContext context, bool isDark) {
    final categories = [
      {'id': 'all', 'label': AppStrings.isAr(context) ? 'جميع الدول' : 'All Countries'},
      {'id': 'ausbildung', 'label': AppStrings.isAr(context) ? 'تدريب مهني (أوسبيلدونغ)' : 'Vocational (Ausbildung)'},
      {'id': 'points', 'label': AppStrings.isAr(context) ? 'نظام النقاط' : 'Points System'},
      {'id': 'skilled', 'label': AppStrings.isAr(context) ? 'عمالة ماهرة وعقود' : 'Skilled Workers'},
      {'id': 'nomad', 'label': AppStrings.isAr(context) ? 'الرحالة الرقمي (عن بعد)' : 'Digital Nomad'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // تصنيف البرامج
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat['id'];
              return ChoiceChip(
                label: Text(cat['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? cat['id']! : 'all';
                  });
                },
                selectedColor: const Color(0xFF1E3A8A),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : AppColors.textDark),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                backgroundColor: AppColors.surfaceCard(context),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF1E3A8A)
                      : AppColors.border(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
              );
            },
          ),
        ),

        // تصفية سريعة بالحد الأدنى للمعدل
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              Text(
                AppStrings.isAr(context) ? 'الحد الأدنى:' : 'Min GPA:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted(context),
                ),
              ),
              const SizedBox(width: 8),
              _buildGpaPill('all', AppStrings.isAr(context) ? 'الكل' : 'All'),
              const SizedBox(width: 6),
              _buildGpaPill('60', '60%+'),
              const SizedBox(width: 6),
              _buildGpaPill('65', '65%+'),
              const SizedBox(width: 6),
              _buildGpaPill('70', '70%+'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGpaPill(String id, String label) {
    final isSelected = _selectedGpaFilter == id;
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: () => setState(() => _selectedGpaFilter = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.textDark),
          ),
        ),
      ),
    );
  }

  // ===== 4. شريط عدد النتائج وحالة الفلترة =====
  Widget _buildResultsSummaryBar(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.isAr(context)
                ? 'الدول المتاحة ($count دولة)'
                : 'Available Countries ($count)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain(context),
            ),
          ),
          if (_userGpa != null || _selectedCategory != 'all' || _selectedGpaFilter != 'all')
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedCategory = 'all';
                  _selectedGpaFilter = 'all';
                  _userGpa = null;
                  _onlyShowMatchingUserGpa = false;
                  _gpaInputController.clear();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: Text(
                AppStrings.isAr(context) ? 'إعادة ضبط' : 'Reset',
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  // ===== 5. بطاقة الدولة الفردية =====
  Widget _buildCountryCard(
    BuildContext context,
    ImmigrationCountry country,
    bool isDark,
  ) {
    final bool isUserQualified = _userGpa != null && _userGpa! >= country.minRequiredGpa;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUserQualified
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : AppColors.border(context),
          width: isUserQualified ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showCountryDetailsSheet(context, country, isDark),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الصف العلوي: علم الدولة + الاسم + بادج المعدل المطلوب
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // علم الدولة
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Text(
                        country.flag,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // اسم الدولة ونوع البرنامج
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                country.nameAr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.5,
                                  color: AppColors.textMain(context),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                country.nameEn,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            country.categoryAr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // شارة المعدل المطلوب
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUserQualified
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFEEF2FF)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUserQualified
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6366F1).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isUserQualified
                                    ? Icons.check_circle_rounded
                                    : Icons.school_rounded,
                                size: 13,
                                color: isUserQualified
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF4F46E5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.isAr(context) ? 'المعدل' : 'GPA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isUserQualified
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${country.minRequiredGpa.toInt()}%+',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isUserQualified
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // تفاصيل المعدل المطلوب وشرحه
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2563EB),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          country.gpaDetailsAr,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? Colors.white70 : AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // شبكة المعايير الأساسية (اللغة، الإثبات المالي، المعالجة، مستوى الصعوبة)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      icon: Icons.language_rounded,
                      label: country.languageRequirementAr,
                      context: context,
                      isDark: isDark,
                    ),
                    _buildInfoChip(
                      icon: Icons.account_balance_wallet_outlined,
                      label: country.financialProofAr,
                      context: context,
                      isDark: isDark,
                    ),
                    _buildInfoChip(
                      icon: Icons.timer_outlined,
                      label: country.processingTimeAr,
                      context: context,
                      isDark: isDark,
                    ),
                    _buildDifficultyChip(country.difficultyAr, country.difficultyColor),
                  ],
                ),
                const SizedBox(height: 14),

                // أهم التخصصات والمهن المطلوبة
                Text(
                  AppStrings.isAr(context)
                      ? 'أبرز المهن والتخصصات المطلوبة:'
                      : 'In-demand fields & jobs:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted(context),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: country.inDemandFields.take(4).map((field) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        field,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // أزرار التفاعل: عرض التفاصيل + البوابة الرسمية
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCountryDetailsSheet(context, country, isDark),
                        icon: const Icon(Icons.menu_book_rounded, size: 16),
                        label: Text(
                          AppStrings.isAr(context)
                              ? 'الشروط والتفاصيل الكاملة'
                              : 'Full Requirements',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _launchPortalUrl(country.officialPortalUrl),
                        icon: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: Text(
                          AppStrings.isAr(context) ? 'البوابة الرسمية' : 'Official Portal',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.border(context)),
                          foregroundColor: isDark ? Colors.white70 : AppColors.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required BuildContext context,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted(context)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white70 : AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textMuted(context),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.isAr(context)
                ? 'لم يتم العثور على دول تطابق معايير البحث'
                : 'No countries match your search criteria',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.isAr(context)
                ? 'جرب تقليل المعدل المطلوب أو كتابة اسم دولة أو تخصص آخر'
                : 'Try lowering the required GPA or searching for another keyword',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===== 6. النافذة السفلية الكاملة لتفاصيل وشروط الدولة =====
  void _showCountryDetailsSheet(
    BuildContext context,
    ImmigrationCountry country,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: AppStrings.direction(context),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // المقبض العلوي
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // المحتوى القابل للتمرير
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                        children: [
                          // رأس الدولة (العلم والاسم والبرامج)
                          Row(
                            children: [
                              Text(
                                country.flag,
                                style: const TextStyle(fontSize: 38),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${country.nameAr} (${country.nameEn})',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMain(context),
                                      ),
                                    ),
                                    Text(
                                      country.categoryAr,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF1E3A8A)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      AppStrings.isAr(context) ? 'المعدل المطلوب' : 'Min GPA',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      country.gpaLabelAr,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // نبذة تعريفية
                          Text(
                            country.overviewAr,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: isDark ? Colors.white70 : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // تفاصيل المعدل المطلوب للأقسام الأكاديمية
                          _buildSectionTitle(
                            context: context,
                            icon: Icons.school_rounded,
                            title: AppStrings.isAr(context)
                                ? 'تفاصيل المعدل المطلوب ومعادلة المؤهل'
                                : 'GPA & Qualification Details',
                          ),
                          const SizedBox(height: 8),
                          _buildBoxContainer(
                            context: context,
                            isDark: isDark,
                            child: Text(
                              country.gpaDetailsAr,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: isDark ? Colors.white : AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // أبرز برامج وتأشيرات الهجرة
                          _buildSectionTitle(
                            context: context,
                            icon: Icons.assignment_outlined,
                            title: AppStrings.isAr(context)
                                ? 'أهم برامج وتأشيرات الهجرة المتاحة'
                                : 'Key Immigration Programs',
                          ),
                          const SizedBox(height: 8),
                          ...country.mainPrograms.map((prog) => _buildCheckItem(context, prog, isDark)),
                          const SizedBox(height: 20),

                          // خطوات الهجرة خطوة بخطوة
                          _buildSectionTitle(
                            context: context,
                            icon: Icons.alt_route_rounded,
                            title: AppStrings.isAr(context)
                                ? 'خارطة طريق الهجرة والحصول على الإقامة'
                                : 'Step-by-Step Immigration Roadmap',
                          ),
                          const SizedBox(height: 10),
                          for (int i = 0; i < country.stepByStepPathways.length; i++)
                            _buildStepItem(context, i + 1, country.stepByStepPathways[i], isDark),
                          const SizedBox(height: 20),

                          // التخصصات والمهن الشحيحة المطلوبة
                          _buildSectionTitle(
                            context: context,
                            icon: Icons.work_outline_rounded,
                            title: AppStrings.isAr(context)
                                ? 'التخصصات والمهن الأكثر طلباً'
                                : 'Most In-Demand Professions',
                          ),
                          const SizedBox(height: 8),
                          _buildBoxContainer(
                            context: context,
                            isDark: isDark,
                            child: Column(
                              children: country.inDemandFields.map((field) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 7, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          field,
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // الشروط والمستمسكات الأساسية
                          _buildSectionTitle(
                            context: context,
                            icon: Icons.checklist_rounded,
                            title: AppStrings.isAr(context)
                                ? 'الشروط والمستمسكات المطلوبة للتقديم'
                                : 'Required Documents & Criteria',
                          ),
                          const SizedBox(height: 8),
                          ...country.requirements.map((req) => _buildCheckItem(context, req, isDark)),
                          const SizedBox(height: 20),

                          // مميزات الهجرة لهذه الدولة
                          _buildSectionTitle(
                            context: context,
                            icon: Icons.card_giftcard_rounded,
                            title: AppStrings.isAr(context)
                                ? 'مميزات العيش والإقامة الدائمة'
                                : 'Benefits of PR & Living',
                          ),
                          const SizedBox(height: 8),
                          ...country.benefits.map((ben) => _buildCheckItem(context, ben, isDark, isGreen: true)),
                          const SizedBox(height: 20),

                          // النصيحة الذهبية
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_rounded,
                                  color: Color(0xFFD97706),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    country.adviceAr,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // زر الانتقال للموقع الرسمي
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => _launchPortalUrl(country.officialPortalUrl),
                              icon: const Icon(Icons.open_in_browser_rounded, size: 20),
                              label: Text(
                                AppStrings.isAr(context)
                                    ? 'الدخول إلى بوابة الهجرة الرسمية لـ ${country.nameAr}'
                                    : 'Visit ${country.nameEn} Official Immigration Portal',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle({
    required BuildContext context,
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E3A8A), size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBoxContainer({
    required BuildContext context,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: child,
    );
  }

  Widget _buildCheckItem(
    BuildContext context,
    String text,
    bool isDark, {
    bool isGreen = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isGreen ? Icons.star_rounded : Icons.check_circle_outline_rounded,
            size: 17,
            color: isGreen ? const Color(0xFF10B981) : const Color(0xFF2563EB),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    int stepNumber,
    String stepText,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stepText,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

