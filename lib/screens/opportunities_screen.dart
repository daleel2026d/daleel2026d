import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/opportunity_model.dart';
import '../models/training_center_model.dart';
import '../widgets/opportunity_card.dart';
import '../main.dart';
import 'opportunity_details_screen.dart';
import 'training_center_details_screen.dart';

class OpportunitiesScreen extends StatelessWidget {
  final String? filterType;
  const OpportunitiesScreen({super.key, this.filterType});

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

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    final Stream<List<Opportunity>> stream =
        (filterType != null && filterType!.isNotEmpty)
            ? firestoreService.getOpportunitiesByType(filterType!)
            : firestoreService.getAllOpportunities();

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Text(
            AppStrings.opportunitiesTitle(context),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          leading: IconButton(
            icon: Icon(
              AppStrings.isAr(context)
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<List<Opportunity>>(
          stream: stream,
          builder: (context, oppSnapshot) {
            return StreamBuilder<List<TrainingCenter>>(
              stream: firestoreService.getAllTrainingCenters(),
              builder: (context, centerSnapshot) {
                if (oppSnapshot.connectionState == ConnectionState.waiting &&
                    centerSnapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDark,
                    ),
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

                final List<Opportunity> centerOpps = [];
                final Map<String, TrainingCenter> oppCenterMap = {};

                final shouldIncludeCenters = filterType == null ||
                    filterType!.isEmpty ||
                    filterType == 'تدريب' ||
                    filterType == 'all';

                if (shouldIncludeCenters) {
                  for (var center in centers) {
                    for (var post in center.posts) {
                      final oppId =
                          'tc_${center.id}_${post.title}_${post.date}';
                      final opp = Opportunity(
                        id: oppId,
                        title: post.title,
                        description: post.description,
                        organizer: center.name,
                        type: 'تدريب',
                        attendance: center.location.isNotEmpty
                            ? center.location
                            : 'حضوري',
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 60,
                          color: AppColors.textMuted(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.isAr(context)
                              ? 'لا توجد فرص أو فعاليات متاحة حالياً'
                              : 'No opportunities or events available currently',
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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
                              ? TrainingCenterDetailsScreen(
                                  center: linkedCenter)
                              : OpportunityDetailsScreen(opportunity: opp),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
