import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/app_localizations.dart';
import '../main.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackBar(AppStrings.enterEmailAndPassword(context));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? error;

    if (_isLogin) {
      error = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      if (_nameController.text.trim().isEmpty) {
        _showSnackBar(AppStrings.fullNameRequired(context));
        setState(() => _isLoading = false);
        return;
      }
      error = await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });

      if (error == null) {
        _handleSuccessNavigation();
      }
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.signInWithGoogle();

    if (mounted) {
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = error;
      });

      if (error == null && FirebaseAuth.instance.currentUser != null) {
        _handleSuccessNavigation();
      }
    }
  }

  void _handleSuccessNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _showSnackBar(String message) {
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
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.isDark(context)
            ? const Color(0xFF1E293B)
            : AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _inputStyle({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.textMuted(context),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.isDark(context)
            ? const Color(0xFF38BDF8)
            : AppColors.primaryDark.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: AppColors.inputFill(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(context), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
      ),
    );
  }

  Widget _googleLogo() {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnyLoading = _isLoading || _isGoogleLoading;

    return Directionality(
      textDirection: AppStrings.direction(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.isDark(context)
              ? Colors.white
              : AppColors.primaryDark,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: Icon(
                    AppStrings.isAr(context)
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.arrow_back_ios_rounded,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          actions: [
            TextButton.icon(
              onPressed: isAnyLoading
                  ? null
                  : () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      }
                    },
              icon: Icon(
                AppStrings.isAr(context)
                    ? Icons.arrow_back_rounded
                    : Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.textMuted(context),
              ),
              label: Text(
                AppStrings.browseAsGuest(context),
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard(context),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 54,
                      color: AppColors.isDark(context)
                          ? const Color(0xFF38BDF8)
                          : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    _isLogin
                        ? AppStrings.login(context)
                        : AppStrings.signUp(context),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? AppStrings.welcomeBack(context)
                        : AppStrings.startJourney(context),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (!_isLogin) ...[
                    TextField(
                      controller: _nameController,
                      enabled: !isAnyLoading,
                      style: TextStyle(color: AppColors.textMain(context)),
                      decoration: _inputStyle(
                        label: AppStrings.fullName(context),
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _emailController,
                    enabled: !isAnyLoading,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppColors.textMain(context)),
                    decoration: _inputStyle(
                      label: AppStrings.email(context),
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    enabled: !isAnyLoading,
                    obscureText: true,
                    style: TextStyle(color: AppColors.textMain(context)),
                    decoration: _inputStyle(
                      label: AppStrings.password(context),
                      icon: Icons.lock_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isAnyLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppColors.primaryDark.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              _isLogin
                                  ? AppStrings.login(context)
                                  : AppStrings.confirmSignUp(context),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // فاصل "أو" / "OR"
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.border(context),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          AppStrings.orDivider(context),
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.border(context),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // زر Google Sign-In / Google Sign-Up
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: isAnyLoading ? null : _submitGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceCard(context),
                        side: BorderSide(
                          color: AppColors.border(context),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isGoogleLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppColors.isDark(context)
                                    ? const Color(0xFF38BDF8)
                                    : AppColors.primaryDark,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _googleLogo(),
                                const SizedBox(width: 12),
                                Text(
                                  _isLogin
                                      ? AppStrings.signInWithGoogle(context)
                                      : AppStrings.signUpWithGoogle(context),
                                  style: TextStyle(
                                    color: AppColors.textMain(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextButton(
                    onPressed: isAnyLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                            });
                          },
                    child: Text(
                      _isLogin
                          ? AppStrings.dontHaveAccount(context)
                          : AppStrings.alreadyHaveAccount(context),
                      style: TextStyle(
                        color: AppColors.isDark(context)
                            ? const Color(0xFF38BDF8)
                            : AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// رسم شعار Google الرسمي بدقة هندسية ونقاء فائق دون أي تداخل
class _GoogleIconPainter extends CustomPainter {
  const _GoogleIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24.0;

    // Blue (#4285F4)
    final Path blue = Path()
      ..moveTo(scale * 23.75, scale * 12.27)
      ..cubicTo(scale * 23.75, scale * 11.57, scale * 23.69, scale * 10.87, scale * 23.56, scale * 10.2)
      ..lineTo(scale * 12.0, scale * 10.2)
      ..lineTo(scale * 12.0, scale * 14.71)
      ..lineTo(scale * 18.6, scale * 14.71)
      ..cubicTo(scale * 18.31, scale * 16.23, scale * 17.46, scale * 17.53, scale * 16.2, scale * 18.39)
      ..lineTo(scale * 20.08, scale * 21.44)
      ..cubicTo(scale * 22.35, scale * 19.35, scale * 23.75, scale * 16.27, scale * 23.75, scale * 12.27)
      ..close();
    canvas.drawPath(
      blue,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Green (#34A853)
    final Path green = Path()
      ..moveTo(scale * 12.0, scale * 24.0)
      ..cubicTo(scale * 15.24, scale * 24.0, scale * 17.95, scale * 22.92, scale * 19.93, scale * 21.09)
      ..lineTo(scale * 16.05, scale * 18.04)
      ..cubicTo(scale * 14.97, scale * 18.76, scale * 13.6, scale * 19.2, scale * 12.0, scale * 19.2)
      ..cubicTo(scale * 8.88, scale * 19.2, scale * 6.23, scale * 17.1, scale * 5.28, scale * 14.27)
      ..lineTo(scale * 1.25, scale * 17.42)
      ..cubicTo(scale * 3.26, scale * 21.36, scale * 7.33, scale * 24.0, scale * 12.0, scale * 24.0)
      ..close();
    canvas.drawPath(
      green,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Yellow (#FBBC05)
    final Path yellow = Path()
      ..moveTo(scale * 5.28, scale * 14.27)
      ..cubicTo(scale * 5.03, scale * 13.55, scale * 4.9, scale * 12.78, scale * 4.9, scale * 12.0)
      ..cubicTo(scale * 4.9, scale * 11.22, scale * 5.03, scale * 10.45, scale * 5.28, scale * 9.73)
      ..lineTo(scale * 1.25, scale * 6.58)
      ..cubicTo(scale * 0.45, scale * 8.18, scale * 0.0, scale * 9.98, scale * 0.0, scale * 12.0)
      ..cubicTo(scale * 0.0, scale * 14.02, scale * 0.45, scale * 15.82, scale * 1.25, scale * 17.42)
      ..lineTo(scale * 5.28, scale * 14.27)
      ..close();
    canvas.drawPath(
      yellow,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Red (#EA4335)
    final Path red = Path()
      ..moveTo(scale * 12.0, scale * 4.75)
      ..cubicTo(scale * 13.77, scale * 4.75, scale * 15.35, scale * 5.36, scale * 16.6, scale * 6.55)
      ..lineTo(scale * 20.02, scale * 3.13)
      ..cubicTo(scale * 17.95, scale * 1.19, scale * 15.24, scale * 0.0, scale * 12.0, scale * 0.0)
      ..cubicTo(scale * 7.33, scale * 0.0, scale * 3.26, scale * 2.64, scale * 1.25, scale * 6.58)
      ..lineTo(scale * 5.28, scale * 9.73)
      ..cubicTo(scale * 6.23, scale * 6.9, scale * 8.88, scale * 4.75, scale * 12.0, scale * 4.75)
      ..close();
    canvas.drawPath(
      red,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}