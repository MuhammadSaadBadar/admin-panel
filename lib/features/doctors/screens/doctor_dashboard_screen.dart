import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/route_names.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../models/doctor.dart';

class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Doctor data
  final List<Doctor> _doctors = [
    Doctor(
      id: 1,
      name: 'Dr. Sana Khan',
      email: 'sana.khan@example.com',
      phone: '+1 555-0199',
      specialization: 'Gynaecologist',
      experience: '10 Years Experience',
      profileImage:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB-xx3wTD94ErlNvjqcA2C6tG0VGz1jTcymaSv2gZLV6U9r9GghNnrxRwKKmhNyXHveMuY0Hyb54_xAS8Mbt2-ZE5EMJgfMR9ts5R3pDssRiTFBSngeGseJyAw5TRXXNsnCDLSkGNwqxIfKH3fLkbC-mVJV8IPoVpTejqQcW0SwwmPYyPdKgOUrJLK-gsUdbL4aR587FFBILxI9OZ4RwiXcyGH0Znpij-i-NWnPjL4wSE8ZtzogaFr2',
      isActive: true,
      specialtyColor: Colors.pink,
    ),
    Doctor(
      id: 2,
      name: 'Dr. Arjun Mehta',
      email: 'arjun.mehta@example.com',
      phone: '+1 555-0200',
      specialization: 'Pediatrician',
      experience: '8 Years Experience',
      profileImage:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBorhh-b7ZkExMO4CkCmhoxcqxQxTd6kjtrOV4ADbk8E6cdJmKtPkMH8V7ilstQTBMBus6YMwlGfFCgJnByw-h1KH2F3c6DVooyCBYaWUihCQnrvoD2nPxlx_OBuewqxVqtGzu8dfayI1893ndnDXVtQLgFDNHSlM7f74hL-xG1TB4u BLE81AUTlW0ySvp4Tf2NUC4wliiaoz1wbT0IJrVBu3tzt1UFhpTI03wE9L3DXVVqsPg1dt3Z',
      isActive: false,
      specialtyColor: Colors.teal,
    ),
    Doctor(
      id: 3,
      name: 'Dr. Elena Vance',
      email: 'elena.vance@example.com',
      phone: '+1 555-0201',
      specialization: 'Gynaecologist',
      experience: '15 Years Experience',
      profileImage:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB0wyBVCbGGfqQrdXgr5wLqfQNoXEf9MYqfe8gsPcQChBK31KQISdFMXRyg9XWwCQy_2Osrl02qmYzA4Jl6zLBvaH8BfXkSr6eL-UYfTgFjCmkkrNQw6uGTgziLfObqJI_56AdVLYWY7HPq8JiFKSOqb1Rv0i4n-9EyUagxhqcPUAfYv6bjElx4qOALXdCnCjDcFO0J1cmOOsxN4D4wifmAa5h6YOPa7oj2_LwT2F9nzRJ4lv5WO7qb',
      isActive: true,
      specialtyColor: Colors.pink,
    ),
    Doctor(
      id: 4,
      name: 'Dr. Kevin Hart',
      email: 'kevin.hart@example.com',
      phone: '+1 555-0202',
      specialization: 'Pediatrician',
      experience: '3 Years Experience',
      profileImage:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDfCnSXVeDZeRPp8C42LRdNS-XFNIyllGxnqKJOxcpSFa3A4XTkqA8vMzKxEJtq46PXgHwO0D9f3HIkLb3Qs8njMgp-kSCFY4f3tt5yXd25rCDDeogn-7CcP_JfROHIFaIoUZBeJ63w1_8-QkbwYYCOiKgRRO62kX2v3ELKKHU569QJ3NLcTwSdW5z-ac2Y_mZHlfVydfUSFHKp44QdLw8NXmSLMsL9b56-RQhjwceBt6QdMqXzvPKJ',
      isActive: false,
      specialtyColor: Colors.teal,
      isPending: true,
    ),
    Doctor(
      id: 5,
      name: 'Dr. Sarah Jenkins',
      email: 'sarah.jenkins@example.com',
      phone: '+1 555-0203',
      specialization: 'Pediatrician',
      experience: '12 Years Experience',
      profileImage:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD9DY6CqVRDyyqpqv4nBfs0GC20NS_9RnHTDefBLqMa0lc47PAWx8r8cRaoy3-Tol72AJx4RpR4ZHrc842lXHEuVNfyBjDG-g6nvr1qyWnj25ZtwdKBEyW8aj_fHuXvRJCXP8-mr94U7vLxfbaQV_DlscZXpKOdOqBJUh0P3Gc8UCwmpqQ-tFVaFKgadAffsUveme817tT8B5NNWA1oCOhRvu5-ekOjyDuj8nY8cWPvhlh3hVr5H69m',
      isActive: true,
      specialtyColor: Colors.teal,
    ),
  ];

  String _searchQuery = '';
  String _selectedFilter = 'All';

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

  List<Doctor> get _filteredDoctors {
    var filtered = _doctors;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (doctor) =>
                doctor.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                doctor.specialization.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                doctor.id.toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply specialty filter
    if (_selectedFilter != 'All') {
      filtered = filtered
          .where((doctor) => doctor.specialization == _selectedFilter)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: Row(
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
                          _buildDoctorGrid(colorScheme),
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
      floatingActionButton: _buildAddDoctorButton(colorScheme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications, color: colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            image: const DecorationImage(
              image: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAWigYIPM6fob0PD0Ik78ijq-h-NQY5hCqVAVWbtHgS4Juv8FqO8yQrAFAEotP0jUj7qKr6dghsCcB1ngSbSkZTyXyUgLACUZ_dMWQVei5pj1zxqkyhcz5L_jLio0k_0qgyg_Aq9tgaIsOSSVo_C-YQQLu56zxoYPedKe2dHbRhPNwoVcWXgqD8a7gia2AA-XHa-Zqq-xeZs1U_u_S9-Dv6bmnrkFJGtPjU49NF-gQfOXNvnH6cnys_',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Filter Chips - FIXED ALIGNMENT
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start, // Added this for proper alignment
          crossAxisAlignment: WrapCrossAlignment.center, // Added this
          children: [
            // "Filters:" label - moved to separate container
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
            _buildFilterChip('All', _selectedFilter == 'All', colorScheme),
            _buildFilterChip(
              'Gynaecologist',
              _selectedFilter == 'Gynaecologist',
              colorScheme,
            ),
            _buildFilterChip(
              'Pediatrician',
              _selectedFilter == 'Pediatrician',
              colorScheme,
            ),
            // Filter icon button - wrapped in a container for proper alignment
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: IconButton(
                onPressed: () {},
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
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withOpacity(0.1)),
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

  Widget _buildDoctorGrid(ColorScheme colorScheme) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet = MediaQuery.of(context).size.width < 900;

    int crossAxisCount = 4;
    if (isMobile)
      crossAxisCount = 1;
    else if (isTablet)
      crossAxisCount = 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.7,
      ),
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) {
        return _buildDoctorCard(_filteredDoctors[index], colorScheme);
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor, ColorScheme colorScheme) {
    final bool isPending = doctor.isPending ?? false;
    final Color specialtyColor = doctor.specialtyColor;

    return GestureDetector(
      onTap: () {
        Get.toNamed(RouteNames.doctorDetail);
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image and actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    color: isPending
                        ? colorScheme.surfaceContainerHighest
                        : Colors.transparent,
                    image: DecorationImage(
                      image: NetworkImage(doctor.profileImage ?? ''),
                      fit: BoxFit.cover,
                      colorFilter: isPending
                          ? const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            )
                          : null,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  children: [
                    Row(
                      children: [
                        _buildIconButton(Icons.visibility, colorScheme),
                        const SizedBox(width: 4),
                        _buildIconButton(Icons.edit, colorScheme),
                      ],
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Pending Approval',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
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
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              doctor.specialization,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: specialtyColor == Colors.pink
                    ? colorScheme.primary
                    : colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.work_history,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  doctor.experience,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 12),
            if (isPending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
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
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildToggleSwitch(doctor.isActive, colorScheme),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.block,
                      color: colorScheme.error.withOpacity(0.6),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),
          ],
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

  Widget _buildToggleSwitch(bool isActive, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // Find the doctor and toggle status
          // For demo purposes, we'll just show a visual change
        });
      },
      child: Container(
        width: 40,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : colorScheme.onSurfaceVariant.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddDoctorButton(ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: () {
        Get.toNamed(RouteNames.doctorForm);
      },
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      icon: const Icon(Icons.add, size: 24),
      label: Text(
        'Add Doctor',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// Data Model removed, imported from model file instead.
