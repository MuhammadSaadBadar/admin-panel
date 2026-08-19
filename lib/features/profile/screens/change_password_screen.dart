import 'package:admin/core/routes/route_names.dart';
import 'package:admin/core/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../controllers/change_password_controller.dart';
import '../../../core/widgets/dashboard_background.dart';

/// Change Password screen — calls `POST /auth/password/change/`.
///
/// Validates client-side, surfaces backend validation messages (including
/// structured field errors), shows a loading indicator, prevents duplicate
/// submissions, and shows a success dialog on completion.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final ChangePasswordController _controller;

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Client-side password strength checks.
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[ChangePasswordScreen] initState');
    _controller = Get.find<ChangePasswordController>();
    _newPasswordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _newPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isPasswordValid => _hasMinLength && _hasNumber && _hasSpecialChar;

  bool get _doPasswordsMatch =>
      _newPasswordController.text == _confirmPasswordController.text &&
      _confirmPasswordController.text.isNotEmpty;

  bool get _isFormValid =>
      _currentPasswordController.text.isNotEmpty &&
      _isPasswordValid &&
      _doPasswordsMatch;

  /// Returns the backend field error for [field], if any.
  String? _fieldError(String field) =>
      _controller.fieldErrors[field]?.join('\n');

  Future<void> _submit() async {
    debugPrint('[ChangePasswordScreen] _submit called');
    final ok = await _controller.changePassword(
      oldPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
    if (ok) {
      debugPrint('[ChangePasswordScreen] _submit — success, showing dialog');
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.check_circle,
          color: ColorConstants.success,
          size: 48,
        ),
        title: Text(
          'Password Updated',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Text(
          'Your password has been changed successfully.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint(
                '[ChangePasswordScreen] Success dialog dismissed — navigating back',
              );
              Get.back(); // close dialog
              Get.back(); // close screen
            },
            child: Text(
              'Done',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ColorConstants.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.background,
      // Shared navigation drawer on mobile (hamburger + swipe-to-open).
      drawer: isMobile
          ? AppDrawer(
              currentRoute: RouteNames.profile,
              onNavigate: (route) {
                Navigator.of(context).pop(); // close drawer
                if (route != RouteNames.profile) {
                  Get.toNamed(route);
                }
              },
            )
          : null,
      body: DashboardBackground(
        child: SafeArea(
          child: Row(
            children: [
              if (!isMobile) _buildSidebar(colorScheme),
              Expanded(
                child: Column(
                  children: [
                    CustomAppBar(
                      title: 'Change Password',
                      showBackButton: isMobile,
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 540),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: ColorConstants.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(colorScheme),
                                  const SizedBox(height: 20),
                                  _buildForm(colorScheme),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Desktop sidebar ────────────────────────────────────────────────────
  Widget _buildSidebar(ColorScheme colorScheme) {
    final List<Map<String, dynamic>> navItems = [
      {
        'icon': Icons.dashboard,
        'label': 'Dashboard',
        'route': RouteNames.dashboard,
      },
      {
        'icon': Icons.medical_services,
        'label': 'Doctor Management',
        'route': RouteNames.doctors,
      },
      {
        'icon': Icons.person,
        'label': 'Patient Management',
        'route': RouteNames.patients,
      },
      {
        'icon': Icons.event,
        'label': 'Appointments',
        'route': RouteNames.appointments,
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'route': RouteNames.settings,
      },
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mama Health',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ADMIN CONSOLE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.05,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = item['route'] == RouteNames.profile;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? colorScheme.secondaryContainer
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isSelected
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        final route = item['route'] as String;
                        if (route != RouteNames.profile) {
                          Get.toNamed(route);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_reset, color: colorScheme.primary, size: 28),
            const SizedBox(width: 10),
            Text(
              'Change Password',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Update your Mama Health account password. Ensure it is strong and unique.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildPasswordField(
          label: 'Current Password',
          controller: _currentPasswordController,
          obscureText: _obscureCurrentPassword,
          onToggleVisibility: () {
            setState(() {
              _obscureCurrentPassword = !_obscureCurrentPassword;
            });
          },
          icon: Icons.password,
          colorScheme: colorScheme,
          errorText:
              _fieldError('old_password') ?? _fieldError('non_field_errors'),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: 'New Password',
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          onToggleVisibility: () {
            setState(() {
              _obscureNewPassword = !_obscureNewPassword;
            });
          },
          icon: Icons.vpn_key,
          colorScheme: colorScheme,
          errorText: _fieldError('new_password'),
          showRequirements: true,
          hasMinLength: _hasMinLength,
          hasNumber: _hasNumber,
          hasSpecialChar: _hasSpecialChar,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: 'Confirm New Password',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
          icon: Icons.error,
          colorScheme: colorScheme,
          errorText:
              _confirmPasswordController.text.isNotEmpty && !_doPasswordsMatch
              ? 'Passwords do not match.'
              : null,
          isError:
              _confirmPasswordController.text.isNotEmpty && !_doPasswordsMatch,
        ),
        const SizedBox(height: 16),

        // General/backend error banner.
        Obx(() {
          if (_controller.errorMessage.value != null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _controller.errorMessage.value!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        _buildActions(colorScheme),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required IconData icon,
    required ColorScheme colorScheme,
    String? errorText,
    bool isError = false,
    bool showRequirements = false,
    bool hasMinLength = false,
    bool hasNumber = false,
    bool hasSpecialChar = false,
  }) {
    final labelColor = isError ? colorScheme.error : colorScheme.onSurface;
    final borderColor = isError
        ? colorScheme.error
        : Colors.white.withOpacity(0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                icon,
                color: isError
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _getHintText(label),
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              GestureDetector(
                onTap: onToggleVisibility,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: isError
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        if (errorText != null && errorText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning, color: colorScheme.error, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (showRequirements) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildRequirementChip('8+ characters', hasMinLength, colorScheme),
              _buildRequirementChip('1 number', hasNumber, colorScheme),
              _buildRequirementChip(
                '1 special char',
                hasSpecialChar,
                colorScheme,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRequirementChip(
    String label,
    bool isMet,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: isMet
            ? colorScheme.primaryContainer.withOpacity(0.2)
            : Colors.transparent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isMet
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getHintText(String label) {
    if (label.contains('Current')) return 'Enter current password';
    if (label.contains('Confirm')) return 'Re-enter new password';
    return 'Enter new password';
  }

  Widget _buildActions(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                debugPrint('[ChangePasswordScreen] Cancel tapped');
                Get.back();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => ElevatedButton(
                onPressed: (_isFormValid && !_controller.isChanging.value)
                    ? _submit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: colorScheme.primary.withOpacity(0.4),
                  disabledForegroundColor: colorScheme.onPrimary.withOpacity(
                    0.5,
                  ),
                ),
                child: _controller.isChanging.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorConstants.background,
                        ),
                      )
                    : Text(
                        'Update Password',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
