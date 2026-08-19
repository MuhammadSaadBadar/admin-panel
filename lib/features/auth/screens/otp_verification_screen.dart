import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/routes/route_names.dart';
import '../services/auth_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late final String _email;
  Timer? _resendTimer;
  bool _isLoading = false;
  int _timerSeconds = 120;
  bool _canResend = false;

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

    final args = Get.arguments;
    final argumentEmail = args is Map<String, dynamic>
        ? args['email'] as String?
        : null;
    final cachedEmail = Get.find<AuthService>().passwordResetEmail;
    _email = argumentEmail ?? cachedEmail ?? '';
    debugPrint('[AuthUI] OTP screen opened email=${_maskEmail(_email)}');

    // Start the timer
    _startTimer();

    // Auto-focus on first input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timerSeconds = 120;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _timerSeconds--;
        if (_timerSeconds <= 0) {
          _timerSeconds = 0;
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  String get _formattedTime {
    final minutes = (_timerSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timerSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleOtpInput(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _handleVerify() async {
    if (_email.isEmpty) {
      Get.snackbar(
        'Missing Email Context',
        'Please request a new reset code from Forgot Password.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
      return;
    }

    if (_otpCode.length != 6) {
      Get.snackbar(
        'Error',
        'Please enter all 6 digits of the verification code.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('[AuthUI] OTP verification started for ${_maskEmail(_email)}');
    try {
      await Get.find<AuthService>().verifyPasswordResetOtp(
        email: _email,
        otpCode: _otpCode,
      );
      debugPrint(
        '[AuthUI] OTP verification success. Navigating to reset password.',
      );
      if (!mounted) return;
      Get.toNamed(RouteNames.resetPassword);
    } on ApiException catch (e) {
      debugPrint('[AuthUI] OTP verification failed: $e');
      if (!mounted) return;
      Get.snackbar(
        'Verification Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
    } catch (e) {
      debugPrint('[AuthUI] OTP verification unexpected error: $e');
      if (!mounted) return;
      Get.snackbar(
        'Unexpected Error',
        'Unable to verify OTP right now. Please try again.',
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

  Future<void> _handleResend() async {
    if (!_canResend) return;

    if (_email.isEmpty) {
      Get.snackbar(
        'Missing Email Context',
        'Please return to Forgot Password and request a new code.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
      return;
    }

    debugPrint('[AuthUI] Resend OTP requested for ${_maskEmail(_email)}');
    try {
      await Get.find<AuthService>().requestPasswordResetCode(_email);
      if (!mounted) return;
      Get.snackbar(
        'Code Resent',
        'If that account exists, a new code has been sent.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.cardBackground,
        colorText: ColorConstants.onSurface,
      );
      _startTimer();
    } on ApiException catch (e) {
      debugPrint('[AuthUI] Resend OTP failed: $e');
      if (!mounted) return;
      Get.snackbar(
        'Resend Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.errorContainer,
        colorText: ColorConstants.onError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: Stack(
        children: [
          // Background decorative elements
          _buildBackgroundElements(),
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
                          children: [_buildOTPCard()],
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

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: ColorConstants.primaryContainer.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.primaryContainer.withOpacity(0.1),
                  blurRadius: 120,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          right: -30,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: ColorConstants.secondaryContainer.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.secondaryContainer.withOpacity(0.1),
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
                'Security Center',
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

  Widget _buildOTPCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30),
        ],
      ),
      child: Column(
        children: [
          // Shimmer glow stripe
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.primaryContainer.withOpacity(0),
                  ColorConstants.primaryContainer.withOpacity(0.5),
                  ColorConstants.primaryContainer.withOpacity(0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Identity',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Enter the 6-digit code sent to ',
                          ),
                          TextSpan(
                            text: _email.isEmpty
                                ? 'your email address'
                                : _email,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.primary,
                            ),
                          ),
                          const TextSpan(
                            text: ' to continue to the administrative portal.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // OTP Input Fields
                // Each field is wrapped in Expanded so the 6 boxes flex to fit
                // the available width instead of being fixed at 64px wide —
                // fixed widths caused a ~100px RenderFlex overflow on narrow
                // phones (6 × 64 = 384px > ~280px available).
                Row(
                  children: List.generate(6, (index) {
                    return Expanded(
                      child: _buildOtpField(index, hasRightMargin: index < 5),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Verify Button
                _buildVerifyButton(),
                const SizedBox(height: 12),
                // Timer and Resend
                _buildTimerAndResend(),
                const SizedBox(height: 16),
                // Security Notice
                _buildSecurityNotice(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField(int index, {bool hasRightMargin = true}) {
    // Use a square box that scales with the available width (via
    // aspectRatio(1)) and the parent's Expanded flex, instead of a fixed
    // 64×80 box. On a narrow phone this keeps all six fields visible without
    // overflowing the card. The right margin provides the inter-field gap.
    return Padding(
      padding: EdgeInsets.only(right: hasRightMargin ? 8 : 0),
      child: AspectRatio(
        aspectRatio: 1,
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          maxLength: 1,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: ColorConstants.primary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: ColorConstants.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ColorConstants.borderWhite10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ColorConstants.borderWhite10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: ColorConstants.primaryContainer,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            _handleOtpInput(value, index);
          },
          onTap: () {
            _focusNodes[index].requestFocus();
          },
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleVerify,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryContainer,
          foregroundColor: ColorConstants.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                    'Verifying...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onPrimaryContainer,
                    ),
                  ),
                ],
              )
            : Text(
                'Verify',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onPrimaryContainer,
                ),
              ),
      ),
    );
  }

  Widget _buildTimerAndResend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Resend in $_formattedTime',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: _canResend ? _handleResend : null,
          child: Text(
            'Resend Code',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _canResend
                  ? ColorConstants.primary
                  : ColorConstants.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerLow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstants.borderWhite5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: ColorConstants.tertiary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Keep this code private. Mama Health staff will never ask for your verification code over phone or email.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
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

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${local[0]}***@$domain';
    return '${local.substring(0, 2)}***@$domain';
  }
}
