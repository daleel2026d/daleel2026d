import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../services/app_localizations.dart';

class TuitionCalculatorScreen extends StatefulWidget {
  final double? initialTuition;

  const TuitionCalculatorScreen({super.key, this.initialTuition});

  @override
  State<TuitionCalculatorScreen> createState() =>
      _TuitionCalculatorScreenState();
}

class _TuitionCalculatorScreenState extends State<TuitionCalculatorScreen> {
  final TextEditingController _amountController = TextEditingController();

  // خيارات التخفيضات
  bool _discountBrothers = false; // 10%
  bool _discountQuran = false; // 20%
  bool _discountTopRank = false; // 20%
  bool _discountMartyrs = false; // 25%
  bool _discountAcademics = false; // 20%
  double _customDiscountPercent = 0.0;

  int _installmentCount = 2; // 1, 2, 3, 4

  final List<double> _presetAmounts = [
    2000000,
    3000000,
    4500000,
    6000000,
    8500000,
    12000000,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTuition != null && widget.initialTuition! > 0) {
      _amountController.text = widget.initialTuition!.toInt().toString();
    } else {
      _amountController.text = '3500000';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _baseAmount {
    final clean = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  double get _totalDiscountPercentage {
    double total = 0.0;
    if (_discountBrothers) total += 10.0;
    if (_discountQuran) total += 20.0;
    if (_discountTopRank) total += 20.0;
    if (_discountMartyrs) total += 25.0;
    if (_discountAcademics) total += 20.0;
    total += _customDiscountPercent;
    // الحد الأقصى للتخفيض التراكمي
    return total.clamp(0.0, 60.0);
  }

  double get _discountAmount => _baseAmount * (_totalDiscountPercentage / 100);

  double get _netAmount => _baseAmount - _discountAmount;

  String _formatCurrency(double amount) {
    final int val = amount.round();
    return val.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  void _copySummary(bool isAr) {
    final buffer = StringBuffer();
    buffer.writeln(isAr ? '💰 تفاصيل القسط الجامعي وجدول الدفعات' : '💰 Tuition & Installments Breakdown');
    buffer.writeln('-----------------------------------');
    buffer.writeln('${isAr ? "القسط الأساسي:" : "Base Tuition:"} ${_formatCurrency(_baseAmount)} ${isAr ? "د.ع" : "IQD"}');
    buffer.writeln('${isAr ? "نسبة التخفيض:" : "Total Discount:"} ${_totalDiscountPercentage.toStringAsFixed(0)}%');
    buffer.writeln('${isAr ? "قيمة الخصم:" : "Discount Saved:"} ${_formatCurrency(_discountAmount)} ${isAr ? "د.ع" : "IQD"}');
    buffer.writeln('${isAr ? "المبلغ الصافي المطلوب:" : "Net Tuition Due:"} ${_formatCurrency(_netAmount)} ${isAr ? "د.ع" : "IQD"}');
    buffer.writeln('-----------------------------------');
    buffer.writeln(isAr ? 'جدول الدفعات المقترحة ($_installmentCount دفعات):' : 'Payment Schedule ($_installmentCount installments):');
    final perInstallment = _netAmount / _installmentCount;
    for (int i = 1; i <= _installmentCount; i++) {
      buffer.writeln('${isAr ? "الدفعة" : "Installment"} $i: ${_formatCurrency(perInstallment)} ${isAr ? "د.ع" : "IQD"}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم نسخ ملخص القسط وجدول الدفعات للحافظة'
              : 'Tuition summary copied to clipboard',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppStrings.isAr(context);
    final isWide = MediaQuery.of(context).size.width >= 700;

    final base = _baseAmount;
    final discountPercent = _totalDiscountPercentage;
    final discountVal = _discountAmount;
    final net = _netAmount;

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Text(
            isAr ? 'حاسبة الأقساط والتخفيضات' : 'Tuition & Discounts Calculator',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: isAr ? 'مشاركة الحسبة' : 'Share Breakdown',
              onPressed: () => _copySummary(isAr),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 32 : 16,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. بطاقة إدخال القسط الدراسي
              _buildAmountInputCard(context, isAr),
              const SizedBox(height: 18),

              // 2. بطاقة النتائج المالية البارزة
              _buildSummaryCard(context, isAr, base, discountPercent, discountVal, net),
              const SizedBox(height: 18),

              // 3. خيارات التخفيضات المعتمدة
              _buildDiscountsCard(context, isAr),
              const SizedBox(height: 18),

              // 4. خطة وجدول الدفعات المجدولة
              _buildInstallmentsCard(context, isAr, net),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInputCard(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'القسط الدراسي السنوي (دينار عراقي)' : 'Annual Tuition Amount (IQD)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain(context),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '3,500,000',
              suffixText: isAr ? 'د.ع' : 'IQD',
              prefixIcon: const Icon(Icons.payments_outlined),
              filled: true,
              fillColor: AppColors.inputFill(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // خيارات سريعة للأقساط الشائعة
          Text(
            isAr ? 'أقساط شائعة:' : 'Quick Presets:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted(context),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _presetAmounts.map((amt) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6, left: 6),
                  child: ActionChip(
                    label: Text('${(amt / 1000000).toStringAsFixed(1)} ${isAr ? "مليون" : "M"}'),
                    onPressed: () {
                      setState(() {
                        _amountController.text = amt.toInt().toString();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    bool isAr,
    double base,
    double discountPercent,
    double discountVal,
    double net,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            const Color(0xFF1E40AF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'القسط الصافي المطلوب' : 'Net Tuition Due',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (discountPercent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${isAr ? "خصم" : "Save"} ${discountPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatCurrency(net),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isAr ? 'دينار عراقي' : 'IQD',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'القسط الأصلي' : 'Original Tuition',
                      style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatCurrency(base)} ${isAr ? "د.ع" : "IQD"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isAr ? 'قيمة التوفير المالي' : 'Total Savings',
                      style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '-${_formatCurrency(discountVal)} ${isAr ? "د.ع" : "IQD"}',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountsCard(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.discount_rounded, color: AppColors.primaryDark, size: 22),
              const SizedBox(width: 8),
              Text(
                isAr ? 'التخفيضات والمنح المعتمدة' : 'Accredited Discounts & Waivers',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDiscountCheckbox(
            isAr ? 'تخفيض الإخوة (10% للدارسين معاً)' : 'Sibling Discount (10%)',
            _discountBrothers,
            (v) => setState(() => _discountBrothers = v ?? false),
          ),
          _buildDiscountCheckbox(
            isAr ? 'تخفيض حفظة القرآن الكريم (20%)' : 'Quran Memorizers (20%)',
            _discountQuran,
            (v) => setState(() => _discountQuran = v ?? false),
          ),
          _buildDiscountCheckbox(
            isAr ? 'تخفيض الأوائل والمتفوقين (20%)' : 'Top Students Discount (20%)',
            _discountTopRank,
            (v) => setState(() => _discountTopRank = v ?? false),
          ),
          _buildDiscountCheckbox(
            isAr ? 'تخفيض ذوي الشهداء والسجناء السياسيين (25%)' : 'Special Quota / Martyrs (25%)',
            _discountMartyrs,
            (v) => setState(() => _discountMartyrs = v ?? false),
          ),
          _buildDiscountCheckbox(
            isAr ? 'تخفيض أبناء التدريسيين والجامعيين (20%)' : 'Faculty Dependents (20%)',
            _discountAcademics,
            (v) => setState(() => _discountAcademics = v ?? false),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'نسبة خصم مخصصة إضافية:' : 'Custom Discount:',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMain(context)),
              ),
              Text(
                '${_customDiscountPercent.toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ],
          ),
          Slider(
            value: _customDiscountPercent,
            min: 0,
            max: 50,
            divisions: 10,
            activeColor: AppColors.primaryDark,
            onChanged: (val) => setState(() => _customDiscountPercent = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCheckbox(
    String label,
    bool val,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      value: val,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.primaryDark,
    );
  }

  Widget _buildInstallmentsCard(BuildContext context, bool isAr, double net) {
    final perInstallment = _installmentCount > 0 ? (net / _installmentCount) : net;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppColors.primaryDark, size: 22),
              const SizedBox(width: 8),
              Text(
                isAr ? 'خطة وجدول الدفعات المقترحة' : 'Payment Schedule & Plan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // اختيار عدد الدفعات
          Row(
            children: [1, 2, 3, 4].map((count) {
              final isSel = _installmentCount == count;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _installmentCount = count),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primaryDark
                            : AppColors.primaryDark.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count == 1
                            ? (isAr ? 'دفعة واحدة' : '1 Payment')
                            : '$count ${isAr ? "دفعات" : "Parts"}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : AppColors.primaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // تفصيل كل دفعة
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _installmentCount,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final number = i + 1;
              String timing = '';
              if (_installmentCount == 1) {
                timing = isAr ? 'عند التثبيت والتسجيل النهائي' : 'At final registration';
              } else if (_installmentCount == 2) {
                timing = number == 1
                    ? (isAr ? 'الفصل الدراسي الأول (عند التسجيل)' : 'Semester 1 (Registration)')
                    : (isAr ? 'الفصل الدراسي الثاني (بداية الترم)' : 'Semester 2');
              } else if (_installmentCount == 3) {
                timing = number == 1
                    ? (isAr ? 'الدفعة الأولى (عند التقديم)' : 'Installment 1')
                    : (number == 2
                        ? (isAr ? 'قبل امتحانات نصف السنة' : 'Midterm')
                        : (isAr ? 'قبل الامتحانات النهائية' : 'Finals'));
              } else {
                timing = '${isAr ? "الربع" : "Quarter"} $number';
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primaryDark.withValues(alpha: 0.1),
                          child: Text(
                            '$number',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isAr ? "الدفعة" : "Installment"} $number',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              timing,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${_formatCurrency(perInstallment)} ${isAr ? "د.ع" : "IQD"}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
