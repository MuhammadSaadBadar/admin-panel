import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../controllers/doctor_invite_controller.dart';
import '../repositories/doctor_repository.dart';
import '../../../core/widgets/dashboard_background.dart';

/// Invite-a-doctor screen (replaces the old direct "create profile" form).
///
/// The backend does not allow admin-created doctor profiles. Instead, the
/// admin sends an invitation (email + specialization) and the doctor completes
/// their own profile via the emailed accept link. This screen collects exactly
/// the two fields the `POST /accounts/doctors/invite/` endpoint accepts.
class InviteDoctorScreen extends StatefulWidget {
  const InviteDoctorScreen({super.key});

  @override
  State<InviteDoctorScreen> createState() => _InviteDoctorScreenState();
}

class _InviteDoctorScreenState extends State<InviteDoctorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late final DoctorInviteController _controller;

  final TextEditingController _emailController = TextEditingController();
  String _selectedSpecialization = 'Obstetrics & Gynecology';

  static const List<String> _specializations = [
    'Obstetrics & Gynecology',
    'Pediatrics',
    'General Practice',
    'Internal Medicine',
    'Cardiology',
    'Dermatology',
    'Nutrition & Dietetics',
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('[InviteDoctorScreen] initState');

    if (!Get.isRegistered<DoctorInviteController>()) {
      Get.put(DoctorInviteController(Get.find<DoctorRepository>()));
    }
    _controller = Get.find<DoctorInviteController>();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    if (Get.isRegistered<DoctorInviteController>()) {
      Get.delete<DoctorInviteController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      body: DashboardBackground(
        child: Row(
          children: [
            // Desktop Sidebar
            if (!isMobile) _buildSidebar(),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  _buildTopAppBar(isMobile),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildForm(),
                          ],
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
      bottomNavigationBar: isMobile
          ? AppBottomNavBar(
              selectedIndex: 1,
              onItemSelected: (index) {
                switch (index) {
                  case 0:
                    Get.toNamed(RouteNames.dashboard);
                    break;
                  case 1:
                    break;
                  case 2:
                    Get.toNamed(RouteNames.patients);
                    break;
                  case 3:
                    Get.toNamed(RouteNames.appointments);
                    break;
                }
              },
            )
          : null,
    );
  }

  Widget _buildSidebar() {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.dashboard, 'label': 'Dashboard', 'selected': false},
      {
        'icon': Icons.medical_services,
        'label': 'Doctor Management',
        'selected': true,
      },
      {'icon': Icons.person, 'label': 'Patient Management', 'selected': false},
      {'icon': Icons.event, 'label': 'Appointments', 'selected': false},
      {
        'icon': Icons.notifications,
        'label': 'Notifications',
        'selected': false,
      },
      {
        'icon': Icons.description,
        'label': 'Content Management',
        'selected': false,
      },
      {'icon': Icons.emergency, 'label': 'SOS Requests', 'selected': false},
      {'icon': Icons.settings, 'label': 'Settings', 'selected': false},
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerLow,
        border: Border(right: BorderSide(color: ColorConstants.borderWhite10)),
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
                    color: ColorConstants.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ADMIN CONSOLE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.05,
                    color: ColorConstants.onSurfaceVariant,
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
                final isSelected = item['selected'] as bool;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? ColorConstants.secondaryContainer
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isSelected
                            ? ColorConstants.onSecondaryContainer
                            : ColorConstants.onSurfaceVariant,
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
                              ? ColorConstants.onSecondaryContainer
                              : ColorConstants.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {},
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorConstants.borderWhite5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ColorConstants.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: ColorConstants.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin User',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.onSurface,
                          ),
                        ),
                        Text(
                          'System Administrator',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: ColorConstants.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return CustomAppBar(
      title: 'Mama Health',
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications, color: ColorConstants.primary),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        Row(
          children: [
            Icon(
              Icons.medical_services,
              color: ColorConstants.onSurfaceVariant,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Doctor Management',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ColorConstants.onSurfaceVariant,
              size: 16,
            ),
            Text(
              'Invite Doctor',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Invite a Doctor',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        Text(
          'Send a secure invitation email. The doctor will use the emailed '
          'link to set up their own account and profile.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Obx(() {
      // Top-level error banner (network failure, unexpected errors, fallback).
      final topError = _controller.error.value;
      final state = _controller.submissionState.value;
      final showEmailDelay = _controller.showEmailDelayHint.value;
      final alreadyPending = _controller.alreadyPending.value;

      return Column(
        children: [
          if (topError != null && topError.isNotEmpty) ...[
            _buildErrorBanner(
              topError,
              isUnknownOutcome: state == InviteSubmissionState.unknown,
            ),
            const SizedBox(height: 16),
          ],
          if (state == InviteSubmissionState.unknown) ...[
            _buildUnknownActions(),
            const SizedBox(height: 16),
          ],
          if (showEmailDelay && !alreadyPending) ...[
            _buildEmailDelayHint(),
            const SizedBox(height: 16),
          ],
          if (alreadyPending) ...[
            _buildAlreadyPendingBanner(),
            const SizedBox(height: 16),
          ],
          // Invitation details
          _buildInvitationCard(),
          const SizedBox(height: 24),
          // Form Actions
          _buildFormActions(),
        ],
      );
    });
  }

  /// Warning banner for the `unknown` outcome, with Check Status / Retry
  /// actions so the user can recover instead of assuming a hard failure.
  Widget _buildUnknownActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstants.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline, color: ColorConstants.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We couldn\'t confirm whether the invitation was sent. '
                  'The server may have processed it. Please check status '
                  'before retrying to avoid duplicates.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _controller.isLoading.value
                      ? null
                      : _controller.verifyStatus,
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: const Text('Check Status'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConstants.primary,
                    side: BorderSide(color: ColorConstants.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _controller.isLoading.value
                      ? null
                      : () => _controller.retry(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: ColorConstants.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Info banner for the "already pending" outcome.
  Widget _buildAlreadyPendingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstants.tertiary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: ColorConstants.tertiary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'An invitation is already pending for this email. '
              'No duplicate invitation was created.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ColorConstants.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hint that the invitation was created but email delivery may be delayed.
  Widget _buildEmailDelayHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstants.success.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule, color: ColorConstants.success, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The invitation was created. Email delivery may take a few '
              'minutes — please also check the spam folder.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ColorConstants.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message, {bool isUnknownOutcome = false}) {
    final Color bannerColor = isUnknownOutcome
        ? ColorConstants.warning
        : ColorConstants.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bannerColor.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUnknownOutcome ? Icons.help_outline : Icons.error_outline,
            color: bannerColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ColorConstants.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, color: ColorConstants.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Invitation Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: ColorConstants.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          // Email field
          Obx(
            () => _buildFormField(
              label: 'Email Address',
              controller: _emailController,
              hintText: 'doctor@clinic.com',
              keyboardType: TextInputType.emailAddress,
              errorText: _controller.fieldErrors['email'],
              onChanged: (_) => _controller.clearFieldError('email'),
            ),
          ),
          const SizedBox(height: 12),
          // Specialization dropdown
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Specialization',
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
                    border: Border.all(
                      color:
                          _controller.fieldErrors.containsKey('specialization')
                          ? ColorConstants.error
                          : ColorConstants.borderWhite10,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSpecialization,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: ColorConstants.onSurface,
                      ),
                      dropdownColor: ColorConstants.surfaceContainerHigh,
                      isExpanded: true,
                      items: _specializations.map((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSpecialization = value!;
                        });
                        _controller.clearFieldError('specialization');
                      },
                    ),
                  ),
                ),
                if (_controller.fieldErrors.containsKey('specialization')) ...[
                  const SizedBox(height: 6),
                  Text(
                    _controller.fieldErrors['specialization']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ColorConstants.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Helper note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.secondaryContainer.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: ColorConstants.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'An invitation email will be sent to the doctor with a '
                    'secure link to set up their account and profile.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            border: Border.all(
              color: errorText != null
                  ? ColorConstants.error
                  : ColorConstants.borderWhite10,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
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
        if (errorText != null && errorText.isNotEmpty) ...[
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

  Widget _buildFormActions() {
    return Obx(() {
      final bool isLoading = _controller.isLoading.value;
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                foregroundColor: ColorConstants.onPrimary,
                disabledBackgroundColor: ColorConstants.primary.withOpacity(
                  0.4,
                ),
                disabledForegroundColor: ColorConstants.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: ColorConstants.primary.withOpacity(0.3),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorConstants.onPrimary,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.send,
                          size: 20,
                          color: ColorConstants.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Send Invitation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onPrimary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.borderWhite10,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: ColorConstants.borderWhite10),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.borderWhite10,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _handleInvite() async {
    debugPrint('[InviteDoctorScreen] Invite button tapped.');
    final bool ok = await _controller.invite(
      email: _emailController.text.trim(),
      specialization: _selectedSpecialization,
    );

    if (ok) {
      debugPrint('[InviteDoctorScreen] Invitation sent successfully.');
      _showSuccessDialog();
    } else {
      debugPrint(
        '[InviteDoctorScreen] Invitation failed — '
        'error="${_controller.error.value}"',
      );
    }
  }

  void _showSuccessDialog() {
    final String email = _emailController.text.trim();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        title: Column(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              color: ColorConstants.tertiary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Invitation Sent!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'An invitation email has been sent to $email.\n\n'
          'The doctor will use the secure link in the email to set up '
          'their account.',
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'OK',
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
}
