import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/training_center_model.dart';
import '../widgets/college_card.dart';
import '../widgets/post_card.dart';
import '../widgets/custom_cached_image.dart';
import '../main.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';

class TrainingCenterDetailsScreen extends StatefulWidget {
  final TrainingCenter center;
  final int initialTabIndex;

  const TrainingCenterDetailsScreen({
    super.key,
    required this.center,
    this.initialTabIndex = 0,
  });

  @override
  State<TrainingCenterDetailsScreen> createState() =>
      _TrainingCenterDetailsScreenState();
}

class _TrainingCenterDetailsScreenState
    extends State<TrainingCenterDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaved = false;
  TrainingCenter get center => widget.center;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  void _checkSaved() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _firestoreService.getUserData(uid).listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final saved = List<String>.from(data['savedTrainingCenters'] ?? []);
        setState(() {
          _isSaved = saved.contains(widget.center.id);
        });
      }
    });
  }

  Future<void> _toggleSaved() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.isAr(context)
                ? 'يرجى تسجيل الدخول لحفظ مراكز التدريب'
                : 'Please log in to save training centers',
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

    final previous = _isSaved;
    setState(() => _isSaved = !previous);

    try {
      await _firestoreService.toggleFavoriteTrainingCenter(
        uid,
        widget.center.id,
        previous,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSaved = previous);
      }
    }
  }

  Future<void> _launchURL(BuildContext context, String urlStr) async {
    if (urlStr.isEmpty) return;
    final Uri url =
        Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Failed to open link');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.isAr(context)
                  ? 'تعذر فتح الرابط حالياً'
                  : 'Could not open link currently',
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

  Future<void> _makeCall(BuildContext context, String phone) async {
    if (phone.isEmpty) return;
    final Uri uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تعذر إجراء المكالمة',
              style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.direction(context),
      child: DefaultTabController(
        length: 4,
        initialIndex: widget.initialTabIndex,
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBg(context),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: const Color(0xFF7C3AED),
                  iconTheme: const IconThemeData(color: Colors.white),
                  leading: IconButton(
                    icon: Icon(
                      AppStrings.isAr(context)
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isSaved ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: _toggleSaved,
                      tooltip: _isSaved
                          ? (AppStrings.isAr(context)
                              ? 'إلغاء الحفظ'
                              : 'Remove Favorite')
                          : (AppStrings.isAr(context)
                              ? 'حفظ المركز'
                              : 'Save Training Center'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: center.coverImageUrl.isNotEmpty
                        ? CustomCachedImage(
                            imageUrl: center.coverImageUrl,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.apartment_rounded,
                            iconSize: 60,
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.apartment_rounded,
                                size: 70,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surfaceCard(context),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        CustomCachedImage(
                          imageUrl: center.imageUrl,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.circular(28),
                          placeholderIcon: Icons.apartment_rounded,
                          iconSize: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                center.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: AppColors.textMain(context),
                                ),
                              ),
                              if (center.location.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  center.location,
                                  style: TextStyle(
                                    color: AppColors.textMuted(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (center.phone.isNotEmpty) ...[
                          IconButton.filled(
                            onPressed: () => _makeCall(context, center.phone),
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (center.website.isNotEmpty)
                          ElevatedButton(
                            onPressed: () => _launchURL(context, center.website),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
                            ),
                            child: const Text(
                              'الموقع',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surfaceCard(context),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      labelColor: const Color(0xFF7C3AED),
                      unselectedLabelColor: AppColors.textMuted(context),
                      indicatorColor: const Color(0xFF7C3AED),
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 13.5,
                      ),
                      tabs: [
                        Tab(text: 'المنشورات (${center.posts.length})'),
                        Tab(text: 'الدورات والأقسام (${center.colleges.length})'),
                        const Tab(text: 'عن المركز'),
                        Tab(text: 'معرض الصور (${center.gallery.length})'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                _buildPostsTab(context),
                _buildCoursesTab(context),
                _buildAboutTab(context),
                _buildGalleryTab(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsTab(BuildContext context) {
    if (center.posts.isEmpty) {
      return Center(
        child: Text(
          AppStrings.isAr(context)
              ? 'لا توجد منشورات حالياً لهذا المركز'
              : 'No posts currently for this center',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: center.posts.length,
      itemBuilder: (context, index) => PostCard(
        post: center.posts[index],
        universityName: center.name,
        universityLogo: center.imageUrl,
      ),
    );
  }

  Widget _buildCoursesTab(BuildContext context) {
    if (center.colleges.isEmpty) {
      return Center(
        child: Text(
          AppStrings.isAr(context)
              ? 'لا توجد دورات أو أقسام مدرجة حالياً'
              : 'No courses or departments listed currently',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: center.colleges.length,
      itemBuilder: (context, index) =>
          CollegeCard(college: center.colleges[index]),
    );
  }

  Widget _buildAboutTab(BuildContext context) {
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
                    'نبذة عن المركز',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    center.description.isNotEmpty
                        ? center.description
                        : 'لا يوجد وصف متاح حالياً.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: AppColors.textMain(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                    'معلومات التواصل والموقع',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (center.location.isNotEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined,
                          color: Color(0xFF7C3AED)),
                      title: const Text('العنوان والمحافظة'),
                      subtitle: Text(center.location),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  if (center.phone.isNotEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.phone_outlined,
                          color: Colors.green),
                      title: const Text('رقم الهاتف'),
                      subtitle: Text(center.phone),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _makeCall(context, center.phone),
                    ),
                  ],
                  if (center.email.isNotEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.email_outlined,
                          color: Colors.blueAccent),
                      title: const Text('البريد الإلكتروني'),
                      subtitle: Text(center.email),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  if (center.website.isNotEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.language_rounded,
                          color: Colors.teal),
                      title: const Text('الموقع الرسمي'),
                      subtitle: Text(center.website),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _launchURL(context, center.website),
                    ),
                  ],
                  if (center.facebook.isNotEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.facebook_rounded,
                          color: Color(0xFF1877F2)),
                      title: const Text('صفحة فيسبوك'),
                      subtitle: Text(center.facebook),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _launchURL(context, center.facebook),
                    ),
                  ],
                  if (center.instagram.isNotEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.camera_alt_outlined,
                          color: Color(0xFFE4405F)),
                      title: const Text('حساب انستغرام'),
                      subtitle: Text(center.instagram),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _launchURL(context, center.instagram),
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

  Widget _buildGalleryTab(BuildContext context) {
    if (center.gallery.isEmpty) {
      return Center(
        child: Text(
          AppStrings.isAr(context)
              ? 'لا توجد صور حالياً'
              : 'No photos available currently',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: center.gallery.length,
      itemBuilder: (context, index) => CustomCachedImage(
        imageUrl: center.gallery[index],
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        placeholderIcon: Icons.image_rounded,
        iconSize: 24,
      ),
    );
  }
}
