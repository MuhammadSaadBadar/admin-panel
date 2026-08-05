import 'package:admin/core/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../controllers/patient_list_controller.dart';
import '../models/patient.dart';
import '../repositories/patient_repository.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final PatientListController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<PatientRepository>()) {
      Get.put(PatientRepository(Get.find()));
    }
    if (!Get.isRegistered<PatientListController>()) {
      Get.put(PatientListController(Get.find()));
    }
    _controller = Get.find<PatientListController>();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _controller.loadMorePatients();
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      drawer: isMobile
          ? AppDrawer(
              currentRoute: RouteNames.patients,
              onNavigate: (route) {
                Navigator.of(context).pop(); // close drawer
                Get.toNamed(route);
              },
            )
          : null,
      body: Row(
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
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          _buildFiltersSection(),
                          const SizedBox(height: 24),
                          _buildPatientGrid(),
                          const SizedBox(height: 24),
                          Obx(() {
                            if (_controller.isLoadingMore.value) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: ColorConstants.primary,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
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
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () {
                Get.toNamed(RouteNames.registerPatient);
              },
              backgroundColor: ColorConstants.primary,
              foregroundColor: ColorConstants.onPrimary,
              child: const Icon(Icons.person_add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                Text(
                  'Mama Health',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
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
                      color: ColorConstants.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'AD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
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
                          'Admin User',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.onSurface,
                          ),
                        ),
                        Text(
                          'Administrator',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.05,
                            color: ColorConstants.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.settings,
                      color: ColorConstants.onSurfaceVariant,
                      size: 20,
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
      title: 'Patient Management',
      showMenuButton: isMobile,
      actions: [
        if (!isMobile)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: ColorConstants.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: ColorConstants.borderWhite10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: ColorConstants.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: ColorConstants.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Global search...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 16),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ColorConstants.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications,
                color: ColorConstants.primary,
                size: 24,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ColorConstants.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLarge = constraints.maxWidth > 800;
          return Column(
            children: [
              if (isLarge)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(flex: 2, child: _buildSearchField()),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 1,
                      child: Obx(
                        () => _buildFilterDropdown(
                          'Trimester',
                          const [
                            'All Trimesters',
                            '1st Trimester',
                            '2nd Trimester',
                            '3rd Trimester',
                          ],
                          selectedValue: _trimesterLabel,
                          onChanged: _onTrimesterChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Obx(
                        () => _buildFilterDropdown(
                          'Risk Level',
                          const ['Any Risk', 'High Risk', 'Normal'],
                          selectedValue: _riskLevelLabel,
                          onChanged: _onRiskLevelChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      flex: 1,
                      child: Obx(
                        () => _buildFilterDropdown(
                          'Doctor',
                          [
                            'All Doctors',
                            ..._controller.doctors.map((d) => d.name),
                          ],
                          selectedValue: _doctorLabel,
                          onChanged: _onDoctorChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _controller.hasActiveFilters
                          ? () => _controller.clearFilters()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.surfaceContainerHigh,
                        foregroundColor: ColorConstants.primary,
                        disabledBackgroundColor:
                            ColorConstants.surfaceContainer,
                        disabledForegroundColor: ColorConstants.onSurfaceVariant
                            .withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.filter_alt_off, size: 20),
                      label: Text(
                        'Clear Filters',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => _buildFilterDropdown(
                              'Trimester',
                              const [
                                'All Trimesters',
                                '1st Trimester',
                                '2nd Trimester',
                                '3rd Trimester',
                              ],
                              selectedValue: _trimesterLabel,
                              onChanged: _onTrimesterChanged,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(
                            () => _buildFilterDropdown(
                              'Risk Level',
                              const ['Any Risk', 'High Risk', 'Normal'],
                              selectedValue: _riskLevelLabel,
                              onChanged: _onRiskLevelChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => _buildFilterDropdown(
                              'Doctor',
                              [
                                'All Doctors',
                                ..._controller.doctors.map((d) => d.name),
                              ],
                              selectedValue: _doctorLabel,
                              onChanged: _onDoctorChanged,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _controller.hasActiveFilters
                                ? () => _controller.clearFilters()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  ColorConstants.surfaceContainerHigh,
                              foregroundColor: ColorConstants.primary,
                              disabledBackgroundColor:
                                  ColorConstants.surfaceContainer,
                              disabledForegroundColor: ColorConstants
                                  .onSurfaceVariant
                                  .withOpacity(0.4),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.filter_alt_off, size: 20),
                            label: Text(
                              'Clear',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              // Active-filter summary + result count (reactive)
              Obx(() {
                final total = _controller.filteredPatients.length;
                final activeFilters = _controller.hasActiveFilters;
                final search = _controller.searchQuery.value.trim();

                if (!activeFilters) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Showing all patients',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                final List<String> parts = [];
                if (search.isNotEmpty) parts.add('Search: "$search"');
                if (_controller.selectedTrimester.value != null) {
                  parts.add('Trimester ${_controller.selectedTrimester.value}');
                }
                if (_controller.selectedRiskLevel.value.isNotEmpty) {
                  parts.add('Risk: ${_controller.selectedRiskLevel.value}');
                }
                if (_controller.selectedDoctorId.value != null) {
                  final doc = _controller.doctors
                      .where((d) => d.id == _controller.selectedDoctorId.value)
                      .firstOrNull;
                  parts.add('Doctor: ${doc?.name ?? "Selected"}');
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Filters: ${parts.join(' • ')}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$total shown',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Patient',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorConstants.borderWhite10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.search,
                color: ColorConstants.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    _controller.updateSearch(value);
                    debugPrint('[PatientDashboard] Search input: "$value"');
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: ColorConstants.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID or phone...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: ColorConstants.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a dropdown filter with a label and list of string items.
  /// [selectedValue] is the currently selected item label (defaults to the
  /// first item when null/empty), and [onChanged] is called with the newly
  /// selected label.
  Widget _buildFilterDropdown(
    String label,
    List<String> items, {
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final currentValue =
        items.contains(selectedValue) && selectedValue.isNotEmpty
        ? selectedValue
        : items.first;

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
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ColorConstants.borderWhite10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onSurface,
              ),
              dropdownColor: ColorConstants.surfaceContainerHigh,
              isExpanded: true,
              items: items
                  .map(
                    (String item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Filter label helpers ───────────────────────────────────────────────
  String get _trimesterLabel {
    switch (_controller.selectedTrimester.value) {
      case 1:
        return '1st Trimester';
      case 2:
        return '2nd Trimester';
      case 3:
        return '3rd Trimester';
      default:
        return 'All Trimesters';
    }
  }

  String get _riskLevelLabel {
    final risk = _controller.selectedRiskLevel.value;
    return risk.isNotEmpty ? risk : 'Any Risk';
  }

  String get _doctorLabel {
    final doctorId = _controller.selectedDoctorId.value;
    if (doctorId == null) return 'All Doctors';
    final doctor = _controller.doctors
        .where((d) => d.id == doctorId)
        .firstOrNull;
    return doctor?.name ?? 'All Doctors';
  }

  void _onTrimesterChanged(String label) {
    switch (label) {
      case '1st Trimester':
        _controller.setTrimester(1);
      case '2nd Trimester':
        _controller.setTrimester(2);
      case '3rd Trimester':
        _controller.setTrimester(3);
      default:
        _controller.setTrimester(null);
    }
  }

  void _onRiskLevelChanged(String label) {
    if (label == 'Any Risk') {
      _controller.setRiskLevel('');
    } else {
      _controller.setRiskLevel(label);
    }
  }

  void _onDoctorChanged(String label) {
    if (label == 'All Doctors') {
      _controller.setDoctor(null);
    } else {
      final doctor = _controller.doctors.firstWhere(
        (d) => d.name == label,
        orElse: () => _controller.doctors.first,
      );
      _controller.setDoctor(doctor.id);
    }
  }

  Widget _buildPatientGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
        }

        return Obx(() {
          final filtered = _controller.filteredPatients;
          final hasSearch = _controller.searchQuery.value.trim().isNotEmpty;
          debugPrint(
            '[PatientDashboard] Grid — total=${_controller.patients.length} '
            'filtered=${filtered.length} search="$hasSearch"',
          );

          if (_controller.isLoading.value && _controller.patients.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error.value != null && _controller.patients.isEmpty) {
            return Center(
              child: Text(
                'Error: ${_controller.error.value}',
                style: GoogleFonts.plusJakartaSans(color: ColorConstants.error),
              ),
            );
          }

          if (filtered.isEmpty) {
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
                      hasSearch
                          ? 'No patients match your search.'
                          : 'No patients found.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                    ),
                    if (hasSearch) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Try a different name, ID, or phone number.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: ColorConstants.onSurfaceVariant.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.75,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildPatientCard(filtered[index]);
            },
          );
        });
      },
    );
  }

  Widget _buildPatientCard(Patient patient) {
    final bool isHighRisk = patient.riskLevel == RiskLevel.high;
    final Color riskColor = isHighRisk
        ? ColorConstants.error
        : ColorConstants.tertiary;
    final Color riskBgColor = isHighRisk
        ? ColorConstants.errorContainer.withOpacity(0.15)
        : ColorConstants.tertiaryContainer.withOpacity(0.15);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container(
              //   width: 56,
              //   height: 56,
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(
              //       color: ColorConstants.primary.withOpacity(0.2),
              //       width: 2,
              //     ),
              //     image: DecorationImage(
              //       image: NetworkImage(patient.profileImage ?? ''),
              //       fit: BoxFit.cover,
              //     ),
              //   ),
              // ),
              // const SizedBox(width: 16),
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
                    Text(
                      '#MH-${patient.id}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: riskBgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: riskColor.withOpacity(0.2)),
                ),
                child: Text(
                  isHighRisk ? 'High Risk' : 'Normal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstants.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ColorConstants.borderWhite5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pregnancy Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.05,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Wk ${patient.week}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: ColorConstants.primary,
                              ),
                            ),
                            TextSpan(
                              text: ' (${patient.trimester})',
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
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstants.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ColorConstants.borderWhite5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Doctor',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.05,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.doctor,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ColorConstants.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vitals
          Text(
            "Today's Vitals",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // View Details Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Get.toNamed(
                  RouteNames.patientDetail,
                  arguments: {'patientId': patient.id},
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: ColorConstants.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: ColorConstants.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Existing _buildPagination removed since we are using infinite scrolling
}

// Data Models removed, imported from model file instead.
