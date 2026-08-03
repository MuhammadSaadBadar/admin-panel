import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/routes/route_names.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: Stack(
        children: [
          // Decorative floating elements
          _buildDecorativeElements(),
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
                          children: [_buildForgotPasswordCard()],
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

  Widget _buildDecorativeElements() {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          left: -48,
          child: Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              color: ColorConstants.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.primary.withOpacity(0.1),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.25,
          right: -48,
          child: Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              color: ColorConstants.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.secondary.withOpacity(0.1),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordCard() {
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header text
            Text(
              'Forgot Password',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your email to receive a verification code. We\'ll help you securely reset your administrator credentials.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: ColorConstants.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Email input
            _buildEmailField(),
            const SizedBox(height: 16),
            // Submit button
            _buildSubmitButton(),
            const SizedBox(height: 8),
            // Back to login link
            _buildBackToLoginLink(),
          ],
        ),
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
            color: ColorConstants.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorConstants.borderWhite10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.mail, color: ColorConstants.borderWhite10, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'administrator@mamahealth.pro',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleForgotPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryContainer,
          foregroundColor: ColorConstants.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
          shadowColor: ColorConstants.primaryContainer.withOpacity(0.2),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onPrimaryContainer,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Send Code',
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
                    size: 28,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    return GestureDetector(
      onTap: () {
        Get.back(); // Go back to login screen
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back, color: ColorConstants.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Back to Login',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
                color: ColorConstants.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: ColorConstants.background,
        border: Border(top: BorderSide(color: ColorConstants.borderWhite5)),
      ),
      child: Row(
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

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();

    // Validate email
    if (email.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      Get.snackbar(
        'Error',
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

    debugPrint(
      '[AuthUI] Forgot password request started for ${_maskEmail(email)}',
    );
    try {
      await Get.find<AuthService>().requestPasswordResetCode(email);
      debugPrint('[AuthUI] Forgot password success. Navigating to OTP screen.');

      if (!mounted) return;
      Get.snackbar(
        'Code Sent',
        'If that account exists, a verification code has been sent.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.cardBackground,
        colorText: ColorConstants.onSurface,
      );
      Get.toNamed(RouteNames.otpVerification, arguments: {'email': email});
    } on ApiException catch (e) {
      debugPrint('[AuthUI] Forgot password failed: $e');
      if (!mounted) return;
      Get.snackbar(
        'Request Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
    } catch (e) {
      debugPrint('[AuthUI] Forgot password unexpected error: $e');
      if (!mounted) return;
      Get.snackbar(
        'Unexpected Error',
        'Unable to request reset code. Please try again.',
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
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
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
