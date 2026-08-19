import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/network/api_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/broadcast_request.dart';
import '../models/notification.dart';

/// A paginated page of notifications, mirroring the DRF paginated response
/// `PaginatedNotificationList` (`{ count, next, previous, results }`).
class PaginatedNotifications {
  final int count;
  final String? next;
  final String? previous;
  final List<AppNotification> results;

  const PaginatedNotifications({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedNotifications.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List? ?? [];
    return PaginatedNotifications(
      count: (json['count'] as num?)?.toInt() ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: rawResults
          .map(
            (e) => AppNotification.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}

/// Repository for the Admin Notifications module.
///
/// Handles:
/// - `GET /api/v1/notifications/` — own inbox (paginated, newest first)
/// - `GET /api/v1/notifications/{id}/` — single notification
/// - `POST /api/v1/notifications/{id}/mark-read/` — mark one notification read
/// - `POST /api/v1/notifications/mark-all-read/` — mark all as read
/// - `POST /api/v1/notifications/broadcast/` — admin broadcast (async, 202)
///
/// Follows the same conventions as [SosRepository] / [DoctorRepository]:
/// debug logging, [ApiErrorMapper] for structured errors, sanitized response
/// bodies, and no hardcoded URLs (all come from [ApiConstants]).
class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  /// Fetches the admin's own notification inbox, newest first.
  ///
  /// The backend returns a DRF paginated response; we request a generous page
  /// size so the admin panel has a meaningful working set.
  Future<PaginatedNotifications> getNotifications({
    int pageSize = 100,
    int? page,
  }) async {
    final Map<String, dynamic> queryParameters = {'page_size': pageSize};
    if (page != null) {
      queryParameters['page'] = page;
    }
    debugPrint(
      '[NotificationRepo] getNotifications called — '
      '${ApiConstants.notifications} queryParameters=$queryParameters',
    );

    try {
      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: queryParameters,
      );
      debugPrint(
        '[NotificationRepo] getNotifications response — '
        'status=${response.statusCode}',
      );

      if (response.data is! Map<String, dynamic>) {
        debugPrint(
          '[NotificationRepo] getNotifications — unexpected response shape',
        );
        return const PaginatedNotifications(count: 0, results: []);
      }

      final parsed = PaginatedNotifications.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
      debugPrint(
        '[NotificationRepo] getNotifications parsed — '
        '${parsed.results.length} results (total=${parsed.count})',
      );
      return parsed;
    } on DioException catch (e) {
      debugPrint(
        '[NotificationRepo] getNotifications DioException — '
        'type=${e.type} status=${e.response?.statusCode} message=${e.message}',
      );
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to load notifications.',
      );
      debugPrint('[NotificationRepo] getNotifications error — $mapped');
      throw mapped;
    }
  }

  /// Fetches the admin's unread notification count via
  /// `GET /notifications/unread-count/`.
  ///
  /// The backend returns `{"unread_count": N}`. Used by the AppBar / Dashboard
  /// bell badge so the count is accurate without loading the full inbox.
  Future<int> getUnreadCount() async {
    debugPrint(
      '[NotificationRepo] getUnreadCount called — '
      '${ApiConstants.notificationsUnreadCount}',
    );

    try {
      final response = await _apiClient.get(
        ApiConstants.notificationsUnreadCount,
      );
      debugPrint(
        '[NotificationRepo] getUnreadCount response — '
        'status=${response.statusCode} body=${_sanitizeResponse(response.data)}',
      );
      final data = response.data;
      if (data is Map) {
        return (data['unread_count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      debugPrint(
        '[NotificationRepo] getUnreadCount DioException — '
        'type=${e.type} status=${e.response?.statusCode} message=${e.message}',
      );
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to load unread notification count.',
      );
      debugPrint('[NotificationRepo] getUnreadCount error — $mapped');
      throw mapped;
    }
  }

  /// Fetches a single notification by id via `GET /notifications/{id}/`.
  Future<AppNotification> getNotification(int id) async {
    final path = '${ApiConstants.notificationsDetail}/$id/';
    debugPrint('[NotificationRepo] getNotification called — id=$id path=$path');

    try {
      final response = await _apiClient.get(path);
      debugPrint(
        '[NotificationRepo] getNotification response — '
        'status=${response.statusCode} body=${_sanitizeResponse(response.data)}',
      );
      final notification = AppNotification.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
      debugPrint(
        '[NotificationRepo] getNotification parsed — id=${notification.id} '
        'type=${notification.notificationType} isRead=${notification.isRead}',
      );
      return notification;
    } on DioException catch (e) {
      debugPrint(
        '[NotificationRepo] getNotification DioException — status='
        '${e.response?.statusCode} message=${e.message}',
      );
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to load this notification.',
      );
      debugPrint('[NotificationRepo] getNotification error — $mapped');
      throw mapped;
    }
  }

  /// Marks a single notification as read via
  /// `POST /notifications/{id}/mark-read/`. Returns the updated [AppNotification].
  Future<AppNotification> markRead(int id) async {
    final path =
        '${ApiConstants.notificationsDetail}/$id'
        '${ApiConstants.notificationMarkReadSuffix}';
    debugPrint('[NotificationRepo] markRead called — id=$id path=$path');

    try {
      final response = await _apiClient.post(path);
      debugPrint(
        '[NotificationRepo] markRead response — status=${response.statusCode} '
        'body=${_sanitizeResponse(response.data)}',
      );
      final notification = AppNotification.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
      debugPrint(
        '[NotificationRepo] markRead parsed — id=${notification.id} '
        'isRead=${notification.isRead}',
      );
      return notification;
    } on DioException catch (e) {
      debugPrint(
        '[NotificationRepo] markRead DioException — status='
        '${e.response?.statusCode} message=${e.message}',
      );
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to mark this notification as read.',
      );
      debugPrint('[NotificationRepo] markRead error — $mapped');
      throw mapped;
    }
  }

