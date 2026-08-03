import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constants.dart';
import '../routes/route_names.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<_NavItem> items = [
      _NavItem(
        icon: Icons.dashboard,
        label: 'Home',
        route: RouteNames.dashboard,
      ),
      _NavItem(
        icon: Icons.medical_services,
        label: 'Doctors',
        route: RouteNames.doctors,
      ),
      _NavItem(
        icon: Icons.person,
        label: 'Patients',
        route: RouteNames.patients,
      ),
      _NavItem(
        icon: Icons.event,
        label: 'Appointments',
        route: RouteNames.appointments,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainer,
        border: Border(top: BorderSide(color: ColorConstants.borderWhite10)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final bool isSelected = selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onItemSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorConstants.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected
                                ? ColorConstants.onPrimaryContainer
                                : ColorConstants.onSurfaceVariant,
                            size: 22, // Slightly smaller icon
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, // Slightly smaller text
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? ColorConstants.onPrimaryContainer
                                  : ColorConstants.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
