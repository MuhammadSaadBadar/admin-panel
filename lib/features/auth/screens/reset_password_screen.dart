import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/routes/route_names.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Password strength tracking
  int _strengthLevel = 0;
  bool _hasLength = false;
  bool _hasSpecial = false;
  bool _hasMatch = false;

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

    // Add listeners for real-time validation
    _newPasswordController.addListener(_updateValidation);
    _confirmPasswordController.addListener(_updateValidation);
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateValidation() {
    setState(() {
      final newPass = _newPasswordController.text;
      final confirmPass = _confirmPasswordController.text;

      _hasLength = newPass.length >= 12;
      _hasSpecial = RegExp(r'[0-9!@#$%^&*]').hasMatch(newPass);
      _hasMatch = confirmPass.isNotEmpty && newPass == confirmPass;

      // Calculate strength
      if (newPass.isEmpty) {
        _strengthLevel = 0;
      } else if (newPass.length >= 12 && _hasSpecial) {
        _strengthLevel = 3;
      } else if (newPass.length >= 8) {
        _strengthLevel = 2;
      } else if (newPass.isNotEmpty) {
        _strengthLevel = 1;
      } else {
        _strengthLevel = 0;
      }
    });
  }

  String get _strengthLabel {
    switch (_strengthLevel) {
      case 1:
        return 'Weak';
      case 2:
        return 'Moderate';
      case 3:
        return 'Secure';
      default:
        return 'Waiting...';
    }
  }

  Color get _strengthColor {
    switch (_strengthLevel) {
      case 1:
        return ColorConstants.error;
      case 2:
        return ColorConstants.secondary;
      case 3:
        return ColorConstants.tertiary;
      default:
        return ColorConstants.onSurfaceVariant;
    }
  }

  double get _strengthWidth {
    switch (_strengthLevel) {
      case 1:
        return 0.33;
      case 2:
        return 0.66;
      case 3:
        return 1.0;
      default:
        return 0.0;
    }
  }

  bool get _isFormValid {
    return _hasLength && _hasSpecial && _hasMatch;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: Stack(
        children: [
          // Subtle ambient background
          _buildAmbientBackground(),
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
                          children: [_buildResetCard()],
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

  Widget _buildAmbientBackground() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: ColorConstants.primary.withOpacity(0.05),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.primary.withOpacity(0.05),
                  blurRadius: 100,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: ColorConstants.secondary.withOpacity(0.05),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.secondary.withOpacity(0.05),
                  blurRadius: 100,
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
                'Mama Health',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Support',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Documentation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResetCard() {
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
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set New Password',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ensure your account remains secure. Enter a robust new password below to regain administrative access.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // New Password Field
            _buildPasswordField(
              label: 'New Password',
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
            const SizedBox(height: 8),
            // Strength Indicator
            _buildStrengthIndicator(),
            const SizedBox(height: 16),
            // Confirm Password Field
            _buildPasswordField(
              label: 'Confirm New Password',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            const SizedBox(height: 16),
            // Password Requirements
            _buildRequirementsList(),
            const SizedBox(height: 16),
            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: 8),
            // Back to Login
            _buildBackToLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorConstants.borderWhite10,
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
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••••••',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.onSurfaceVariant.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
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

  Widget _buildStrengthIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Security Rating',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.borderWhite10,
              ),
            ),
            Text(
              _strengthLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _strengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _strengthWidth,
            backgroundColor: ColorConstants.surfaceContainerHighest,
            color: _strengthColor,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstants.borderWhite5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: ColorConstants.onPrimaryContainer,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Requirement Checklist',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            text: 'Minimum 12 characters',
            isMet: _hasLength,
          ),
          _buildRequirementItem(
            text: 'Includes symbols or numbers',
            isMet: _hasSpecial,
          ),
          _buildRequirementItem(
            text: 'Passwords match exactly',
            isMet: _hasMatch,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem({required String text, required bool isMet}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.check_circle_outline,
            color: isMet
                ? ColorConstants.tertiary
                : ColorConstants.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isMet
                  ? ColorConstants.tertiary
                  : ColorConstants.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || !_isFormValid ? null : _handleResetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryContainer,
          foregroundColor: ColorConstants.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
          shadowColor: ColorConstants.primaryContainer.withOpacity(0.1),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Updating...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onPrimaryContainer,
                    ),
                  ),
                ],
              )
            : Text(
                'Reset Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onPrimaryContainer,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    return GestureDetector(
      onTap: () {
        Get.offAllNamed(RouteNames.login);
      },
      child: Center(
        child: Text(
          'Return to Secure Login',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ColorConstants.onSurfaceVariant,
          ),
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
          Text(
            '© Mama Health. Secure Administrative Environment.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorConstants.secondary,
            ),
          ),
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

  void _handleResetPassword() async {
    if (!_isFormValid) {
      Get.snackbar(
        'Invalid Password',
        'Please satisfy all password requirements before continuing.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('[AuthUI] Reset password request started.');
    try {
      await Get.find<AuthService>().resetPassword(
        newPassword: _newPasswordController.text,
      );
      debugPrint('[AuthUI] Reset password success. Redirecting to login.');
      if (!mounted) return;
      Get.snackbar(
        'Password Updated',
        'Your password has been updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.cardBackground,
        colorText: ColorConstants.onSurface,
      );
      Get.offAllNamed(RouteNames.login);
    } on StateError catch (e) {
      debugPrint('[AuthUI] Reset password missing token state: $e');
      if (!mounted) return;
      Get.snackbar(
        'Session Expired',
        'Please request and verify a new OTP code first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
      Get.offAllNamed(RouteNames.forgotPassword);
    } on ApiException catch (e) {
      debugPrint('[AuthUI] Reset password failed: $e');
      if (!mounted) return;
      Get.snackbar(
        'Reset Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
    } catch (e) {
      debugPrint('[AuthUI] Reset password unexpected error: $e');
      if (!mounted) return;
      Get.snackbar(
        'Unexpected Error',
        'Unable to reset password right now. Please try again.',
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
}
