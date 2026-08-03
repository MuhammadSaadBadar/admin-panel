import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/route_names.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../controllers/patient_detail_controller.dart';
import '../models/patient.dart';
import '../models/patient_summary.dart';
import '../repositories/patient_repository.dart';
import '../../../core/network/api_client.dart';

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
      body: SafeArea(
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
                    child: Obx(() {
                      if (_controller.isLoadingPatient.value ||
                          _controller.isLoadingSummary.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final patient = _controller.patient.value;
                      final summary = _controller.patientSummary.value;
                      if (patient == null || summary == null) {
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
                                  _buildProfileHeader(
                                    isMobile,
                                    patient,
                                    summary,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildActionBar(isMobile),
      bottomNavigationBar: isMobile
          ? AppBottomNavBar(
              selectedIndex: 2,
              onItemSelected: (index) {
                switch (index) {
                  case 0:
                    Get.toNamed(RouteNames.dashboard);
                    break;
                  case 1:
                    Get.toNamed(RouteNames.doctors);
                    break;
                  case 2:
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

  Widget _buildProfileHeader(
    bool isMobile,
    Patient patient,
    PatientSummary summary,
  ) {
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
            // Profile Image and basic info
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorConstants.primary,
                          width: 2,
                        ),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDEHU7JAd4RhpKgcmJHy1EIueVPY3IjHgZKjr88o6ygDq3gZOdIrPWne_4vVlkBHVZ71lMbFVufgNzfRyQnMmsc7zQ5GjUekpbnhI0OyhScqT0UzJdc_cwwSoSOML45s8WPxjEP8U80aUkG5y0YPCLImW_gpx49C32eD3QuVzVbrqctrRvN9quiaL6nTkXzg_Rx2Eo3T-aQVEgevZAucuIiEeY4uS7-sA0dubSIfzEJEqHPtpeeSHMd',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: ColorConstants.tertiary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorConstants.cardBackground,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstants.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: ColorConstants.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'High Risk',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.error,
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
            const SizedBox(height: 12),
            // Info chips
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.water_drop,
                    label: patient.patientProfile?.bloodGroup ?? 'Unknown',
                    iconColor: ColorConstants.tertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: summary.pregnancyProgress?.currentWeek != null
                        ? '${summary.pregnancyProgress!.currentWeek} Weeks'
                        : 'N/A',
                    iconColor: ColorConstants.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Desktop layout
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
          // Profile Image
          Stack(
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorConstants.primary, width: 2),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDEHU7JAd4RhpKgcmJHy1EIueVPY3IjHgZKjr88o6ygDq3gZOdIrPWne_4vVlkBHVZ71lMbFVufgNzfRyQnMmsc7zQ5GjUekpbnhI0OyhScqT0UzJdc_cwwSoSOML45s8WPxjEP8U80aUkG5y0YPCLImW_gpx49C32eD3QuVzVbrqctrRvN9quiaL6nTkXzg_Rx2Eo3T-aQVEgevZAucuIiEeY4uS7-sA0dubSIfzEJEqHPtpeeSHMd',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: ColorConstants.tertiary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorConstants.cardBackground,
                      width: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Profile Info
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConstants.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: ColorConstants.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'High Risk',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.error,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      icon: Icons.water_drop,
                      label: patient.patientProfile?.bloodGroup ?? 'Unknown',
                      iconColor: ColorConstants.tertiary,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: summary.pregnancyProgress?.currentWeek != null
                          ? '${summary.pregnancyProgress!.currentWeek} Weeks'
                          : 'N/A',
                      iconColor: ColorConstants.primary,
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

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

  Widget _buildBentoGrid(
    bool isMobile,
    Patient patient,
    PatientSummary summary,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _buildPersonalInfoCard(isMobile, patient),
          const SizedBox(height: 16),
          _buildPregnancyDetailsCard(isMobile, summary),
          const SizedBox(height: 16),
          _buildHealthTrackers(isMobile, summary),
          const SizedBox(height: 16),
          _buildSymptomsAndDiet(isMobile, summary),
          const SizedBox(height: 16),
          _buildAppointmentHistory(isMobile, summary),
          const SizedBox(height: 16),
          _buildMedicalReports(isMobile),
        ],
      );
    }

    // Desktop layout
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildPersonalInfoCard(false, patient),
              const SizedBox(height: 24),
              _buildPregnancyDetailsCard(false, summary),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Column
        Expanded(
          flex: 8,
          child: Column(
            children: [
              _buildHealthTrackers(false, summary),
              const SizedBox(height: 24),
              _buildSymptomsAndDiet(false, summary),
              const SizedBox(height: 24),
              _buildAppointmentHistory(false, summary),
              const SizedBox(height: 24),
              _buildMedicalReports(false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(bool isMobile, Patient patient) {
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
              Text(
                'Personal Info',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurface,
                ),
              ),
              Icon(
                Icons.person,
                color: ColorConstants.primary,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildInfoRow(
            'Date of Birth',
            patient.patientProfile?.dateOfBirth != null
                ? '${patient.patientProfile!.dateOfBirth} (${patient.age} Yrs)'
                : 'N/A',
            isMobile,
          ),
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
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          _buildInfoRow(
            'Emergency Contact',
            patient.patientProfile?.emergencyContactName ?? 'N/A',
            isMobile,
          ),
          Text(
            patient.patientProfile?.emergencyContactPhone ?? 'N/A',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          _buildInfoRow('Address', 'Not Available', isMobile),
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
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: ColorConstants.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPregnancyDetailsCard(bool isMobile, PatientSummary summary) {
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
                summary.pregnancyProgress?.currentWeek != null
                    ? 'Week ${summary.pregnancyProgress!.currentWeek} (${((summary.pregnancyProgress!.percentComplete ?? 0) * 100).toStringAsFixed(0)}%)'
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
              value: summary.pregnancyProgress?.percentComplete ?? 0,
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
                    summary.pregnancyProgress?.eddDate ?? 'N/A',
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
                    summary.pregnancyProgress?.lmpDate ?? 'N/A',
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
      ),
    );
  }

  Widget _buildHealthTrackers(bool isMobile, PatientSummary summary) {
    if (isMobile) {
      return Column(
        children: [
          _buildBloodPressureCard(isMobile, summary),
          const SizedBox(height: 12),
          _buildBloodSugarCard(isMobile, summary),
          const SizedBox(height: 12),
          _buildKickCountsCard(isMobile),
          const SizedBox(height: 12),
          _buildWaterIntakeCard(isMobile),
        ],
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildBloodPressureCard(false, summary),
        _buildBloodSugarCard(false, summary),
        _buildKickCountsCard(false),
        _buildWaterIntakeCard(false),
      ],
    );
  }

  Widget _buildBloodPressureCard(bool isMobile, PatientSummary summary) {
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
                          text: summary.latestBloodPressure != null
                              ? '${summary.latestBloodPressure!.systolic}/${summary.latestBloodPressure!.diastolic} '
                              : 'N/A ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onSurface,
                          ),
                        ),
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
          SizedBox(height: isMobile ? 8 : 12),
          Row(
            children: [
              _buildMiniBar(20, ColorConstants.error.withOpacity(0.2)),
              _buildMiniBar(30, ColorConstants.error.withOpacity(0.2)),
              _buildMiniBar(25, ColorConstants.error.withOpacity(0.2)),
              _buildMiniBar(40, ColorConstants.error),
              _buildMiniBar(35, ColorConstants.error.withOpacity(0.2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBar(double height, Color color) {
    return Expanded(
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildBloodSugarCard(bool isMobile, PatientSummary summary) {
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
                          text: summary.latestBloodSugar != null
                              ? '${summary.latestBloodSugar!.valueMgDl} '
                              : 'N/A ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onSurface,
                          ),
                        ),
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
          SizedBox(height: isMobile ? 4 : 8),
          Row(
            children: [
              Icon(
                Icons.trending_down,
                color: ColorConstants.tertiary,
                size: isMobile ? 14 : 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  summary.latestBloodSugar?.readingContext ?? 'N/A',
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
        ],
      ),
    );
  }

  Widget _buildKickCountsCard(bool isMobile) {
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
                    'Kick Counts',
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
                          text: '12 ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: '/ 2hrs',
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
                Icons.child_care,
                color: ColorConstants.secondary,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            'Average for week: 10/2hr',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w500,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntakeCard(bool isMobile) {
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
                    'Water Intake',
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
                          text: '8 ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: '/ 10 glasses',
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
                Icons.water_drop,
                color: Colors.blue.shade400,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.8,
              backgroundColor: ColorConstants.surfaceContainerHighest,
              color: Colors.blue.shade400,
              minHeight: isMobile ? 4 : 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsAndDiet(bool isMobile, PatientSummary summary) {
    if (isMobile) {
      return Column(
        children: [
          Container(
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSymptomChip('Fatigue', ColorConstants.error),
                    _buildSymptomChip('Back Pain', ColorConstants.primary),
                    _buildSymptomChip('Mild Nausea', ColorConstants.tertiary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
                  'Diet Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary.activeDietPlan?.notes ?? 'No active diet plan.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.open_in_new,
                    color: ColorConstants.primary,
                    size: 14,
                  ),
                  label: Text(
                    'View Full Plan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Desktop layout
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSymptomChip('Fatigue', ColorConstants.error),
                    _buildSymptomChip('Back Pain', ColorConstants.primary),
                    _buildSymptomChip('Mild Nausea', ColorConstants.tertiary),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.borderWhite10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diet Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary.activeDietPlan?.notes ?? 'No active diet plan.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.open_in_new,
                    color: ColorConstants.primary,
                    size: 16,
                  ),
                  label: Text(
                    'View Full Plan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.05,
                      color: ColorConstants.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildAppointmentHistory(bool isMobile, PatientSummary summary) {
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
              Text(
                'Appointment History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'VIEW ALL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: ColorConstants.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 4 : 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: isMobile ? 16 : 32,
              headingRowColor: WidgetStateProperty.all(
                Colors.white.withOpacity(0.05),
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
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Status')),
              ],
              rows: [
                DataRow(
                  cells: [
                    const DataCell(
                      Text(
                        'Aug 15, 2024',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const DataCell(Text('Dr. Sarah Jenkins')),
                    const DataCell(Text('Routine Checkup')),
                    DataCell(
                      Text(
                        'Completed',
                        style: TextStyle(color: ColorConstants.tertiary),
                      ),
                    ),
                  ],
                ),
                DataRow(
                  cells: [
                    const DataCell(
                      Text(
                        'Sep 02, 2024',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const DataCell(Text('Dr. James Miller')),
                    const DataCell(Text('Ultrasound')),
                    DataCell(
                      Text(
                        'Upcoming',
                        style: TextStyle(
                          color: ColorConstants.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildMedicalReports(bool isMobile) {
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
          Text(
            'Medical Reports',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: ColorConstants.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          if (isMobile)
            Column(
              children: [
                _buildReportItem(
                  'Blood_Work_Q2.pdf',
                  'July 10, 2024 • 1.2 MB',
                  isMobile,
                ),
                const SizedBox(height: 8),
                _buildReportItem(
                  'Ultrasound_20wk.pdf',
                  'July 28, 2024 • 4.5 MB',
                  isMobile,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildReportItem(
                    'Blood_Work_Q2.pdf',
                    'July 10, 2024 • 1.2 MB',
                    false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReportItem(
                    'Ultrasound_20wk.pdf',
                    'July 28, 2024 • 4.5 MB',
                    false,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReportItem(String title, String subtitle, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstants.borderWhite5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf,
            color: ColorConstants.error,
            size: isMobile ? 20 : 24,
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? 4 : 8),
          Icon(
            Icons.download,
            color: ColorConstants.onSurfaceVariant,
            size: isMobile ? 18 : 20,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 5 : 0),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: ColorConstants.surfaceContainer.withOpacity(0.9),
          border: Border(top: BorderSide(color: ColorConstants.borderWhite10)),
        ),
        child: isMobile
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorConstants.primary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: ColorConstants.primary),
                      ),
                      child: Text(
                        'Edit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: Colors.orange.shade400.withOpacity(0.3),
                        ),
                        backgroundColor: Colors.orange.shade400.withOpacity(
                          0.2,
                        ),
                      ),
                      child: Text(
                        'Suspend',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.error,
                        foregroundColor: ColorConstants.onError,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstants.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: ColorConstants.primary),
                    ),
                    child: Text(
                      'Edit Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: Colors.orange.shade400.withOpacity(0.3),
                      ),
                      backgroundColor: Colors.orange.shade400.withOpacity(0.2),
                    ),
                    child: Text(
                      'Suspend',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.error,
                      foregroundColor: ColorConstants.onError,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Delete Record',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
