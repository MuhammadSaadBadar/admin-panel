import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/routes/route_names.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: Stack(
        children: [
          // Background glow effects
          _buildBackgroundGlow(),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLoginCard(),
                            const SizedBox(height: 16),
                            _buildSystemStatus(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  ColorConstants.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
                stops: const [0.3, 0.7],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  ColorConstants.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
                stops: const [0.3, 0.7],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: ColorConstants.surface,
        border: Border(bottom: BorderSide(color: ColorConstants.borderWhite10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: ColorConstants.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                'Mama Health ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Glowing top accent
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  ColorConstants.primaryContainer,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header text
                Column(
                  children: [
                    Text(
                      'Administrative Login',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please authenticate to access the health dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Email input
                _buildEmailField(),
                const SizedBox(height: 16),
                // Password input
                _buildPasswordField(),
                const SizedBox(height: 16),
                // Actions row
                _buildActionsRow(),
                const SizedBox(height: 24),
                // Login button
                _buildLoginButton(),
                const SizedBox(height: 16),
                // System notice
                _buildSystemNotice(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorConstants.borderWhite10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.mail,
                color: ColorConstants.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'administrator@mamahealth.pro',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.onSurfaceVariant.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorConstants.borderWhite10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.lock,
                color: ColorConstants.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••••••',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.onSurfaceVariant.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: ColorConstants.onSurfaceVariant,
                  size: 20,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me checkbox
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberMe = !_rememberMe;
            });
          },
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _rememberMe
                      ? ColorConstants.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _rememberMe
                        ? ColorConstants.primary
                        : Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: _rememberMe
                    ? Icon(
                        Icons.check,
                        color: ColorConstants.onPrimary,
                        size: 14,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Keep me logged in',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Forgot password link
        GestureDetector(
          onTap: () {
            debugPrint('[AuthUI] Navigating to forgot password screen.');
            Get.toNamed(RouteNames.forgotPassword);
          },
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorConstants.primaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryContainer,
          foregroundColor: ColorConstants.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
          shadowColor: ColorConstants.primaryContainer.withOpacity(0.2),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorConstants.onPrimaryContainer,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Login',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: ColorConstants.onPrimaryContainer,
                    size: 24,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSystemNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ColorConstants.borderWhite5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: ColorConstants.tertiary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Authorized access only. All sessions are encrypted and monitored for compliance with HIPAA and clinical data protection protocols.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ColorConstants.tertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'System Online',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: ColorConstants.background,
        border: Border(top: BorderSide(color: ColorConstants.borderWhite5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildFooterLink('Privacy Policy'),
                  const SizedBox(width: 16),
                  _buildFooterLink('Terms of Service'),
                  const SizedBox(width: 16),
                  _buildFooterLink('System Status'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          'Coming Soon',
          '$text will be available soon.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorConstants.cardBackground,
          colorText: ColorConstants.onSurface,
        );
      },
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ColorConstants.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Missing Credentials',
        'Please enter your email and password.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      Get.snackbar(
        'Invalid Email',
        'Please enter a valid email address.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('[AuthUI] Login started for ${_maskEmail(email)}');
    try {
      final authService = Get.find<AuthService>();
      await authService.login(email: email, password: password);
      debugPrint('[AuthUI] Login success. Navigating to dashboard.');
      if (!mounted) return;
      Get.offAllNamed(RouteNames.dashboard);
    } on ApiException catch (e) {
      debugPrint('[AuthUI] Login failed: $e');
      if (!mounted) return;
      Get.snackbar(
        'Login Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
    } catch (e) {
      debugPrint('[AuthUI] Login failed with unexpected error: $e');
      if (!mounted) return;
      Get.snackbar(
        'Unexpected Error',
        'Unable to sign in right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${local[0]}***@$domain';
    return '${local.substring(0, 2)}***@$domain';
  }
}
