import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/opportunity_model.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../widgets/custom_cached_image.dart';
import '../widgets/college_card.dart';
import '../widgets/post_card.dart';
import '../main.dart';
import 'login_screen.dart';

class OpportunityDetailsScreen extends StatefulWidget {
  final Opportunity opportunity;
  final int initialTabIndex;

  const OpportunityDetailsScreen({
    super.key,
    required this.opportunity,
    this.initialTabIndex = 0,
  });

  @override
  State<OpportunityDetailsScreen> createState() =>
      _OpportunityDetailsScreenState();
}

class _OpportunityDetailsScreenState extends State<OpportunityDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _listenSavedState();
  }

  void _listenSavedState() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _firestoreService.getUserData(uid).listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data() as Map<String, dynamic>;
      final savedIds = List<String>.from(data['savedOpportunities'] ?? []);
      setState(() {
        _isSaved = savedIds.contains(widget.opportunity.id);
      });
    });
  }

  Future<void> _toggleSaveOpportunity() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.loginToFavoriteOpp(context),
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
    final currentlySaved = _isSaved;
    setState(() => _isSaved = !currentlySaved);
    await _firestoreService.toggleSavedOpportunity(
      uid,
      widget.opportunity.id,
      currentlySaved,
    );
  }

  Future<void> _launchURL(BuildContext context) async {
    if (widget.opportunity.registrationLink.isEmpty) {
      _showSnackBar(context, AppStrings.linkNotAvailable(context));
      return;
    }
    final Uri url = Uri.parse(
        widget.opportunity.registrationLink.startsWith('http')
            ? widget.opportunity.registrationLink
            : 'https://${widget.opportunity.registrationLink}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Failed to open link');
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

  Color get _typeColor {
    final t = widget.opportunity.type.toLowerCase();
    if (t.contains('ورش') || t.contains('workshop')) return Colors.blue;
    if (t.contains('مؤتمر') || t.contains('conference')) return Colors.purple;
    if (t.contains('تدريب') || t.contains('training')) return Colors.orange;
    if (t.contains('مسابق') || t.contains('competition')) return Colors.green;
    return const Color(0xFF0284C7);
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
                  backgroundColor: _typeColor,
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
                      icon: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: _isSaved ? Colors.amber : Colors.white,
                      ),
                      onPressed: _toggleSaveOpportunity,
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: widget.opportunity.coverImageUrl.isNotEmpty
                        ? CustomCachedImage(
                            imageUrl: widget.opportunity.coverImageUrl,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.local_activity_rounded,
                            iconSize: 60,
                          )
                        : (widget.opportunity.imageUrl.isNotEmpty
                            ? CustomCachedImage(
                                imageUrl: widget.opportunity.imageUrl,
                                fit: BoxFit.cover,
                                placeholderIcon: Icons.local_activity_rounded,
                                iconSize: 60,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _typeColor,
                                      _typeColor.withValues(alpha: 0.7)
                                    ],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.event_rounded,
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
                          imageUrl: widget.opportunity.imageUrl,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.circular(28),
                          placeholderIcon: Icons.event_note_rounded,
                          iconSize: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.opportunity.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.5,
                                  color: AppColors.textMain(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.opportunity.organizer} • ${widget.opportunity.attendance}',
                                style: TextStyle(
                                  color: AppColors.textMuted(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.opportunity.registrationLink.isNotEmpty)
                          ElevatedButton(
                            onPressed: () => _launchURL(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _typeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppStrings.isAr(context) ? 'تسجيل' : 'Register',
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
                      labelColor: _typeColor,
                      unselectedLabelColor: AppColors.textMuted(context),
                      indicatorColor: _typeColor,
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
                        Tab(
                            text:
                                'المنشورات (${widget.opportunity.posts.length})'),
                        Tab(
                            text:
                                'المحاور والتخصصات (${widget.opportunity.colleges.length})'),
                        const Tab(text: 'عن الفعالية'),
                        Tab(
                            text:
                                'معرض الصور (${widget.opportunity.gallery.length})'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                _buildPostsTab(context),
                _buildTopicsTab(context),
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
    if (widget.opportunity.posts.isEmpty) {
      return Center(
        child: Text(
          AppStrings.isAr(context)
              ? 'لا توجد منشورات حالياً لهذه الفعالية'
              : 'No posts currently for this event',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.opportunity.posts.length,
      itemBuilder: (context, index) => PostCard(
        post: widget.opportunity.posts[index],
        universityName: widget.opportunity.title,
        universityLogo: widget.opportunity.imageUrl,
      ),
    );
  }

  Widget _buildTopicsTab(BuildContext context) {
    if (widget.opportunity.colleges.isEmpty) {
      return Center(
        child: Text(
          AppStrings.isAr(context)
              ? 'الفعالية متاحة لكافة الطلاب والمهتمين'
              : 'Event open for all interested students',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.opportunity.colleges.length,
      itemBuilder: (context, index) =>
          CollegeCard(college: widget.opportunity.colleges[index]),
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
                label: Text(widget.opportunity.type),
                backgroundColor: _typeColor.withValues(alpha: 0.1),
                side: BorderSide(color: _typeColor.withValues(alpha: 0.3)),
              ),
              Chip(
                label: Text(widget.opportunity.attendance),
                backgroundColor: AppColors.surfaceCard(context),
                side: BorderSide(color: AppColors.border(context)),
              ),
              if (widget.opportunity.price.isNotEmpty)
                Chip(
                  label: Text(widget.opportunity.price),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
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
                    'معلومات الفعالية والتسجيل',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (widget.opportunity.date.isNotEmpty)
                    _infoRow(
                      Icons.calendar_today_outlined,
                      AppStrings.isAr(context) ? 'التاريخ' : 'Date',
                      widget.opportunity.date,
                    ),
                  if (widget.opportunity.location.isNotEmpty)
                    _infoRow(
                      Icons.location_on_outlined,
                      AppStrings.isAr(context) ? 'الموقع' : 'Location',
                      widget.opportunity.location,
                    ),
                  if (widget.opportunity.targetAudience.isNotEmpty)
                    _infoRow(
                      Icons.people_outline,
                      AppStrings.isAr(context)
                          ? 'الفئة المستهدفة'
                          : 'Target Audience',
                      widget.opportunity.targetAudience,
                    ),
                  if (widget.opportunity.registrationDeadline.isNotEmpty)
                    _infoRow(
                      Icons.access_time,
                      AppStrings.isAr(context)
                          ? 'آخر موعد للتسجيل'
                          : 'Registration Deadline',
                      widget.opportunity.registrationDeadline,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.opportunity.description.isNotEmpty) ...[
            Card(
              color: AppColors.surfaceCard(context),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التفاصيل والوصف',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.opportunity.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textMain(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (widget.opportunity.registrationLink.isNotEmpty)
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
                  backgroundColor: _typeColor,
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _typeColor),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab(BuildContext context) {
    if (widget.opportunity.gallery.isEmpty) {
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
      itemCount: widget.opportunity.gallery.length,
      itemBuilder: (context, index) => CustomCachedImage(
        imageUrl: widget.opportunity.gallery[index],
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        placeholderIcon: Icons.image_rounded,
        iconSize: 24,
      ),
    );
  }
}
