import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/custom_appbar.dart';
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
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: Row(
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
      bottomNavigationBar: isMobile
          ? AppBottomNavBar(
              selectedIndex: 0,
              onItemSelected: (index) {
                switch (index) {
                  case 0:
                    break;
                  case 1:
                    Get.toNamed(RouteNames.doctors);
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
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your personal information and account.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
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
                const SizedBox(height: 20),
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
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.of(context).size.width < 1024 && !_isEditing)
                _buildEditButton(colorScheme),
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
        color: colorScheme.primaryContainer.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          profile.initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid(AdminProfile profile, ColorScheme colorScheme) {
    final bool isNarrow = MediaQuery.of(context).size.width < 600;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isNarrow ? 1 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 4,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        if (isStatus)
          Row(
            children: [
              Icon(
                isVerified ? Icons.check_circle : Icons.error_outline,
                color: isVerified ? ColorConstants.success : colorScheme.error,
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
                      : colorScheme.error,
                ),
              ),
            ],
          )
        else if (isChip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: colorScheme.primary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
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
              color: colorScheme.onSurface,
              letterSpacing: isMono ? 0.4 : 0,
            ),
          ),
      ],
    );
  }

  // ── Edit Form ──────────────────────────────────────────────────────────
  Widget _buildEditForm(ColorScheme colorScheme) {
    final bool isNarrow = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isNarrow ? 1 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 4,
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
                  Icon(Icons.error_outline, color: colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _controller.saveError.value!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: colorScheme.error,
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
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
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
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => ElevatedButton(
                  onPressed: _controller.isSaving.value ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
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
                            color: ColorConstants.background,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMono ? 14 : 16,
              fontWeight: isMono ? FontWeight.w500 : FontWeight.w400,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
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
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
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
          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
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
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_reset, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Change Password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
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
        Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
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
      icon: Icon(Icons.edit, color: colorScheme.onSurface, size: 16),
      label: Text(
        'Edit Profile',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHigh,
        foregroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
    );
  }

  Widget _buildTopAppBar(ColorScheme colorScheme, bool isMobile) {
    return CustomAppBar(title: 'Admin Profile', showBackButton: true);
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
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _controller.profile.value?.email ?? 'Mama Health',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
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
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.error.value ?? 'An error occurred.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
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
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No profile data available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
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
