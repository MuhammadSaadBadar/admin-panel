import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/route_names.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/custom_appbar.dart';

class AddEditDoctorScreen extends StatefulWidget {
  const AddEditDoctorScreen({super.key});

  @override
  State<AddEditDoctorScreen> createState() => _AddEditDoctorScreenState();
}

class _AddEditDoctorScreenState extends State<AddEditDoctorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _languagesController = TextEditingController();

  String _selectedSpecialization = 'Obstetrics & Gynecology';
  String _selectedStartTime = '09:00';
  String _selectedEndTime = '17:00';
  final List<String> _workingDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final List<String> _selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _hospitalController.dispose();
    _languagesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
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
              'Add New Doctor',
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
          'Doctor Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        Text(
          'Configure professional details for the clinical staff.',
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
    return Column(
      children: [
        // Profile Photo Upload
        _buildPhotoUpload(),
        const SizedBox(height: 24),
        // Basic Information
        _buildBasicInfo(),
        const SizedBox(height: 24),
        // Professional Credentials
        _buildCredentials(),
        const SizedBox(height: 24),
        // Availability & Languages
        _buildAvailability(),
        const SizedBox(height: 24),
        // Form Actions
        _buildFormActions(),
      ],
    );
  }

  Widget _buildPhotoUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        children: [
          // Photo upload area
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorConstants.onSurfaceVariant,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  color: ColorConstants.surfaceContainer,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        color: ColorConstants.borderWhite10,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit,
                    color: ColorConstants.onPrimaryContainer,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Upload Photo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ColorConstants.onSurface,
            ),
          ),
          Text(
            'Recommended size: 500x500px',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
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
          Text(
            'Core Information',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ColorConstants.primary,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: ColorConstants.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          // Full Name
          _buildFormField(
            label: 'Full Name',
            controller: _nameController,
            hintText: 'Dr. Sarah Mitchell',
          ),
          const SizedBox(height: 12),
          // Email
          _buildFormField(
            label: 'Email Address',
            controller: _emailController,
            hintText: 'sarah.m@mamahealth.pro',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          // Phone
          _buildFormField(
            label: 'Phone Number',
            controller: _phoneController,
            hintText: '+1 (555) 000-0000',
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildCredentials() {
    final List<String> specializations = [
      'Obstetrics & Gynecology',
      'Pediatrics',
      'General Practice',
      'Internal Medicine',
      'Cardiology',
    ];

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
          Text(
            'Credentials',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ColorConstants.primary,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: ColorConstants.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          // Specialization Dropdown
          Column(
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
                  border: Border.all(color: ColorConstants.borderWhite10),
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
                    items: specializations.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSpecialization = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Qualification
          _buildFormField(
            label: 'Qualification',
            controller: _qualificationController,
            hintText: 'MBBS, MD - Gynaecology',
          ),
          const SizedBox(height: 12),
          // Experience & Fee
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Experience (Years)',
                  controller: _experienceController,
                  hintText: '10',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  label: 'Consultation Fee',
                  controller: _feeController,
                  hintText: '\$150',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Hospital
          _buildFormField(
            label: 'Hospital / Clinic Name',
            controller: _hospitalController,
            hintText: 'Mama Health Central Clinic',
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability() {
    final List<String> allDays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

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
          Text(
            'Availability',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ColorConstants.primary,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: ColorConstants.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          // Working Days
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Working Days',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorConstants.secondaryContainer
                            : ColorConstants.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? ColorConstants.primary
                              : ColorConstants.borderWhite10,
                        ),
                      ),
                      child: Text(
                        day,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? ColorConstants.onSecondaryContainer
                              : ColorConstants.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Start & End Time
          Row(
            children: [
              Expanded(
                child: _buildTimePicker('Start Time', _selectedStartTime, (
                  time,
                ) {
                  setState(() {
                    _selectedStartTime = time;
                  });
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePicker('End Time', _selectedEndTime, (time) {
                  setState(() {
                    _selectedEndTime = time;
                  });
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Languages
          _buildFormField(
            label: 'Languages Spoken',
            controller: _languagesController,
            hintText: 'English, Spanish, French',
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    String initialTime,
    Function(String) onTimeSelected,
  ) {
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
        GestureDetector(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.parse(initialTime.split(':')[0]),
                minute: int.parse(initialTime.split(':')[1]),
              ),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFFFFB1C5),
                      onPrimary: Color(0xFF65002F),
                      surface: Color(0xFF1E1E1E),
                      onSurface: Color(0xFFE5E2E1),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final String formattedTime =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              onTimeSelected(formattedTime);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: ColorConstants.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorConstants.borderWhite10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: ColorConstants.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  initialTime,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
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
            border: Border.all(color: ColorConstants.borderWhite10),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
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
      ],
    );
  }

  Widget _buildFormActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Show success dialog
              _showSuccessDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryContainer,
              foregroundColor: ColorConstants.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: ColorConstants.primaryContainer.withOpacity(0.3),
            ),
            child: Text(
              'Save Doctor Profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
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
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ColorConstants.borderWhite10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        title: Column(
          children: [
            Icon(Icons.check_circle, color: ColorConstants.tertiary, size: 48),
            const SizedBox(height: 12),
            Text(
              'Saved Successfully!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ColorConstants.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Doctor profile has been saved successfully.',
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
