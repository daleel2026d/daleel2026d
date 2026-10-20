import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../services/app_localizations.dart';

class ChecklistTask {
  final String id;
  final String title;
  final String phase; // documents, application, registration, custom
  final String note;
  bool isCompleted;
  final bool isDefault;

  ChecklistTask({
    required this.id,
    required this.title,
    required this.phase,
    this.note = '',
    this.isCompleted = false,
    this.isDefault = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'phase': phase,
        'note': note,
        'isCompleted': isCompleted,
        'isDefault': isDefault,
      };

  factory ChecklistTask.fromMap(Map<String, dynamic> map) => ChecklistTask(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        phase: map['phase'] ?? 'custom',
        note: map['note'] ?? '',
        isCompleted: map['isCompleted'] ?? false,
        isDefault: map['isDefault'] ?? false,
      );
}

class AdmissionChecklistScreen extends StatefulWidget {
  const AdmissionChecklistScreen({super.key});

  @override
  State<AdmissionChecklistScreen> createState() =>
      _AdmissionChecklistScreenState();
}

class _AdmissionChecklistScreenState extends State<AdmissionChecklistScreen> {
  static const String _prefKey = 'daleel_admission_tasks_v2';
  List<ChecklistTask> _tasks = [];
  bool _isLoading = true;
  String _activeFilter = 'all'; // all, pending, completed

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  List<ChecklistTask> _getDefaultTasks() {
    return [
      ChecklistTask(
        id: 'doc_1',
        title: 'استلام وتصديق وثيقة تخرج السادس الإعدادي',
        phase: 'documents',
        note: 'تصديق من إدارة المدرسة وقسم الامتحانات في مديرية التربية.',
      ),
      ChecklistTask(
        id: 'doc_2',
        title: 'إجراء الفحص الطبي في المركز الصحي المعتمد',
        phase: 'documents',
        note: 'ضروري لإرفاقه مع استمارة الفحص الطبي للقبول الجامعي.',
      ),
      ChecklistTask(
        id: 'doc_3',
        title: 'تجهيز المستمسكات الرسمية وصور المعاملة الحديثة',
        phase: 'documents',
        note: 'البطاقة الوطنية، بطاقة السكن، و 6 صور شخصية بخلفية بيضاء.',
      ),
      ChecklistTask(
        id: 'doc_4',
        title: 'استخراج تأييد الدرجات المصدق بالرقم السري والامتحاني',
        phase: 'documents',
        note: 'تأكد من سلامة الاسم والرقم الامتحاني.',
      ),
      ChecklistTask(
        id: 'app_1',
        title: 'فتح حساب في بوابة الدراسات والتخطيط والمتابعة',
        phase: 'application',
        note: 'استخدام الرقم الامتحاني والرقم السري الخاص بالطالب.',
      ),
      ChecklistTask(
        id: 'app_2',
        title: 'ترتيب خيارات الكليات والمعاهد في استمارة القبول',
        phase: 'application',
        note: 'ملء الاستمارة بتركيز بناءً على معدل السنة السابقة ورغبتك الحقيقية.',
      ),
      ChecklistTask(
        id: 'app_3',
        title: 'تدقيق الخيارات والرموز الكودية قبل الحفظ النهائي',
        phase: 'application',
        note: 'المراجعة الدقيقة لمنع الخطأ في أسماء الكليات والمحافظات.',
      ),
      ChecklistTask(
        id: 'app_4',
        title: 'حفظ وطباعة نسخة PDF من الاستمارة الإلكترونية',
        phase: 'application',
        note: 'الاحتفاظ بنسخة ورقية وإلكترونية للرجوع إليها لاحقاً.',
      ),
      ChecklistTask(
        id: 'reg_1',
        title: 'التأكد من نتيجة القبول المركزي الرسمية',
        phase: 'registration',
        note: 'طباعة إشعار القبول الرسمي من البوابة.',
      ),
      ChecklistTask(
        id: 'reg_2',
        title: 'مراجعة قسم التسجيل وشؤون الطلبة في الكلية المقبولة',
        phase: 'registration',
        note: 'ضمن الفترة المحددة للتسجيل لتفادي إلغاء القبول.',
      ),
      ChecklistTask(
        id: 'reg_3',
        title: 'جلب الكفيل الضامن وإتمام التعهدات القانونية',
        phase: 'registration',
        note: 'كفالة موظف مدني مع تأييد استمرار بالخدمة.',
      ),
      ChecklistTask(
        id: 'reg_4',
        title: 'تسديد رسوم التسجيل المالي وإصدار الهوية الجامعية',
        phase: 'registration',
        note: 'استلام الوصل الرسمي والتقديم على الأقسام الداخلية إذا كنت من محافظة أخرى.',
      ),
    ];
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_prefKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedStr);
        final loaded = decoded.map((e) => ChecklistTask.fromMap(e)).toList();
        setState(() {
          _tasks = loaded;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    setState(() {
      _tasks = _getDefaultTasks();
      _isLoading = false;
    });
    _saveTasks();
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = jsonEncode(_tasks.map((e) => e.toMap()).toList());
      await prefs.setString(_prefKey, str);
    } catch (_) {}
  }

  void _toggleTask(ChecklistTask task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
    _saveTasks();
  }

  void _addNewTask(String title, String note) {
    if (title.trim().isEmpty) return;
    setState(() {
      _tasks.insert(
        0,
        ChecklistTask(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          title: title.trim(),
          phase: 'custom',
          note: note.trim(),
          isDefault: false,
        ),
      );
    });
    _saveTasks();
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
    _saveTasks();
  }

