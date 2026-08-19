import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/password_validator.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../../../core/widgets/password_requirements_checklist.dart';
import '../controllers/patient_registration_controller.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final PatientRegistrationController _registrationController;

  bool _obscurePassword = true;
  bool _consentChecked = false;

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

    _registrationController = Get.find<PatientRegistrationController>();

    // Clear the matching field's validation error as the user types.
    _firstNameController.addListener(
      () => _registrationController.clearFieldError('firstName'),
    );
    _lastNameController.addListener(
      () => _registrationController.clearFieldError('lastName'),
    );
    _emailController.addListener(
      () => _registrationController.clearFieldError('email'),
    );
    _phoneController.addListener(
      () => _registrationController.clearFieldError('phoneNumber'),
    );
    _passwordController.addListener(
      () => _registrationController.clearFieldError('password'),
    );

    // Rebuild on validation/error/success-state changes from the controller.
    ever(_registrationController.fieldErrors, (_) {
      if (mounted) setState(() {});
    });
    ever(_registrationController.error, (_) {
      if (mounted) setState(() {});
    });
    ever(_registrationController.successDetail, (_) {
      if (mounted) setState(() {});
    });
    ever(_registrationController.isLoading, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        PasswordValidator.isStrong(_passwordController.text) &&
        _consentChecked;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      body: DashboardBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopAppBar(isMobile),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(height: isMobile ? 40 : 80),
                        _buildMainContent(isMobile),
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel.withOpacity(0.60),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorConstants.dashboardPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.arrow_back,
                color: ColorConstants.dashboardInk,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Register Patient',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: ColorConstants.dashboardInk,
            ),
          ),
          const Spacer(),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorConstants.dashboardTeal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ColorConstants.dashboardTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'NEW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.dashboardTeal,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 672),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Description
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.dashboardCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.dashboardLine, width: 1),
            ),
            child: Text(
              'Onboard a new expectant mother to the system. All information is encrypted and handled according to clinical privacy standards.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w400,
                color: ColorConstants.dashboardInkSoft,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Form Card
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            decoration: BoxDecoration(
              color: ColorConstants
                  .primaryContainer, // Changed from dashboardPanel
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColorConstants.onPrimaryContainer.withOpacity(
                  0.2,
                ), // Subtle border
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.onPrimaryContainer.withOpacity(
                    0.1,
                  ), // Adjusted shadow
                  blurRadius: 20,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorConstants.primary,
                            ColorConstants.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: ColorConstants.onPrimary, // Changed to onPrimary
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Personal Information',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants
                            .onPrimaryContainer, // Changed to onPrimaryContainer
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // First & Last Name
                LayoutBuilder(
                  builder: (context, constraints) {
                    final firstNameField = _buildFormField(
                      label: 'First Name',
                      controller: _firstNameController,
                      hintText: 'e.g. Sarah',
                      fieldKey: 'firstName',
                    );
                    final lastNameField = _buildFormField(
                      label: 'Last Name',
                      controller: _lastNameController,
                      hintText: 'e.g. Jenkins',
                      fieldKey: 'lastName',
                    );

                    if (constraints.maxWidth < 420) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          firstNameField,
                          const SizedBox(height: 16),
                          lastNameField,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: firstNameField),
                        const SizedBox(width: 16),
                        Expanded(child: lastNameField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Email
                _buildFormField(
                  label: 'Email Address',
                  controller: _emailController,
                  hintText: 'patient.email@example.com',
                  fieldKey: 'email',
                  prefixIcon: Icons.mail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Phone
                _buildFormField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  hintText: '03000000000',
                  fieldKey: 'phoneNumber',
                  prefixIcon: Icons.call,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                // Password
                _buildPasswordField(),
                const SizedBox(height: 24),
                // Divider
                Divider(
                  height: 1,
                  color: ColorConstants.onPrimaryContainer.withOpacity(
                    0.2,
                  ), // Updated divider color
                ),
                const SizedBox(height: 16),
                // Consent Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _consentChecked,
                      onChanged: (value) {
                        setState(() {
                          _consentChecked = value ?? false;
                        });
                      },
                      activeColor: ColorConstants.dashboardPink,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: BorderSide(
                        color: ColorConstants.dashboardLine,
                        width: 1.5,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _consentChecked = !_consentChecked;
                          });
                        },
                        child: Text(
                          'Confirmed Data Privacy Consent Received',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ColorConstants.onPrimaryContainer
                                .withOpacity(0.8), // Updated text color
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Submit Button
                _buildSubmitButton(),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // HIPAA Compliance
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ColorConstants.dashboardTeal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user,
                  color: ColorConstants.dashboardTeal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HIPAA Compliant System',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.05,
                  color: ColorConstants.dashboardTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String fieldKey = '',
    IconData? prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    final String? errorText = fieldKey.isNotEmpty
        ? _registrationController.fieldErrors[fieldKey]
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorConstants.onPrimaryContainer.withOpacity(
              0.8,
            ), // Updated label color
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.onPrimary.withOpacity(
              0.1,
            ), // Light background on primary container
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorConstants.onPrimaryContainer.withOpacity(
                0.3,
              ), // Subtle border
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ColorConstants.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    prefixIcon,
                    color: ColorConstants.primary, // Changed to primary
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  onChanged: (_) {
                    setState(() {});
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants
                        .onPrimaryContainer, // Text color on primary container
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.onPrimaryContainer.withOpacity(
                        0.5,
                      ), // Hint text
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorConstants.error, // Keep error as is
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField() {
    final String? passwordError =
        _registrationController.fieldErrors['password'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorConstants.onPrimaryContainer.withOpacity(
              0.8,
            ), // Updated label
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.onPrimary.withOpacity(
              0.1,
            ), // Light background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorConstants.onPrimaryContainer.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ColorConstants.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock,
                  color: ColorConstants.secondary, // Changed to secondary
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) {
                    setState(() {});
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onPrimaryContainer, // Text color
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter a strong password',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.onPrimaryContainer.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
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
                  color: ColorConstants.onPrimaryContainer.withOpacity(
                    0.7,
                  ), // Updated
                  size: 20,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Real-time password-strength checklist
        PasswordRequirementsChecklist(password: _passwordController.text),
        const SizedBox(height: 8),
        Text(
          'Patient will be prompted to change this upon first login.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: ColorConstants.onPrimaryContainer.withOpacity(
              0.7,
            ), // Updated
          ),
        ),
        if (passwordError != null) ...[
          const SizedBox(height: 6),
          Text(
            passwordError,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorConstants.error, // Keep error as is
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    final bool isLoading = _registrationController.isLoading.value;
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: _isFormValid && !isLoading
              ? LinearGradient(
                  colors: [ColorConstants.onPrimary, ColorConstants.onPrimary],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isFormValid && !isLoading
              ? [
                  BoxShadow(
                    color: ColorConstants.dashboardPink.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading || !_isFormValid ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFormValid && !isLoading
                ? Colors.transparent
                : ColorConstants.onPrimary.withOpacity(0.1),
            foregroundColor: _isFormValid && !isLoading
                ? Colors.white
                : ColorConstants.onPrimary.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Register Patient',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _isFormValid && !isLoading
                        ? Colors.white
                        : ColorConstants.onPrimary.withOpacity(0.4),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: ColorConstants.dashboardPanel.withOpacity(0.60),
        border: Border(top: BorderSide(color: ColorConstants.dashboardLine)),
      ),
      child: Column(
        children: [
          Text(
            '© Mama Health • Secure Administrative Environment',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorConstants.dashboardInkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterLink('Privacy Policy'),
              const SizedBox(width: 16),
              _buildFooterLink('Terms of Service'),
              const SizedBox(width: 16),
              _buildFooterLink('Security Registry'),
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
          backgroundColor: ColorConstants.dashboardPanel,
          colorText: ColorConstants.dashboardInk,
        );
      },
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ColorConstants.dashboardInkSoft.withOpacity(0.6),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    debugPrint('[RegisterPatientScreen] _handleRegister() called.');

    if (_registrationController.isLoading.value) {
      debugPrint(
        '[RegisterPatientScreen] Submit ignored — registration already in flight.',
      );
      return;
    }

    final bool success = await _registrationController.register(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      password: _passwordController.text,
    );

    debugPrint('[RegisterPatientScreen] register() returned success=$success.');

    if (!success) {
      final String message =
          _registrationController.error.value ??
          'Failed to register patient. Please try again.';
      debugPrint('[RegisterPatientScreen] Showing error: $message');
      if (mounted) {
        Get.snackbar(
          'Registration Failed',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorConstants.dashboardPanel,
          colorText: ColorConstants.error,
          duration: const Duration(seconds: 5),
        );
      }
      return;
    }

    // Success — show dialog with the backend confirmation message.
    final String detail =
        _registrationController.successDetail.value ??
        'Patient has been successfully registered. '
            'An email with login instructions has been sent.';
    debugPrint('[RegisterPatientScreen] Showing success dialog.');

    if (!mounted) return;
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.dashboardPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstants.dashboardTeal,
                    ColorConstants.dashboardTeal2,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Registered!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ColorConstants.dashboardInk,
              ),
            ),
          ],
        ),
        content: Text(
          detail,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: ColorConstants.dashboardInkSoft,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.dashboardPink,
                  ColorConstants.dashboardPink2,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () {
                Get.back(); // Close dialog
                Get.offNamed(RouteNames.patients);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'View All Patients',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              // Clear the form for the next registration
              _firstNameController.clear();
              _lastNameController.clear();
              _emailController.clear();
              _phoneController.clear();
              _passwordController.clear();
              setState(() {
                _consentChecked = false;
              });
              debugPrint(
                '[RegisterPatientScreen] Form cleared for another registration.',
              );
            },
            child: Text(
              'Register Another',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorConstants.dashboardInkSoft,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