  /// Marks all notifications as read via `POST /notifications/mark-all-read/`.
  ///
  /// Returns the number of notifications marked as read (parsed from the
  /// `detail` message, e.g. "3 notification(s) marked as read.").
  Future<int> markAllRead() async {
    debugPrint(
      '[NotificationRepo] markAllRead called — '
      '${ApiConstants.notificationsMarkAllRead}',
    );

    try {
      final response = await _apiClient.post(
        ApiConstants.notificationsMarkAllRead,
      );
      debugPrint(
        '[NotificationRepo] markAllRead response — status=${response.statusCode} '
        'body=${_sanitizeResponse(response.data)}',
      );
      final count = _parseMarkedCount(response.data);
      debugPrint('[NotificationRepo] markAllRead — marked $count as read');
      return count;
    } on DioException catch (e) {
      debugPrint(
        '[NotificationRepo] markAllRead DioException — status='
        '${e.response?.statusCode} message=${e.message}',
      );
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to mark all notifications as read.',
      );
      debugPrint('[NotificationRepo] markAllRead error — $mapped');
      throw mapped;
    }
  }

  /// Broadcasts a notification to patients and/or doctors via
  /// `POST /notifications/broadcast/`.
  ///
  /// The backend fans out **asynchronously** via Celery and returns `202
  /// Accepted` with `{ "detail": "Broadcast queued." }` immediately. We treat
  /// any 2xx (including 202) as success and return the server `detail` message.
  Future<String> broadcast(BroadcastRequest request) async {
    final payload = request.toJson();
    debugPrint(
      '[NotificationRepo] broadcast called — ${ApiConstants.notificationsBroadcast} '
      'payload=$payload',
    );

    try {
      final response = await _apiClient.post(
        ApiConstants.notificationsBroadcast,
        data: payload,
      );
      debugPrint(
        '[NotificationRepo] broadcast response — status=${response.statusCode} '
        'body=${_sanitizeResponse(response.data)}',
      );
      final detail = _extractDetail(response.data);
      debugPrint('[NotificationRepo] broadcast — detail="$detail"');
      return detail;
    } on DioException catch (e) {
      debugPrint(
        '[NotificationRepo] broadcast DioException — type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      debugPrint('[NotificationRepo] broadcast error body=${e.response?.data}');
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to send the broadcast.',
      );
      debugPrint('[NotificationRepo] broadcast error — $mapped');
      throw mapped;
    }
  }

  // ── Response parsing helpers ───────────────────────────────────────────

  /// Extracts the number of notifications marked as read from the
  /// mark-all-read response. The backend returns
  /// `{"detail": "3 notification(s) marked as read."}`.
  int _parseMarkedCount(dynamic data) {
    if (data is Map) {
      final detail = data['detail']?.toString();
      if (detail != null) {
        final match = RegExp(r'(\d+)').firstMatch(detail);
        if (match != null) {
          return int.tryParse(match.group(0)!) ?? 0;
        }
      }
    }
    return 0;
  }

  /// Extracts a human-readable `detail` message from a response body.
  String _extractDetail(dynamic data) {
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    return 'Broadcast queued.';
  }

  /// Sanitizes a response body for debug logs (prevents echoing long bodies).
  static Object? _sanitizeResponse(dynamic data) {
    if (data is Map) {
      final safe = <String, dynamic>{};
      data.forEach((key, value) {
        final k = key.toString();
        if (k == 'body') {
          safe[k] = value is String && value.length > 50
              ? '${value.substring(0, 50)}...[truncated]'
              : value;
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
