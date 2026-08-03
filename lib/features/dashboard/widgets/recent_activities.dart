import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../models/dashboard_stats.dart';

class RecentActivities extends StatelessWidget {
  final DashboardStats? stats;

  const RecentActivities({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final activities = stats?.recentActivities ?? const <RecentActivity>[];

    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Recent Activity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: ColorConstants.borderWhite5),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No recent activity available yet.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            )
          else
            ...activities.take(5).map((activity) {
              final item = _ActivityStyle.fromType(activity.type);
              return Column(
                children: [
                  _ActivityItem(
                    icon: item.icon,
                    iconColor: item.iconColor,
                    iconBgColor: item.iconBgColor,
                    title: activity.description,
                    subtitle: _formatTimestamp(activity.timestamp),
                    isSOS: activity.type == 'sos_triggered',
                  ),
                  Divider(height: 1, color: ColorConstants.borderWhite5),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    }
    return '${difference.inDays} days ago';
  }
}

class _ActivityStyle {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _ActivityStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  factory _ActivityStyle.fromType(String type) {
    switch (type) {
      case 'patient_registered':
        return const _ActivityStyle(
          icon: Icons.person_add,
          iconColor: ColorConstants.tertiary,
          iconBgColor: Color(0x1A71D7CD),
        );
      case 'appointment_booked':
        return const _ActivityStyle(
          icon: Icons.calendar_today,
          iconColor: ColorConstants.secondary,
          iconBgColor: Color(0x1ABAC3FF),
        );
      case 'sos_triggered':
      default:
        return const _ActivityStyle(
          icon: Icons.emergency,
          iconColor: ColorConstants.error,
          iconBgColor: Color(0x33FFB4AB),
        );
    }
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final bool isSOS;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.isSOS = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSOS ? FontWeight.w700 : FontWeight.w400,
                    color: ColorConstants.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSOS
                        ? ColorConstants.error
                        : ColorConstants.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isSOS)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConstants.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Resolve',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.onError,
                ),
              ),
            )
          else
            Icon(
              Icons.more_vert,
              color: ColorConstants.onSurfaceVariant,
              size: 20,
            ),
        ],
      ),
    );
  }
}
