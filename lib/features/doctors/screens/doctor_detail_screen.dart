import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../../appointments/models/appointment.dart';
import '../../patients/models/patient.dart';
import '../controllers/doctor_detail_controller.dart';
import '../models/doctor.dart';

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({super.key});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final DoctorDetailController _controller;
  int _doctorId = 0;

  @override
  void initState() {
    super.initState();

    _controller = Get.find<DoctorDetailController>();

    // Extract the doctor ID from navigation arguments.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && args['doctorId'] != null) {
        _doctorId = args['doctorId'] as int;
      }
      debugPrint('[DoctorDetailsScreen] Received doctorId=$_doctorId');
      if (_doctorId > 0) {
        _controller.loadDoctor(_doctorId);
      }
    });

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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      body: DashboardBackground(
        child: SafeArea(
          child: Row(
            children: [
              if (!isMobile) _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildTopAppBar(isMobile),
                    Expanded(
                      child: Obx(() {
                        if (_controller.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: ColorConstants.primary,
                            ),
                          );
                        }

                        if (_controller.error.value != null) {
                          return _buildErrorState();
                        }

                        final doctor = _controller.doctor.value;
                        if (doctor == null) {
                          return _buildNoDoctorState();
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeroProfile(isMobile, doctor),
                                    SizedBox(height: isMobile ? 16 : 24),
                                    _buildContactCard(isMobile, doctor),
                                    SizedBox(height: isMobile ? 16 : 24),
                                    _buildQualificationCard(isMobile, doctor),
                                    SizedBox(height: isMobile ? 16 : 24),
                                    _buildBioCard(isMobile, doctor),
                                    SizedBox(height: isMobile ? 16 : 24),
                                    _buildAssignedPatientsSection(isMobile),
                                    SizedBox(height: isMobile ? 16 : 24),
                                    _buildAppointmentsSection(isMobile),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
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

  // ── Sidebar ─────────────────────────────────────────────────────────────
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
        color: ColorConstants.primaryContainer,
        border: Border(
          right: BorderSide(
            color: ColorConstants.onPrimaryContainer.withOpacity(0.1),
          ),
        ),
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
                    color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
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
                            : ColorConstants.onPrimaryContainer.withOpacity(
                                0.7,
                              ),
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
                              : ColorConstants.onPrimaryContainer.withOpacity(
                                  0.7,
                                ),
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
                color: ColorConstants.onPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorConstants.onPrimaryContainer.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ColorConstants.onPrimary.withOpacity(0.15),
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
                            color: ColorConstants.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'System Administrator',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: ColorConstants.onPrimaryContainer
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Top App Bar ─────────────────────────────────────────────────────────
  Widget _buildTopAppBar(bool isMobile) {
    return CustomAppBar(
      title: 'Doctor Details',
      showBackButton: true,
      onBackTap: () => Navigator.pop(context),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.notifications,
            color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
            size: isMobile ? 20 : 24,
          ),
        ),
      ],
    );
  }

  // ── Error & Empty States ────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: ColorConstants.error, size: 56),
            const SizedBox(height: 16),
            Text(
              'Failed to load doctor details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.error.value ?? 'An error occurred.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('[DoctorDetailsScreen] Retry — doctorId=$_doctorId');
                _controller.loadDoctor(_doctorId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                foregroundColor: ColorConstants.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDoctorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              size: 56,
              color: ColorConstants.onPrimaryContainer.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No doctor selected',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a doctor from the list to view details.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Profile ────────────────────────────────────────────────────────
  Widget _buildHeroProfile(bool isMobile, Doctor doctor) {
    final initials = _getInitials(doctor.name);
    final dateJoined = doctor.dateJoined != null
        ? _formatDate(doctor.dateJoined!)
        : 'N/A';

    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorConstants.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ColorConstants.onPrimaryContainer.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                _buildAvatar(96, initials),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: doctor.isActive
                          ? ColorConstants.success
                          : ColorConstants.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorConstants.onPrimary,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              doctor.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              doctor.specialization.isNotEmpty
                  ? doctor.specialization
                  : 'General',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: ColorConstants.onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusBadge(
                  'ID: #${doctor.id}',
                  ColorConstants.onPrimary.withOpacity(0.7),
                  false,
                ),
                _buildStatusBadge(
                  doctor.isActive ? 'ACTIVE' : 'INACTIVE',
                  doctor.isActive
                      ? ColorConstants.success
                      : ColorConstants.error,
                  true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildToggleActiveButton(doctor),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorConstants.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.onPrimaryContainer.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.onPrimaryContainer.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              _buildAvatar(128, initials),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: doctor.isActive
                        ? ColorConstants.success
                        : ColorConstants.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorConstants.onPrimary,
                      width: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  doctor.specialization.isNotEmpty
                      ? doctor.specialization
                      : 'General',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusBadge(
                      'ID: #${doctor.id}',
                      ColorConstants.onPrimaryContainer.withOpacity(0.7),
                      false,
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(
                      doctor.isActive ? 'ACTIVE' : 'INACTIVE',
                      doctor.isActive
                          ? ColorConstants.success
                          : ColorConstants.error,
                      true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 16,
                      color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Joined: $dateJoined',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ColorConstants.onPrimaryContainer.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildToggleActiveButton(doctor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double size, String initials) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.primary.withOpacity(0.25),
            ColorConstants.secondary.withOpacity(0.25),
          ],
        ),
        border: Border.all(
          color: ColorConstants.onPrimary.withOpacity(0.3),
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: ColorConstants.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color, bool isDot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact Card ────────────────────────────────────────────────────────
  Widget _buildContactCard(bool isMobile, Doctor doctor) {
    return _buildSectionCard(
      isMobile: isMobile,
      icon: Icons.contact_phone_outlined,
      title: 'Contact Information',
      children: [
        _buildInfoRow(
          Icons.email_outlined,
          'Email',
          doctor.email.isNotEmpty ? doctor.email : 'N/A',
          isMobile,
        ),
        _buildInfoRow(
          Icons.phone_outlined,
          'Phone',
          doctor.phoneNumber.isNotEmpty ? doctor.phoneNumber : 'N/A',
          isMobile,
        ),
      ],
    );
  }

  // ── Qualification Card ──────────────────────────────────────────────────
  Widget _buildQualificationCard(bool isMobile, Doctor doctor) {
    return _buildSectionCard(
      isMobile: isMobile,
      icon: Icons.school_outlined,
      title: 'Professional Details',
      children: [
        _buildInfoRow(
          Icons.workspace_premium_outlined,
          'License Number',
          doctor.licenseNumber.isNotEmpty ? doctor.licenseNumber : 'N/A',
          isMobile,
        ),
        _buildInfoRow(
          Icons.work_history_outlined,
          'Experience',
          doctor.yearsOfExperience > 0
              ? '${doctor.yearsOfExperience} Years'
              : 'N/A',
          isMobile,
        ),
        _buildInfoRow(
          Icons.person_add_alt_1,
          'Accepting Patients',
          doctor.isAcceptingPatients ? 'Yes' : 'No',
          isMobile,
        ),
      ],
    );
  }

  // ── Bio Card ────────────────────────────────────────────────────────────
  Widget _buildBioCard(bool isMobile, Doctor doctor) {
    return _buildSectionCard(
      isMobile: isMobile,
      icon: Icons.notes_outlined,
      title: 'About',
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            doctor.bio.isNotEmpty ? doctor.bio : 'No bio available.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  // ── Toggle Active Button ────────────────────────────────────────────────
  Widget _buildToggleActiveButton(Doctor doctor) {
    return Obx(() {
      if (_controller.isTogglingActive.value) {
        return const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColorConstants.onPrimary,
          ),
        );
      }

      final bool active = _controller.doctor.value?.isActive ?? doctor.isActive;
      return ElevatedButton.icon(
        onPressed: () => _confirmToggleActive(doctor),
        icon: Icon(active ? Icons.block : Icons.check_circle_outline, size: 18),
        label: Text(active ? 'Deactivate Doctor' : 'Activate Doctor'),
        style: ElevatedButton.styleFrom(
          backgroundColor: active
              ? ColorConstants.onPrimary.withOpacity(0.1)
              : ColorConstants.success,
          foregroundColor: active
              ? ColorConstants.error
              : ColorConstants.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }

  void _confirmToggleActive(Doctor doctor) {
    final bool newState = !(doctor.isActive);
    final String action = newState ? 'activate' : 'deactivate';

    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${newState ? 'Activate' : 'Deactivate'} Doctor',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onPrimaryContainer,
          ),
        ),
        content: Text(
          'Are you sure you want to $action ${doctor.name}? '
          '${newState ? 'They will regain access to the platform.' : 'They will no longer be able to access the platform, but their history is preserved.'}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              debugPrint(
                '[DoctorDetails] Confirm toggle — id=${doctor.id} '
                'isActive=$newState',
              );
              _controller.toggleActive(doctor.id, newState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newState
                  ? ColorConstants.success
                  : ColorConstants.error,
              foregroundColor: newState
                  ? ColorConstants.onPrimary
                  : ColorConstants.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              newState ? 'Activate' : 'Deactivate',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Assigned Patients Section ──────────────────────────────────────────
  Widget _buildAssignedPatientsSection(bool isMobile) {
    return _buildSectionCard(
      isMobile: isMobile,
      icon: Icons.groups_outlined,
      title: 'Assigned Patients',
      trailing: Obx(
        () => Text(
          '${_controller.assignedPatients.length}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ColorConstants.primary,
          ),
        ),
      ),
      children: [
        Obx(() {
          if (_controller.isLoadingPatients.value &&
              _controller.assignedPatients.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: ColorConstants.primary),
              ),
            );
          }

          if (_controller.patientsError.value != null &&
              _controller.assignedPatients.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ColorConstants.error,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _controller.patientsError.value!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (_controller.assignedPatients.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No patients have been assigned to this doctor yet.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
                ),
              ),
            );
          }

          return Column(
            children: _controller.assignedPatients
                .map((patient) => _buildPatientRow(patient, isMobile))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildPatientRow(Patient patient, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: ColorConstants.onPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.onPrimaryContainer.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorConstants.onPrimary.withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                _getInitials(patient.name),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  patient.email.isNotEmpty ? patient.email : 'No email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(
            patient.isActive ? 'ACTIVE' : 'INACTIVE',
            patient.isActive ? ColorConstants.success : ColorConstants.error,
            true,
          ),
        ],
      ),
    );
  }

  // ── Appointments Section ───────────────────────────────────────────────
  Widget _buildAppointmentsSection(bool isMobile) {
    return _buildSectionCard(
      isMobile: isMobile,
      icon: Icons.event_note_outlined,
      title: 'Appointments',
      trailing: Obx(
        () => Text(
          '${_controller.appointments.length}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ColorConstants.primary,
          ),
        ),
      ),
      children: [
        Obx(() {
          if (_controller.isLoadingAppointments.value &&
              _controller.appointments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: ColorConstants.primary),
              ),
            );
          }

          if (_controller.appointmentsError.value != null &&
              _controller.appointments.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ColorConstants.error,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _controller.appointmentsError.value!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (_controller.appointments.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No appointments found for this doctor.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
                ),
              ),
            );
          }

          return Column(
            children: _controller.appointments
                .map(
                  (appointment) => _buildAppointmentRow(appointment, isMobile),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildAppointmentRow(Appointment appointment, bool isMobile) {
    final statusColor = _appointmentStatusColor(appointment.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: ColorConstants.onPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.onPrimaryContainer.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorConstants.primary.withOpacity(0.15),
            ),
            child: Icon(Icons.event, size: 18, color: ColorConstants.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patient.fullName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${appointment.appointmentType.displayLabel} • ${_formatDateTime(appointment.scheduledAt)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: ColorConstants.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(appointment.status.displayLabel, statusColor, true),
        ],
      ),
    );
  }

  Color _appointmentStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange.shade400;
      case AppointmentStatus.confirmed:
        return ColorConstants.tertiary;
      case AppointmentStatus.completed:
        return ColorConstants.success;
      case AppointmentStatus.cancelled:
        return ColorConstants.error;
      case AppointmentStatus.noShow:
        return ColorConstants.onPrimaryContainer.withOpacity(0.7);
      case AppointmentStatus.unknown:
        return ColorConstants.onPrimaryContainer.withOpacity(0.7);
    }
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Not scheduled';
    final local = date.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} • '
        '$h:$minute $ampm';
  }

  Widget _buildSectionCard({
    required bool isMobile,
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: ColorConstants.primaryContainer.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.onPrimaryContainer.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: ColorConstants.primary,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    bool isMobile,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorConstants.onPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ColorConstants.tertiary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color: ColorConstants.onPrimaryContainer.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .toList();
    return parts.map((w) => w[0].toUpperCase()).join();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
