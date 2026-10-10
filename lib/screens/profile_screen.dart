import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/university_model.dart';
import '../models/opportunity_model.dart';
import '../widgets/custom_cached_image.dart';
import '../main.dart';
import 'login_screen.dart';
import 'university_details_screen.dart';
import 'opportunity_details_screen.dart';
import 'account_settings_screen.dart';
import 'settings_screen.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_university_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.direction(context),
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;
          if (user == null) {
            return _buildGuestView(context);
          }
          return _buildUserProfileView(context, user.uid);
        },
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: Text(
          AppStrings.profile(context),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.settings(context),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // بطاقة الترحيب بحساب الزائر
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.isDark(context)
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                          : AppColors.primaryDark.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 44,
                      color: AppColors.isDark(context)
                          ? const Color(0xFF38BDF8)
                          : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lavenderCard(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppStrings.guestMode(context),
                      style: TextStyle(
                        color: AppColors.isDark(context)
                            ? const Color(0xFF38BDF8)
                            : AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.welcomeToGuide(context),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.guestPromptDesc(context),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted(context),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login_rounded, size: 20),
                      label: Text(
                        AppStrings.loginOrRegister(context),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppColors.primaryDark.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // عنوان المزايا
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: AppColors.isDark(context)
                      ? const Color(0xFF38BDF8)
                      : AppColors.primaryDark,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.whyCreateAccount(context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // كروت المزايا
            _buildFeatureItem(
              icon: Icons.favorite_rounded,
              iconColor: Colors.redAccent,
              title: AppStrings.featFavUnis(context),
              subtitle: AppStrings.featFavUnisDesc(context),
            ),
            const SizedBox(height: 10),
            _buildFeatureItem(
              icon: Icons.workspace_premium_rounded,
              iconColor: Colors.amber.shade700,
              title: AppStrings.featOpp(context),
              subtitle: AppStrings.featOppDesc(context),
            ),
            const SizedBox(height: 10),
            _buildFeatureItem(
              icon: Icons.tune_rounded,
              iconColor: AppColors.accentBlue,
              title: AppStrings.featCustomize(context),
              subtitle: AppStrings.featCustomizeDesc(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.isDark(context)
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                        : AppColors.primaryDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: AppColors.isDark(context)
                        ? const Color(0xFF38BDF8)
                        : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain(context),
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted(context),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  AppStrings.isAr(context)
                      ? Icons.arrow_back_ios_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileView(BuildContext context, String uid) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: Text(
          AppStrings.profile(context),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.settings(context),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getUserData(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryDark),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                AppStrings.userNotFound(context),
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String name = userData['name'] ?? '';
          final String email = userData['email'] ?? '';
          final String track = userData['track'] ?? '';
          final double average = (userData['average'] ?? 0).toDouble();
          final List<String> favoriteIds = List<String>.from(
            userData['favorites'] ?? [],
          );
          final List<String> savedOpportunityIds = List<String>.from(
            userData['savedOpportunities'] ?? [],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: AppColors.surfaceCard(context),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.isDark(context)
                              ? const Color(0xFF38BDF8)
                              : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name.isNotEmpty
                            ? name
                            : (AppStrings.isAr(context)
                                ? 'طالب / مستخدم'
                                : 'Student / User'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain(context),
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 13,
                        ),
                      ),
                      if (track.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppStrings.trackLabel(context, track, average),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // لوحة التحكم الإدارية (تظهر للمتحكم بالتطبيق)
                if (AuthService.isAdmin(FirebaseAuth.instance.currentUser))
                  _buildProfileOptionTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: AppStrings.isAr(context)
                        ? 'لوحة التحكم الإدارية'
                        : 'Admin Dashboard',
                    subtitle: AppStrings.isAr(context)
                        ? 'إدارة الجامعات والكليات، المنح، الفرص، ومراكز التدريب'
                        : 'Manage universities, scholarships, opportunities & centers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),

                // إدارة الجامعة (تظهر لأي إيميل مسجل كمدير لجامعة أو كلية)
                StreamBuilder<List<University>>(
                  stream: _firestoreService.getUniversitiesManagedBy(
                    (email.isNotEmpty
                            ? email
                            : FirebaseAuth.instance.currentUser?.email ?? '')
                        .trim()
                        .toLowerCase(),
                  ),
                  builder: (context, snapshot) {
                    final managed = snapshot.data ?? [];
                    if (managed.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final uni in managed)
                          _buildProfileOptionTile(
                            icon: Icons.apartment_outlined,
                            title: AppStrings.isAr(context)
                                ? 'إدارة الجامعة (${uni.name})'
                                : 'Manage University (${uni.name})',
                            subtitle: AppStrings.isAr(context)
                                ? 'تعديل بيانات وصور وكليات الجامعة'
                                : 'Edit university details, photos & colleges',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminUniversityEditScreen(
                                    university: uni,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 14),

                Text(
                  AppStrings.favUniversities(context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
                const SizedBox(height: 12),

                if (favoriteIds.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.lavenderCard(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Center(
                      child: Text(
                        AppStrings.noFavUniversities(context),
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  StreamBuilder<List<University>>(
                    stream: _firestoreService.getAllUniversities(),
                    builder: (context, uniSnapshot) {
                      if (!uniSnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryDark,
                          ),
                        );
                      }
                      final favoriteUniversities = uniSnapshot.data!
                          .where((uni) => favoriteIds.contains(uni.id))
                          .toList();
                      if (favoriteUniversities.isEmpty) {
                        return Text(
                          AppStrings.noFavUniversities(context),
                          style: TextStyle(color: AppColors.textMuted(context)),
                        );
                      }

                      return Column(
                        children: favoriteUniversities.map((uni) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.lavenderCard(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                leading: CustomCachedImage(
                                  imageUrl: uni.logoUrl,
                                  width: 40,
                                  height: 40,
                                  borderRadius: BorderRadius.circular(20),
                                  placeholderIcon: Icons.account_balance,
                                  iconSize: 20,
                                ),
                                title: Text(
                                  uni.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain(context),
                                  ),
                                ),
                                subtitle: Text(
                                  '${uni.city} • ${uni.type}',
                                  style: TextStyle(
                                    color: AppColors.textMuted(context),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                  tooltip: AppStrings.isAr(context)
                                      ? 'إزالة من المفضلة'
                                      : 'Remove from favorites',
                                  onPressed: () async {
                                    await _firestoreService.toggleFavorite(
                                      uid,
                                      uni.id,
                                      true,
                                    );
                                  },
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UniversityDetailsScreen(
                                          university: uni,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                const SizedBox(height: 20),
                Text(
                  AppStrings.savedOpportunities(context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain(context),
                  ),
                ),
                const SizedBox(height: 12),

                if (savedOpportunityIds.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.lavenderCard(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Center(
                      child: Text(
                        AppStrings.noSavedOpportunities(context),
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  StreamBuilder<List<Opportunity>>(
                    stream: _firestoreService.getSavedOpportunities(
                      savedOpportunityIds,
                    ),
                    builder: (context, oppSnapshot) {
                      if (oppSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryDark,
                          ),
                        );
                      }
                      if (!oppSnapshot.hasData || oppSnapshot.data!.isEmpty) {
                        return Text(
                          AppStrings.noSavedOpportunities(context),
                          style: TextStyle(color: AppColors.textMuted(context)),
                        );
                      }
                      final savedOpportunities = oppSnapshot.data!;
                      return Column(
                        children: savedOpportunities.map((opportunity) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border(context)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OpportunityDetailsScreen(
                                        opportunity: opportunity,
                                      ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CustomCachedImage(
                                    imageUrl: opportunity.imageUrl,
                                    width: 80,
                                    height: 80,
                                    borderRadius: BorderRadius.circular(12),
                                    placeholderIcon: Icons.event,
                                    iconSize: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          opportunity.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textMain(context),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          opportunity.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted(context),
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          opportunity.date,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      await _firestoreService
                                          .toggleSavedOpportunity(
                                            uid,
                                            opportunity.id,
                                            true,
                                          );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.close,
                                        color: AppColors.textMuted(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                const SizedBox(height: 20),
                Divider(color: AppColors.border(context)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.manage_accounts_outlined,
                    color: AppColors.isDark(context)
                        ? const Color(0xFF38BDF8)
                        : AppColors.primaryDark,
                  ),
                  title: Text(
                    AppStrings.editAccountSettings(context),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain(context),
                    ),
                  ),
                  trailing: Icon(
                    AppStrings.isAr(context)
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textMuted(context),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountSettingsScreen(
                        currentName: name,
                        currentTrack: track,
                        currentAverage: average,
                      ),
                    ),
                  ),
                ),
                Divider(color: AppColors.border(context)),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
