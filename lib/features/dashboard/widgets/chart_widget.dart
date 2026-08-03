import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../models/dashboard_stats.dart';

class ChartWidget extends StatelessWidget {
  final DashboardStats? stats;

  const ChartWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    if (isMobile) {
      return Column(
        children: [
          PatientGrowthChart(stats: stats),
          SizedBox(height: 16),
          TrimesterDistributionChart(stats: stats),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: PatientGrowthChart(stats: stats)),
        SizedBox(width: 24),
        Expanded(child: TrimesterDistributionChart(stats: stats)),
      ],
    );
  }
}

class PatientGrowthChart extends StatelessWidget {
  final DashboardStats? stats;

  const PatientGrowthChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Text(
                  'Activity Snapshot',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isMobile) ...[
                const ChartButton(label: 'Live', isActive: true),
                const SizedBox(width: 4),
                const ChartButton(label: 'Summary', isActive: false),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildBars(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBars() {
    final values = <_MetricBar>[
      _MetricBar('Patients', stats?.totalPatients ?? 0),
      _MetricBar('Doctors', stats?.totalDoctors ?? 0),
      _MetricBar('Month', stats?.appointmentsThisMonth ?? 0),
      _MetricBar('Today', stats?.todayAppointments ?? 0),
      _MetricBar('New', stats?.newPatientsThisWeek ?? 0),
      _MetricBar('SOS', stats?.activeSosEvents ?? 0),
    ];
    final maxValue = values
        .map((item) => item.value)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return values.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final normalized = maxValue == 0
          ? 0.1
          : (item.value / maxValue).clamp(0.1, 1.0);
      return ChartBar(
        label: item.label,
        // Pass the actual API count so the tooltip shows real data.
        value: item.value,
        height: 24 + (normalized * 100),
        isActive: index == 2,
        isLast: index == values.length - 1,
      );
    }).toList();
  }
}

class ChartBar extends StatelessWidget {
  final String label;
  final double height;
  /// The raw API count displayed in the tooltip when this bar is active.
  final int value;
  final bool isActive;
  final bool isLast;

  const ChartBar({
    super.key,
    required this.label,
    required this.height,
    required this.value,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color barColor = isActive
        ? ColorConstants.primary
        : ColorConstants.primary.withOpacity(isLast ? 0.1 : 0.2);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isActive)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: ColorConstants.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              // Show the actual count from the API, not the pixel height.
              child: Text(
                '$value',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onSurface,
                ),
              ),
            ),
          Container(
            width: 20,
            height: height,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              border: isActive
                  ? Border.all(color: ColorConstants.primary)
                  : null,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: ColorConstants.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ChartButton extends StatelessWidget {
  final String label;
  final bool isActive;

  const ChartButton({super.key, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isActive
            ? ColorConstants.surfaceContainerHigh
            : Colors.transparent,
        border: isActive
            ? Border.all(color: ColorConstants.borderWhite10)
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive
              ? ColorConstants.onSurface
              : ColorConstants.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Donut chart showing the patient trimester distribution.
///
/// Segment proportions are computed from live API data. When all counts
/// are zero (e.g. no patients registered yet), the chart falls back to
/// equal thirds as a visual placeholder.
class TrimesterDistributionChart extends StatelessWidget {
  final DashboardStats? stats;

  const TrimesterDistributionChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final double chartSize = isMobile ? 150 : 192;
    final double innerSize = isMobile ? 120 : 160;

    // Compute segment proportions from live API data.
    final t1 = stats?.trimesterDistribution.trimester1 ?? 0;
    final t2 = stats?.trimesterDistribution.trimester2 ?? 0;
    final t3 = stats?.trimesterDistribution.trimester3 ?? 0;
    final unknownCount = stats?.trimesterDistribution.unknown ?? 0;
    final total = t1 + t2 + t3 + unknownCount;

    // Stops define where each colour's segment ends in the sweep (0.0–1.0).
    // T3 and Unknown are merged into the third segment visually.
    // clamp() ensures stops are strictly increasing and the gradient renders.
    final double rawStop1 = total > 0 ? t1 / total : 0.35;
    final double rawStop2 = total > 0 ? (t1 + t2) / total : 0.70;
    final double stop1 = rawStop1.clamp(0.02, 0.95);
    final double stop2 = rawStop2.clamp(stop1 + 0.03, 0.98);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        children: [
          Text(
            'Trimester Distribution',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.w600,
              color: ColorConstants.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: chartSize,
                height: chartSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Data-driven stops so the visual arc matches API proportions.
                  gradient: SweepGradient(
                    colors: const [
                      Color(0xFFFFB1C5), // T1 — Primary
                      Color(0xFFBAC3FF), // T2 — Secondary
                      Color(0xFF71D7CD), // T3 + Unknown — Tertiary
                    ],
                    stops: [stop1, stop2, 1.0],
                  ),
                ),
              ),
              Container(
                width: innerSize,
                height: innerSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstants.surfaceContainerLow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _totalPatientsLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                    Text(
                      'Active',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TrimesterItem(
            color: ColorConstants.primary,
            label: 'Trimester 1',
            value: _percentageLabel(_trimesterValue(1), total),
          ),
          TrimesterItem(
            color: ColorConstants.secondary,
            label: 'Trimester 2',
            value: _percentageLabel(_trimesterValue(2), total),
          ),
          TrimesterItem(
            color: ColorConstants.tertiary,
            label: 'Trimester 3',
            value: _percentageLabel(_trimesterValue(3), total),
          ),
          TrimesterItem(
            color: ColorConstants.error,
            label: 'Unknown',
            value: _percentageLabel(_trimesterValue(4), total),
          ),
        ],
      ),
    );
  }

  String get _totalPatientsLabel => (stats?.totalPatients ?? 0).toString();

  int _trimesterValue(int slot) {
    final distribution = stats?.trimesterDistribution;
    if (distribution == null) return 0;
    switch (slot) {
      case 1:
        return distribution.trimester1;
      case 2:
        return distribution.trimester2;
      case 3:
        return distribution.trimester3;
      case 4:
        return distribution.unknown;
      default:
        return 0;
    }
  }

  String _percentageLabel(int value, int total) {
    if (total <= 0) return '0%';
    return '${((value / total) * 100).toStringAsFixed(0)}%';
  }
}

class _MetricBar {
  final String label;
  final int value;

  const _MetricBar(this.label, this.value);
}

class TrimesterItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const TrimesterItem({
    super.key,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorConstants.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
