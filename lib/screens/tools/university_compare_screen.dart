import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../models/university_model.dart';
import '../../models/college_model.dart';
import '../../services/firestore_service.dart';
import '../../services/app_localizations.dart';
import '../../widgets/custom_cached_image.dart';
import '../university_details_screen.dart';

class SelectedCollegeSlot {
  final University university;
  final College college;

  SelectedCollegeSlot({required this.university, required this.college});
}

class UniversityCompareScreen extends StatefulWidget {
  final College? preselectedCollege1;
  final University? preselectedUni1;
  final College? preselectedCollege2;
  final University? preselectedUni2;

  const UniversityCompareScreen({
    super.key,
    this.preselectedCollege1,
    this.preselectedUni1,
    this.preselectedCollege2,
    this.preselectedUni2,
  });

  @override
  State<UniversityCompareScreen> createState() =>
      _UniversityCompareScreenState();
}

class _UniversityCompareScreenState extends State<UniversityCompareScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  SelectedCollegeSlot? _slot1;
  SelectedCollegeSlot? _slot2;
  bool _isLoading = true;
  List<University> _allUniversities = [];

  final TextEditingController _studentGpaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCollege1 != null && widget.preselectedUni1 != null) {
      _slot1 = SelectedCollegeSlot(
        university: widget.preselectedUni1!,
        college: widget.preselectedCollege1!,
      );
    }
    if (widget.preselectedCollege2 != null && widget.preselectedUni2 != null) {
      _slot2 = SelectedCollegeSlot(
        university: widget.preselectedUni2!,
        college: widget.preselectedCollege2!,
      );
    }
    _loadData();
  }

  @override
  void dispose() {
    _studentGpaController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final list = await _firestoreService.fetchUniversitiesOnce();
      if (mounted) {
        setState(() {
          _allUniversities = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _swapSlots() {
    setState(() {
      final temp = _slot1;
      _slot1 = _slot2;
      _slot2 = temp;
    });
  }

  void _showCollegePicker(int slotNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CollegePickerSheet(
        universities: _allUniversities,
        onSelect: (uni, college) {
          setState(() {
            if (slotNumber == 1) {
              _slot1 = SelectedCollegeSlot(university: uni, college: college);
            } else {
              _slot2 = SelectedCollegeSlot(university: uni, college: college);
            }
          });
        },
      ),
    );
  }

  void _copyComparison(bool isAr) {
    if (_slot1 == null || _slot2 == null) return;
    final text = StringBuffer();
    text.writeln(isAr ? '⚖️ مقارنة أكاديمية من تطبيق دليل مستقبلي' : '⚖️ Academic Comparison');
    text.writeln('-----------------------------------');
    text.writeln('${_slot1!.college.name} (${_slot1!.university.name})');
    text.writeln('  • ${isAr ? "المحافظة:" : "City:"} ${_slot1!.university.city}');
    text.writeln('  • ${isAr ? "النوع:" : "Type:"} ${_slot1!.university.type}');
    text.writeln('  • ${isAr ? "الحد الأدنى:" : "Min GPA:"} ${_slot1!.college.minGpa}');
    text.writeln('-----------------------------------');
    text.writeln('${_slot2!.college.name} (${_slot2!.university.name})');
    text.writeln('  • ${isAr ? "المحافظة:" : "City:"} ${_slot2!.university.city}');
    text.writeln('  • ${isAr ? "النوع:" : "Type:"} ${_slot2!.university.type}');
    text.writeln('  • ${isAr ? "الحد الأدنى:" : "Min GPA:"} ${_slot2!.college.minGpa}');

    Clipboard.setData(ClipboardData(text: text.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم نسخ ملخص المقارنة إلى الحافظة'
              : 'Comparison summary copied to clipboard',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppStrings.isAr(context);
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Text(
            isAr ? 'مقارنة الجامعات والكليات' : 'Compare Universities & Colleges',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          actions: [
            if (_slot1 != null && _slot2 != null)
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: isAr ? 'مشاركة المقارنة' : 'Share Comparison',
                onPressed: () => _copyComparison(isAr),
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
                    // بطاقة تعليمات سريعة
                    _buildTopBanner(context, isAr),
                    const SizedBox(height: 16),

                    // بطاقتي الاختيار والمبادلة
                    _buildSelectionRow(context, isAr),
                    const SizedBox(height: 20),

                    // جدول المقارنة التفصيلي
                    if (_slot1 != null && _slot2 != null) ...[
                      _buildComparisonTable(context, isAr),
                      const SizedBox(height: 20),
                      _buildRecommendationCard(context, isAr),
                    ] else ...[
                      _buildEmptyState(context, isAr),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopBanner(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.compare_arrows_rounded,
            color: AppColors.primaryDark,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAr
                  ? 'اختر كليتين لمقارنة معدلات القبول، الأقساط، والموقع الجغرافي جنباً إلى جنب لمساعدتك في اتخاذ القرار الأنسب.'
                  : 'Select two colleges to compare admission rates, tuition, and location side-by-side.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textMain(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionRow(BuildContext context, bool isAr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // الخيار الأول
        Expanded(
          child: _buildSlotCard(
            context,
            slot: _slot1,
            slotNumber: 1,
            isAr: isAr,
            onTap: () => _showCollegePicker(1),
            onClear: () => setState(() => _slot1 = null),
          ),
        ),

        // زر التبديل بين الخيارين
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IconButton.filledTonal(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: isAr ? 'تبديل الترتيب' : 'Swap',
            onPressed: (_slot1 != null || _slot2 != null) ? _swapSlots : null,
          ),
        ),

        // الخيار الثاني
        Expanded(
          child: _buildSlotCard(
            context,
            slot: _slot2,
            slotNumber: 2,
            isAr: isAr,
            onTap: () => _showCollegePicker(2),
            onClear: () => setState(() => _slot2 = null),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotCard(
    BuildContext context, {
    required SelectedCollegeSlot? slot,
    required int slotNumber,
    required bool isAr,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    if (slot == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryDark.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primaryDark,
                size: 32,
              ),
              const SizedBox(height: 6),
              Text(
                isAr ? 'اختر كلية $slotNumber' : 'Pick College $slotNumber',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomCachedImage(
                imageUrl: slot.university.logoUrl,
                width: 38,
                height: 38,
                borderRadius: BorderRadius.circular(19),
                placeholderIcon: Icons.school_rounded,
                iconSize: 20,
              ),
              const SizedBox(height: 6),
              Text(
                slot.college.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                slot.university.name,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Positioned(
            top: -4,
            left: isAr ? -4 : null,
            right: isAr ? null : -4,
            child: InkWell(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, bool isAr) {
    final s1 = _slot1!;
    final s2 = _slot2!;

    final isGov1 = s1.university.type.contains('حكوم');
    final isGov2 = s2.university.type.contains('حكوم');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRowHeader(context, isAr, s1, s2),
          const Divider(height: 1),
          _buildComparisonRow(
            context,
            title: isAr ? 'نوع الجامعة' : 'Type',
            icon: Icons.account_balance_rounded,
            val1: s1.university.type.isNotEmpty ? s1.university.type : (isGov1 ? 'حكومي' : 'أهلي'),
            val2: s2.university.type.isNotEmpty ? s2.university.type : (isGov2 ? 'حكومي' : 'أهلي'),
            highlight: false,
          ),
          const Divider(height: 1),
          _buildComparisonRow(
            context,
            title: isAr ? 'المحافظة' : 'Governorate',
            icon: Icons.location_on_rounded,
            val1: s1.university.city,
            val2: s2.university.city,
            highlight: false,
          ),
          const Divider(height: 1),
          _buildComparisonRow(
            context,
            title: isAr ? 'الحد الأدنى للمعدل' : 'Min GPA',
            icon: Icons.trending_up_rounded,
            val1: '${s1.college.minGpa}',
            val2: '${s2.college.minGpa}',
            highlight: true,
            val1IsBetter: s1.college.minGpa <= s2.college.minGpa,
          ),
          const Divider(height: 1),
          _buildComparisonRow(
            context,
            title: isAr ? 'القسط الدراسي' : 'Tuition Fees',
            icon: Icons.payments_rounded,
            val1: isGov1 ? (isAr ? 'مجاني (حكومي)' : 'Free') : (isAr ? 'حسب الأقسام الأهلية' : 'Private Tuition'),
            val2: isGov2 ? (isAr ? 'مجاني (حكومي)' : 'Free') : (isAr ? 'حسب الأقسام الأهلية' : 'Private Tuition'),
            highlight: false,
          ),
          const Divider(height: 1),
          _buildComparisonRow(
            context,
            title: isAr ? 'نظام ونوع الدوام' : 'Study Mode',
            icon: Icons.schedule_rounded,
            val1: isAr ? 'صباحي / مسائي متاح' : 'Morning / Evening',
            val2: isAr ? 'صباحي / مسائي متاح' : 'Morning / Evening',
            highlight: false,
          ),
          const Divider(height: 1),
          _buildComparisonRow(
            context,
            title: isAr ? 'الاعتماد الوزاري' : 'Accreditation',
            icon: Icons.verified_rounded,
            val1: isAr ? 'معترف بها رسمياً' : 'Officially Accredited',
            val2: isAr ? 'معترف بها رسمياً' : 'Officially Accredited',
            highlight: false,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UniversityDetailsScreen(
                            university: s1.university,
                            initialTabIndex: 1,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      isAr ? 'صفحة ${s1.university.name}' : 'View ${s1.university.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UniversityDetailsScreen(
                            university: s2.university,
                            initialTabIndex: 1,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      isAr ? 'صفحة ${s2.university.name}' : 'View ${s2.university.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowHeader(
    BuildContext context,
    bool isAr,
    SelectedCollegeSlot s1,
    SelectedCollegeSlot s2,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              isAr ? 'المعيار' : 'Criteria',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textMain(context),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s1.college.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s2.college.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String val1,
    required String val2,
    required bool highlight,
    bool? val1IsBetter,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textMuted(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: highlight && val1IsBetter == true
                  ? BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(
                val1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                  color: highlight && val1IsBetter == true
                      ? Colors.green
                      : AppColors.textMain(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: highlight && val1IsBetter == false
                  ? BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(
                val2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                  color: highlight && val1IsBetter == false
                      ? Colors.green
                      : AppColors.textMain(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, bool isAr) {
    final s1 = _slot1!;
    final s2 = _slot2!;

    final gpaDiff = (s1.college.minGpa - s2.college.minGpa).abs();
    final lowerGpaSlot = s1.college.minGpa < s2.college.minGpa ? s1 : s2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: Color(0xFF0284C7),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'التحليل والمؤشر الذكي:' : 'Smart Insight:',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'تتطلب كلية ${lowerGpaSlot.college.name} معدلاً أقل بفارق (${gpaDiff.toStringAsFixed(1)} درجة)، مما يجعل فرصة القبول فيها أسهل نسبياً في حال كان معدلك متقارباً.'
                      : '${lowerGpaSlot.college.name} requires a lower GPA by ${gpaDiff.toStringAsFixed(1)} points, making admission odds relatively easier.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textMain(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.balance_rounded,
              size: 64,
              color: AppColors.textMuted(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),
            Text(
              isAr
                  ? 'اختر كليتين في الخانتين أعلاه لبدء المقارنة الفورية'
                  : 'Select two colleges in the slots above to begin comparison',
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
}

class _CollegePickerSheet extends StatefulWidget {
  final List<University> universities;
  final Function(University, College) onSelect;

  const _CollegePickerSheet({
    required this.universities,
    required this.onSelect,
  });

  @override
  State<_CollegePickerSheet> createState() => _CollegePickerSheetState();
}

class _CollegePickerSheetState extends State<_CollegePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isAr = AppStrings.isAr(context);

    // بناء قائمة مسطحة من الكليات مع جامعاتها للبحث الفوري
    final List<Map<String, dynamic>> items = [];
    for (final uni in widget.universities) {
      for (final col in uni.colleges) {
        if (_query.trim().isEmpty ||
            col.name.toLowerCase().contains(_query.toLowerCase()) ||
            uni.name.toLowerCase().contains(_query.toLowerCase())) {
          items.add({'uni': uni, 'col': col});
        }
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: isAr ? 'ابحث عن اسم الكلية أو الجامعة...' : 'Search college or university...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.inputFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final uni = items[i]['uni'] as University;
                final col = items[i]['col'] as College;
                return ListTile(
                  leading: CustomCachedImage(
                    imageUrl: uni.logoUrl,
                    width: 36,
                    height: 36,
                    borderRadius: BorderRadius.circular(18),
                    placeholderIcon: Icons.school_rounded,
                  ),
                  title: Text(
                    col.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  subtitle: Text(
                    '${uni.name} • ${uni.city}',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(context)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${col.minGpa}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    widget.onSelect(uni, col);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
