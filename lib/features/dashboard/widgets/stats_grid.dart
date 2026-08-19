import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../models/dashboard_stats.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats? stats;

  const StatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet = MediaQuery.of(context).size.width < 900;

    int crossAxisCount = 4;
    // Use a guaranteed minimum height (mainAxisExtent) rather than a
    // childAspectRatio so the card content never overflows on narrow screens —
    // the fixed ratio made cell height shrink with column width on small
    // handsets, clipping the value text.
    double mainAxisExtent = 110;
    double spacing = 16;

    if (isMobile) {
      crossAxisCount = 2;
      mainAxisExtent = 132;
      spacing = 8;
    } else if (isTablet) {
      crossAxisCount = 2;
      mainAxisExtent = 120;
      spacing = 16;
    }

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: mainAxisExtent,
      ),
      children: [
        StatCard(
          icon: Icons.person,
          iconColor: ColorConstants.secondary,
          iconBgColor: Color(
            0x1ABAC3FF,
          ), // ColorConstants.secondary.withOpacity(0.1)
          label: 'Total Patients',
          value: _formatNumber(stats?.totalPatients ?? 0),
          percentage:
              '${_formatNumber(stats?.newPatientsThisWeek ?? 0)} this week',
          percentageColor: ColorConstants.tertiary,
        ),
        StatCard(
          icon: Icons.medical_services,
          iconColor: ColorConstants.tertiary,
          iconBgColor: Color(
            0x1A71D7CD,
          ), // ColorConstants.tertiary.withOpacity(0.1)
          label: 'Total Doctors',
          value: _formatNumber(stats?.totalDoctors ?? 0),
          percentage: 'Active staff',
          percentageColor: ColorConstants.tertiary,
        ),
        StatCard(
          icon: Icons.event,
          iconColor: ColorConstants.primary,
          iconBgColor: Color(
            0x1AFFB1C5,
          ), // ColorConstants.primary.withOpacity(0.1)
          label: 'Appointments',
          value: _formatNumber(stats?.totalAppointments ?? 0),
          percentage:
              '${_formatNumber(stats?.appointmentsThisMonth ?? 0)} this month',
          percentageColor: ColorConstants.onSurfaceVariant,
        ),
        SOSCard(activeSosCount: stats?.activeSosEvents ?? 0),
      ],
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;
  final String percentage;
  final Color percentageColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.percentage,
    required this.percentageColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorConstants.primary, ColorConstants.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Flexible(
                child: Text(
                  percentage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                  color: Colors.white.withOpacity(0.85),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SOSCard extends StatelessWidget {
  final int activeSosCount;

  const SOSCard({super.key, required this.activeSosCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(
          0x33FFB4AB,
        ), // ColorConstants.errorContainer.withOpacity(0.2)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.primary, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FFB1C5), // ColorConstants.primary.withOpacity(0.4)
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(
                    0x33FFB4AB,
                  ), // ColorConstants.error.withOpacity(0.2)
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emergency,
                  color: ColorConstants.error,
                  size: 20,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ColorConstants.error,
                  shape: BoxShape.circle,
                ),
                child: const PulsingDot(),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active SOS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                  color: ColorConstants.error,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activeSosCount.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8 + (8 * _controller.value),
          height: 8 + (8 * _controller.value),
          decoration: BoxDecoration(
            color: ColorConstants.error.withOpacity(
              0.75 * (1 - _controller.value * 0.5),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
