import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/network/api_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/sos_event.dart';

/// Repository for the Admin SOS module.
///
/// Handles:
/// - `GET /api/v1/emergency/sos/` — list all SOS events (admin), optional `?status=` filter
/// - `GET /api/v1/emergency/sos/{id}/` — single event detail
/// - `POST /api/v1/emergency/sos/{id}/resolve/` — resolve / dismiss an event
///
/// Follows the same conventions as [DoctorRepository] / [ProfileRepository]:
/// debug logging, [ApiErrorMapper] for structured errors, sanitized response
/// bodies, and no hardcoded URLs (all come from [ApiConstants]).
class SosRepository {
  final ApiClient _apiClient;

  SosRepository(this._apiClient);

  /// Fetches the list of SOS events.
  ///
  /// Admin sees all events. Optionally narrows with `?status=active` (or
  /// `resolved`/`false_alarm`). The backend returns a DRF paginated response
  /// (`{ count, next, previous, results }`); we request a generous page size
  /// so the admin panel has a meaningful working set for the filter tabs.
  Future<List<SosEvent>> getSosEvents({String? status}) async {
    final Map<String, dynamic> queryParameters = {'page_size': 100};
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    debugPrint(
      '[SosRepo] getSosEvents called — ${ApiConstants.emergencySos} '
      'queryParameters=$queryParameters',
    );
    final response = await _apiClient.get(
      ApiConstants.emergencySos,
      queryParameters: queryParameters,
    );
    debugPrint(
      '[SosRepo] getSosEvents response — status=${response.statusCode}',
    );

    final List<dynamic> rawList;
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      rawList = data['results'] as List? ?? [];
      debugPrint('[SosRepo] getSosEvents — total on server=${data['count']}');
    } else if (response.data is List) {
      rawList = response.data as List;
    } else {
      debugPrint('[SosRepo] getSosEvents — unexpected response shape');
      return [];
    }

    final events = rawList.map((json) => SosEvent.fromJson(json)).toList();
    debugPrint(
      '[SosRepo] getSosEvents parsed — ${events.length} events '
      '(filter status=$status)',
    );
    return events;
  }

  /// Fetches a single SOS event by id via `GET /emergency/sos/{id}/`.
  Future<SosEvent> getSosEvent(int id) async {
    final path = '${ApiConstants.emergencySosDetail}/$id/';
    debugPrint('[SosRepo] getSosEvent called — id=$id path=$path');
    final response = await _apiClient.get(path);
    debugPrint(
      '[SosRepo] getSosEvent response — status=${response.statusCode} '
      'body=${_sanitizeResponse(response.data)}',
    );
    final event = SosEvent.fromJson(response.data);
    debugPrint(
      '[SosRepo] getSosEvent parsed — id=${event.id} '
      'patient="${event.patientName}" status=${event.status}',
    );
    return event;
  }

  /// Resolves or dismisses an SOS event via
  /// `POST /emergency/sos/{id}/resolve/` with body `{"status": <status>}`.
  ///
  /// [status] must be `resolved` or `false_alarm` (the backend only allows
  /// `active` at creation). Returns the updated [SosEvent].
  Future<SosEvent> resolveSosEvent(int id, String status) async {
    final path =
        '${ApiConstants.emergencySosDetail}/$id'
        '${ApiConstants.emergencySosResolveSuffix}';
    final body = {'status': status};
    debugPrint(
      '[SosRepo] resolveSosEvent called — id=$id status=$status path=$path',
    );
    debugPrint('[SosRepo] resolveSosEvent request — body=$body');

    try {
      final response = await _apiClient.post(path, data: body);
      debugPrint(
        '[SosRepo] resolveSosEvent response — status=${response.statusCode} '
        'body=${_sanitizeResponse(response.data)}',
      );
      final event = SosEvent.fromJson(response.data);
      debugPrint(
        '[SosRepo] resolveSosEvent parsed — id=${event.id} '
        'status=${event.status}',
      );
      return event;
    } on DioException catch (e) {
      debugPrint(
        '[SosRepo] resolveSosEvent DioException — type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      debugPrint('[SosRepo] resolveSosEvent error body=${e.response?.data}');
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to update the SOS event.',
      );
      debugPrint('[SosRepo] resolveSosEvent error — $mapped');
      throw mapped;
    }
  }

  // ── Logging helpers ────────────────────────────────────────────────────

  /// Sanitizes a response body for debug logs (prevents echoing emails).
  static Object? _sanitizeResponse(dynamic data) {
    if (data is Map) {
      final safe = <String, dynamic>{};
      data.forEach((key, value) {
        final k = key.toString();
        if (k.contains('email')) {
          safe[k] = '***';
        } else {
          safe[k] = value is Map || value is List ? '[redacted]' : value;
        }
      });
      return safe;
    }
    return data is String && data.length > 200
        ? '${data.substring(0, 200)}...[truncated]'
        : data;
  }
}
