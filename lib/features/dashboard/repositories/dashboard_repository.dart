import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/features/dashboard/models/dashboard_stats.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  /// Fetches the admin dashboard stats.
  ///
  /// Optionally accepts a `dateFrom` / `dateTo` range (formatted as
  /// `YYYY-MM-DD`) which is passed to the backend as `date_from` / `date_to`
  /// query params to filter the stats. When omitted, the call uses the default
  /// (unfiltered) stats.
  Future<DashboardStats> getStats({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    // Single source of truth: endpoint is defined in ApiConstants.
    // Do not duplicate this path in AppConstants or any other class.
    const path = ApiConstants.reportsAdminStats;

    final Map<String, dynamic> queryParameters = {};
    if (dateFrom != null) {
      queryParameters['date_from'] = _formatDate(dateFrom);
    }
    if (dateTo != null) {
      queryParameters['date_to'] = _formatDate(dateTo);
    }

    debugPrint('[DashboardRepo] Stats request start — path=$path');
    debugPrint(
      '[DashboardRepo] Auth header will be attached by AuthInterceptor.',
    );
    debugPrint('[DashboardRepo] Query params: $queryParameters');

    try {
      final response = await _apiClient.get(
        path,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
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

      final parsed = DashboardStats.fromJson(Map<String, dynamic>.from(data));
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

  /// Formats a [DateTime] as `YYYY-MM-DD` for the `date_from` / `date_to`
  /// query parameters accepted by the dashboard stats endpoint.
  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
