import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/scholarship_model.dart';
import '../widgets/scholarship_card.dart';
import '../main.dart';
import 'scholarship_details_screen.dart';

class ScholarshipsScreen extends StatelessWidget {
  const ScholarshipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Text(
            AppStrings.scholarshipsTitle(context),
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
        body: StreamBuilder<List<Scholarship>>(
          stream: firestoreService.getAllScholarships(),
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
                      ? 'لا توجد منح متاحة حالياً'
                      : 'No scholarships available currently',
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 15,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scholarships.length,
              itemBuilder: (context, index) {
                final scholarship = scholarships[index];
                return ScholarshipCard(
                  scholarship: scholarship,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScholarshipDetailsScreen(scholarship: scholarship),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
