import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/university_model.dart';
import '../../models/college_model.dart';
import '../../services/firestore_service.dart';
import '../../services/app_localizations.dart';
import '../../widgets/custom_cached_image.dart';
import 'student_wishlist_screen.dart';
import '../university_details_screen.dart';

enum ChanceLevel {
  high, // فرصة قوية ومضمونة
  medium, // فرصة متقاربة وتنافسية
  low, // فرصة طموحة / موازي ومسائي
}

class AdmissionResultItem {
  final College college;
  final University university;
  final double diff; // studentGpa - collegeMinGpa
  final ChanceLevel level;
  final double matchPercentage;

  AdmissionResultItem({
    required this.college,
    required this.university,
    required this.diff,
    required this.level,
    required this.matchPercentage,
  });
}

class AdmissionChanceScreen extends StatefulWidget {
  final double? initialGpa;
  final String? initialTrack;

  const AdmissionChanceScreen({
    super.key,
    this.initialGpa,
    this.initialTrack,
  });

  @override
  State<AdmissionChanceScreen> createState() => _AdmissionChanceScreenState();
}

class _AdmissionChanceScreenState extends State<AdmissionChanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _gpaController = TextEditingController();

  String _selectedTrack = 'علمي';
  String _selectedCity = 'كافة المحافظات';
  String _selectedUniType = 'all'; // all, government, private

  // درجات إضافية ومفاضلة
  bool _addFirstRoundBonus = false; // +1 دور أول
  bool _addLanguageBonus = false; // + درجات لغة فرنسية/أجنبية
  final double _languageBonusValue = 1.0;
  bool _isMartyrFamily = false; // ذوي الشهداء / القنوات الخاصة

  bool _isLoading = true;
  List<University> _allUniversities = [];
  List<AdmissionResultItem> _results = [];
  ChanceLevel? _activeFilterLevel; // null = all

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

  @override
  void initState() {
    super.initState();
    if (widget.initialGpa != null && widget.initialGpa! > 0) {
      _gpaController.text = widget.initialGpa!.toStringAsFixed(1);
    }
    if (widget.initialTrack != null && widget.initialTrack!.isNotEmpty) {
      _selectedTrack = widget.initialTrack!;
    }
    _fetchUniversities();
  }

  @override
  void dispose() {
    _gpaController.dispose();
    super.dispose();
  }

  Future<void> _fetchUniversities() async {
    setState(() => _isLoading = true);
    try {
      final list = await _firestoreService.fetchUniversitiesOnce();
      if (mounted) {
        setState(() {
          _allUniversities = list;
          _isLoading = false;
        });
        _calculateChances();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _calculatedTotalGpa {
    final rawGpa = double.tryParse(_gpaController.text.trim()) ?? 0.0;
    if (rawGpa <= 0) return 0.0;
    double total = rawGpa;
    if (_addFirstRoundBonus) total += 1.0;
    if (_addLanguageBonus) total += _languageBonusValue;
    return double.parse(total.toStringAsFixed(2));
  }

  void _calculateChances() {
    final effectiveGpa = _calculatedTotalGpa;
    if (effectiveGpa <= 0) {
      setState(() => _results = []);
      return;
    }

    final List<AdmissionResultItem> items = [];

    for (final uni in _allUniversities) {
      // فلترة نوع الجامعة
      if (_selectedUniType == 'government' && uni.type.contains('أهلي')) {
        continue;
      }
      if (_selectedUniType == 'private' && !uni.type.contains('أهلي')) {
        continue;
      }

      // فلترة المحافظة
      if (_selectedCity != 'كافة المحافظات' &&
          !uni.city.contains(_selectedCity) &&
          !_selectedCity.contains(uni.city)) {
        continue;
      }

      for (final college in uni.colleges) {
        if (college.minGpa <= 0) continue;

        // مطابقة الفرع الدراسي
        if (!_matchesTrack(college.category, _selectedTrack)) continue;

        final diff = effectiveGpa - college.minGpa;

        // تصنيف فرصة القبول
        ChanceLevel level;
        double matchScore;

        if (diff >= 1.5) {
          level = ChanceLevel.high;
          matchScore = ((effectiveGpa / college.minGpa) * 100).clamp(90, 99.5);
        } else if (diff >= -1.0) {
          level = ChanceLevel.medium;
          matchScore = (75.0 + (diff * 10)).clamp(60, 89.0);
        } else if (diff >= -5.0) {
          level = ChanceLevel.low;
          matchScore = (50.0 + (diff * 5)).clamp(30, 59.0);
        } else {
          // فارق كبير جداً، لا يضاف
          continue;
        }

        // إذا كانت قنوات خاصة (ذوي شهداء مثلاً)، ترتفع أولوية الكلية
        if (_isMartyrFamily && level == ChanceLevel.low && diff >= -5.0) {
          level = ChanceLevel.medium;
          matchScore += 15.0;
        }

        items.add(
          AdmissionResultItem(
            college: college,
            university: uni,
            diff: diff,
            level: level,
            matchPercentage: matchScore,
          ),
        );
      }
    }

    // ترتيب حسب أفضلية المطابقة
    items.sort((a, b) {
      if (a.level.index != b.level.index) {
        return a.level.index.compareTo(b.level.index);
      }
      return b.diff.compareTo(a.diff);
    });

    setState(() {
      _results = items;
    });
  }

  bool _matchesTrack(String category, String selected) {
    final cat = category.trim().toLowerCase();
    final sel = selected.trim().toLowerCase();
    if (cat.isEmpty || cat.contains('عام') || cat.contains('مشترك')) return true;
    if (sel.contains('علم')) {
      return cat.contains('علم') || cat.contains('احيائ') || cat.contains('تطبيق');
    } else if (sel.contains('ادب')) {
      return cat.contains('ادب');
    }
    return cat.contains(sel);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppStrings.isAr(context);
    final isWide = MediaQuery.of(context).size.width >= 700;
    final totalGpa = _calculatedTotalGpa;

    final highCount = _results.where((r) => r.level == ChanceLevel.high).length;
    final mediumCount =
        _results.where((r) => r.level == ChanceLevel.medium).length;
    final lowCount = _results.where((r) => r.level == ChanceLevel.low).length;

    final filteredResults = _activeFilterLevel == null
        ? _results
        : _results.where((r) => r.level == _activeFilterLevel).toList();

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Text(
            isAr ? 'حاسبة فرص القبول والمفاضلة' : 'Admission Chances & Calculator',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.playlist_add_check_rounded),
              tooltip: isAr ? 'استمارة رغباتي' : 'My Wishlist',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentWishlistScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بطاقة الإدخال والتحكم
                    _buildInputsCard(context, isAr, totalGpa),
                    const SizedBox(height: 18),

                    // شريط إحصائيات الفرص
                    if (totalGpa > 0) ...[
                      _buildSummaryStats(
                        context,
                        isAr,
                        highCount,
                        mediumCount,
                        lowCount,
                      ),
                      const SizedBox(height: 18),
                    ],

                    // تبويبات تصفية النتائج
                    if (_results.isNotEmpty) ...[
                      _buildLevelTabs(
                        context,
                        isAr,
                        highCount,
                        mediumCount,
                        lowCount,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // قائمة النتائج أو رسالة التنبيه
                    if (totalGpa <= 0)
                      _buildEmptyPrompt(context, isAr)
                    else if (filteredResults.isEmpty)
                      _buildNoResults(context, isAr)
                    else
                      isWide
                          ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: filteredResults.length,
                              itemBuilder: (ctx, i) => _buildResultCard(
                                context,
                                filteredResults[i],
                                isAr,
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredResults.length,
                              itemBuilder: (ctx, i) => _buildResultCard(
                                context,
                                filteredResults[i],
                                isAr,
                              ),
                            ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInputsCard(BuildContext context, bool isAr, double totalGpa) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                  color: AppColors.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  color: AppColors.primaryDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'بيانات الطالب والمعدل' : 'Student & GPA Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    Text(
                      isAr
                          ? 'أدخل معدلك وحدد الإضافات لحساب فرص القبول بدقة'
                          : 'Enter GPA & bonuses to calculate exact admission odds',
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
          const SizedBox(height: 16),

          // حقل إدخال المعدل الأساسي
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _gpaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: isAr ? 'المعدل الأساسي' : 'Primary GPA',
                    hintText: 'مثال: 85.5',
                    prefixIcon: const Icon(Icons.grade_rounded),
                    filled: true,
                    fillColor: AppColors.inputFill(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                  onChanged: (_) => _calculateChances(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryDark.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isAr ? 'المعدل المحتسب' : 'Calculated GPA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalGpa > 0 ? totalGpa.toStringAsFixed(2) : '--',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // خيارات الفروع والمحافظة
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTrack,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الفرع' : 'Track',
                    filled: true,
                    fillColor: AppColors.inputFill(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'علمي', child: Text('علمي / أحيائي')),
                    DropdownMenuItem(value: 'تطبيقي', child: Text('تطبيقي')),
                    DropdownMenuItem(value: 'أدبي', child: Text('أدبي')),
                    DropdownMenuItem(value: 'مهني', child: Text('مهني')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTrack = val);
                      _calculateChances();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUniType,
                  decoration: InputDecoration(
                    labelText: isAr ? 'النوع' : 'Type',
                    filled: true,
                    fillColor: AppColors.inputFill(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(isAr ? 'الكل' : 'All'),
                    ),
                    DropdownMenuItem(
                      value: 'government',
                      child: Text(isAr ? 'حكومي' : 'Government'),
                    ),
                    DropdownMenuItem(
                      value: 'private',
                      child: Text(isAr ? 'أهلي' : 'Private'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedUniType = val);
                      _calculateChances();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // المحافظة
          DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            decoration: InputDecoration(
              labelText: isAr ? 'المحافظة المطلوبة' : 'Governorate',
              prefixIcon: const Icon(Icons.location_on_outlined),
              filled: true,
              fillColor: AppColors.inputFill(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
            ),
            items: _iraqGovernorates.map((g) {
              return DropdownMenuItem(value: g, child: Text(g));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedCity = val);
                _calculateChances();
              }
            },
          ),
          const SizedBox(height: 14),

          // خيارات درجات الإضافة والمفاضلة
          Text(
            isAr ? 'درجات الإضافة والمفاضلة الوزارية:' : 'Bonus & Quota Points:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain(context),
            ),
          ),
          const SizedBox(height: 6),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: _addFirstRoundBonus,
                label: Text(isAr ? 'درجة الدور الأول (+1)' : 'Round 1 (+1)'),
                avatar: const Icon(Icons.star_rounded, size: 16),
                onSelected: (val) {
                  setState(() => _addFirstRoundBonus = val);
                  _calculateChances();
                },
              ),
              FilterChip(
                selected: _addLanguageBonus,
                label: Text(
                  isAr ? 'درجة لغة فرنسية/أجنبية (+1)' : 'Foreign Lang (+1)',
                ),
                avatar: const Icon(Icons.translate_rounded, size: 16),
                onSelected: (val) {
                  setState(() => _addLanguageBonus = val);
                  _calculateChances();
                },
              ),
              FilterChip(
                selected: _isMartyrFamily,
                label: Text(isAr ? 'قناة ذوي الشهداء' : 'Special Quota'),
                avatar: const Icon(Icons.shield_outlined, size: 16),
                onSelected: (val) {
                  setState(() => _isMartyrFamily = val);
                  _calculateChances();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(
    BuildContext context,
    bool isAr,
    int high,
    int medium,
    int low,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBadge(
            context,
            title: isAr ? 'فرصة قوية' : 'High Chance',
            count: high,
            color: const Color(0xFF10B981),
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatBadge(
            context,
            title: isAr ? 'تنافسية' : 'Competitive',
            count: medium,
            color: const Color(0xFFF59E0B),
            icon: Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatBadge(
            context,
            title: isAr ? 'طموحة / موازي' : 'Ambitious',
            count: low,
            color: const Color(0xFFEF4444),
            icon: Icons.trending_up_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTabs(
    BuildContext context,
    bool isAr,
    int high,
    int medium,
    int low,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(isAr ? "الكل" : "All"),
            selected: _activeFilterLevel == null,
            onSelected: (val) {
              if (val) setState(() => _activeFilterLevel = null);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(
              isAr ? "🟢 فرصة قوية" : "🟢 High",
            ),
            selected: _activeFilterLevel == ChanceLevel.high,
            onSelected: (val) {
              if (val) setState(() => _activeFilterLevel = ChanceLevel.high);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(
              isAr ? "🟡 تنافسية" : "🟡 Competitive",
            ),
            selected: _activeFilterLevel == ChanceLevel.medium,
            onSelected: (val) {
              if (val) setState(() => _activeFilterLevel = ChanceLevel.medium);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(
              isAr ? "🔴 طموحة/موازي" : "🔴 Ambitious",
            ),
            selected: _activeFilterLevel == ChanceLevel.low,
            onSelected: (val) {
              if (val) setState(() => _activeFilterLevel = ChanceLevel.low);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    AdmissionResultItem item,
    bool isAr,
  ) {
    Color levelColor;
    String levelText;

    switch (item.level) {
      case ChanceLevel.high:
        levelColor = const Color(0xFF10B981);
        levelText = isAr ? 'فرصة قوية ومضمونة' : 'Strong Chance';
        break;
      case ChanceLevel.medium:
        levelColor = const Color(0xFFF59E0B);
        levelText = isAr ? 'فرصة تنافسية متقاربة' : 'Competitive';
        break;
      case ChanceLevel.low:
        levelColor = const Color(0xFFEF4444);
        levelText = isAr ? 'طموحة / تتطلب موازي ومسائي' : 'Ambitious / Parallel';
        break;
    }

    final diffText = item.diff >= 0
        ? '+${item.diff.toStringAsFixed(1)}'
        : item.diff.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomCachedImage(
                imageUrl: item.university.logoUrl,
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(18),
                placeholderIcon: Icons.school_rounded,
                iconSize: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.college.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.university.name} • ${item.university.city}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: levelColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  levelText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // خط مؤشر التوافق
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (item.matchPercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.border(context),
                    color: levelColor,
                    minHeight: 7,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${item.matchPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // مقارنة المعدلات وأزرار الإجراء
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isAr ? "الحد الأدنى:" : "Min GPA:"} ${item.college.minGpa} ($diffText)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted(context),
                ),
              ),
              Row(
                children: [
                  // إضافة للرغبات
                  IconButton(
                    icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                    tooltip: isAr ? 'إضافة إلى رغباتي' : 'Add to Wishlist',
                    color: AppColors.primaryDark,
                    onPressed: () async {
                      await StudentWishlistService.addChoice(
                        collegeName: item.college.name,
                        universityName: item.university.name,
                        minGpa: item.college.minGpa,
                        city: item.university.city,
                        type: item.university.type,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تمت إضافة ${item.college.name} إلى استمارة رغباتك'
                                  : 'Added to your wishlist',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  // تفاصيل الجامعة
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    tooltip: isAr ? 'صفحة الجامعة' : 'University details',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UniversityDetailsScreen(
                            university: item.university,
                            initialTabIndex: 1,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt(BuildContext context, bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 56,
              color: AppColors.textMuted(context).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'أدخل معدلك أعلاه لعرض الكليات وفرص القبول المتاحة'
                  : 'Enter your GPA above to see college admission odds',
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

  Widget _buildNoResults(BuildContext context, bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.textMuted(context).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'لم يتم العثور على كليات مطابقة لمعايير البحث الحالية'
                  : 'No colleges match your current criteria',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
