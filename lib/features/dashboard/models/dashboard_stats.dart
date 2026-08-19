import 'package:flutter/foundation.dart';

class DashboardStats {
  final int totalDoctors;
  final int totalPatients;
  final int totalAppointments;
  final int appointmentsThisMonth;
  final int todayAppointments;
  final int activeSosEvents;
  final int newPatientsThisWeek;
  final int activeUsersLast30Days;
  final double? newPatientsGrowthPercent;
  final double? averageDoctorRating;
  final int totalDoctorRatings;
  final int patientsPaid;
  final int patientsOnTrial;
  final int patientsTrialExpired;
  final double? totalRevenueCollected;
  final double? revenueThisMonth;
  final RangeStats? rangeStats;
  final TrimesterDistribution trimesterDistribution;
  final List<RecentActivity> recentActivities;

  DashboardStats({
    required this.totalDoctors,
    required this.totalPatients,
    required this.totalAppointments,
    required this.appointmentsThisMonth,
    required this.todayAppointments,
    required this.activeSosEvents,
    required this.newPatientsThisWeek,
    required this.activeUsersLast30Days,
    required this.newPatientsGrowthPercent,
    required this.averageDoctorRating,
    required this.totalDoctorRatings,
    required this.patientsPaid,
    required this.patientsOnTrial,
    required this.patientsTrialExpired,
    required this.totalRevenueCollected,
    required this.revenueThisMonth,
    required this.rangeStats,
    required this.trimesterDistribution,
    required this.recentActivities,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // Guard trimester_distribution: the key may be absent or null on the
    // first call before any patients are registered. Fall back to zeros
    // rather than crashing with an `as Map` cast on null.
    final TrimesterDistribution trimesterDistribution;
    if (json['trimester_distribution'] is Map) {
      trimesterDistribution = TrimesterDistribution.fromJson(
        Map<String, dynamic>.from(json['trimester_distribution'] as Map),
      );
    } else {
      debugPrint(
        '[DashboardStats] Warning: "trimester_distribution" key is '
        'missing or null in API response — defaulting to zeros.',
      );
      trimesterDistribution = const TrimesterDistribution(
        trimester1: 0,
        trimester2: 0,
        trimester3: 0,
        unknown: 0,
      );
    }

    return DashboardStats(
      totalDoctors: _asInt(json['total_doctors']),
      totalPatients: _asInt(json['total_patients']),
      totalAppointments: _asInt(json['total_appointments']),
      appointmentsThisMonth: _asInt(json['appointments_this_month']),
      todayAppointments: _asInt(json['today_appointments']),
      activeSosEvents: _asInt(json['active_sos_events']),
      newPatientsThisWeek: _asInt(json['new_patients_this_week']),
      activeUsersLast30Days: _asInt(json['active_users_last_30_days']),
      newPatientsGrowthPercent: _asDouble(json['new_patients_growth_percent']),
      averageDoctorRating: _asDouble(json['average_doctor_rating']),
      totalDoctorRatings: _asInt(json['total_doctor_ratings']),
      patientsPaid: _asInt(json['patients_paid']),
      patientsOnTrial: _asInt(json['patients_on_trial']),
      patientsTrialExpired: _asInt(json['patients_trial_expired']),
      totalRevenueCollected: _asDecimal(json['total_revenue_collected']),
      revenueThisMonth: _asDecimal(json['revenue_this_month']),
      rangeStats: json['range_stats'] is Map
          ? RangeStats.fromJson(
              Map<String, dynamic>.from(json['range_stats'] as Map),
            )
          : null,
      trimesterDistribution: trimesterDistribution,
      recentActivities: (json['recent_activities'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (activity) =>
                RecentActivity.fromJson(Map<String, dynamic>.from(activity)),
          )
          .toList(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Parses a nullable double (e.g. `new_patients_growth_percent`), returning
  /// `null` when the value is absent or explicitly `null` (the backend returns
  /// `null` until there is a full prior month of data to compare against).
  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Parses a nullable decimal that the backend serializes as a string
  /// (e.g. `total_revenue_collected` / `revenue_this_month` are `"18000.00"`).
  /// Returns `null` (not `0`) when absent or explicitly `null` so the UI can
  /// distinguish "no confirmed payments yet" from an actual zero.
  static double? _asDecimal(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class TrimesterDistribution {
  final int trimester1;
  final int trimester2;
  final int trimester3;
  final int unknown;

  const TrimesterDistribution({
    required this.trimester1,
    required this.trimester2,
    required this.trimester3,
    required this.unknown,
  });

  factory TrimesterDistribution.fromJson(Map<String, dynamic> json) =>
      TrimesterDistribution(
        trimester1: DashboardStats._asInt(json['trimester_1']),
        trimester2: DashboardStats._asInt(json['trimester_2']),
        trimester3: DashboardStats._asInt(json['trimester_3']),
        unknown: DashboardStats._asInt(json['unknown']),
      );
}

/// Custom-range overlay returned by `GET /reports/admin/stats/` when both
/// `date_from` and `date_to` (inclusive, `YYYY-MM-DD`) are supplied. It is an
/// additive view *alongside* the fixed today/week/month windows, not a
/// replacement — it is `null` unless a range is requested.
class RangeStats {
  final DateTime dateFrom;
  final DateTime dateTo;
  final int appointmentsInRange;
  final int newPatientsInRange;
  final int newDoctorsInRange;

  const RangeStats({
    required this.dateFrom,
    required this.dateTo,
    required this.appointmentsInRange,
    required this.newPatientsInRange,
    required this.newDoctorsInRange,
  });

  factory RangeStats.fromJson(Map<String, dynamic> json) {
    final rawFrom = (json['date_from'] ?? '').toString();
    final rawTo = (json['date_to'] ?? '').toString();
    final parsedFrom = DateTime.tryParse(rawFrom);
    final parsedTo = DateTime.tryParse(rawTo);

    if (parsedFrom == null || parsedTo == null) {
      debugPrint(
        '[DashboardStats] Warning: range_stats dates could not be parsed '
        '("$rawFrom" / "$rawTo") — defaulting to epoch.',
      );
    }

    return RangeStats(
      dateFrom: parsedFrom ?? DateTime.fromMillisecondsSinceEpoch(0),
      dateTo: parsedTo ?? DateTime.fromMillisecondsSinceEpoch(0),
      appointmentsInRange: DashboardStats._asInt(json['appointments_in_range']),
      newPatientsInRange: DashboardStats._asInt(json['new_patients_in_range']),
      newDoctorsInRange: DashboardStats._asInt(json['new_doctors_in_range']),
    );
  }
}

class RecentActivity {
  final String type;
  final String description;
  final DateTime timestamp;

  const RecentActivity({
    required this.type,
    required this.description,
    required this.timestamp,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = (json['timestamp'] ?? '').toString();
    final parsedTimestamp = DateTime.tryParse(rawTimestamp);

    if (parsedTimestamp == null && rawTimestamp.isNotEmpty) {
      debugPrint(
        '[DashboardStats] Warning: failed to parse timestamp '
        '"$rawTimestamp" — defaulting to epoch (1970-01-01).',
      );
    }

    return RecentActivity(
      type: (json['type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      timestamp: parsedTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
