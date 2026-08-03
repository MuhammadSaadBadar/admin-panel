import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/features/dashboard/models/dashboard_stats.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardStats> getStats() async {
    // Single source of truth: endpoint is defined in ApiConstants.
    // Do not duplicate this path in AppConstants or any other class.
    const path = ApiConstants.reportsAdminStats;

    debugPrint('[DashboardRepo] Stats request start — path=$path');
    debugPrint('[DashboardRepo] Auth header will be attached by AuthInterceptor.');
    debugPrint('[DashboardRepo] Query params: none');

    try {
      final response = await _apiClient.get(path);
      debugPrint(
        '[DashboardRepo] Stats response received — status=${response.statusCode}',
      );
      debugPrint('[DashboardRepo] Stats response body=${response.data}');

      final data = response.data;
      if (data is! Map) {
        debugPrint(
          '[DashboardRepo] Unexpected response shape: expected Map, got ${data.runtimeType}',
        );
        throw StateError(
          'Dashboard API returned an unexpected response shape '
          '(expected Map, got ${data.runtimeType}).',
        );
      }

      final parsed = DashboardStats.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
      debugPrint(
        '[DashboardRepo] Stats parsed successfully — '
        'doctors=${parsed.totalDoctors} patients=${parsed.totalPatients} '
        'appointments=${parsed.totalAppointments} '
        'sos=${parsed.activeSosEvents} '
        'activities=${parsed.recentActivities.length}',
      );
      return parsed;
    } on DioException catch (e) {
      debugPrint(
        '[DashboardRepo] Stats request failed — '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      debugPrint('[DashboardRepo] Failure response body=${e.response?.data}');
      rethrow;
    }
  }
}
