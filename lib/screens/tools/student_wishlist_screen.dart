import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../services/app_localizations.dart';
import '../../services/firestore_service.dart';
import '../../models/university_model.dart';
import '../../models/college_model.dart';

class WishlistChoice {
  final String id;
  final String collegeName;
  final String universityName;
  final double minGpa;
  final String city;
  final String type;
  String personalNote;

  WishlistChoice({
    required this.id,
    required this.collegeName,
    required this.universityName,
    required this.minGpa,
    required this.city,
    required this.type,
    this.personalNote = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'collegeName': collegeName,
        'universityName': universityName,
        'minGpa': minGpa,
        'city': city,
        'type': type,
        'personalNote': personalNote,
      };

  factory WishlistChoice.fromMap(Map<String, dynamic> map) => WishlistChoice(
        id: map['id'] ?? '',
        collegeName: map['collegeName'] ?? '',
        universityName: map['universityName'] ?? '',
        minGpa: (map['minGpa'] as num?)?.toDouble() ?? 0.0,
        city: map['city'] ?? '',
        type: map['type'] ?? '',
        personalNote: map['personalNote'] ?? '',
      );
}

class StudentWishlistService {
  static const String _key = 'daleel_student_wishlist_v2';

  static Future<List<WishlistChoice>> getChoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_key);
      if (str != null && str.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(str);
        return decoded.map((e) => WishlistChoice.fromMap(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> saveChoices(List<WishlistChoice> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = jsonEncode(list.map((e) => e.toMap()).toList());
      await prefs.setString(_key, str);
    } catch (_) {}
  }

  static Future<void> addChoice({
    required String collegeName,
    required String universityName,
    required double minGpa,
    required String city,
    required String type,
  }) async {
    final list = await getChoices();
    // التحقق من عدم التكرار
    final exists = list.any(
      (c) => c.collegeName == collegeName && c.universityName == universityName,
    );
    if (!exists) {
      list.add(
        WishlistChoice(
          id: 'wish_${DateTime.now().millisecondsSinceEpoch}',
          collegeName: collegeName,
          universityName: universityName,
          minGpa: minGpa,
          city: city,
          type: type,
        ),
      );
      await saveChoices(list);
    }
  }
}

class StudentWishlistScreen extends StatefulWidget {
  const StudentWishlistScreen({super.key});

  @override
  State<StudentWishlistScreen> createState() => _StudentWishlistScreenState();
}

class _StudentWishlistScreenState extends State<StudentWishlistScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<WishlistChoice> _choices = [];
  bool _isLoading = true;
  List<University> _allUniversities = [];

  @override
  void initState() {
    super.initState();
    _loadChoices();
    _loadUniversities();
  }

  Future<void> _loadChoices() async {
    final list = await StudentWishlistService.getChoices();
    if (mounted) {
      setState(() {
        _choices = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUniversities() async {
    try {
      final list = await _firestoreService.fetchUniversitiesOnce();
      if (mounted) setState(() => _allUniversities = list);
    } catch (_) {}
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _choices.removeAt(oldIndex);
      _choices.insert(newIndex, item);
    });
    StudentWishlistService.saveChoices(_choices);
  }

  void _removeChoice(int index) {
    setState(() {
      _choices.removeAt(index);
    });
    StudentWishlistService.saveChoices(_choices);
  }

  void _editNote(BuildContext context, WishlistChoice choice, bool isAr) {
    final controller = TextEditingController(text: choice.personalNote);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'ملاحظاتي الشخصية' : 'Personal Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: isAr
                ? 'اكتب ملاحظاتك عن هذه الكلية (الأقساط، الدوام، المواصلات)...'
                : 'Write your notes (tuition, commute, schedule)...',
            filled: true,
            fillColor: AppColors.inputFill(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                choice.personalNote = controller.text.trim();
              });
              StudentWishlistService.saveChoices(_choices);
              Navigator.pop(ctx);
            },
            child: Text(isAr ? 'حفظ الملاحظة' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _shareWishlist(bool isAr) {
    if (_choices.isEmpty) return;
    final buffer = StringBuffer();
    buffer.writeln(isAr ? '🎓 استمارة ترتيب رغباتي للقبول الجامعي 2026' : '🎓 My University Choices Wishlist 2026');
    buffer.writeln('-----------------------------------');
    for (int i = 0; i < _choices.length; i++) {
      final c = _choices[i];
      buffer.writeln('${i + 1}. ${c.collegeName} - ${c.universityName} (${c.city})');
      buffer.writeln('   • ${isAr ? "الحد الأدنى:" : "Min GPA:"} ${c.minGpa}');
      if (c.personalNote.isNotEmpty) {
        buffer.writeln('   • ${isAr ? "ملاحظة:" : "Note:"} ${c.personalNote}');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم نسخ استمارة الرغبات إلى الحافظة للمشاركة'
              : 'Wishlist copied to clipboard',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddChoiceSheet(BuildContext context, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<Map<String, dynamic>> items = [];
            for (final uni in _allUniversities) {
              for (final col in uni.colleges) {
                if (query.trim().isEmpty ||
                    col.name.toLowerCase().contains(query.toLowerCase()) ||
                    uni.name.toLowerCase().contains(query.toLowerCase())) {
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
                        hintText: isAr ? 'ابحث عن كلية لإضافتها لرغباتك...' : 'Search college to add...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppColors.inputFill(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: (val) => setModalState(() => query = val),
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
                          title: Text(col.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: Text('${uni.name} • ${uni.city}', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(context))),
                          trailing: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryDark),
                          onTap: () async {
                            await StudentWishlistService.addChoice(
                              collegeName: col.name,
                              universityName: uni.name,
                              minGpa: col.minGpa,
                              city: uni.city,
                              type: uni.type,
                            );
                            _loadChoices();
                            if (ctx.mounted) Navigator.pop(ctx);
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
            isAr ? 'استمارة رغباتي وملاحظاتي' : 'My College Wishlist',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          actions: [
            if (_choices.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: isAr ? 'مشاركة الاستمارة' : 'Share Wishlist',
                onPressed: () => _shareWishlist(isAr),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(isAr ? 'إضافة رغبة' : 'Add Choice'),
          onPressed: () => _showAddChoiceSheet(context, isAr),
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
                    _buildBanner(context, isAr),
                    const SizedBox(height: 16),
                    if (_choices.isEmpty)
                      _buildEmptyState(context, isAr)
                    else ...[
                      Text(
                        isAr
                            ? 'اسحب لتغيير ترتيب أولوية الرغبات (1 إلى ${_choices.length}):'
                            : 'Drag to reorder your preference ranking (1 to ${_choices.length}):',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _choices.length,
                        // ignore: deprecated_member_use
                        onReorder: _onReorder,
                        itemBuilder: (ctx, i) {
                          final choice = _choices[i];
                          return _buildWishlistItem(
                            context,
                            key: ValueKey(choice.id),
                            index: i,
                            choice: choice,
                            isAr: isAr,
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.playlist_add_check_circle_rounded, color: AppColors.primaryDark, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAr
                  ? 'رتب كلياتك ورغباتك الأكاديمية بالسحب والإفلات، ودون ملاحظاتك الخاصة لتجهيز استمارة القبول المركزي بكل ثقة.'
                  : 'Reorder your college choices via drag-and-drop, take personal notes, and prepare for admission.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMain(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(
    BuildContext context, {
    required Key key,
    required int index,
    required WishlistChoice choice,
    required bool isAr,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryDark,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.collegeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${choice.universityName} • ${choice.city} (حد أدنى: ${choice.minGpa})',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(context)),
                      ),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.drag_indicator_rounded, color: AppColors.textGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ملاحظة خاصة
            if (choice.personalNote.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        choice.personalNote,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            // أزرار سريعة
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: Text(choice.personalNote.isEmpty ? (isAr ? 'إضافة ملاحظة' : 'Add Note') : (isAr ? 'تعديل الملاحظة' : 'Edit Note'), style: const TextStyle(fontSize: 11.5)),
                  onPressed: () => _editNote(context, choice, isAr),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                  label: Text(isAr ? 'حذف' : 'Remove', style: const TextStyle(fontSize: 11.5, color: Colors.red)),
                  onPressed: () => _removeChoice(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.playlist_add_rounded, size: 64, color: AppColors.textMuted(context).withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text(
              isAr ? 'استمارة رغباتك فارغة حالياً' : 'Your wishlist is currently empty',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain(context)),
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'اضغط زر "إضافة رغبة" بالأسفل أو أضف الكليات مباشرة من حاسبة القبول'
                  : 'Tap "Add Choice" or add colleges from the admission calculator',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
