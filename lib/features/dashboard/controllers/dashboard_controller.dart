import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class DashboardController extends GetxController {
  final DashboardRepository _repository;

  DashboardController(this._repository);

  final Rxn<DashboardStats> stats = Rxn<DashboardStats>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    debugPrint('[DashboardController] Initialized.');
  }

  /// Pull-to-refresh entry point. Delegates to [loadStats].
  Future<void> refresh() => loadStats();

  /// Fetches the admin dashboard stats from the API.
  ///
  /// Guards against concurrent in-flight calls: if a request is already
  /// running, subsequent calls are ignored until it completes.
  Future<void> loadStats() async {
    if (isLoading.value) {
      debugPrint(
        '[DashboardController] loadStats() called while already in flight — skipped.',
      );
      return;
    }

    debugPrint('[DashboardController] loadStats() started.');
    isLoading.value = true;
    error.value = null;
    debugPrint(
      '[DashboardController] State updated: loading=true, error=null.',
    );

    try {
      final data = await _repository.getStats();
      stats.value = data;
      debugPrint(
        '[DashboardController] Stats loaded successfully — '
        'doctors=${data.totalDoctors} patients=${data.totalPatients} '
        'appointments=${data.totalAppointments} '
        'todayAppointments=${data.todayAppointments} '
        'sos=${data.activeSosEvents} '
        'newPatientsThisWeek=${data.newPatientsThisWeek} '
        'activities=${data.recentActivities.length}',
      );
      debugPrint('[DashboardController] UI refresh triggered.');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? 'no body';
      final message = _humanReadableError(statusCode, e.message);
      error.value = message;
      debugPrint(
        '[DashboardController] Stats load failed (DioException) — '
        'status=$statusCode message=${e.message} body=$body',
      );
      debugPrint(
        '[DashboardController] User-facing error message: "$message"',
      );
    } catch (e, stackTrace) {
      const message = 'An unexpected error occurred. Please try again.';
      error.value = message;
      debugPrint(
        '[DashboardController] Stats load failed (unexpected) — error=$e',
      );
      debugPrint('[DashboardController] Stack trace: $stackTrace');
    } finally {
      isLoading.value = false;
      debugPrint('[DashboardController] State updated: loading=false.');
    }
  }

  /// Converts an HTTP status code and raw Dio message into a user-friendly
  /// error string that is safe to display in the UI.
  String _humanReadableError(int? statusCode, String? rawMessage) {
    switch (statusCode) {
      case 400:
        return 'Bad request (400). Please contact support.';
      case 401:
        return 'Session expired (401). Please log in again.';
      case 403:
        return 'Access denied (403). Admin privileges are required.';
      case 404:
        return 'Dashboard endpoint not found (404). Please contact support.';
      case 429:
        return 'Too many requests (429). Please wait a moment and retry.';
      case 500:
      case 502:
      case 503:
        return 'Server error ($statusCode). '
            'The server may be starting up — please wait and retry.';
      default:
        if (rawMessage?.contains('SocketException') == true ||
            rawMessage?.contains('Connection refused') == true) {
          return 'No internet connection. Please check your network.';
        }
        return statusCode != null
            ? 'Request failed with status $statusCode.'
            : 'Unable to connect to the server. Please check your network.';
    }
  }
}
