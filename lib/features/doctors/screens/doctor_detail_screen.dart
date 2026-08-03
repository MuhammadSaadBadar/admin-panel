import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/route_names.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/custom_appbar.dart';

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({super.key});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
        child: Column(
          children: [
            Expanded(
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Column(
                                    children: [
                                      _buildHeroProfile(),
                                      const SizedBox(height: 24),
                                      _buildSecondaryInfoGrid(isMobile),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action Bar
            _buildActionBar(isMobile),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }

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
            color: ColorConstants.onSurfaceVariant,
            size: isMobile ? 20 : 24,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroProfile() {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Column(
        children: [
          // Profile Image - centered
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
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
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.primary.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorConstants.surfaceContainerHigh,
                    width: 3,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBSLM_gvz7yTBfM4ixeqOqNt6yfbXGtEdGExAeZm6xbbaBcZNXLcweK_5iqm0qIr3AIynrTXuQeGnxIzflvzNLGQ5k4JMHDpeknr2st_gF_yU_JXMIFFn7kgkcKKBrhB57BewOztf6Vla89m3yItzkRSnNuAD64j6ghLZ5gGPnaX2gQS_4scVcCltH7GZjHLTYR-x5XfrMhdFbWV0z9_C2stbROgE3w2emtFx33PPG4wvwN78k1XgOz',
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
                    color: Colors.green.shade500,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorConstants.background,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dr. Sarah Jenkins',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ColorConstants.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Senior Gynecologist & Obstetrician',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.green.shade500.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade400,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ColorConstants.borderWhite5),
                ),
                child: Text(
                  'ID: MH-9021',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info Cards - Stacked vertically on mobile
          _buildInfoCard(
            icon: Icons.school,
            iconColor: ColorConstants.primary,
            iconBgColor: ColorConstants.primaryContainer.withOpacity(0.2),
            title: 'Qualification',
            subtitle: 'MBBS, MD - Obstetrics & Gynecology',
            description: 'Johns Hopkins School of Medicine',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.work_history,
            iconColor: ColorConstants.tertiary,
            iconBgColor: ColorConstants.tertiaryContainer.withOpacity(0.2),
            title: 'Experience',
            subtitle: '12+ Years Clinical Practice',
            description: 'Specialized in High-Risk Pregnancy',
          ),
        ],
      );
    }

    // Desktop layout
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Image Section
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 192,
                    height: 192,
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
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.primary.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 192,
                    height: 192,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorConstants.surfaceContainerHigh,
                        width: 4,
                      ),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBSLM_gvz7yTBfM4ixeqOqNt6yfbXGtEdGExAeZm6xbbaBcZNXLcweK_5iqm0qIr3AIynrTXuQeGnxIzflvzNLGQ5k4JMHDpeknr2st_gF_yU_JXMIFFn7kgkcKKBrhB57BewOztf6Vla89m3yItzkRSnNuAD64j6ghLZ5gGPnaX2gQS_4scVcCltH7GZjHLTYR-x5XfrMhdFbWV0z9_C2stbROgE3w2emtFx33PPG4wvwN78k1XgOz',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorConstants.background,
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Dr. Sarah Jenkins',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Senior Gynecologist & Obstetrician',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: ColorConstants.primary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.green.shade500.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade400,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: ColorConstants.borderWhite5),
                    ),
                    child: Text(
                      'ID: MH-9021',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 8,
          child: Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.school,
                  iconColor: ColorConstants.primary,
                  iconBgColor: ColorConstants.primaryContainer.withOpacity(0.2),
                  title: 'Qualification',
                  subtitle: 'MBBS, MD - Obstetrics & Gynecology',
                  description: 'Johns Hopkins School of Medicine',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.work_history,
                  iconColor: ColorConstants.tertiary,
                  iconBgColor: ColorConstants.tertiaryContainer.withOpacity(
                    0.2,
                  ),
                  title: 'Experience',
                  subtitle: '12+ Years Clinical Practice',
                  description: 'Specialized in High-Risk Pregnancy',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String description,
  }) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: isMobile ? 20 : 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w500,
              color: ColorConstants.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryInfoGrid(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          // Patient Summary Card
          Container(
            padding: const EdgeInsets.all(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assigned Patients',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                    ),
                    Icon(Icons.groups, color: ColorConstants.primary, size: 24),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '142',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+12% from last month',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.arrow_forward,
                    color: ColorConstants.primary,
                    size: 16,
                  ),
                  label: Text(
                    'View All Patient Records',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Weekly Availability Card
          Container(
            padding: const EdgeInsets.all(20),
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
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: ColorConstants.tertiary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Weekly Availability',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onSurface,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorConstants.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: BorderSide(color: ColorConstants.borderWhite10),
                      ),
                      child: Text(
                        'Update',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDaySchedule('MON', '09:00 - 17:00'),
                      _buildDaySchedule('TUE', '09:00 - 17:00'),
                      _buildDaySchedule('WED', '09:00 - 17:00'),
                      _buildDaySchedule('THU', '09:00 - 17:00'),
                      _buildDaySchedule('FRI', '09:00 - 13:00'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Upcoming Appointments
          Container(
            padding: const EdgeInsets.all(20),
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
                    Row(
                      children: [
                        Icon(
                          Icons.event_note,
                          color: ColorConstants.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Upcoming Appointments',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorConstants.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ColorConstants.borderWhite5),
                      ),
                      child: Icon(
                        Icons.filter_list,
                        color: ColorConstants.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 88,
                    ),
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowHeight: 40,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 70,
                      headingRowColor: WidgetStateProperty.all(
                        ColorConstants.surfaceContainerLow,
                      ),
                      headingTextStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                      dataTextStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: ColorConstants.onSurface,
                      ),
                      columns: const [
                        DataColumn(label: Text('Patient')),
                        DataColumn(label: Text('Date & Time')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text(''), numeric: true),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: ColorConstants.secondary
                                          .withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'EM',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: ColorConstants.secondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Elena M.',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Today, Oct 24'),
                                  Text(
                                    '14:30 PM',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ColorConstants.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorConstants.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: ColorConstants.borderWhite5,
                                  ),
                                ),
                                child: Text(
                                  'In-Person',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: ColorConstants.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Confirmed',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: ColorConstants.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Icon(
                                Icons.more_vert,
                                color: ColorConstants.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: ColorConstants.primary.withOpacity(
                                        0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'JW',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: ColorConstants.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Jessica W.',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Tomorrow'),
                                  Text(
                                    '10:00 AM',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ColorConstants.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorConstants.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: ColorConstants.borderWhite5,
                                  ),
                                ),
                                child: Text(
                                  'Telehealth',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: ColorConstants.borderWhite10,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pending',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: ColorConstants.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Icon(
                                Icons.more_vert,
                                color: ColorConstants.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
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
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Summary Card
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ColorConstants.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: ColorConstants.primary, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Assigned Patients',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.05,
                                color: ColorConstants.onSurfaceVariant,
                              ),
                            ),
                            Icon(
                              Icons.groups,
                              color: ColorConstants.primary,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '142',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: ColorConstants.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+12% from last month',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(
                        Icons.arrow_forward,
                        color: ColorConstants.primary,
                        size: 16,
                      ),
                      label: Text(
                        'View All Patient Records',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ColorConstants.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Weekly Availability Card
            Expanded(
              flex: 7,
              child: Container(
                padding: const EdgeInsets.all(24),
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
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: ColorConstants.tertiary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Weekly Availability',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.onSurface,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorConstants.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: BorderSide(
                              color: ColorConstants.borderWhite10,
                            ),
                          ),
                          child: Text(
                            'Update Hours',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildDaySchedule('MON', '09:00 - 17:00'),
                        _buildDaySchedule('TUE', '09:00 - 17:00'),
                        _buildDaySchedule('WED', '09:00 - 17:00'),
                        _buildDaySchedule('THU', '09:00 - 17:00'),
                        _buildDaySchedule('FRI', '09:00 - 13:00'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Upcoming Appointments
        Container(
          padding: const EdgeInsets.all(24),
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
                  Row(
                    children: [
                      Icon(
                        Icons.event_note,
                        color: ColorConstants.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Upcoming Appointments',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorConstants.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ColorConstants.borderWhite5),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: ColorConstants.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 32,
                  headingRowColor: WidgetStateProperty.all(
                    ColorConstants.surfaceContainerLow,
                  ),
                  headingTextStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                  dataTextStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onSurface,
                  ),
                  columns: const [
                    DataColumn(label: Text('Patient Name')),
                    DataColumn(label: Text('Date & Time')),
                    DataColumn(label: Text('Consultation Type')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Action'), numeric: true),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: ColorConstants.secondary.withOpacity(
                                    0.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    'EM',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: ColorConstants.secondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Elena Martinez'),
                            ],
                          ),
                        ),
                        const DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Today, Oct 24'),
                              Text(
                                '14:30 PM',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorConstants.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ColorConstants.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: ColorConstants.borderWhite5,
                              ),
                            ),
                            child: Text(
                              'In-Person',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: ColorConstants.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Confirmed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: ColorConstants.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Icon(
                            Icons.more_vert,
                            color: ColorConstants.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: ColorConstants.primary.withOpacity(
                                    0.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    'JW',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: ColorConstants.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Jessica Wright'),
                            ],
                          ),
                        ),
                        const DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tomorrow, Oct 25'),
                              Text(
                                '10:00 AM',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorConstants.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ColorConstants.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: ColorConstants.borderWhite5,
                              ),
                            ),
                            child: Text(
                              'Telehealth',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: ColorConstants.borderWhite10,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pending',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: ColorConstants.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Icon(
                            Icons.more_vert,
                            color: ColorConstants.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaySchedule(String day, String time) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: isMobile ? 80 : null,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstants.borderWhite5),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: ColorConstants.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerHigh.withOpacity(0.9),
        border: Border(top: BorderSide(color: ColorConstants.borderWhite10)),
      ),
      child: isMobile
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primary,
                          foregroundColor: ColorConstants.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConstants.error,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: ColorConstants.error),
                        ),
                        icon: const Icon(Icons.block, size: 16),
                        label: Text(
                          'Disable',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: ColorConstants.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ColorConstants.error.withOpacity(0.5),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.delete,
                          color: ColorConstants.error,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Last modified by Admin on Oct 20, 2023',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Last modified by Admin on Oct 20, 2023',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: ColorConstants.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primary,
                            foregroundColor: ColorConstants.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.edit, size: 16),
                          label: Text(
                            'Edit Profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorConstants.error,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: ColorConstants.error),
                          ),
                          icon: const Icon(Icons.block, size: 16),
                          label: Text(
                            'Disable',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: ColorConstants.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ColorConstants.error.withOpacity(0.5),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.delete,
                            color: ColorConstants.error,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
