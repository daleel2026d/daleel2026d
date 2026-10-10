import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/opportunity_model.dart';
import '../models/scholarship_model.dart';
import '../models/training_center_model.dart';
import '../widgets/scholarship_card.dart';
import '../widgets/opportunity_card.dart';
import '../widgets/custom_cached_image.dart';
import '../main.dart';
import 'scholarship_details_screen.dart';
import 'opportunity_details_screen.dart';
import 'training_centers_screen.dart';
import 'training_center_details_screen.dart';

class ScholarshipsOpportunitiesScreen extends StatefulWidget {
  const ScholarshipsOpportunitiesScreen({super.key});

  @override
  State<ScholarshipsOpportunitiesScreen> createState() =>
      _ScholarshipsOpportunitiesScreenState();
}

class _ScholarshipsOpportunitiesScreenState
    extends State<ScholarshipsOpportunitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedTab = 'scholarships'; // 'scholarships', 'opportunities', 'centers'

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Text(
            AppStrings.navScholarships(context),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
        body: Column(
          children: [
            // 1. عنصر مراكز التدريب في بداية الصفحة فوق الشريط (على شكل مبنى + تحته الاسم + تحته عدد المراكز)
            _buildTopTrainingCentersHeader(),

            // 2. شريط التصفية
            _buildFilterBar(),

            // 3. المحتوى
            Expanded(
              child: _buildSelectedTabView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTrainingCentersHeader() {
    return StreamBuilder<List<TrainingCenter>>(
      stream: _firestoreService.getAllTrainingCenters(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        final isSelected = _selectedTab == 'centers';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrainingCentersScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.12)
                        : AppColors.surfaceCard(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : AppColors.border(context),
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF7C3AED).withValues(alpha: 0.18)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // شكل المبنى
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF7C3AED).withValues(alpha: 0.12),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(0xFF7C3AED)
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Icon(
                          Icons.apartment_rounded,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF7C3AED),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // كلمة مراكز التدريب
                      Text(
                        AppStrings.isAr(context)
                            ? 'مراكز التدريب'
                            : 'Training Centers',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : AppColors.textMain(context),
                        ),
                      ),
                      const SizedBox(height: 1),

                      // عدد المراكز
                      Text(
                        AppStrings.isAr(context)
                            ? '$count مركز'
                            : '$count Centers',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            _filterButton(
              value: 'scholarships',
              label: AppStrings.isAr(context) ? 'منح' : 'Scholarships',
            ),
            _filterButton(
              value: 'opportunities',
              label: AppStrings.isAr(context) ? 'فرص' : 'Opportunities',
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton({required String value, required String label}) {
    final isSelected = _selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = value),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryDark
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMain(context),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 11.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabView() {
    switch (_selectedTab) {
      case 'opportunities':
        return _buildOpportunitiesView();
      case 'centers':
        return _buildTrainingCentersView();
      case 'scholarships':
      default:
        return _buildScholarshipsView();
    }
  }

  Widget _buildScholarshipsView() {
    return StreamBuilder<List<Scholarship>>(
      stream: _firestoreService.getAllScholarships(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryDark),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${snapshot.error}',
              style: TextStyle(color: AppColors.textMain(context)),
            ),
          );
        }

        final scholarships = snapshot.data ?? [];
        if (scholarships.isEmpty) {
          return Center(
            child: Text(
              AppStrings.isAr(context)
                  ? 'لا توجد منح دراسية متاحة حالياً'
                  : 'No scholarships available currently',
              style: TextStyle(color: AppColors.textMuted(context)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: scholarships.length,
          itemBuilder: (context, index) {
            final s = scholarships[index];
            return ScholarshipCard(
              scholarship: s,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ScholarshipDetailsScreen(scholarship: s),
                ),
              ),
            );
          },
        );
      },
    );
  }

  DateTime _parseOpportunityDate(String date) {
    final clean = date.trim();
    if (clean.isEmpty) return DateTime.now();
    try {
      final normalized = clean.replaceAll('/', '-');
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) return parsed;
      final parts = normalized.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else if (parts[2].length == 4) {
          return DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}
    return DateTime.now();
  }

  Widget _buildOpportunitiesView() {
    return StreamBuilder<List<Opportunity>>(
      stream: _firestoreService.getAllOpportunities(),
      builder: (context, oppSnapshot) {
        return StreamBuilder<List<TrainingCenter>>(
          stream: _firestoreService.getAllTrainingCenters(),
          builder: (context, centerSnapshot) {
            if (oppSnapshot.connectionState == ConnectionState.waiting &&
                centerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryDark),
              );
            }
            if (oppSnapshot.hasError && centerSnapshot.hasError) {
              return Center(
                child: Text(
                  '${oppSnapshot.error ?? centerSnapshot.error}',
                  style: TextStyle(color: AppColors.textMain(context)),
                ),
              );
            }

            final directOpps = oppSnapshot.data ?? [];
            final centers = centerSnapshot.data ?? [];

            // تحويل منشورات مراكز التدريب إلى فرص تظهر في القائمة
            final List<Opportunity> centerOpps = [];
            final Map<String, TrainingCenter> oppCenterMap = {};

            for (var center in centers) {
              for (var post in center.posts) {
                final oppId = 'tc_${center.id}_${post.title}_${post.date}';
                final opp = Opportunity(
                  id: oppId,
                  title: post.title,
                  description: post.description,
                  organizer: center.name,
                  type: 'تدريب',
                  attendance:
                      center.location.isNotEmpty ? center.location : 'حضوري',
                  targetAudience: 'الجميع',
                  date: post.date,
                  registrationDeadline: '',
                  price: 'تدريب',
                  registrationLink: center.website.isNotEmpty
                      ? center.website
                      : (center.phone.isNotEmpty ? center.phone : ''),
                  imageUrl: post.imageUrl.isNotEmpty
                      ? post.imageUrl
                      : center.imageUrl,
                  coverImageUrl: center.coverImageUrl,
                  location: center.location,
                );
                centerOpps.add(opp);
                oppCenterMap[oppId] = center;
              }
            }

            final List<Opportunity> allOpportunities = [
              ...directOpps,
              ...centerOpps,
            ];

            allOpportunities.sort((a, b) {
              final aDate = _parseOpportunityDate(a.date);
              final bDate = _parseOpportunityDate(b.date);
              return bDate.compareTo(aDate);
            });

            if (allOpportunities.isEmpty) {
              return Center(
                child: Text(
                  AppStrings.isAr(context)
                      ? 'لا توجد فرص وفعاليات متاحة حالياً'
                      : 'No opportunities available currently',
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: allOpportunities.length,
              itemBuilder: (context, index) {
                final opp = allOpportunities[index];
                final linkedCenter = oppCenterMap[opp.id];

                return OpportunityCard(
                  opportunity: opp,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => linkedCenter != null
                          ? TrainingCenterDetailsScreen(center: linkedCenter)
                          : OpportunityDetailsScreen(opportunity: opp),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTrainingCentersView() {
    return StreamBuilder<List<TrainingCenter>>(
      stream: _firestoreService.getAllTrainingCenters(),
      builder: (context, centersSnapshot) {
        return StreamBuilder<List<Opportunity>>(
          stream: _firestoreService.getAllOpportunities(),
          builder: (context, oppsSnapshot) {
            if (centersSnapshot.connectionState == ConnectionState.waiting &&
                oppsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryDark),
              );
            }

            final dedicatedCenters = centersSnapshot.data ?? [];
            final opportunities = oppsSnapshot.data ?? [];

            // خريطة الفرص حسب اسم الجهة أو المركز
            final Map<String, List<Opportunity>> oppsByOrganizer = {};
            for (var opp in opportunities) {
              final org = opp.organizer.trim();
              if (org.isNotEmpty) {
                oppsByOrganizer.putIfAbsent(org, () => []).add(opp);
              }
            }

            if (dedicatedCenters.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        size: 40,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.isAr(context)
                          ? 'لا توجد مراكز تدريب مضافة حالياً'
                          : 'No training centers added yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: dedicatedCenters.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final center = dedicatedCenters[index];
                final centerOpps = oppsByOrganizer[center.name] ??
                    opportunities
                        .where((o) =>
                            o.organizer.trim().toLowerCase() ==
                            center.name.trim().toLowerCase())
                        .toList();

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.lavenderCard(context),
                              border: Border.all(
                                color: AppColors.border(context),
                                width: 1.5,
                              ),
                            ),
                            child: center.imageUrl.isNotEmpty
                                ? CustomCachedImage(
                                    imageUrl: center.imageUrl,
                                    width: 50,
                                    height: 50,
                                    borderRadius: BorderRadius.circular(25),
                                    placeholderIcon:
                                        Icons.business_rounded,
                                  )
                                : Icon(
                                    Icons.business_rounded,
                                    size: 26,
                                    color: AppColors.isDark(context)
                                        ? const Color(0xFF38BDF8)
                                        : AppColors.primaryDark,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  center.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain(context),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: AppColors.textMuted(context),
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        center.location.isNotEmpty
                                            ? center.location
                                            : (AppStrings.isAr(context)
                                                ? 'جهة معتمدة للتدريب والتطوير'
                                                : 'Certified Training Entity'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              AppColors.textMuted(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (centerOpps.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${centerOpps.length} ${AppStrings.isAr(context) ? 'فرص' : 'Opps'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.isDark(context)
                                      ? const Color(0xFF38BDF8)
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (center.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          center.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted(context),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (center.specialties.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: center.specialties.take(4).map((spec) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lavenderCard(context),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.border(context),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                spec,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textMain(context),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCenterFullDetailsModal(
                                context,
                                center,
                                centerOpps,
                              ),
                              icon: const Icon(Icons.info_outline_rounded,
                                  size: 16),
                              label: Text(
                                centerOpps.isNotEmpty
                                    ? (AppStrings.isAr(context)
                                        ? 'الفرص والتفاصيل (${centerOpps.length})'
                                        : 'Details & Opps (${centerOpps.length})')
                                    : (AppStrings.isAr(context)
                                        ? 'تفاصيل المركز'
                                        : 'Center Details'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.isDark(context)
                                    ? const Color(0xFF38BDF8)
                                    : AppColors.primaryDark,
                                side: BorderSide(
                                  color: AppColors.isDark(context)
                                      ? const Color(0xFF38BDF8)
                                      : AppColors.primaryDark,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          if (center.phone.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: () => _launchContactUri(
                                  'tel:${center.phone.trim()}'),
                              icon: const Icon(Icons.phone_rounded, size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.green.withValues(alpha: 0.15),
                                foregroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                          if (center.website.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: () => _launchContactUri(
                                  center.website.trim()),
                              icon: const Icon(Icons.language_rounded,
                                  size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    AppColors.primaryDark.withValues(alpha: 0.1),
                                foregroundColor: AppColors.isDark(context)
                                    ? const Color(0xFF38BDF8)
                                    : AppColors.primaryDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _launchContactUri(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showCenterFullDetailsModal(
    BuildContext context,
    TrainingCenter center,
    List<Opportunity> centerOpps,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          center.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (center.description.isNotEmpty) ...[
                        Text(
                          AppStrings.isAr(context)
                              ? 'عن مركز التدريب:'
                              : 'About Center:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          center.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted(context),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (center.location.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 16, color: Colors.redAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                center.location,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMain(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (center.phone.isNotEmpty ||
                          center.website.isNotEmpty ||
                          center.email.isNotEmpty) ...[
                        Row(
                          children: [
                            if (center.phone.isNotEmpty)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchContactUri(
                                      'tel:${center.phone.trim()}'),
                                  icon: const Icon(Icons.phone, size: 16),
                                  label: Text(AppStrings.isAr(context)
                                      ? 'اتصال / واتساب'
                                      : 'Call / WhatsApp'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            if (center.phone.isNotEmpty &&
                                center.website.isNotEmpty)
                              const SizedBox(width: 10),
                            if (center.website.isNotEmpty)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchContactUri(
                                      center.website.trim()),
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: Text(AppStrings.isAr(context)
                                      ? 'الموقع / الرابط'
                                      : 'Website / Link'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryDark,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (centerOpps.isNotEmpty) ...[
                        Text(
                          AppStrings.isAr(context)
                              ? 'الفرص والدورات المتاحة حالياً (${centerOpps.length}):'
                              : 'Available Courses & Opps (${centerOpps.length}):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...centerOpps.map(
                          (opp) => OpportunityCard(
                            opportunity: opp,
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OpportunityDetailsScreen(
                                          opportunity: opp),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
