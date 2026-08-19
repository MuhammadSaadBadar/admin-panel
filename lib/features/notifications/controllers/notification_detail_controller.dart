import 'package:admin/core/network/api_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/notification.dart';
import '../repositories/notification_repository.dart';

import 'notification_controller.dart';

/// Controller for the notification detail screen
/// ([NotificationDetailScreen]).
///
/// Loads a single notification via `GET /api/v1/notifications/{id}/` and
/// exposes a "mark as read" action via `POST /api/v1/notifications/{id}/mark-read/`.
///
/// Follows the same reactive pattern as the SOS detail controller: holds an
/// [Rx] notification, loading flag, and error message, exposing a single
/// [load] entry point that the UI calls once it knows the ID.
class NotificationDetailController extends GetxController {
  final NotificationRepository _repository;

  NotificationDetailController(this._repository);

  // ── State ──────────────────────────────────────────────────────────────
  final Rxn<AppNotification> notification = Rxn<AppNotification>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  /// Whether a "mark as read" request is in flight.
  final RxBool isMarkingRead = false.obs;

  // ── Actions ─────────────────────────────────────────────────────────────
  /// Fetches the full notification for [id] from the backend.
  Future<void> load(int id) async {
    debugPrint('[NotificationDetailController] load called — id=$id');
    isLoading.value = true;
    error.value = null;

    try {
      final result = await _repository.getNotification(id);
      notification.value = result;
      debugPrint(
        '[NotificationDetailController] load — loaded notification '
        'id=${result.id} type=${result.notificationType} '
        'isRead=${result.isRead}',
      );

      // Auto-mark unread notifications as read when opened (standard inbox UX).
      if (!result.isRead) {
        debugPrint(
          '[NotificationDetailController] load — auto-marking id=$id as read',
        );
        await markRead(silent: true);
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().markOneReadLocally(id);
        }
      }
    } catch (e) {
      debugPrint('[NotificationDetailController] load — ERROR: $e');
      error.value = _errorMessage(e);
    } finally {
      isLoading.value = false;
      debugPrint('[NotificationDetailController] load — isLoading=false');
    }
  }

  /// Marks the currently-loaded notification as read via the backend, then
  /// updates local state. Returns `true` on success.
  Future<bool> markRead({bool silent = false}) async {
    final current = notification.value;
    if (current == null) return false;
    if (current.isRead) return true;

    debugPrint(
      '[NotificationDetailController] markRead called — id=${current.id} '
      'silent=$silent',
    );
    isMarkingRead.value = true;
    try {
      final updated = await _repository.markRead(current.id);
      notification.value = updated;
      debugPrint(
        '[NotificationDetailController] markRead — updated id=${updated.id} '
        'isRead=${updated.isRead}',
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationDetailController] markRead — ERROR: $e');
      if (!silent) {
        Get.snackbar(
          'Update Failed',
          'Could not mark this notification as read.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
      return false;
    } finally {
      isMarkingRead.value = false;
    }
  }

  static String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }
}
