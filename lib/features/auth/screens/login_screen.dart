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
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

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

    // Repaint the focused field so its border can highlight — purely
    // visual, does not affect the underlying form state.
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isCompact = size.width < 520;

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
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 16 : 24,
                        vertical: 24,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLoginCard(isCompact),
                            const SizedBox(height: 20),
                            _buildSystemStatus(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // _buildFooter(isCompact),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Background
  // ─────────────────────────────────────────────

  Widget _buildBackgroundGlow() {
    return Stack(
      children: [
        Positioned(top: -100, right: -100, child: _glowOrb()),
        Positioned(bottom: -100, left: -100, child: _glowOrb()),
      ],
    );
  }

  Widget _glowOrb() {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            ColorConstants.primary.withOpacity(0.14),
            Colors.transparent,
          ],
          stops: const [0.3, 0.7],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: ColorConstants.surface,
        border: Border(bottom: BorderSide(color: ColorConstants.borderWhite10)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorConstants.primary,
                  ColorConstants.primary.withOpacity(0.6),
                ],
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Mama Health',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: ColorConstants.primary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ColorConstants.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ColorConstants.borderWhite10),
            ),
            child: Text(
              'ADMIN PANEL',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Login card
  // ─────────────────────────────────────────────

  Widget _buildLoginCard(bool isCompact) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.borderWhite10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Glowing top accent
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  ColorConstants.primary,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 22 : 30),
            child: Column(
              children: [
                _buildCardHeaderText(),
                const SizedBox(height: 28),
                _buildTextField(
                  label: 'Email Address',
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  icon: Icons.mail_outline_rounded,
                  hint: 'administrator@mamahealth.pro',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Security Password',
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  icon: Icons.lock_outline_rounded,
                  hint: 'Enter your password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: ColorConstants.onSurfaceVariant,
                      size: 20,
                    ),
                    splashRadius: 18,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 18),
                _buildActionsRow(),
                const SizedBox(height: 26),
                _buildLoginButton(),
                const SizedBox(height: 18),
                _buildSystemNotice(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeaderText() {
    return Column(
      children: [
        Text(
          'Administrative Login',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: ColorConstants.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Please authenticate to access the health dashboard',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: ColorConstants.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Reusable text field
  // ─────────────────────────────────────────────

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final bool isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: ColorConstants.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused
                  ? ColorConstants.primary
                  : ColorConstants.borderWhite10,
              width: isFocused ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                icon,
                color: isFocused
                    ? ColorConstants.primary
                    : ColorConstants.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.onSurfaceVariant.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (suffixIcon != null) suffixIcon,
              const SizedBox(width: 6),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Actions row (remember me / forgot password)
  // ─────────────────────────────────────────────

  Widget _buildActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberMe = !_rememberMe;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: _rememberMe
                      ? ColorConstants.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _rememberMe
                        ? ColorConstants.primary
                        : Colors.white.withOpacity(0.24),
                    width: 1.6,
                  ),
                ),
                child: _rememberMe
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Keep me logged in',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            debugPrint('[AuthUI] Navigating to forgot password screen.');
            Get.toNamed(RouteNames.forgotPassword);
          },
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: ColorConstants.primaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Login button
  // ─────────────────────────────────────────────

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          foregroundColor: ColorConstants.onPrimary,
          disabledBackgroundColor: ColorConstants.primary.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorConstants.onPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Login',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: ColorConstants.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: ColorConstants.onPrimary,
                    size: 19,
                  ),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // System notice / status
  // ─────────────────────────────────────────────

  Widget _buildSystemNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorConstants.tertiary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.tertiary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: ColorConstants.tertiary,
            size: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Authorized access only. All sessions are encrypted and monitored for compliance with HIPAA and clinical data protection protocols.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
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
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: ColorConstants.tertiary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ColorConstants.tertiary.withOpacity(0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'System Online',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Footer
  // ─────────────────────────────────────────────

  // Widget _buildFooter(bool isCompact) {
  //   return Container(
  //     padding: EdgeInsets.symmetric(
  //       horizontal: isCompact ? 16 : 32,
  //       vertical: 16,
  //     ),
  //     decoration: BoxDecoration(
  //       color: ColorConstants.background,
  //       border: Border(top: BorderSide(color: ColorConstants.borderWhite5)),
  //     ),
  //     child: Wrap(
  //       alignment: WrapAlignment.center,
  //       spacing: 20,
  //       runSpacing: 8,
  //       children: [
  //         _buildFooterLink('Privacy Policy'),
  //         _buildFooterLink('Terms of Service'),
  //         _buildFooterLink('System Status'),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildFooterLink(String text) {
  //   return GestureDetector(
  //     onTap: () {
  //       Get.snackbar(
  //         'Coming Soon',
  //         '$text will be available soon.',
  //         snackPosition: SnackPosition.BOTTOM,
  //         backgroundColor: ColorConstants.cardBackground,
  //         colorText: ColorConstants.onSurface,
  //       );
  //     },
  //     child: Text(
  //       text,
  //       style: GoogleFonts.plusJakartaSans(
  //         fontSize: 12,
  //         fontWeight: FontWeight.w500,
  //         color: ColorConstants.onSurfaceVariant,
  //       ),
  //     ),
  //   );
  // }

  // ─────────────────────────────────────────────
  // Business logic — unchanged
  // ─────────────────────────────────────────────

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
