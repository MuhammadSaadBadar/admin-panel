import 'package:flutter/foundation.dart';

class DashboardStats {
  final int totalDoctors;
  final int totalPatients;
  final int totalAppointments;
  final int appointmentsThisMonth;
  final int todayAppointments;
  final int activeSosEvents;
  final int newPatientsThisWeek;
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
