import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/color_constants.dart';
import '../../core/routes/route_names.dart';
import '../../features/auth/services/auth_service.dart';

/// A themed [Drawer] used on mobile to provide navigation across the app.
///
/// The drawer mirrors the design language of the desktop sidebars (dark
/// surfaces, `ColorConstants` palette, `GoogleFonts.plusJakartaSans`, active
/// item highlight with a primary accent bar). It includes the core navigation
/// items and a fixed **Logout** action at the bottom that confirms, clears the
/// session via [AuthService.logout], and navigates to the Login screen with a
/// cleared navigation stack so the user cannot go back into authenticated
/// screens.
class AppDrawer extends StatelessWidget {
  /// The current route used to highlight the selected navigation item.
  final String currentRoute;

  /// Callback invoked when a non-logout navigation item is selected.
  final void Function(String route) onNavigate;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: ColorConstants.surfaceContainerLow,
      width: 300,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(
            height: 1,
            thickness: 1,
            color: ColorConstants.borderWhite10,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: RouteNames.dashboard,
                ),
                _buildNavItem(
                  icon: Icons.medical_services_rounded,
                  label: 'Doctor Management',
                  route: RouteNames.doctors,
                ),
                _buildNavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Patient Management',
                  route: RouteNames.patients,
                ),
                _buildNavItem(
                  icon: Icons.event_rounded,
                  label: 'Appointments',
                  route: RouteNames.appointments,
                ),
                _buildNavItem(
                  icon: Icons.emergency_rounded,
                  label: 'Emergency SOS',
                  route: RouteNames.sos,
                ),
                _buildNavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  route: RouteNames.notifications,
                ),
                // _buildNavItem(
                //   icon: Icons.settings_rounded,
                //   label: 'Settings',
                //   route: RouteNames.settings,
                // ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  route: RouteNames.profile,
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: ColorConstants.borderWhite10,
          ),
          _buildLogoutButton(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.surfaceContainerHigh,
            ColorConstants.surfaceContainerLow,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorConstants.primary,
                      ColorConstants.primary.withOpacity(0.6),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mama Health',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: ColorConstants.primary,
                    ),
                  ),
                  Text(
                    'ADMIN CONSOLE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: ColorConstants.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorConstants.primary.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: ColorConstants.primaryContainer,
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: ColorConstants.onPrimaryContainer,
                    size: 22,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'System Administrator',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Navigation items ───────────────────────────────────────────────────
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String route,
  }) {
    final bool isSelected = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onNavigate(route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? ColorConstants.secondaryContainer
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorConstants.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Icon(
                  icon,
                  color: isSelected
                      ? ColorConstants.onSecondaryContainer
                      : ColorConstants.onSurfaceVariant,
                  size: 21,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? ColorConstants.onSecondaryContainer
                          : ColorConstants.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logout (fixed at bottom) ───────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _confirmLogout(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ColorConstants.error.withOpacity(0.1),
              border: Border.all(color: ColorConstants.error.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: ColorConstants.error,
                  size: 21,
                ),
                const SizedBox(width: 14),
                Text(
                  'Logout',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
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
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.error,
              foregroundColor: ColorConstants.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    debugPrint('[AppDrawer] Logout confirmed — clearing session.');
    final authService = Get.find<AuthService>();
    await authService.logout();
    debugPrint('[AppDrawer] Session cleared — navigating to login.');
    // Clear the entire navigation stack so the user cannot press "back"
    // into any authenticated screen after logout.
    Get.offAllNamed(RouteNames.login);
  }
}
