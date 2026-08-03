import 'package:flutter/material.dart';

import '../../core/constants/color_constants.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: ColorConstants.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 35,
                    color: ColorConstants.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mama Health Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'admin@mamahealth.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: '/dashboard',
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Doctors',
            route: '/doctors',
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Patients',
            route: '/patients',
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Appointments',
            route: '/appointments',
          ),
          _buildDrawerItem(
            icon: Icons.assessment,
            title: 'Reports',
            route: '/reports',
          ),
          _buildDrawerItem(
            icon: Icons.notifications,
            title: 'Notifications',
            route: '/notifications',
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            route: '/settings',
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            route: '/logout',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? ColorConstants.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? ColorConstants.primary : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: ColorConstants.primary.withOpacity(0.1),
      onTap: () => onNavigate(route),
    );
  }
}
