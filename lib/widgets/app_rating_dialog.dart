import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/app_localizations.dart';
import '../services/rating_service.dart';

class AppRatingDialog extends StatefulWidget {
  final bool isAutoPrompt;

  const AppRatingDialog({super.key, this.isAutoPrompt = false});

  @override
  State<AppRatingDialog> createState() => _AppRatingDialogState();
}

class _AppRatingDialogState extends State<AppRatingDialog> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _feedbackSubmitted = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _onDismiss() {
    if (widget.isAutoPrompt) {
      RatingService.markPromptDismissed();
    }
    Navigator.of(context).pop();
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isNotEmpty) {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'anad1990h@gmail.com',
        queryParameters: {
          'subject': 'ملاحظات تقييم التطبيق ($_rating نجوم) - دليل مستقبلي',
          'body': text,
        },
      );
      try {
        await launchUrl(emailUri);
      } catch (_) {}
    }

    await RatingService.markAsRated();
    if (!mounted) return;

    setState(() => _feedbackSubmitted = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.isAr(context)
                ? 'شكراً جزيلاً لملاحظاتك القيمة!'
                : 'Thank you for your valuable feedback!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppStrings.isAr(context);

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Dialog(
        backgroundColor: AppColors.surfaceCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: _feedbackSubmitted
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAr ? 'تم استلام ملاحظتك بنجاح' : 'Feedback Received',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة النجمة اللامعة
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // العنوان
                    Text(
                      isAr
                          ? 'هل يعجبك تطبيق دليل مستقبلي؟'
                          : 'Enjoying Future Guide?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // الوصف
                    Text(
                      isAr
                          ? 'رأيك يهمنا ويسهم في استمرار تحسين التطبيق وخدمة الطلاب بشكل أفضل.'
                          : 'Your rating helps us improve the experience for all students.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted(context),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    // النجوم التفاعلية (1 إلى 5)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        final isFilled = starIndex <= _rating;
                        return InkWell(
                          onTap: () => setState(() => _rating = starIndex),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isFilled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 38,
                              color: isFilled
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.textMuted(context)
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                        );
                      }),
                    ),

                    // قسم إضافي ذكي حسب عدد النجوم المحددة
                    if (_rating >= 4) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAr
                          ? 'سعداء جداً بإعجابك! نسعد بدعمك بتقييم 5 نجوم على متجر Google Play ⭐'
                          : 'We are thrilled! Please consider rating us 5 stars on Google Play ⭐',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMain(context),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            RatingService.launchStoreListing();
                          },
                          icon: const Icon(Icons.rate_review_rounded, size: 20),
                          label: Text(
                            isAr ? 'تقييم في متجر التطبيقات' : 'Rate on Store',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ] else if (_rating >= 1 && _rating <= 3) ...[
                      const SizedBox(height: 14),
                      Text(
                        isAr
                            ? 'نأسف لذلك! أخبرنا كيف يمكننا تحسين التطبيق:'
                            : 'We are sorry! Tell us how we can improve:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _feedbackController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMain(context),
                        ),
                        decoration: InputDecoration(
                          hintText: isAr
                              ? 'اكتب اقتراحك أو سبب التقييم هنا...'
                              : 'Write your suggestion here...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted(context),
                          ),
                          filled: true,
                          fillColor: AppColors.inputFill(context),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: AppColors.border(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: AppColors.border(context)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isAr ? 'إرسال الملاحظة' : 'Send Feedback',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    // زر لاحقاً أو الإلغاء
                    TextButton(
                      onPressed: _onDismiss,
                      child: Text(
                        widget.isAutoPrompt
                            ? (isAr ? 'تذكيري لاحقاً' : 'Remind me later')
                            : (isAr ? 'إلغاء' : 'Cancel'),
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
