import 'package:admin/core/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../controllers/profile_controller.dart';
import '../models/admin_profile.dart';

/// Admin Profile screen — displays the current admin's profile fetched from
/// `GET /auth/me/` and allows editing contact fields via `PATCH /auth/me/`.
///
/// Follows the app's responsive layout (desktop sidebar + mobile bottom nav),
/// the shared [CustomAppBar], and the reactive [ProfileController] pattern.
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late final ProfileController _controller;

  // Edit-form controllers (populated from the loaded profile on first render).
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[AdminProfileScreen] initState');
    _controller = Get.find<ProfileController>();
    _controller.resetSaveState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _controller.loadProfile();

    // Populate the edit form with the freshly loaded profile.
    final profile = _controller.profile.value;
    if (profile != null) {
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _phoneController.text = profile.phoneNumber;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startEditing() {
    final profile = _controller.profile.value;
    if (profile != null) {
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _phoneController.text = profile.phoneNumber;
    }
    _controller.resetSaveState();
    setState(() => _isEditing = true);
  }

  Future<void> _saveChanges() async {
    debugPrint('[AdminProfileScreen] _saveChanges — saving profile');
    final ok = await _controller.saveProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );
    if (ok) {
      setState(() => _isEditing = false);
      Get.snackbar(
        'Profile Updated',
        'Your profile has been updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: ColorConstants.primary,
        colorText: ColorConstants.onPrimary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      // Shared navigation drawer on mobile (hamburger + swipe-to-open).
      drawer: isMobile
          ? AppDrawer(
              currentRoute: RouteNames.profile,
              onNavigate: (route) {
                Navigator.of(context).pop(); // close drawer
                if (route != RouteNames.profile) {
                  Get.toNamed(route);
                }
              },
            )
          : null,
      body: DashboardBackground(
        child: SafeArea(
          child: Row(
            children: [
              if (!isMobile) _buildSidebar(colorScheme),
              Expanded(
                child: Column(
                  children: [
                    _buildTopAppBar(colorScheme, isMobile),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Obx(() {
                          if (_controller.isLoading.value) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: CircularProgressIndicator(
                                  color: ColorConstants.primary,
                                ),
                              ),
                            );
                          }

                          if (_controller.error.value != null) {
                            return _buildErrorState(colorScheme);
                          }

                          final profile = _controller.profile.value;
                          if (profile == null) {
                            return _buildEmptyState(colorScheme);
                          }

                          return _buildProfileContent(profile, colorScheme);
                        }),
                      ),
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

  // ── Content ────────────────────────────────────────────────────────────
  Widget _buildProfileContent(AdminProfile profile, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: MediaQuery.of(context).size.width >= 1024
                          ? 32
                          : 24,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your personal information and account.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: ColorConstants.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isEditing) _buildEditButton(colorScheme),
          ],
        ),
        const SizedBox(height: 24),

        // Profile content
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildProfileCard(profile, colorScheme),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: _buildAccountCard(profile, colorScheme),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _buildProfileCard(profile, colorScheme),
                const SizedBox(height: 10),
                _buildAccountCard(profile, colorScheme),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Profile Card ───────────────────────────────────────────────────────
  Widget _buildProfileCard(AdminProfile profile, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorConstants.primary, // Changed to primary
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.onPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(profile, colorScheme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: ColorConstants.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isEditing)
            _buildEditForm(colorScheme)
          else
            _buildInfoGrid(profile, colorScheme),
        ],
      ),
    );
  }

  Widget _buildAvatar(AdminProfile profile, ColorScheme colorScheme) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorConstants.onPrimary.withOpacity(0.15),
        border: Border.all(color: ColorConstants.onPrimary.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          profile.initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid(AdminProfile profile, ColorScheme colorScheme) {
    final bool isNarrow = MediaQuery.of(context).size.width < 600;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isNarrow ? 1 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        // Use a guaranteed item height (mainAxisExtent) instead of a ratio so
        // each info tile (label + value) has enough room on narrow Android
        // screens — the fixed 8:1 ratio shrank tile height with column width,
        // causing a 15px bottom overflow on the value.
        mainAxisExtent: 76,
      ),
      children: [
        _buildInfoItem('Full Name', profile.fullName, colorScheme),
        _buildInfoItem(
          'Role',
          profile.role.toUpperCase(),
          colorScheme,
          isChip: true,
        ),
        _buildInfoItem(
          'Email Address',
          profile.email,
          colorScheme,
          isMono: true,
        ),
        _buildInfoItem(
          'Phone Number',
          profile.phoneNumber.isNotEmpty ? profile.phoneNumber : '—',
          colorScheme,
          isMono: true,
        ),
        _buildInfoItem(
          'Email Verified',
          profile.isEmailVerified ? 'Verified' : 'Not Verified',
          colorScheme,
          isStatus: true,
          isVerified: profile.isEmailVerified,
        ),
        _buildInfoItem(
          'Member Since',
          _formatDate(profile.dateJoined),
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool isChip = false,
    bool isMono = false,
    bool isStatus = false,
    bool isVerified = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.primary, // Container with primary color
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstants.onPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorConstants.onPrimary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          if (isStatus)
            Row(
              children: [
                Icon(
                  isVerified ? Icons.check_circle : Icons.error_outline,
                  color: isVerified
                      ? ColorConstants.success
                      : ColorConstants.onPrimary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isVerified
                        ? ColorConstants.success
                        : ColorConstants.onPrimary,
                  ),
                ),
              ],
            )
          else if (isChip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConstants.onPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: ColorConstants.onPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: ColorConstants.onPrimary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onPrimary,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMono ? 14 : 16,
                fontWeight: isMono ? FontWeight.w500 : FontWeight.w400,
                color: ColorConstants.onPrimary,
                letterSpacing: isMono ? 0.4 : 0,
              ),
            ),
        ],
      ),
    );
  }

  // ── Edit Form ──────────────────────────────────────────────────────────
  Widget _buildEditForm(ColorScheme colorScheme) {
    final bool isNarrow = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isNarrow ? 1 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            // Guaranteed height so the label + text field fit on small screens.
            mainAxisExtent: 86,
          ),
          children: [
            _buildEditField('First Name', _firstNameController, colorScheme),
            _buildEditField('Last Name', _lastNameController, colorScheme),
            _buildEditField(
              'Phone Number',
              _phoneController,
              colorScheme,
              isMono: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Save error (if any)
        Obx(() {
          if (_controller.saveError.value != null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ColorConstants.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _controller.saveError.value!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: ColorConstants.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: ColorConstants.onPrimary.withOpacity(0.2)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onPrimary.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => ElevatedButton(
                  onPressed: _controller.isSaving.value ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ColorConstants.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _controller.isSaving.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorConstants.primary,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.primary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    ColorScheme colorScheme, {
    bool isMono = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorConstants.onPrimary.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ColorConstants.onPrimary.withOpacity(0.2),
            ),
            color: ColorConstants.onPrimary.withOpacity(0.1),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMono ? 14 : 16,
              fontWeight: isMono ? FontWeight.w500 : FontWeight.w400,
              color: ColorConstants.onPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: ColorConstants.onPrimary.withOpacity(0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Account / Security Card ────────────────────────────────────────────
  Widget _buildAccountCard(AdminProfile profile, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.primary, // Changed to primary
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.onPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: ColorConstants.onPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAccountItem(
            icon: Icons.admin_panel_settings,
            label: 'Role',
            value: profile.role.toUpperCase(),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          _buildAccountItem(
            icon: Icons.email,
            label: 'Account ID',
            value: '#${profile.id}',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: ColorConstants.onPrimary.withOpacity(0.2)),
          const SizedBox(height: 16),
          // Change Password action
          GestureDetector(
            onTap: () {
              debugPrint('[AdminProfileScreen] Navigating to change password');
              Get.toNamed(RouteNames.profileChangePassword);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ColorConstants.onPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ColorConstants.onPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_reset,
                    color: ColorConstants.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Change Password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.onPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: ColorConstants.onPrimary.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(icon, color: ColorConstants.onPrimary.withOpacity(0.7), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: ColorConstants.onPrimary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header / Sidebar / Error / Empty / Buttons ─────────────────────────
  Widget _buildEditButton(ColorScheme colorScheme) {
    return TextButton.icon(
      onPressed: _startEditing,
      icon: Icon(Icons.edit, color: ColorConstants.primary, size: 16),
      label: Text(
        'Edit Profile',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ColorConstants.primary,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: ColorConstants.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: ColorConstants.primary.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildTopAppBar(ColorScheme colorScheme, bool isMobile) {
    return CustomAppBar(title: 'Admin Profile', showBackButton: isMobile);
  }

  Widget _buildSidebar(ColorScheme colorScheme) {
    final List<Map<String, dynamic>> navItems = [
      {
        'icon': Icons.dashboard,
        'label': 'Dashboard',
        'route': RouteNames.dashboard,
      },
      {
        'icon': Icons.medical_services,
        'label': 'Doctor Management',
        'route': RouteNames.doctors,
      },
      {
        'icon': Icons.person,
        'label': 'Patient Management',
        'route': RouteNames.patients,
      },
      {
        'icon': Icons.event,
        'label': 'Appointments',
        'route': RouteNames.appointments,
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'route': RouteNames.settings,
      },
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: ColorConstants.primary,
        border: Border(
          right: BorderSide(color: ColorConstants.onPrimary.withOpacity(0.2)),
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
                    color: ColorConstants.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildAvatar(
                      _controller.profile.value ??
                          const AdminProfile(
                            id: 0,
                            email: '',
                            role: 'admin',
                            firstName: 'A',
                            lastName: '',
                            phoneNumber: '',
                            isEmailVerified: false,
                          ),
                      colorScheme,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _controller.profile.value?.fullName ??
                                'Admin Panel',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ColorConstants.primary,
                            ),
                          ),
                          Text(
                            _controller.profile.value?.email ?? 'Mama Health',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: ColorConstants.primary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
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
                final isSelected = item['route'] == RouteNames.profile;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? ColorConstants.onPrimary.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isSelected
                            ? ColorConstants.onPrimary
                            : ColorConstants.onPrimary.withOpacity(0.7),
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
                              ? ColorConstants.onPrimary
                              : ColorConstants.onPrimary.withOpacity(0.7),
                        ),
                      ),
                      onTap: () {
                        final route = item['route'] as String;
                        if (route != RouteNames.profile) {
                          Get.toNamed(route);
                        }
                      },
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

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: ColorConstants.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.error.value ?? 'An error occurred.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: ColorConstants.onPrimary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ColorConstants.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              size: 56,
              color: ColorConstants.onPrimary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No profile data available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
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
