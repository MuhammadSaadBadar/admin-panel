import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../../doctors/models/doctor.dart';
import '../../doctors/repositories/doctor_repository.dart';
import '../controllers/assign_doctor_controller.dart';
import '../repositories/patient_repository.dart';

class AssignDoctorScreen extends StatefulWidget {
  const AssignDoctorScreen({super.key});

  @override
  State<AssignDoctorScreen> createState() => _AssignDoctorScreenState();
}

class _AssignDoctorScreenState extends State<AssignDoctorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late final AssignDoctorController _controller;

  @override
  void initState() {
    super.initState();
    debugPrint('[AssignDoctorScreen] initState');

    // Register controller
    if (!Get.isRegistered<DoctorRepository>()) {
      Get.put(DoctorRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<PatientRepository>()) {
      Get.put(PatientRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<AssignDoctorController>()) {
      Get.put(
        AssignDoctorController(
          Get.find<DoctorRepository>(),
          Get.find<PatientRepository>(),
        ),
      );
    }
    _controller = Get.find<AssignDoctorController>();

    // Extract patient ID from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      final patientId = args?['patientId'] as int? ?? 0;
      debugPrint('[AssignDoctorScreen] Received patientId=$patientId');
      _controller.init(patientId);
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
    if (Get.isRegistered<AssignDoctorController>()) {
      Get.delete<AssignDoctorController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: DashboardBackground(
        child: Column(
          children: [
            _buildTopAppBar(isMobile),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildBody(isMobile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────
  Widget _buildBody(bool isMobile) {
    return Stack(
      children: [
        // Content always rendered
        _buildContent(isMobile),

        // Loading overlay
        Positioned.fill(
          child: Obx(
            () => _controller.isLoading.value
                ? const ColoredBox(
                    color: ColorConstants.background,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ColorConstants.primary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // Error overlay
        Positioned.fill(
          child: Obx(
            () => _controller.errorMessage.value != null
                ? ColoredBox(
                    color: ColorConstants.background,
                    child: _buildErrorState(),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // ── Content ────────────────────────────────────────────────────────────
  Widget _buildContent(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(isMobile),
          const SizedBox(height: 16),
          // Header with doctor count - using Obx for reactivity
          Obx(() => _buildHeaderInfo()),
          const SizedBox(height: 12),
          // Doctor list - using Obx for reactivity
          Obx(() => _buildDoctorList(isMobile)),
        ],
      ),
    );
  }

  // ── Top App Bar ───────────────────────────────────────────────────────
  Widget _buildTopAppBar(bool isMobile) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ColorConstants.appBarBackground,
        border: Border(
          bottom: BorderSide(
            color: ColorConstants.onSurfaceVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              debugPrint('[AssignDoctorScreen] Back button pressed');
              Get.back();
            },
            icon: const Icon(Icons.arrow_back, color: ColorConstants.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Assign Doctor',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.w700,
                color: ColorConstants.primary,
              ),
            ),
          ),
          Obx(() {
            if (_controller.isAssigning.value) {
              return const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColorConstants.primary,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  // ── Error State ───────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: ColorConstants.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _controller.errorMessage.value ?? 'An error occurred.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: ColorConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _controller.fetchDoctors(),
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

  // ── Search Bar ────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primary.withOpacity(0.06),
            blurRadius: 12,
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
              color: ColorConstants.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.search,
              color: ColorConstants.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) {
                _controller.searchQuery.value = value;
              },
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search doctors by name...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: ColorConstants.onSurfaceVariant.withOpacity(0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header Info ───────────────────────────────────────────────────────
  Widget _buildHeaderInfo() {
    final filtered = _controller.filteredDoctors;
    final total = _controller.doctors.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Available Doctors ($total)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ColorConstants.onSurface,
          ),
        ),
        if (filtered.length != total)
          Text(
            '${filtered.length} matching',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  // ── Doctor List ───────────────────────────────────────────────────────
  Widget _buildDoctorList(bool isMobile) {
    final filtered = _controller.filteredDoctors;

    // Debug print to verify data
    debugPrint('[AssignDoctorScreen] Rendering ${filtered.length} doctors');
    for (var doc in filtered) {
      debugPrint(
        '[AssignDoctorScreen] Doctor: ${doc.name}, '
        'Specialization: ${doc.specialization}, '
        'City: ${doc.city}',
      );
    }

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: filtered
          .map((doctor) => _buildDoctorCard(doctor, isMobile))
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              size: 56,
              color: ColorConstants.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No doctors found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or city filter.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: ColorConstants.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Doctor Card ───────────────────────────────────────────────────────
  Widget _buildDoctorCard(Doctor doctor, bool isMobile) {
    final isSelected = _controller.selectedDoctorId.value == doctor.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: ColorConstants.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? ColorConstants.primary
              : ColorConstants.borderWhite10,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dashboardShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? _buildMobileDoctorLayout(doctor, isSelected)
          : _buildDesktopDoctorLayout(doctor, isSelected),
    );
  }

  Widget _buildMobileDoctorLayout(Doctor doctor, bool isSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAvatar(doctor, 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialization.isNotEmpty
                        ? doctor.specialization
                        : 'General',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ColorConstants.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(doctor),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(Icons.location_on_outlined, doctor.city),
            if (doctor.experience.isNotEmpty) ...[
              const SizedBox(width: 8),
              _buildInfoChip(Icons.work_outline, doctor.experience),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildAssignButton(doctor, isSelected),
        ),
      ],
    );
  }

  Widget _buildDesktopDoctorLayout(Doctor doctor, bool isSelected) {
    return Row(
      children: [
        _buildAvatar(doctor, 56),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                doctor.specialization.isNotEmpty
                    ? doctor.specialization
                    : 'General',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(Icons.location_on_outlined, doctor.city),
                  if (doctor.experience.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    _buildInfoChip(Icons.work_outline, doctor.experience),
                  ],
                  const SizedBox(width: 10),
                  _buildInfoChip(Icons.email_outlined, doctor.email),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildStatusBadge(doctor),
        const SizedBox(width: 16),
        _buildAssignButton(doctor, isSelected),
      ],
    );
  }

  // ── Reusable Widgets ─────────────────────────────────────────────────
  Widget _buildAvatar(Doctor doctor, double size) {
    final initials = doctor.name.isNotEmpty
        ? doctor.name
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0])
              .join()
              .toUpperCase()
        : '?';

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorConstants.onPrimary.withOpacity(0.15),
            border: Border.all(color: ColorConstants.borderWhite10, width: 1.5),
          ),
          child: doctor.profileImage != null && doctor.profileImage!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    doctor.profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildInitials(initials, size),
                  ),
                )
              : _buildInitials(initials, size),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.25,
            height: size * 0.25,
            decoration: BoxDecoration(
              color: doctor.isActive
                  ? ColorConstants.success
                  : ColorConstants.onSurfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: ColorConstants.background, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitials(String initials, double size) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
          color: ColorConstants.onPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    if (text.isEmpty || text == 'Unknown') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConstants.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ColorConstants.onPrimary),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ColorConstants.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Doctor doctor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: doctor.isActive
            ? ColorConstants.onPrimary.withOpacity(0.15)
            : ColorConstants.onPrimary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        doctor.isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: doctor.isActive
              ? ColorConstants.onPrimary
              : ColorConstants.onPrimary,
        ),
      ),
    );
  }

  Widget _buildAssignButton(Doctor doctor, bool isSelected) {
    final isAssigningThis = _controller.isAssigning.value && isSelected;

    return ElevatedButton(
      onPressed: isAssigningThis ? null : () => _handleAssignDoctor(doctor),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? ColorConstants.primary
            : ColorConstants.surfaceContainerHigh,
        foregroundColor: isSelected
            ? ColorConstants.onPrimary
            : ColorConstants.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(
          color: isSelected
              ? ColorConstants.primary
              : ColorConstants.primary.withOpacity(0.2),
        ),
        elevation: 0,
      ),
      child: isAssigningThis
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorConstants.onPrimary,
              ),
            )
          : Text(
              isSelected ? 'Assign Doctor' : 'Select',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  // ── Assign Handler ────────────────────────────────────────────────────
  void _handleAssignDoctor(Doctor doctor) {
    debugPrint(
      '[AssignDoctorScreen] Assign button tapped for ${doctor.name} (id=${doctor.id})',
    );

    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Assignment',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to assign the following doctor to this patient?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildAvatar(doctor, 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onSurface,
                          ),
                        ),
                        Text(
                          doctor.specialization.isNotEmpty
                              ? doctor.specialization
                              : 'General',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: ColorConstants.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _controller.assignDoctor(doctor.id, doctor.name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: ColorConstants.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
