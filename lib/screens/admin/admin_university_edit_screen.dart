import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../models/university_model.dart';
import '../../models/college_model.dart';
import '../../models/post_model.dart';
import '../../widgets/custom_cached_image.dart';
import '../../main.dart';

class AdminUniversityEditScreen extends StatefulWidget {
  final University? university;

  const AdminUniversityEditScreen({super.key, this.university});

  @override
  State<AdminUniversityEditScreen> createState() =>
      _AdminUniversityEditScreenState();
}

class _AdminUniversityEditScreenState extends State<AdminUniversityEditScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  late TabController _tabController;
  late String _sessionUniId;

  // Controllers for Tab 1 (General Info)
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _logoCtrl;
  late TextEditingController _coverCtrl;
  late TextEditingController _webCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _managerEmailCtrl;
  late String _selectedType;

  // Image Uploading States
  bool _isUploadingCover = false;
  bool _isUploadingLogo = false;
  bool _isUploadingGallery = false;
  bool _showManualUrlInputs = false;

  // State for Tab 2 (Colleges)
  List<College> _colleges = [];

  // State for Tab 3 (Posts)
  List<Post> _posts = [];

  // State for Tab 4 (Gallery)
  List<String> _gallery = [];
  final TextEditingController _galleryImageCtrl = TextEditingController();

  bool _isSaving = false;

  String _normalizeUniType(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    if (t.contains('حكوم') || t == 'public' || t == 'government') return 'حكومي';
    if (t.contains('أهل') || t.contains('اهل') || t.contains('خاص') || t == 'private') return 'أهلي';
    if (t.contains('دول') || t == 'international') return 'دولي';
    return 'حكومي';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final uni = widget.university;
    _sessionUniId = uni?.id ?? 'uni_${DateTime.now().millisecondsSinceEpoch}';
    _nameCtrl = TextEditingController(text: uni?.name ?? '');
    _cityCtrl = TextEditingController(text: uni?.city ?? 'بغداد');
    _selectedType = _normalizeUniType(uni?.type);
    _descCtrl = TextEditingController(text: uni?.description ?? '');
    _logoCtrl = TextEditingController(text: uni?.logoUrl ?? '');
    _coverCtrl = TextEditingController(text: uni?.coverImageUrl ?? '');
    _webCtrl = TextEditingController(text: uni?.websiteUrl ?? '');
    _whatsappCtrl = TextEditingController(text: uni?.whatsapp ?? '');
    _managerEmailCtrl = TextEditingController(text: uni?.managerEmail ?? '');

    if (uni != null) {
      _colleges = List<College>.from(uni.colleges);
      _posts = List<Post>.from(uni.posts);
      _gallery = List<String>.from(uni.gallery);
    }
  }

  Future<void> _pickAndUploadCover() async {
    final file = await _storageService.pickImage();
    if (file == null) return;

    setState(() => _isUploadingCover = true);
    try {
      final url = await _storageService.uploadUniversityImage(
        universityId: _sessionUniId,
        file: file,
        folder: 'covers',
      );
      setState(() {
        _coverCtrl.text = url;
        _isUploadingCover = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع صورة واجهة الجامعة بنجاح إلى Firebase Storage'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingCover = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع الصورة إلى Firebase: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final file = await _storageService.pickImage();
    if (file == null) return;

    setState(() => _isUploadingLogo = true);
    try {
      final url = await _storageService.uploadUniversityImage(
        universityId: _sessionUniId,
        file: file,
        folder: 'logos',
      );
      setState(() {
        _logoCtrl.text = url;
        _isUploadingLogo = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع شعار الجامعة بنجاح إلى Firebase Storage'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع الشعار إلى Firebase: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadGalleryImage() async {
    final file = await _storageService.pickImage();
    if (file == null) return;

    setState(() => _isUploadingGallery = true);
    try {
      final url = await _storageService.uploadUniversityImage(
        universityId: _sessionUniId,
        file: file,
        folder: 'gallery',
      );
      setState(() {
        _gallery.add(url);
        _isUploadingGallery = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الصورة وإضافتها للمعرض بنجاح عبر Firebase Storage'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingGallery = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع الصورة إلى Firebase: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _descCtrl.dispose();
    _logoCtrl.dispose();
    _coverCtrl.dispose();
    _webCtrl.dispose();
    _whatsappCtrl.dispose();
    _managerEmailCtrl.dispose();
    _galleryImageCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveUniversity() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الجامعة أولاً'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> data = {
        'name': name,
        'city': _cityCtrl.text.trim(),
        'type': _selectedType,
        'description': _descCtrl.text.trim(),
        'logoUrl': _logoCtrl.text.trim(),
        'coverImageUrl': _coverCtrl.text.trim(),
        'websiteUrl': _webCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'managerEmail': _managerEmailCtrl.text.trim().toLowerCase(),
        'adminEmail': _managerEmailCtrl.text.trim().toLowerCase(),
        'colleges': _colleges.map((c) => c.toMap()).toList(),
        'posts': _posts.map((p) => p.toMap()).toList(),
        'gallery': _gallery,
      };

      if (widget.university != null) {
        await _firestoreService.updateUniversity(widget.university!.id, data);
      } else {
        await _firestoreService.addUniversity(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.university != null
                ? 'تم حفظ وتحديث الجامعة بنجاح'
                : 'تمت إضافة الجامعة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.university != null;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          title: Text(
            isEdit ? 'تعديل بيانات الجامعة' : 'إضافة جامعة جديدة',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          centerTitle: true,
          backgroundColor: AppColors.surfaceHeader(context),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveUniversity,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  _isSaving ? 'جارٍ الحفظ...' : 'حفظ التعديلات',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: const Color(0xFF38BDF8),
            indicatorWeight: 3,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: [
              const Tab(
                icon: Icon(Icons.info_outline_rounded, size: 20),
                text: 'معلومات الجامعة',
              ),
              Tab(
                icon: const Icon(Icons.school_rounded, size: 20),
                text: 'الكليات والأقسام (${_colleges.length})',
              ),
              Tab(
                icon: const Icon(Icons.newspaper_rounded, size: 20),
                text: 'المنشورات (${_posts.length})',
              ),
              Tab(
                icon: const Icon(Icons.photo_library_rounded, size: 20),
                text: 'معرض الصور (${_gallery.length})',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralInfoTab(),
            _buildCollegesTab(),
            _buildPostsTab(),
            _buildGalleryTab(),
          ],
        ),
      ),
    );
  }

  // ================= TAB 1: معلومات الجامعة =================
  Widget _buildGeneralInfoTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppColors.surfaceCard(context),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'البيانات الأساسية للجامعة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم الجامعة *',
                      hintText: 'مثال: جامعة بغداد',
                      prefixIcon: Icon(Icons.account_balance_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'المحافظة / المدينة',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'النوع',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'حكومي', child: Text('حكومي')),
                            DropdownMenuItem(
                                value: 'أهلي', child: Text('أهلي')),
                            DropdownMenuItem(
                                value: 'دولي', child: Text('دولي')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedType = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'نبذة تفصيلية عن الجامعة',
                      hintText: 'اكتب نبذة عن تاريخ الجامعة وتصنيفها...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _webCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رابط الموقع الرسمي',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.language_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _whatsappCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم واتساب للتواصل (WhatsApp Number)',
                      hintText: 'مثال: 9647700000000 أو 07700000000',
                      prefixIcon: Icon(Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF25D366)),
                      helperText:
                          'الرقم الذي سيتواصل معه الطلاب عند الضغط على زر تواصل واتساب في صفحة الجامعة (يترك فارغاً إذا لم يتوفر)',
                      helperMaxLines: 2,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _managerEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني لمدير الجامعة (Manager Email)',
                      hintText: 'مثال: manager@gmail.com',
                      prefixIcon: Icon(Icons.manage_accounts_rounded,
                          color: Color(0xFF2563EB)),
                      helperText:
                          'عند تسجيل هذا المدير الدخول للتطبيق، ستظهر له إدارة هذه الجامعة في صفحة الإعدادات لتعديلها',
                      helperMaxLines: 2,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.surfaceCard(context),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.cloud_done_rounded,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'صور وواجهة الجامعة (تخزين مباشر في Firebase)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'ارفع الصور مباشرة من هاتفك أو جهازك وسيتم حفظها وتعديلها في Firebase دون الحاجة لروابط',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 1. صورة واجهة / غلاف الجامعة
                  const Row(
                    children: [
                      Icon(Icons.panorama_rounded, size: 18, color: Color(0xFF0284C7)),
                      SizedBox(width: 6),
                      Text(
                        'صورة واجهة / غلاف الجامعة (Cover Image)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_coverCtrl.text.trim().isNotEmpty) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomCachedImage(
                            imageUrl: _coverCtrl.text.trim(),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.account_balance,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _coverCtrl.text.contains('firebasestorage')
                                      ? Icons.cloud_done_rounded
                                      : Icons.image_rounded,
                                  color: const Color(0xFF10B981),
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _coverCtrl.text.contains('firebasestorage')
                                      ? 'مخزنة في Firebase Storage'
                                      : 'صورة الواجهة الحالية',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isUploadingCover ? null : _pickAndUploadCover,
                            icon: _isUploadingCover
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.photo_library_rounded, size: 18),
                            label: Text(
                              _isUploadingCover
                                  ? 'جارٍ رفع الصورة إلى Firebase...'
                                  : 'تغيير صورة الواجهة من الجهاز',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'حذف صورة الواجهة',
                          onPressed: () => setState(() => _coverCtrl.clear()),
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.redAccent.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 42,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'لم يتم تعيين صورة واجهة بعد',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اضغط أدناه لاختيار صورة من هاتفك ليتم رفعها وحفظها في Firebase تلقائياً',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed:
                                _isUploadingCover ? null : _pickAndUploadCover,
                            icon: _isUploadingCover
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add_photo_alternate_rounded,
                                    size: 18),
                            label: Text(
                              _isUploadingCover
                                  ? 'جارٍ رفع الصورة إلى Firebase...'
                                  : 'رفع صورة الواجهة من الجهاز إلى Firebase',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 2. شعار الجامعة الرسمي
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 18, color: Color(0xFF0284C7)),
                      SizedBox(width: 6),
                      Text(
                        'شعار الجامعة الرسمي (Logo)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryDark.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _logoCtrl.text.trim().isNotEmpty
                              ? CustomCachedImage(
                                  imageUrl: _logoCtrl.text.trim(),
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                  placeholderIcon: Icons.school_rounded,
                                )
                              : const Icon(Icons.school_rounded,
                                  size: 32, color: Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed:
                                  _isUploadingLogo ? null : _pickAndUploadLogo,
                              icon: _isUploadingLogo
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.photo_camera_back_outlined,
                                      size: 18),
                              label: Text(
                                _isUploadingLogo
                                    ? 'جارٍ رفع الشعار...'
                                    : (_logoCtrl.text.trim().isNotEmpty
                                        ? 'تغيير الشعار من الجهاز'
                                        : 'رفع الشعار إلى Firebase'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            if (_logoCtrl.text.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _logoCtrl.clear()),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: Colors.redAccent),
                                  label: const Text(
                                    'إزالة الشعار',
                                    style: TextStyle(
                                        color: Colors.redAccent, fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  // خيار متقدم لعرض أو تعديل الرابط يدوياً إن دعت الحاجة
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(
                          () => _showManualUrlInputs = !_showManualUrlInputs),
                      icon: Icon(
                        _showManualUrlInputs
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.textMuted(context),
                      ),
                      label: Text(
                        _showManualUrlInputs
                            ? 'إخفاء الروابط اليدوية'
                            : 'خيارات متقدمة (عرض الرابط يدوياً)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ),
                  ),
                  if (_showManualUrlInputs) ...[
                    const SizedBox(height: 6),
                    TextField(
                      controller: _coverCtrl,
                      decoration: const InputDecoration(
                        labelText: 'رابط صورة الواجهة المباشر',
                        prefixIcon: Icon(Icons.link_rounded),
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _logoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'رابط الشعار المباشر',
                        prefixIcon: Icon(Icons.link_rounded),
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 2: الكليات والأقسام =================
  Widget _buildCollegesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'قائمة الكليات (${_colleges.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ElevatedButton.icon(
                onPressed: () => _openCollegeDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة كلية جديدة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _colleges.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 64, color: AppColors.textMuted(context)),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد كليات مضافة بعد',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textMuted(context)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _openCollegeDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('إضافة أول كلية الآن'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: _colleges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final college = _colleges[index];
                    return Card(
                      color: AppColors.surfaceCard(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppColors.border(context)),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Color(0xFF0284C7)),
                        ),
                        title: Text(
                          college.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'المسار: ${college.category.isNotEmpty ? college.category : 'عام'} • المعدل الأدنى: ${college.minGpa > 0 ? '${college.minGpa}%' : 'غير محدد'}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted(context)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.blueAccent, size: 20),
                              onPressed: () =>
                                  _openCollegeDialog(index: index, college: college),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () {
                                setState(() => _colleges.removeAt(index));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openCollegeDialog({int? index, College? college}) {
    final isEdit = index != null && college != null;
    final nameCtrl = TextEditingController(text: college?.name ?? '');
    final gpaCtrl = TextEditingController(
        text: college != null && college.minGpa > 0
            ? college.minGpa.toString()
            : '');
    final catCtrl =
        TextEditingController(text: college?.category ?? 'علمي');
    final descCtrl =
        TextEditingController(text: college?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.surfaceCard(context),
            title: Text(
              isEdit ? 'تعديل بيانات الكلية' : 'إضافة كلية جديدة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم الكلية *',
                        hintText: 'مثال: كلية الطب العام',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: gpaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'الحد الأدنى للمعدل %',
                              hintText: 'مثال: 95.5',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: catCtrl,
                            decoration: const InputDecoration(
                              labelText: 'المسار / الفرع',
                              hintText: 'علمي, أدبي, عام',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'وصف أو أقسام الكلية',
                        hintText: 'اكتب الأقسام المتاحة أو تفاصيل الدراسة...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final colName = nameCtrl.text.trim();
                  if (colName.isEmpty) return;

                  final gpa = double.tryParse(gpaCtrl.text.trim()) ?? 0.0;
                  final newCol = College(
                    name: colName,
                    minGpa: gpa,
                    category: catCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                  );

                  setState(() {
                    if (isEdit) {
                      _colleges[index] = newCol;
                    } else {
                      _colleges.add(newCol);
                    }
                  });

                  Navigator.pop(ctx);
                },
                child: Text(isEdit ? 'تحديث الكلية' : 'إضافة الكلية'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= TAB 3: المنشورات =================
  Widget _buildPostsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'منشورات وأخبار الجامعة (${_posts.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ElevatedButton.icon(
                onPressed: () => _openPostDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة منشور جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper_outlined,
                          size: 64, color: AppColors.textMuted(context)),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد منشورات مضافة بعد',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textMuted(context)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _openPostDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('إضافة أول منشور الآن'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: _posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Card(
                      color: AppColors.surfaceCard(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppColors.border(context)),
                      ),
                      child: ListTile(
                        leading: post.imageUrl.isNotEmpty
                            ? CustomCachedImage(
                                imageUrl: post.imageUrl,
                                width: 48,
                                height: 48,
                                borderRadius: BorderRadius.circular(8),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.article_rounded,
                                    color: Colors.amber),
                              ),
                        title: Text(
                          post.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          post.description,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted(context)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.blueAccent, size: 20),
                              onPressed: () =>
                                  _openPostDialog(index: index, post: post),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () {
                                setState(() => _posts.removeAt(index));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openPostDialog({int? index, Post? post}) {
    final isEdit = index != null && post != null;
    final titleCtrl = TextEditingController(text: post?.title ?? '');
    final dateCtrl = TextEditingController(
        text: post?.date.isNotEmpty == true
            ? post!.date
            : DateTime.now().toString().split(' ')[0]);
    final imgCtrl = TextEditingController(text: post?.imageUrl ?? '');
    final descCtrl = TextEditingController(text: post?.description ?? '');
    bool isUploadingPostImg = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: AppColors.surfaceCard(context),
                title: Text(
                  isEdit ? 'تعديل المنشور' : 'إضافة منشور جديد',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 460,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'عنوان المنشور *',
                            hintText: 'مثال: فتح باب التقديم للدراسات المسائية',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: dateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'تاريخ النشر',
                            hintText: 'مثال: 2026-09-02',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isUploadingPostImg
                                    ? null
                                    : () async {
                                        final file =
                                            await _storageService.pickImage();
                                        if (file == null) return;
                                        setDialogState(
                                            () => isUploadingPostImg = true);
                                        try {
                                          final url = await _storageService
                                              .uploadUniversityImage(
                                            universityId: _sessionUniId,
                                            file: file,
                                            folder: 'posts',
                                          );
                                          setDialogState(() {
                                            imgCtrl.text = url;
                                            isUploadingPostImg = false;
                                          });
                                        } catch (e) {
                                          setDialogState(
                                              () => isUploadingPostImg = false);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'فشل رفع صورة المنشور: $e')),
                                            );
                                          }
                                        }
                                      },
                                icon: isUploadingPostImg
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.cloud_upload_outlined,
                                        size: 16),
                                label: Text(
                                  isUploadingPostImg
                                      ? 'جارٍ الرفع إلى Firebase...'
                                      : 'رفع صورة المنشور من الجهاز إلى Firebase',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (imgCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CustomCachedImage(
                                  imageUrl: imgCtrl.text.trim(),
                                  height: 90,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholderIcon: Icons.image_rounded,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: IconButton.filledTonal(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  icon: const Icon(Icons.close, size: 14),
                                  onPressed: () => setDialogState(
                                      () => imgCtrl.clear()),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: descCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'تفاصيل ومحتوى المنشور *',
                            hintText: 'اكتب نص الخبر أو الإعلان هنا...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  final desc = descCtrl.text.trim();
                  if (title.isEmpty || desc.isEmpty) return;

                  final newPost = Post(
                    title: title,
                    date: dateCtrl.text.trim(),
                    imageUrl: imgCtrl.text.trim(),
                    description: desc,
                  );

                  setState(() {
                    if (isEdit) {
                      _posts[index] = newPost;
                    } else {
                      _posts.add(newPost);
                    }
                  });

                  Navigator.pop(ctx);
                },
                child: Text(isEdit ? 'تحديث المنشور' : 'نشر الآن'),
              ),
            ],
          ),
        );
      },
    );
  },
);
}

  // ================= TAB 4: معرض الصور =================
  Widget _buildGalleryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploadingGallery
                      ? null
                      : _pickAndUploadGalleryImage,
                  icon: _isUploadingGallery
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 20),
                  label: Text(
                    _isUploadingGallery
                        ? 'جارٍ رفع الصورة إلى Firebase Storage...'
                        : 'رفع صورة جديدة للمعرض من الجهاز إلى Firebase',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: AppColors.surfaceCard(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _galleryImageCtrl,
                          decoration: const InputDecoration(
                            hintText: 'أو أضف رابط صورة يدوياً (اختياري)...',
                            prefixIcon: Icon(Icons.link_rounded),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final url = _galleryImageCtrl.text.trim();
                          if (url.isNotEmpty) {
                            setState(() {
                              _gallery.add(url);
                              _galleryImageCtrl.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_link, size: 18),
                        label: const Text('إضافة رابط'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _gallery.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 64, color: AppColors.textMuted(context)),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد صور في المعرض بعد',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textMuted(context)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'أضف روابط صور الجامعة من الحقل أعلاه',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted(context)),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: _gallery.length,
                  itemBuilder: (context, index) {
                    final imgUrl = _gallery[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomCachedImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.image_rounded,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete_rounded,
                                  color: Colors.redAccent, size: 18),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              onPressed: () {
                                setState(() => _gallery.removeAt(index));
                              },
                            ),
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
