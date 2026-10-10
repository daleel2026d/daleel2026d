import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../services/app_localizations.dart';

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
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
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
            ],
          ),
        ),
      ),
    );
  }
}