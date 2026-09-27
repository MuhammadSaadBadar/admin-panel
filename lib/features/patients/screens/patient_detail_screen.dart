import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../controllers/patient_detail_controller.dart';
import '../models/patient.dart';
import '../models/patient_summary.dart';
import '../repositories/patient_repository.dart';

class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final PatientDetailController _controller;
  int _patientId = 0;

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<PatientRepository>()) {
      Get.put(PatientRepository(Get.find<ApiClient>()));
    }
    if (!Get.isRegistered<PatientDetailController>()) {
      Get.put(PatientDetailController(Get.find<PatientRepository>()));
    }
    _controller = Get.find<PatientDetailController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && args['patientId'] != null) {
        _patientId = args['patientId'] as int;
        _controller.loadAllData(_patientId);
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
                        if (_controller.isLoadingPatient.value ||
                            _controller.isLoadingSummary.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final patient = _controller.patient.value;
                        final summary = _controller.patientSummary.value;
                        if (patient == null) {
                          return const Center(
                            child: Text("Failed to load patient data"),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [
                                    _PatientProfileHeader(
                                      isMobile: isMobile,
                                      patient: patient,
                                      summary: summary,
                                    ),
                                    SizedBox(height: isMobile ? 16 : 24),
                                    _buildBentoGrid(isMobile, patient, summary),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        final patient = _controller.patient.value;
        if (patient == null) return const SizedBox.shrink();
        return _ActionBar(
          isMobile: isMobile,
          patient: patient,
          controller: _controller,
        );
      }),
    );
  }

  Widget _buildSidebar() {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.dashboard, 'label': 'Dashboard', 'selected': false},
      {
        'icon': Icons.medical_services,
        'label': 'Doctor Management',
        'selected': false,
      },
      {'icon': Icons.person, 'label': 'Patient Management', 'selected': true},
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorConstants.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'A',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ColorConstants.onPrimaryContainer,
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
                              'Admin Panel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: ColorConstants.onSurface,
                              ),
                            ),
                            Text(
                              'Mama Health',
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
        ],
      ),
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return CustomAppBar(
      title: 'Patient Details',
      showBackButton: true,
      onBackTap: () => Navigator.pop(context),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.notifications,
            color: ColorConstants.primary,
            size: isMobile ? 20 : 24,
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid(
    bool isMobile,
    Patient patient,
    PatientSummary? summary,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _PersonalInfoCard(isMobile: isMobile, patient: patient),
          const SizedBox(height: 16),
          _PregnancyDetailsCard(isMobile: isMobile, summary: summary),
          const SizedBox(height: 16),
          _BabySizeCard(isMobile: isMobile, controller: _controller),
          const SizedBox(height: 16),
          _HealthTrackersCard(isMobile: isMobile, summary: summary),
          const SizedBox(height: 16),
          _SymptomsAndDietCard(
            isMobile: isMobile,
            summary: summary,
            onDietPlanTap: _controller.isLoadingPatient.value || _controller.isLoadingSummary.value
                ? null
                : _openDietManagement,
            dietButtonColor: _controller.isLoadingPatient.value || _controller.isLoadingSummary.value
                ? ColorConstants.onSurfaceVariant
                : null,
          ),
          const SizedBox(height: 16),
_MedicationsCard(
             isMobile: isMobile,
             onRemindersTap: _controller.isLoadingPatient.value || _controller.isLoadingSummary.value
                 ? null
                 : _openMedicationReminders,
             onHistoryTap: _controller.isLoadingPatient.value || _controller.isLoadingSummary.value
                 ? null
                 : _openMedicationHistory,
           ),
          const SizedBox(height: 16),
          _AppointmentHistoryCard(isMobile: isMobile, summary: summary),

          const SizedBox(height: 16),
          _SosHistoryCard(isMobile: isMobile, controller: _controller),
          const SizedBox(height: 80), // Padding for fab
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0), // Padding for fab
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _PersonalInfoCard(isMobile: false, patient: patient),
                const SizedBox(height: 24),
                _PregnancyDetailsCard(isMobile: false, summary: summary),
                const SizedBox(height: 24),
                _BabySizeCard(isMobile: false, controller: _controller),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 8,
            child: Column(
              children: [
                _HealthTrackersCard(isMobile: false, summary: summary),
                const SizedBox(height: 24),
                _SymptomsAndDietCard(
                  isMobile: false,
                  summary: summary,
                  onDietPlanTap: _controller.isLoadingPatient.value || _controller.isLoadingSummary.value
                      ? null
                      : _openDietManagement,
                  dietButtonColor: _controller.isLoadingPatient.value || _controller.isLoadingSummary.value
                      ? ColorConstants.onSurfaceVariant
                      : null,
                ),
                const SizedBox(height: 24),
_MedicationsCard(
                   isMobile: false,
                   onRemindersTap: _controller.isLoadingPatient.value || _controller.isLoadingSummary.value
                       ? null
                       : _openMedicationReminders,
                   onHistoryTap: _controller.isLoadingPatient.value || _controller.isLoadingSummary.value
                       ? null
                       : _openMedicationHistory,
                 ),
                const SizedBox(height: 24),
                _AppointmentHistoryCard(isMobile: false, summary: summary),
                const SizedBox(height: 24),
                _SosHistoryCard(isMobile: false, controller: _controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDietManagement() async {
    debugPrint(
      '[PatientDetails] Opening Diet Management for patientId=$_patientId',
    );
    await Get.toNamed(
      RouteNames.dietPlans,
      arguments: {'patientId': _patientId},
    );
    // The Diet Plan Management / Create screens may have created or updated
    // the patient's active diet plan. That flow lives deeper in the stack, so
    // this screen's initState won't re-run on return. Refresh the summary now
    // so the active diet plan reflects the latest backend state.
    if (mounted) {
      debugPrint(
        '[PatientDetails] Returning from Diet Management — refreshing summary '
        'for patientId=$_patientId',
      );
      _controller.loadPatientSummary(_patientId);
    }
  }

  Future<void> _openMedicationReminders() async {
    debugPrint(
      '[PatientDetails] Opening Medication Reminders for patientId=$_patientId',
    );
    await Get.toNamed(
      RouteNames.medicationReminders,
      arguments: {'patientId': _patientId},
    );
    // The reminder screens may have created/updated/deleted reminders or
    // status flags. Refresh the summary so medication adherence stays in sync.
    if (mounted) {
      debugPrint(
        '[PatientDetails] Returning from Medication Reminders — refreshing '
        'summary for patientId=$_patientId',
      );
      _controller.loadPatientSummary(_patientId);
    }
  }

  Future<void> _openMedicationHistory() async {
    debugPrint(
      '[PatientDetails] Opening Medication History for patientId=$_patientId',
    );
    await Get.toNamed(
      RouteNames.medicationHistory,
      arguments: {'patientId': _patientId},
    );
    if (mounted) {
      _controller.loadPatientSummary(_patientId);
    }
  }

  Future<void> _openBloodPressureHistory() async {
    debugPrint(
      '[PatientDetails] Opening Blood Pressure History for patientId=$_patientId',
    );
    await Get.toNamed(
      RouteNames.bloodPressureHistory,
      arguments: {'patientId': _patientId},
    );
    if (mounted) {
      _controller.loadPatientSummary(_patientId);
    }
  }

  Future<void> _openBloodSugarHistory() async {
    debugPrint(
      '[PatientDetails] Opening Blood Sugar History for patientId=$_patientId',
    );
    await Get.toNamed(
      RouteNames.bloodSugarHistory,
      arguments: {'patientId': _patientId},
    );
    if (mounted) {
      _controller.loadPatientSummary(_patientId);
    }
  }
}

class _PatientProfileHeader extends StatelessWidget {
  final bool isMobile;
  final Patient patient;
  final PatientSummary? summary;

  const _PatientProfileHeader({
    required this.isMobile,
    required this.patient,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        (patient.firstName.isNotEmpty
            ? patient.firstName[0].toUpperCase()
            : '') +
        (patient.lastName.isNotEmpty ? patient.lastName[0].toUpperCase() : '');

    final avatarWidget = Stack(
      children: [
        Container(
          width: isMobile ? 80 : 128,
          height: isMobile ? 80 : 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorConstants.primaryContainer,
            border: Border.all(color: ColorConstants.primary, width: 2),
          ),
          child: Center(
            child: Text(
              initials.isNotEmpty ? initials : "?",
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 32 : 48,
                fontWeight: FontWeight.bold,
                color: ColorConstants.onPrimaryContainer,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: isMobile ? 2 : 4,
          right: isMobile ? 2 : 4,
          child: Container(
            width: isMobile ? 20 : 24,
            height: isMobile ? 20 : 24,
            decoration: BoxDecoration(
              color: patient.isActive
                  ? ColorConstants.tertiary
                  : ColorConstants.error,
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorConstants.cardBackground,
                width: isMobile ? 3 : 4,
              ),
            ),
          ),
        ),
      ],
    );

    final bloodGroup =
        (patient.patientProfile?.bloodGroup != null &&
            patient.patientProfile!.bloodGroup!.isNotEmpty)
        ? patient.patientProfile!.bloodGroup!
        : 'N/A';

    final weeks = summary?.pregnancyProgress?.currentWeek != null
        ? '${summary!.pregnancyProgress!.currentWeek} Weeks'
        : 'N/A';

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorConstants.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.primary.withOpacity(0.05),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                avatarWidget,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#MH-${patient.id}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusBadge(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.water_drop,
                    bloodGroup,
                    ColorConstants.tertiary,
                    isMobile,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.calendar_today,
                    weeks,
                    ColorConstants.primary,
                    isMobile,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primary.withOpacity(0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        children: [
          avatarWidget,
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      patient.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '#MH-${patient.id}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.water_drop,
                      bloodGroup,
                      ColorConstants.tertiary,
                      isMobile,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.calendar_today,
                      weeks,
                      ColorConstants.primary,
                      isMobile,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isActive = patient.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? ColorConstants.tertiary.withOpacity(0.15)
            : ColorConstants.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? ColorConstants.tertiary : ColorConstants.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? ColorConstants.tertiary : ColorConstants.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    Color iconColor,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: isMobile ? 16 : 20),
          SizedBox(width: isMobile ? 4 : 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  final bool isMobile;
  final Patient patient;

  const _PersonalInfoCard({required this.isMobile, required this.patient});

  @override
  Widget build(BuildContext context) {
    final ageLabel = patient.age != null ? '${patient.age} Yrs' : 'N/A';
    final dob = patient.patientProfile?.dateOfBirth != null
        ? '${patient.patientProfile!.dateOfBirth} ($ageLabel)'
        : 'N/A';
    final emergencyContactName =
        (patient.patientProfile?.emergencyContactName?.isNotEmpty ?? false)
        ? patient.patientProfile!.emergencyContactName!
        : 'N/A';
    final emergencyContactPhone =
        (patient.patientProfile?.emergencyContactPhone?.isNotEmpty ?? false)
        ? patient.patientProfile!.emergencyContactPhone!
        : 'N/A';
    final address = (patient.patientProfile?.address?.isNotEmpty ?? false)
        ? patient.patientProfile!.address!
        : 'N/A';

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Info',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onPrimary,
                ),
              ),
              Icon(
                Icons.person,
                color: ColorConstants.onPrimary,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildInfoRow('Date of Birth', dob, isMobile),
          SizedBox(height: isMobile ? 8 : 12),
          _buildInfoRow(
            'Contact',
            patient.phoneNumber.isNotEmpty ? patient.phoneNumber : 'N/A',
            isMobile,
          ),
          Text(
            patient.email.isNotEmpty ? patient.email : 'N/A',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.onPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          _buildInfoRow('Emergency Contact', emergencyContactName, isMobile),
          Text(
            emergencyContactPhone,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.onPrimaryContainer,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          _buildInfoRow('Address', address, isMobile),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: ColorConstants.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: ColorConstants.onPrimary,
          ),
        ),
      ],
    );
  }
}

class _PregnancyDetailsCard extends StatelessWidget {
  final bool isMobile;
  final PatientSummary? summary;

  const _PregnancyDetailsCard({required this.isMobile, required this.summary});

  @override
  Widget build(BuildContext context) {
    final prog = summary?.pregnancyProgress;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: ColorConstants.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pregnant_woman,
                color: ColorConstants.primary,
                size: isMobile ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Pregnancy Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          if (prog == null)
            Text(
              'Pregnancy data not available.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurfaceVariant,
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Progress',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
                Text(
                  prog.currentWeek != null
                      ? 'Week ${prog.currentWeek} (${((prog.percentComplete ?? 0) * 100).toStringAsFixed(0)}%)'
                      : 'N/A',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: prog.percentComplete ?? 0,
                backgroundColor: ColorConstants.surfaceContainerHighest,
                color: ColorConstants.primary,
                minHeight: isMobile ? 6 : 8,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Divider(height: 1, color: ColorConstants.borderWhite5),
            SizedBox(height: isMobile ? 12 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EDD',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prog.eddDate ?? 'N/A',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Conception',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prog.lmpDate ?? 'N/A',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HealthTrackersCard extends StatelessWidget {
  final bool isMobile;
  final PatientSummary? summary;

  const _HealthTrackersCard({required this.isMobile, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          _buildBloodPressureCard(isMobile),
          const SizedBox(height: 12),
          _buildBloodSugarCard(isMobile),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: _buildBloodPressureCard(false)),
        const SizedBox(width: 16),
        Expanded(child: _buildBloodSugarCard(false)),
      ],
    );
  }

  Widget _buildBloodPressureCard(bool isMobile) {
    final bp = summary?.latestBloodPressure;
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blood Pressure',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05,
                      color: ColorConstants.onSurfaceVariant,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: bp != null
                              ? '${bp.systolic}/${bp.diastolic} '
                              : 'N/A ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onSurface,
                          ),
                        ),
                        if (bp != null)
                          TextSpan(
                            text: 'mmHg',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w400,
                              color: ColorConstants.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.monitor_heart,
                color: ColorConstants.error,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
          if (bp == null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'No reading today',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBloodSugarCard(bool isMobile) {
    final bs = summary?.latestBloodSugar;
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blood Sugar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05,
                      color: ColorConstants.onSurfaceVariant,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: bs != null ? '${bs.valueMgDl} ' : 'N/A ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onSurface,
                          ),
                        ),
                        if (bs != null)
                          TextSpan(
                            text: 'mg/dL',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w400,
                              color: ColorConstants.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.bloodtype,
                color: ColorConstants.tertiary,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
          if (bs != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_down,
                    color: ColorConstants.tertiary,
                    size: isMobile ? 14 : 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      bs.readingContext ?? 'N/A',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w500,
                        color: ColorConstants.tertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'No reading today',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SymptomsAndDietCard extends StatelessWidget {
  final bool isMobile;
  final PatientSummary? summary;
  final Future<void> Function()? onDietPlanTap;
  final Color? dietButtonColor;

  const _SymptomsAndDietCard({
    required this.isMobile,
    required this.summary,
    required this.onDietPlanTap,
    this.dietButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final recentSymptoms = summary?.recentSymptoms ?? [];
    final symptomNames = <String>[];
    for (final log in recentSymptoms) {
      for (final item in log.symptoms) {
        if (item.name.isNotEmpty && !symptomNames.contains(item.name)) {
          symptomNames.add(item.name);
        }
      }
    }
    final dietPlan = summary?.activeDietPlan;

    final dietWidget = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diet Plan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onPrimary,
                ),
              ),
              Icon(
                Icons.restaurant_menu,
                color: ColorConstants.onPrimary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dietPlan?.notes ?? 'No active diet plan.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: ColorConstants.onPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDietPlanTap,
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: Text(
                'Manage Diet Plans',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: dietButtonColor ?? ColorConstants.onPrimary,
                side: BorderSide(color: dietButtonColor ?? ColorConstants.onPrimary),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final symptomsWidget = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logged Symptoms',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (symptomNames.isEmpty)
            Text(
              'No recent symptoms logged.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: symptomNames
                  .map((s) => _buildSymptomChip(s, ColorConstants.error))
                  .toList(),
            ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [symptomsWidget, const SizedBox(height: 12), dietWidget],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: symptomsWidget),
        const SizedBox(width: 16),
        Expanded(child: dietWidget),
      ],
    );
  }

  Widget _buildSymptomChip(String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentHistoryCard extends StatelessWidget {
  final bool isMobile;
  final PatientSummary? summary;

  const _AppointmentHistoryCard({
    required this.isMobile,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final appointments = summary?.upcomingAppointments ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Appointments',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: ColorConstants.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          if (appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No upcoming appointments.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: isMobile ? 16 : 32,
                headingRowColor: WidgetStateProperty.all(
                  ColorConstants.surfaceContainerHighest,
                ),
                headingTextStyle: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 10 : 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                  color: ColorConstants.onSurfaceVariant,
                ),
                dataTextStyle: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w400,
                  color: ColorConstants.onSurface,
                ),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Doctor')),
                  DataColumn(label: Text('Status')),
                ],
                rows: appointments.map((appt) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          appt.scheduledAt.isNotEmpty
                              ? appt.scheduledAt
                              : 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          appt.appointmentType.isNotEmpty
                              ? appt.appointmentType
                              : 'Unknown',
                        ),
                      ),
                      DataCell(
                        Text(
                          appt.status.isNotEmpty ? appt.status : 'Pending',
                          style: TextStyle(color: ColorConstants.tertiary),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MedicationsCard extends StatelessWidget {
  final bool isMobile;
  final Future<void> Function()? onRemindersTap;
  final Future<void> Function()? onHistoryTap;

  const _MedicationsCard({
    required this.isMobile,
    required this.onRemindersTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildTile({
      required IconData icon,
      required String title,
      required String subtitle,
      required Future<void> Function()? onTap,
      required Color accent,
    }) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        decoration: BoxDecoration(
          color: ColorConstants.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.onPrimary),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Container(
                width: isMobile ? 40 : 48,
                height: isMobile ? 40 : 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: isMobile ? 20 : 24),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 11 : 12,
                        color: ColorConstants.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ColorConstants.onPrimary,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medications',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.primary,
            ),
          ),
          const SizedBox(height: 12),
          buildTile(
            icon: Icons.medication,
            title: 'Medication Reminders',
            subtitle: 'View and manage this patient\'s reminders',
            onTap: onRemindersTap,
            accent: ColorConstants.onPrimary,
          ),
          const SizedBox(height: 12),
          buildTile(
            icon: Icons.assignment_turned_in,
            title: 'Medication History',
            subtitle: 'View this patient\'s intake records',
            onTap: onHistoryTap,
            accent: ColorConstants.onPrimary,
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medications',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurface,
                ),
              ),
              Icon(
                Icons.medication,
                color: ColorConstants.primary,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Row(
            children: [
              Expanded(
                child: buildTile(
                  icon: Icons.medication,
                  title: 'Medication Reminders',
                  subtitle: 'Manage this patient\'s reminders',
                  onTap: onRemindersTap,
                  accent: ColorConstants.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildTile(
                  icon: Icons.assignment_turned_in,
                  title: 'Medication History',
                  subtitle: 'View intake records',
                  onTap: onHistoryTap,
                  accent: ColorConstants.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BabySizeCard extends StatelessWidget {
  final bool isMobile;
  final PatientDetailController controller;

  const _BabySizeCard({required this.isMobile, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Baby Size',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurface,
                ),
              ),
              Icon(
                Icons.child_friendly,
                color: ColorConstants.primary,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
Obx(() {
             if (controller.isLoadingBabySize.value) {
               return const Center(
                 child: Padding(
                   padding: EdgeInsets.all(12),
                   child: CircularProgressIndicator(strokeWidth: 2),
                 ),
               );
             }
             if (controller.babySizeError.value != null) {
               return Text(
                 'Failed to load baby size data: ${controller.babySizeError.value}',
                 style: GoogleFonts.plusJakartaSans(
                   fontSize: 14,
                   color: ColorConstants.onSurfaceVariant,
                 ),
               );
             }
             final baby = controller.babySize.value;
             if (baby == null) {
               return Text(
                 'Baby size data is loading...',
                 style: GoogleFonts.plusJakartaSans(
                   fontSize: 14,
                   color: ColorConstants.onSurfaceVariant,
                 ),
               );
             }
             return Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     Icon(
                       Icons.straighten,
                       color: ColorConstants.primary,
                       size: isMobile ? 16 : 18,
                     ),
                     const SizedBox(width: 6),
                     Text(
                       'Week ${baby.week}',
                       style: GoogleFonts.plusJakartaSans(
                         fontSize: isMobile ? 16 : 18,
                         fontWeight: FontWeight.w700,
                         color: ColorConstants.primary,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 if (baby.sizeComparison.isNotEmpty)
                   Text(
                     'Size of a ${baby.sizeComparison}',
                     style: GoogleFonts.plusJakartaSans(
                       fontSize: isMobile ? 14 : 16,
                       fontWeight: FontWeight.w600,
                       color: ColorConstants.onSurface,
                     ),
                   ),
                 if (baby.sizeComparison.isEmpty &&
                     (baby.lengthCm.isNotEmpty || baby.weightGrams.isNotEmpty))
                   Text(
                     'Size details for this week are not available.',
                     style: GoogleFonts.plusJakartaSans(
                       fontSize: isMobile ? 14 : 16,
                       fontWeight: FontWeight.w600,
                       color: ColorConstants.onSurface,
                     ),
                   ),
                 if (baby.sizeComparison.isEmpty &&
                     baby.lengthCm.isEmpty &&
                     baby.weightGrams.isEmpty &&
                     baby.description.isEmpty)
                   Text(
                     'No size comparison data available for this week.',
                     style: GoogleFonts.plusJakartaSans(
                       fontSize: isMobile ? 14 : 16,
                       fontWeight: FontWeight.w600,
                       color: ColorConstants.onSurfaceVariant,
                     ),
                   ),
                 const SizedBox(height: 8),
                 Wrap(
                   spacing: 16,
                   runSpacing: 4,
                   children: [
                     if (baby.lengthCm.isNotEmpty)
                       _buildMetric('Length', baby.lengthCm, 'cm'),
                     if (baby.weightGrams.isNotEmpty)
                       _buildMetric('Weight', baby.weightGrams, 'g'),
                   ],
                 ),
                 if (baby.description.isNotEmpty) ...[
                   const SizedBox(height: 8),
                   Text(
                     baby.description,
                     style: GoogleFonts.plusJakartaSans(
                       fontSize: 12,
                       fontStyle: FontStyle.italic,
                       color: ColorConstants.onSurfaceVariant,
                     ),
                   ),
                 ],
               ],
             );
           }),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, String unit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        Text(
          '$value $unit',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SosHistoryCard extends StatelessWidget {
  final bool isMobile;
  final PatientDetailController controller;

  const _SosHistoryCard({required this.isMobile, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: ColorConstants.error, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency SOS History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurface,
                ),
              ),
              Icon(
                Icons.emergency,
                color: ColorConstants.error,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Obx(() {
            if (controller.isLoadingSos.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (controller.sosError.value != null) {
              return Text(
                'SOS history unavailable.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: ColorConstants.onSurfaceVariant,
                ),
              );
            }
            final events = controller.sosHistory;
            if (events.isEmpty) {
              return Text(
                'No emergency SOS events.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: ColorConstants.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: events.take(5).map((event) {
                final isActive = event.isActive;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? ColorConstants.error.withOpacity(0.08)
                        : ColorConstants.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? ColorConstants.error
                              : ColorConstants.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.createdAt.isNotEmpty
                                  ? event.createdAt
                                  : 'Unknown time',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.onSurface,
                              ),
                            ),
                            if (event.notes.isNotEmpty)
                              Text(
                                event.notes,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: ColorConstants.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(event.status),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'active'
        ? ColorConstants.error
        : status == 'resolved'
        ? ColorConstants.success
        : ColorConstants.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool isMobile;
  final Patient patient;
  final PatientDetailController controller;

  const _ActionBar({
    required this.isMobile,
    required this.patient,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = patient.isActive;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 5 : 0),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainer.withOpacity(0.9),
        border: Border(top: BorderSide(color: ColorConstants.borderWhite10)),
      ),
      child: isMobile
          ? _buildMobileLayout(context, isActive)
          : _buildDesktopLayout(context, isActive),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isActive) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        _buildMobileButton(
          label: 'Assign Doctor',
          icon: Icons.person_add_alt_1,
          color: ColorConstants.onPrimaryContainer,
          onPressed: () => _navigateToAssignDoctor(),
        ),
        _buildMobileButton(
          label: isActive ? 'Deactivate' : 'Activate',
          icon: isActive ? Icons.block : Icons.check_circle_outline,
          color: isActive
              ? ColorConstants.onPrimaryContainer
              : ColorConstants.success,
          onPressed: () => _confirmStatusToggle(context, isActive),
        ),
        // _buildMobileButton(
        //   label: 'Delete',
        //   icon: Icons.delete_outline,
        //   color: ColorConstants.error,
        //   onPressed: () {},
        //   filled: true,
        // ),
      ],
    );
  }

  Widget _buildMobileButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: ColorConstants.onError,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: color.withOpacity(0.4)),
        backgroundColor: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Assign Doctor button
        OutlinedButton.icon(
          onPressed: () => _navigateToAssignDoctor(),
          icon: const Icon(Icons.person_add_alt_1, size: 18),
          label: Text(
            'Assign Doctor',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorConstants.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: ColorConstants.secondary.withOpacity(0.4)),
          ),
        ),
        const SizedBox(width: 12),
        // Activate / Deactivate toggle
        Obx(() {
          final updating = controller.isUpdatingStatus.value;
          return OutlinedButton.icon(
            onPressed: updating
                ? null
                : () => _confirmStatusToggle(context, isActive),
            icon: updating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isActive ? Icons.block : Icons.check_circle_outline,
                    size: 18,
                  ),
            label: Text(
              isActive ? 'Deactivate Patient' : 'Activate Patient',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isActive
                  ? ColorConstants.warning
                  : ColorConstants.success,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color:
                    (isActive ? ColorConstants.warning : ColorConstants.success)
                        .withOpacity(0.3),
              ),
              backgroundColor:
                  (isActive ? ColorConstants.warning : ColorConstants.success)
                      .withOpacity(0.15),
            ),
          );
        }),
        const SizedBox(width: 12),
        // Mark Paid (admin manual payment confirmation)
        Obx(() {
          final marking = controller.isMarkingPaid.value;
          return OutlinedButton.icon(
            onPressed: marking ? null : () => _showMarkPaidDialog(context),
            icon: marking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payments_outlined, size: 18),
            label: Text(
              'Mark Paid',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.tertiary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: ColorConstants.tertiary.withOpacity(0.4)),
              backgroundColor: ColorConstants.tertiary.withOpacity(0.1),
            ),
          );
        }),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.delete_outline, size: 18),
          label: Text(
            'Delete Record',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.error,
            foregroundColor: ColorConstants.onError,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
          ),
        ),
      ],
    );
  }

  // ── Navigation ──────────────────────────────────────────────────────────
  void _navigateToAssignDoctor() {
    debugPrint(
      '[ActionBar] Navigating to Assign Doctor for patientId=${patient.id}',
    );
    Get.toNamed(RouteNames.assignDoctor, arguments: {'patientId': patient.id});
  }

  // ── Mark Paid ─────────────────────────────────────────────────────────
  void _showMarkPaidDialog(BuildContext context) {
    final referenceController = TextEditingController();
    final amountController = TextEditingController();
    debugPrint(
      '[ActionBar] Opening mark-paid dialog for patientId=${patient.id}',
    );

    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mark Patient as Paid',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Record a manual payment received for ${patient.name}. '
              'This confirms the patient has full access.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: ColorConstants.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: referenceController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'Payment Reference (optional)',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: ColorConstants.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorConstants.borderWhite10),
                ),
                filled: true,
                fillColor: ColorConstants.surfaceContainer,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'Amount Paid (optional)',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: ColorConstants.onSurfaceVariant,
                ),
                prefixText: 'Rs. ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorConstants.borderWhite10),
                ),
                filled: true,
                fillColor: ColorConstants.surfaceContainer,
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
              controller.markPatientPaid(
                paymentReference: referenceController.text.trim(),
                amountPaid: amountController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.tertiary,
              foregroundColor: ColorConstants.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Confirm Payment',
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

  // ── Status Toggle ──────────────────────────────────────────────────────
  void _confirmStatusToggle(BuildContext context, bool currentlyActive) {
    final newStatus = !currentlyActive;
    final actionLabel = newStatus ? 'Activate' : 'Deactivate';
    debugPrint(
      '[ActionBar] Status toggle requested: ${currentlyActive ? "active→inactive" : "inactive→active"}',
    );

    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$actionLabel Patient',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to ${actionLabel.toLowerCase()} ${patient.name}?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ColorConstants.onSurfaceVariant,
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
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog
              try {
                await controller.updateAccountStatus(newStatus);
                Get.snackbar(
                  'Success',
                  '${patient.name} has been ${actionLabel.toLowerCase()}d.',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 3),
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to $actionLabel patient. Please try again.',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 4),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus
                  ? ColorConstants.success
                  : ColorConstants.warning,
              foregroundColor: ColorConstants.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              actionLabel,
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
