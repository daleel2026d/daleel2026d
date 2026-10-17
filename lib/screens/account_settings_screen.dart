import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../services/app_localizations.dart';
import '../services/auth_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String currentName;
  final String currentTrack;
  final double currentAverage;

  const AccountSettingsScreen({
    super.key,
    required this.currentName,
    required this.currentTrack,
    required this.currentAverage,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _averageController;
  late String _selectedTrack;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _averageController = TextEditingController(
      text: widget.currentAverage > 0 ? widget.currentAverage.toString() : '',
    );
    _selectedTrack =
        widget.currentTrack.isNotEmpty ? widget.currentTrack : 'علمي';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _averageController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) return;
    final double? average = double.tryParse(_averageController.text.trim());
    if (average == null) return;

    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'average': average,
        'track': _selectedTrack,
      });
    }
    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: AppStrings.direction(context),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceCard(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red,
                  size: 26,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.isAr(context)
                      ? 'حذف الحساب نهائياً'
                      : 'Delete Account Permanently',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.isAr(context)
                    ? 'هل أنت متأكد من رغبتك في حذف حسابك نهائياً؟'
                    : 'Are you sure you want to permanently delete your account?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain(context),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.isAr(context)
                            ? 'تحذير: هذا الإجراء لا يمكن التراجع عنه. سيتم مسح جميع بياناتك، الجامعات المفضلة، والفرص المحفوظة نهائياً من التطبيق.'
                            : 'Warning: This action is irreversible. All your data, favorites, and saved opportunities will be permanently wiped.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppStrings.cancel(context),
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                AppStrings.isAr(context) ? 'نعم، احذف الحساب' : 'Yes, Delete Account',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      _executeDeleteAccount();
    }
  }

  Future<void> _executeDeleteAccount() async {
    setState(() => _isDeleting = true);
    final error = await AuthService().deleteAccount();
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.isAr(context)
                ? 'تم حذف حسابك بنجاح نهائياً'
                : 'Your account has been deleted permanently',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      // إغلاق الشاشة والرجوع للشاشة الرئيسية
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: AppStrings.direction(context),
          child: AlertDialog(
            backgroundColor: AppColors.surfaceCard(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  AppStrings.isAr(context) ? 'تنبيه' : 'Notice',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              error,
              style: TextStyle(color: AppColors.textMain(context), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppStrings.isAr(context) ? 'حسناً' : 'OK',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _trackButton(String keyLabel, String displayLabel) {
    final bool isSelected = _selectedTrack == keyLabel;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: () => setState(() => _selectedTrack = keyLabel),
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected
                ? AppColors.primaryDark
                : AppColors.surfaceCard(context),
            foregroundColor: isSelected
                ? Colors.white
                : AppColors.textMain(context),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryDark
                  : AppColors.border(context),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(displayLabel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: Text(
            AppStrings.editAccountSettings(context),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.fullName(context),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: TextStyle(color: AppColors.textMain(context)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputFill(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.schoolAverage(context),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _averageController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.textMain(context)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputFill(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.studyBranch(context),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain(context),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _trackButton('علمي', AppStrings.trackScientific(context)),
                  _trackButton('أدبي', AppStrings.trackLiterary(context)),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving || _isDeleting ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          AppStrings.saveChanges(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),

              // مسافة فاصلة آمنة تفصل زر الحفظ عن منطقة حذف الحساب
              const SizedBox(height: 55),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      AppStrings.isAr(context) ? 'منطقة الخطر' : 'Danger Zone',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border(context))),
                ],
              ),
              const SizedBox(height: 16),

              // بطاقة حذف الحساب
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.isDark(context)
                      ? Colors.red.withValues(alpha: 0.06)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_remove_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.isAr(context)
                                    ? 'حذف الحساب نهائياً'
                                    : 'Delete Account Permanently',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppStrings.isAr(context)
                                    ? 'سيتم مسح حسابك وكافة بياناتك وسجلاتك بشكل دائم.'
                                    : 'Your account and all associated data will be permanently wiped.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting || _isSaving
                            ? null
                            : _confirmDeleteAccount,
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : const Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                        label: Text(
                          _isDeleting
                              ? (AppStrings.isAr(context)
                                  ? 'جارٍ حذف الحساب...'
                                  : 'Deleting Account...')
                              : (AppStrings.isAr(context)
                                  ? 'حذف الحساب'
                                  : 'Delete Account'),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}