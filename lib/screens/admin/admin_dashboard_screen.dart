import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import 'admin_universities_screen.dart';
import 'admin_scholarships_screen.dart';
import 'admin_opportunities_screen.dart';
import 'admin_training_centers_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final bool hasAdminAccess = AuthService.isAdmin(user);

        // إذا كان المستخدم مسجل دخول وهو المدير المصرح له -> عرض لوحة التحكم
        if (hasAdminAccess) {
          return _buildDashboardContent(context, user!);
        }

        // إذا لم يكن مسجلاً أو حسابه ليس مديراً -> عرض شاشة تسجيل دخول المدير
        return _buildAdminLoginGate(context, user);
      },
    );
  }

  // ===== واجهة لوحة التحكم الكاملة للمدير =====
  Widget _buildDashboardContent(BuildContext context, User adminUser) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'لوحة التحكم الإدارية',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2B48),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'تسجيل الخروج من لوحة المدير',
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // بطاقة معلومات المدير
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          color: Color(0xFF10B981), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'مسجل بصلاحيات الإدارة: ${adminUser.email}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // رأس الصفحة الترحيبي
                const Text(
                  'مرحباً بك يا مدير النظام 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'اختر القسم الذي تريد إدارته وتحديث بياناته الآن:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // 1. إدارة الجامعات والكليات
                _buildDashboardCard(
                  context,
                  title: 'إدارة الجامعات والكليات',
                  subtitle: 'إضافة مؤسسات جديدة، تعديل الشروط، أو حذف سجلات',
                  icon: Icons.account_balance_rounded,
                  iconColor: const Color(0xFF1E3A8A),
                  iconBgColor: const Color(0xFFEFF6FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUniversitiesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 2. إدارة المنح الدراسية
                _buildDashboardCard(
                  context,
                  title: 'إدارة المنح الدراسية',
                  subtitle: 'تحديث مواعيد التقديم، تعديل أنواع التمويل، وإضافة منح',
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFFEA580C),
                  iconBgColor: const Color(0xFFFFF7ED),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminScholarshipsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 3. إدارة الفرص والفعاليات
                _buildDashboardCard(
                  context,
                  title: 'إدارة الفرص والفعاليات',
                  subtitle: 'إضافة، تعديل، أو حذف فرصة أو فعالية',
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF16A34A),
                  iconBgColor: const Color(0xFFF0FDF4),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminOpportunitiesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 4. إدارة مراكز التدريب
                _buildDashboardCard(
                  context,
                  title: 'إدارة مراكز التدريب',
                  subtitle: 'إضافة مراكز تدريب جديدة، تعديل بيانات الاتصال، وحذف مراكز',
                  icon: Icons.business_center_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFF5F3FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminTrainingCentersScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== بوابة التحقق وتسجيل دخول المدير =====
  Widget _buildAdminLoginGate(BuildContext context, User? currentUser) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'تسجيل دخول المدير',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2B48),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // قفل الأمان
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 48,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'منطقة محميّة - الإدارة فقط',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'لوحة التحكم مخصصة لمدير التطبيق المصرح له لإضافة وحذف البيانات.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                if (currentUser != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الحساب الحالي (${currentUser.email}) ليس لديه صلاحية الإدارة.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // زر الدخول المباشر بحساب جوجل
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text(
                    'تسجيل الدخول بحساب Google المدير',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border(context))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'أو بالإيميل وكلمة المرور',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border(context))),
                  ],
                ),
                const SizedBox(height: 16),

                // حقل الإيميل
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني للمدير',
                    hintText: 'daleel2026d@gmail.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // حقل كلمة المرور
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // زر تسجيل الدخول
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailPasswordSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2B48),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'دخول لوحة التحكم',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final error = await _authService.signInWithGoogle();
      if (error != null) {
        setState(() => _errorMessage = error);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (!AuthService.isAdmin(user)) {
          setState(() {
            _errorMessage =
                'الحساب (${user?.email}) غير مصرح له كمدير للنظام.';
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'فشل تسجيل الدخول: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailPasswordSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final error = await _authService.signIn(email, password);
      if (error != null) {
        setState(() => _errorMessage = error);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (!AuthService.isAdmin(user)) {
          setState(() {
            _errorMessage =
                'الحساب ($email) غير مصرح له كمدير للنظام.';
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border(context),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textMuted(context),
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.isDark(context)
                      ? iconColor.withValues(alpha: 0.2)
                      : iconBgColor,
                ),
                child: Icon(
                  icon,
                  color: AppColors.isDark(context) ? Colors.white : iconColor,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
