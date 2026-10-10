import 'package:flutter/material.dart';
import '../models/scholarship_model.dart';
import '../services/app_localizations.dart';
import '../main.dart';
import 'custom_cached_image.dart';

class ScholarshipCard extends StatelessWidget {
  final Scholarship scholarship;
  final VoidCallback onTap;

  const ScholarshipCard({
    super.key,
    required this.scholarship,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFullyFunded = scholarship.fundingType.contains('كامل') ||
        scholarship.fundingType.toLowerCase().contains('full');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(context)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  AppStrings.isAr(context)
                       ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scholarship.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textMain(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isFullyFunded
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              scholarship.fundingType,
                              style: TextStyle(
                                color: isFullyFunded
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textMuted(context),
                          ),
                          Text(
                            scholarship.country,
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.applicationDeadline(context)}: ${scholarship.deadline}',
                        style: TextStyle(
                          color: Colors.redAccent.shade200,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                CustomCachedImage(
                  imageUrl: scholarship.imageUrl,
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(10),
                  placeholderIcon: Icons.workspace_premium,
                  iconSize: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
