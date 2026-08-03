import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
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
        _passwordController.text.length >= 8 &&
        _consentChecked;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: Column(
        children: [
          _buildTopAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [const SizedBox(height: 80), _buildMainContent()],
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ColorConstants.surface.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: ColorConstants.borderWhite10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Icons.arrow_back,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
              Text(
                'Register Patient',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 672),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Description
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Text(
              'Onboard a new expectant mother to the system. All information is encrypted and handled according to clinical privacy standards.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: ColorConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Form Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.cardBackground.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.borderWhite10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Icon(
                      Icons.person_add,
                      color: ColorConstants.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Personal Information',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // First & Last Name
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        label: 'First Name',
                        controller: _firstNameController,
                        hintText: 'e.g. Sarah',
                        fieldKey: 'firstName',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        label: 'Last Name',
                        controller: _lastNameController,
                        hintText: 'e.g. Jenkins',
                        fieldKey: 'lastName',
                      ),
                    ),
                  ],
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
                  hintText: '+1 (555) 000-0000',
                  fieldKey: 'phoneNumber',
                  prefixIcon: Icons.call,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                // Password
                _buildPasswordField(),
                const SizedBox(height: 24),
                // Divider
                Divider(height: 1, color: ColorConstants.borderWhite5),
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
                      activeColor: ColorConstants.primary,
                      checkColor: ColorConstants.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(
                        color: ColorConstants.borderWhite10,
                        width: 1,
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
                            color: ColorConstants.onSurfaceVariant,
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
              Icon(
                Icons.verified_user,
                color: ColorConstants.tertiary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'HIPAA Compliant System',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.05,
                  color: ColorConstants.tertiary,
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
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorConstants.borderWhite10),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                const SizedBox(width: 12),
                Icon(prefixIcon, color: ColorConstants.borderWhite5, size: 20),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  onChanged: (_) {
                    // Rebuild so the submit button re-evaluates `_isFormValid`
                    // live as the user corrects previously invalid input.
                    setState(() {});
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.borderWhite5.withOpacity(0.5),
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
              color: ColorConstants.error,
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
          '********',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorConstants.borderWhite10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.lock, color: ColorConstants.borderWhite5, size: 20),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) {
                    // Rebuild so the submit button re-evaluates `_isFormValid`
                    // live as the user corrects the password.
                    setState(() {});
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '********',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.borderWhite5.withOpacity(0.5),
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
                  color: ColorConstants.borderWhite5,
                  size: 20,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Patient will be prompted to change this upon first login.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: ColorConstants.borderWhite5,
          ),
        ),
        if (passwordError != null) ...[
          const SizedBox(height: 6),
          Text(
            passwordError,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorConstants.error,
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
      child: ElevatedButton(
        onPressed: isLoading || !_isFormValid ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryContainer,
          foregroundColor: ColorConstants.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
          shadowColor: ColorConstants.primary.withOpacity(0.2),
        ),
        child: isLoading
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
                    'Processing...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onPrimaryContainer,
                    ),
                  ),
                ],
              )
            : Text(
                'Register Patient',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onPrimaryContainer,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: ColorConstants.background,
        border: Border(top: BorderSide(color: ColorConstants.borderWhite5)),
      ),
      child: Column(
        children: [
          Text(
            '© 2024 Mama Health Pro • Secure Administrative Environment',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorConstants.onSurfaceVariant,
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
          backgroundColor: ColorConstants.cardBackground,
          colorText: ColorConstants.onSurface,
        );
      },
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ColorConstants.borderWhite5,
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
          backgroundColor: ColorConstants.cardBackground,
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
        backgroundColor: ColorConstants.cardBackground,
        title: Column(
          children: [
            Icon(Icons.check_circle, color: ColorConstants.tertiary, size: 48),
            const SizedBox(height: 12),
            Text(
              'Registered!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          detail,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: ColorConstants.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              // Navigate to patient management
              Get.offNamed(RouteNames.patients);
            },
            child: Text(
              'View All Patients',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ColorConstants.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              // Clear the form for the next registration — no default password.
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
                fontWeight: FontWeight.w500,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
