import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../controllers/doctor_list_controller.dart';
import '../models/doctor.dart';

class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen>
    with SingleTickerProviderStateMixin {
  // Used to reliably open/close the mobile drawer. Using a GlobalKey avoids
  // the Scaffold.of(context) context-hierarchy problem (the AppBar is built
  // with a context that is a *parent* of the returned Scaffold, so
  // Scaffold.of fails to find it).
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /// A single, persistent [TextEditingController] for the search field.
  ///
  /// IMPORTANT: This must be created ONCE and reused across rebuilds. Creating
  /// a new `TextEditingController` inside the `Obx`/build method — even with
  /// `text: controller.searchQuery.value` — resets the field on every keystroke,
  /// causing cursor jumps and reordered/duplicated characters. Keeping it as a
  /// State field preserves the exact text as typed.
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Seed the text controller with the current search query (typically empty).
    final controller = Get.find<DoctorListController>();
    _searchController = TextEditingController(
      text: controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? AppDrawer(
              currentRoute: RouteNames.doctors,
              onNavigate: (route) {
                _scaffoldKey.currentState?.closeDrawer(); // close drawer
                Get.toNamed(route);
              },
            )
          : null,
      body: DashboardBackground(
        child: Row(
          children: [
            // Desktop Sidebar
            if (!isMobile) _buildSidebar(colorScheme),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  _buildTopAppBar(colorScheme, isMobile),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSearchAndFilters(colorScheme),
                            const SizedBox(height: 24),
                            _buildDoctorContent(colorScheme),
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
      // floatingActionButton: _buildAddDoctorButton(colorScheme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Doctor Content (loading / error / empty / list) ───────────────────
  Widget _buildDoctorContent(ColorScheme colorScheme) {
    // Use the controller registered in InitialBinding.
    final controller = Get.find<DoctorListController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CircularProgressIndicator(color: ColorConstants.primary),
          ),
        );
      }

      if (controller.error.value != null) {
        return _buildErrorState(colorScheme, controller);
      }

      final filtered = controller.filteredDoctors;

      if (filtered.isEmpty) {
        // Differentiate "no doctors at all" from "no results match the active
        // search/filter".
        if (controller.doctors.isEmpty) {
          return _buildEmptyState(colorScheme, hasActiveFilters: false);
        }
        return _buildEmptyState(colorScheme, hasActiveFilters: true);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCount(colorScheme, controller),
          const SizedBox(height: 16),
          _buildDoctorGrid(colorScheme, filtered),
        ],
      );
    });
  }

  Widget _buildErrorState(
    ColorScheme colorScheme,
    DoctorListController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load doctors',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error.value ?? 'An error occurred.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.loadDoctors(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ColorScheme colorScheme, {
    required bool hasActiveFilters,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasActiveFilters ? Icons.search_off : Icons.person_search,
              size: 56,
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasActiveFilters ? 'No matching doctors' : 'No doctors found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilters
                  ? 'No doctors match your current search or filters.'
                  : 'Try adjusting your search or filters.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a summary line: "Showing X of Y doctors", reflecting the filtered
  /// results rather than the total dataset.
  Widget _buildResultCount(
    ColorScheme colorScheme,
    DoctorListController controller,
  ) {
    return Text(
      'Showing ${controller.filteredCount} of ${controller.doctors.length} '
      'doctors${_activeFilterSummary(controller)}',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Builds a short summary of the active search/filter for the count line.
  String _activeFilterSummary(DoctorListController controller) {
    final parts = <String>[];
    if (controller.searchQuery.value.isNotEmpty) {
      parts.add('matching "${controller.searchQuery.value}"');
    }
    if (controller.selectedSpecialization.value.isNotEmpty) {
      parts.add('in ${controller.selectedSpecialization.value}');
    }
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }

  Widget _buildSidebar(ColorScheme colorScheme) {
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
        color: colorScheme.surfaceContainerLow,
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
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Panel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Mama Health',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
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

  Widget _buildTopAppBar(ColorScheme colorScheme, bool isMobile) {
    return CustomAppBar(
      title: 'Doctor Management',
      showBackButton: isMobile,
      actions: [
        const NotificationBell(),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            color: colorScheme.surfaceContainerHigh,
          ),
          child: Icon(Icons.person, color: colorScheme.primary, size: 18),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ColorScheme colorScheme) {
    final controller = Get.find<DoctorListController>();

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.borderWhite10),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: controller.setSearchQuery,
                    controller: _searchController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name, ID or specialty...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (controller.searchQuery.value.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      // Clear both the reactive query AND the text field so the
                      // UI and state stay synchronized.
                      _searchController.clear();
                      controller.setSearchQuery('');
                    },
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    tooltip: 'Clear search',
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Filter Chips - FIXED ALIGNMENT
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'Filters:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _buildFilterChip(
                'All',
                controller.selectedSpecialization.value.isEmpty,
                colorScheme,
                onTap: () => controller.toggleSpecialization(''),
              ),
              ...controller.availableSpecializations.map(
                (spec) => _buildFilterChip(
                  spec,
                  controller.selectedSpecialization.value == spec,
                  colorScheme,
                  onTap: () => controller.toggleSpecialization(spec),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: IconButton(
                  onPressed: () => _showFilterMenu(controller, colorScheme),
                  icon: Icon(
                    Icons.filter_list,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  tooltip: 'All specializations',
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// Shows a dropdown menu of all available specializations (plus "All") so
  /// the user can select/deselect a filter even when the chips overflow.
  void _showFilterMenu(
    DoctorListController controller,
    ColorScheme colorScheme,
  ) {
    Get.bottomSheet(
      Container(
        color: ColorConstants.cardBackground,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by specialization',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...controller.availableSpecializations.map(
              (spec) => ListTile(
                title: Text(
                  spec,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                trailing: controller.selectedSpecialization.value == spec
                    ? Icon(Icons.check, color: colorScheme.primary)
                    : null,
                onTap: () {
                  Get.back();
                  controller.toggleSpecialization(spec);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    ColorScheme colorScheme, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: ColorConstants.borderWhite10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'Active')
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            if (label == 'Active') const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorGrid(ColorScheme colorScheme, List<Doctor> doctors) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet = MediaQuery.of(context).size.width < 900;

    int crossAxisCount = 4;
    if (isMobile)
      crossAxisCount = 1;
    else if (isTablet)
      crossAxisCount = 2;

    // Use a guaranteed minimum cell height (mainAxisExtent) instead of a
    // childAspectRatio. The ratio tied cell height to column width, which on
    // narrow handsets shrank the card and clipped the specialization /
    // toggle row (57px overflow). A responsive extent keeps the card tall
    // enough on every device size.
    final double mainAxisExtent = isMobile ? 258 : (isTablet ? 240 : 210);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: mainAxisExtent,
      ),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        return _buildDoctorCard(doctors[index], colorScheme);
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor, ColorScheme colorScheme) {
    final bool isPending = doctor.isPending ?? false;

    return GestureDetector(
      onTap: () async {
        debugPrint(
          '[DoctorDashboard] Navigating to doctor detail — id=${doctor.id}',
        );
        final listController = Get.find<DoctorListController>();
        await Get.toNamed(
          RouteNames.doctorDetail,
          arguments: {'doctorId': doctor.id},
        );
        // The details screen may have changed the doctor's status. Refresh the
        // list from the server so the dashboard always reflects the latest
        // state when the user returns.
        debugPrint(
          '[DoctorDashboard] Returning from doctor detail — refreshing list',
        );
        await listController.refreshFromServer();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorConstants.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.borderWhite10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image and actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(doctor, colorScheme, isPending),
                const Spacer(),
                Column(
                  children: [
                    if (isPending) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Pending Approval',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              doctor.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              doctor.specialization.isNotEmpty
                  ? doctor.specialization
                  : 'General',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.work_history,
                  size: 16,
                  color: Colors.white.withOpacity(0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    doctor.experience.isNotEmpty
                        ? doctor.experience
                        : '${doctor.yearsOfExperience} years',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 12),
            if (isPending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ColorConstants.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Review Application',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Active Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildToggleSwitch(
                        doctor,
                        colorScheme,
                        Get.find<DoctorListController>(),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Doctor doctor, ColorScheme colorScheme, bool isPending) {
    final initials = doctor.name.isNotEmpty
        ? doctor.name
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0])
              .join()
              .toUpperCase()
        : '?';

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        color: Colors.white.withOpacity(0.15),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        splashRadius: 16,
      ),
    );
  }

  Widget _buildToggleSwitch(
    Doctor doctor,
    ColorScheme colorScheme,
    DoctorListController controller,
  ) {
    return GestureDetector(
      onTap: () {
        _confirmToggleActive(doctor, controller);
      },
      child: Container(
        width: 40,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: doctor.isActive
              ? Colors.white
              : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          alignment: doctor.isActive
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: doctor.isActive
                  ? ColorConstants.primary
                  : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before changing a doctor's active status,
  /// then calls [DoctorListController.toggleActive].
  void _confirmToggleActive(Doctor doctor, DoctorListController controller) {
    final bool newState = !doctor.isActive;
    final String action = newState ? 'activate' : 'deactivate';

    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${newState ? 'Activate' : 'Deactivate'} Doctor',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to $action ${doctor.name}? '
          '${newState ? 'They will regain access to the platform.' : 'They will no longer be able to access the platform, but their history is preserved.'}',
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
            onPressed: () {
              Get.back();
              debugPrint(
                '[DoctorDashboard] Confirm toggle — id=${doctor.id} '
                'isActive=$newState',
              );
              controller.toggleActive(doctor.id, newState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newState
                  ? ColorConstants.success
                  : ColorConstants.error,
              foregroundColor: newState
                  ? ColorConstants.background
                  : ColorConstants.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              newState ? 'Activate' : 'Deactivate',
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

  // Widget _buildAddDoctorButton(ColorScheme colorScheme) {
  //   return FloatingActionButton.extended(
  //     onPressed: () {
  //       Get.toNamed(RouteNames.doctorForm);
  //     },
  //     backgroundColor: colorScheme.primaryContainer,
  //     foregroundColor: colorScheme.onPrimaryContainer,
  //     icon: const Icon(Icons.add, size: 24),
  //     label: Text(
  //       'Add Doctor',
  //       style: GoogleFonts.plusJakartaSans(
  //         fontSize: 14,
  //         fontWeight: FontWeight.w700,
  //       ),
  //     ),
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //   );
  // }
}
