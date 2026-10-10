import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scholarship_model.dart';
import '../services/app_localizations.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_cached_image.dart';
import '../widgets/college_card.dart';
import '../widgets/post_card.dart';
import '../main.dart';

class ScholarshipDetailsScreen extends StatefulWidget {
  final Scholarship scholarship;
  final int initialTabIndex;

  const ScholarshipDetailsScreen({
    super.key,
    required this.scholarship,
    this.initialTabIndex = 0,
  });

  @override
  State<ScholarshipDetailsScreen> createState() =>
      _ScholarshipDetailsScreenState();
}

class _ScholarshipDetailsScreenState extends State<ScholarshipDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaved = false;
  Scholarship get scholarship => widget.scholarship;

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
        final saved = List<String>.from(data['savedScholarships'] ?? []);
        setState(() {
          _isSaved = saved.contains(widget.scholarship.id);
        });
      }
    });
  }

  Future<void> _toggleSaved() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showSnackBar(
        context,
        AppStrings.isAr(context)
            ? 'يرجى تسجيل الدخول لحفظ المنح الدراسية'
            : 'Please log in to save scholarships',
      );
      return;
    }

    final previous = _isSaved;
    setState(() => _isSaved = !previous);

    try {
      await _firestoreService.toggleFavoriteScholarship(
        uid,
        widget.scholarship.id,
        previous,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSaved = previous);
      }
    }
  }

  Future<void> _launchURL(BuildContext context) async {
    if (widget.scholarship.officialLink.isEmpty) {
      _showSnackBar(context, AppStrings.linkNotAvailable(context));
      return;
    }
    final Uri url = Uri.parse(
        widget.scholarship.officialLink.startsWith('http')
            ? widget.scholarship.officialLink
            : 'https://${widget.scholarship.officialLink}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Failed to open';
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          AppStrings.isAr(context)
              ? 'تعذر فتح الرابط حالياً'
              : 'Could not open link currently',
        );
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
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
        backgroundColor: AppColors.isDark(context)
            ? const Color(0xFF1E293B)
            : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                  backgroundColor: const Color(0xFFEA580C),
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
                              ? 'حفظ المنحة'
                              : 'Save Scholarship'),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () => _launchURL(context),
                      tooltip: AppStrings.visitWebsite(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: scholarship.coverImageUrl.isNotEmpty
                        ? CustomCachedImage(
                            imageUrl: scholarship.coverImageUrl,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.workspace_premium_rounded,
                            iconSize: 60,
                          )
                        : (scholarship.imageUrl.isNotEmpty
                            ? CustomCachedImage(
                                imageUrl: scholarship.imageUrl,
                                fit: BoxFit.cover,
                                placeholderIcon:
                                    Icons.workspace_premium_rounded,
                                iconSize: 60,
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFEA580C),
                                      Color(0xFF9A3412)
                                    ],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 70,
                                    color: Colors.white24,
                                  ),
                                ),
                              )),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surfaceCard(context),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        CustomCachedImage(
                          imageUrl: scholarship.imageUrl,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.circular(28),
                          placeholderIcon: Icons.school_rounded,
                          iconSize: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scholarship.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.5,
                                  color: AppColors.textMain(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${scholarship.fundingType} • ${scholarship.country}',
                                style: TextStyle(
                                  color: AppColors.textMuted(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (scholarship.officialLink.isNotEmpty)
                          ElevatedButton(
                            onPressed: () => _launchURL(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppStrings.isAr(context)
                                  ? 'تقديم'
                                  : 'Apply',
                              style: const TextStyle(fontSize: 12),
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
                      labelColor: const Color(0xFFEA580C),
                      unselectedLabelColor: AppColors.textMuted(context),
                      indicatorColor: const Color(0xFFEA580C),
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
                        Tab(text: 'المنشورات (${scholarship.posts.length})'),
                        Tab(
                            text:
                                'التخصصات المشمولة (${scholarship.colleges.length})'),
                        const Tab(text: 'عن المنحة'),
                        Tab(text: 'معرض الصور (${scholarship.gallery.length})'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                _buildPostsTab(context),
                _buildCollegesTab(context),
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
    if (scholarship.posts.isEmpty) {
      return Center(
        child: Text(
          AppStrings.isAr(context)
              ? 'لا توجد منشورات حالياً لهذه المنحة'
              : 'No posts currently for this scholarship',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scholarship.posts.length,
      itemBuilder: (context, index) => PostCard(
        post: scholarship.posts[index],
        universityName: scholarship.name,
        universityLogo: scholarship.imageUrl,
      ),
    );
  }

  Widget _buildCollegesTab(BuildContext context) {
    if (scholarship.colleges.isEmpty) {
      return Center(
        child: Text(
          AppStrings.isAr(context)
              ? 'المنحة متاحة لكافة التخصصات أو لم يتم تحديد تخصصات بعد'
              : 'Scholarship open for all majors or not specified yet',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scholarship.colleges.length,
      itemBuilder: (context, index) =>
          CollegeCard(college: scholarship.colleges[index]),
    );
  }

  Widget _buildAboutTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  scholarship.fundingType,
                  style: TextStyle(color: AppColors.textMain(context)),
                ),
                backgroundColor: AppColors.surfaceCard(context),
                side: BorderSide(color: AppColors.border(context)),
              ),
              Chip(
                label: Text(
                  scholarship.country,
                  style: const TextStyle(color: Color(0xFFEA580C)),
                ),
                backgroundColor: const Color(0xFFEA580C).withValues(alpha: 0.1),
                side: BorderSide(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
              ),
              if (scholarship.deadline.isNotEmpty)
                Chip(
                  label: Text(
                    '${AppStrings.applicationDeadline(context)}: ${scholarship.deadline}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
            ],
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
                  const Text(
                    'تفاصيل وشروط القبول',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    scholarship.description.isNotEmpty
                        ? scholarship.description
                        : 'لا يوجد وصف تفصيلي متاح حالياً.',
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
          const SizedBox(height: 24),
          if (scholarship.officialLink.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _launchURL(context),
                icon: const Icon(Icons.open_in_browser_rounded,
                    color: Colors.white),
                label: Text(
                  AppStrings.registrationLink(context),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab(BuildContext context) {
    if (scholarship.gallery.isEmpty) {
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
      itemCount: scholarship.gallery.length,
      itemBuilder: (context, index) => CustomCachedImage(
        imageUrl: scholarship.gallery[index],
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        placeholderIcon: Icons.image_rounded,
        iconSize: 24,
      ),
    );
  }
}