  void _resetTasks(bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'إعادة ضبط المهام' : 'Reset Tasks'),
        content: Text(
          isAr
              ? 'هل تريد استعادة قائمة المهام الافتراضية وحذف التعديلات؟'
              : 'Restore default checklist and reset all progress?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _tasks = _getDefaultTasks();
              });
              _saveTasks();
            },
            child: Text(isAr ? 'تأكيد الاستعادة' : 'Reset'),
          ),
        ],
      ),
    );
  }

  void _shareProgress(bool isAr) {
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final total = _tasks.length;
    final percent = total > 0 ? ((completedCount / total) * 100).toInt() : 0;

    final buffer = StringBuffer();
    buffer.writeln(
        isAr ? '📋 تقدم خطة التقديم الجامعي: $percent%' : '📋 Admission Roadmap Progress: $percent%');
    buffer.writeln(isAr
        ? 'تم إنجاز $completedCount من أصل $total خطوة.'
        : 'Completed $completedCount of $total milestones.');
    buffer.writeln('-----------------------------------');
    for (var t in _tasks) {
      buffer.writeln('${t.isCompleted ? "✅" : "⏳"} ${t.title}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم نسخ ملخص إنجاز المهام للحافظة'
              : 'Checklist progress copied to clipboard',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context, bool isAr) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'إضافة مهمة جديدة' : 'Add Custom Milestone',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: isAr ? 'عنوان المهمة' : 'Milestone Title',
                  hintText: isAr ? 'مثال: مراجعة دائرة التقاعد' : 'e.g. Visit ministry office',
                  filled: true,
                  fillColor: AppColors.inputFill(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: isAr ? 'ملاحظة أو تذكير (اختياري)' : 'Note (optional)',
                  filled: true,
                  fillColor: AppColors.inputFill(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    _addNewTask(titleController.text, noteController.text);
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    isAr ? 'حفظ المهمة' : 'Save Milestone',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
    final isAr = AppStrings.isAr(context);
    final isWide = MediaQuery.of(context).size.width >= 700;

    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final totalCount = _tasks.length;
    final double progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    final filteredTasks = _tasks.where((t) {
      if (_activeFilter == 'pending') return !t.isCompleted;
      if (_activeFilter == 'completed') return t.isCompleted;
      return true;
    }).toList();

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Text(
            isAr ? 'مخطط ومهام التقديم الجامعي' : 'Admission Roadmap & Checklist',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: isAr ? 'مشاركة الإنجاز' : 'Share Progress',
              onPressed: () => _shareProgress(isAr),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: isAr ? 'إعادة ضبط' : 'Reset',
              onPressed: () => _resetTasks(isAr),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_task_rounded),
          label: Text(isAr ? 'مهمة جديدة' : 'New Task'),
          onPressed: () => _showAddTaskSheet(context, isAr),
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
                    // بطاقة شريط التقدم والإحصائيات
                    _buildProgressCard(
                      context,
                      isAr,
                      completedCount,
                      totalCount,
                      progress,
                    ),
                    const SizedBox(height: 18),

                    // تبويبات التصفية
                    _buildFilterTabs(context, isAr),
                    const SizedBox(height: 14),

                    // قائمة المهام
                    if (filteredTasks.isEmpty)
                      _buildEmptyFilterState(context, isAr)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTasks.length,
                        itemBuilder: (ctx, i) => _buildTaskItem(
                          context,
                          filteredTasks[i],
                          isAr,
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    bool isAr,
    int completed,
    int total,
    double progress,
  ) {
    final int percent = (progress * 100).toInt();

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'مستوى جاهزية ملفك الأكاديمي' : 'Admission Readiness',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'أكملت $completed من أصل $total خطوة متطلبة للتقديم الجامعي'
                          : 'Completed $completed of $total required milestones',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.border(context),
              color: percent == 100 ? const Color(0xFF10B981) : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, bool isAr) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(isAr ? 'جميع الخطوات' : 'All Milestones'),
            selected: _activeFilter == 'all',
            onSelected: (val) {
              if (val) setState(() => _activeFilter = 'all');
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(isAr ? 'قيد الإنجاز ⏳' : 'Pending ⏳'),
            selected: _activeFilter == 'pending',
            onSelected: (val) {
              if (val) setState(() => _activeFilter = 'pending');
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(isAr ? 'المكتملة ✅' : 'Completed ✅'),
            selected: _activeFilter == 'completed',
            onSelected: (val) {
              if (val) setState(() => _activeFilter = 'completed');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    ChecklistTask task,
    bool isAr,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : AppColors.border(context),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: InkWell(
          onTap: () => _toggleTask(task),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? const Color(0xFF10B981)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: task.isCompleted
                    ? const Color(0xFF10B981)
                    : AppColors.textMuted(context),
                width: 2,
              ),
            ),
            child: task.isCompleted
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted
                ? AppColors.textMuted(context)
                : AppColors.textMain(context),
          ),
        ),
        subtitle: task.note.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.note,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted(context),
                  ),
                ),
              )
            : null,
        trailing: !task.isDefault
            ? IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: Colors.red.shade400,
                onPressed: () => _deleteTask(task.id),
              )
            : null,
        onTap: () => _toggleTask(task),
      ),
    );
  }

  Widget _buildEmptyFilterState(BuildContext context, bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.done_all_rounded,
              size: 56,
              color: AppColors.textMuted(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'لا توجد مهام في هذا التصنيف' : 'No tasks in this category',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
