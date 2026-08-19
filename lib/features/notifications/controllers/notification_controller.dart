import 'package:admin/core/network/api_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/broadcast_request.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';

/// Controller for the Admin Notifications inbox screen
/// ([NotificationsScreen]).
///
/// Loads the admin's own notifications from `GET /api/v1/notifications/` and
/// exposes reactive state: loading / error / list. Supports client-side filter
/// tabs (All / Unread / Broadcasts / Alerts), a "mark all read" action via
/// `POST /api/v1/notifications/mark-all-read/`, and a broadcast action via
/// `POST /api/v1/notifications/broadcast/`.
///
/// Also exposes [unreadCount] so the AppBar bell badge can stay in sync across
/// the app.
class NotificationController extends GetxController {
  final NotificationRepository _repository;

  NotificationController(this._repository);

  @override
  void onInit() {
    super.onInit();
    debugPrint('[NotificationController] onInit — preloading inbox for badge');
    loadNotifications();
  }

  // ── State ──────────────────────────────────────────────────────────────
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  final RxString selectedFilter = 'All'.obs;

  /// Whether a broadcast is currently being sent.
  final RxBool isSendingBroadcast = false.obs;

  /// Whether a "mark all read" request is in flight.
  final RxBool isMarkingAllRead = false.obs;

  /// Whether a background refresh (pull-to-refresh / AppBar refresh) is running.
  final RxBool isRefreshing = false.obs;

  /// Live unread-notification count used by the bell badge. Populated from the
  /// dedicated `GET /notifications/unread-count/` endpoint via
  /// [fetchUnreadCount], so it stays accurate without loading the full inbox.
  final RxInt unreadCountValue = 0.obs;

  // ── Computed ────────────────────────────────────────────────────────────
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// The notifications filtered by the selected tab.
  List<AppNotification> get filteredNotifications {
    final filter = selectedFilter.value;
    switch (filter) {
      case 'Unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'Broadcasts':
        return notifications.where((n) => n.isBroadcast).toList();
      case 'Alerts':
        return notifications.where((n) => n.isUrgent).toList();
      case 'All':
      default:
        return notifications.toList();
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  /// Fetches the notification inbox from the backend.
  Future<void> loadNotifications() async {
    debugPrint('[NotificationController] loadNotifications called');
    if (isLoading.value) {
      debugPrint(
        '[NotificationController] loadNotifications — already loading, skip',
      );
      return;
    }
    isLoading.value = true;
    error.value = null;

    try {
      final page = await _repository.getNotifications();
      notifications.assignAll(page.results);
      debugPrint(
        '[NotificationController] loadNotifications — loaded '
        '${page.results.length} notifications (total=${page.count}), '
        'unread=$unreadCount',
      );
      // Keep the bell badge in sync with the loaded inbox.
      await fetchUnreadCount();
    } catch (e) {
      debugPrint('[NotificationController] loadNotifications — ERROR: $e');
      error.value = _errorMessage(e);
    } finally {
      isLoading.value = false;
      debugPrint(
        '[NotificationController] loadNotifications — isLoading=false',
      );
    }
  }

  /// Fetches the unread-notification count from the dedicated
  /// `GET /notifications/unread-count/` endpoint and updates [unreadCountValue].
  ///
  /// Used by the AppBar/Dashboard bell badge. On failure it keeps the last
  /// known count (defaults to 0) so the UI never breaks.
  Future<void> fetchUnreadCount() async {
    debugPrint('[NotificationController] fetchUnreadCount called');
    try {
      final count = await _repository.getUnreadCount();
      unreadCountValue.value = count;
      debugPrint('[NotificationController] fetchUnreadCount — unread=$count');
    } catch (e) {
      debugPrint('[NotificationController] fetchUnreadCount — ERROR: $e');
      // Graceful: keep the last known count on failure.
    }
  }

  /// Pull-to-refresh / AppBar refresh entry point. Fetches the latest inbox
  /// without flipping the full-screen loading state when data already exists.
  @override
  Future<void> refresh() async {
    debugPrint('[NotificationController] refresh called');
    if (isRefreshing.value) {
      debugPrint('[NotificationController] refresh — already refreshing, skip');
      return;
    }
    isRefreshing.value = true;
    try {
      final page = await _repository.getNotifications(pageSize: 100);
      notifications.assignAll(page.results);
      error.value = null;
      debugPrint(
        '[NotificationController] refresh — loaded ${page.results.length} '
        'notifications, unread=$unreadCount',
      );
    } catch (e) {
      debugPrint('[NotificationController] refresh — ERROR: $e');
      // Keep existing list on transient refresh errors.
    } finally {
      isRefreshing.value = false;
    }
    // Keep the bell badge in sync with the refreshed inbox.
    await fetchUnreadCount();
  }

  /// Updates the active filter tab (client-side).
  void setFilter(String filter) {
    debugPrint('[NotificationController] setFilter — "$filter"');
    selectedFilter.value = filter;
  }

  /// Marks all notifications as read via the backend.
  Future<void> markAllRead() async {
    debugPrint('[NotificationController] markAllRead called');
    if (notifications.isEmpty) {
      debugPrint('[NotificationController] markAllRead — nothing to mark');
      return;
    }
    isMarkingAllRead.value = true;
    try {
      final markedCount = await _repository.markAllRead();
      // Update local state so the UI reflects immediately.
      for (var i = 0; i < notifications.length; i++) {
        final n = notifications[i];
        if (!n.isRead) {
          notifications[i] = _copyAsRead(n);
        }
      }
      notifications.refresh();
      debugPrint(
        '[NotificationController] markAllRead — marked $markedCount as read, '
        'unread now=$unreadCount',
      );
      // Keep the bell badge in sync after marking all as read.
      unreadCountValue.value = 0;
      await fetchUnreadCount();
      Get.snackbar(
        'All notifications read',
        markedCount > 0
            ? '$markedCount notification(s) marked as read.'
            : 'All notifications marked as read.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('[NotificationController] markAllRead — ERROR: $e');
      Get.snackbar(
        'Update Failed',
        'Could not mark all notifications as read.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isMarkingAllRead.value = false;
    }
  }

  /// Sends a broadcast notification via the backend.
  ///
  /// Handles the backend's `202 Accepted` (async fan-out) as success. Returns
  /// `true` on success, `false` on failure.
  Future<bool> broadcast(BroadcastRequest request) async {
    debugPrint(
      '[NotificationController] broadcast called — title="${request.title}" '
      'target=${request.targetRole}',
    );
    isSendingBroadcast.value = true;
    try {
      final detail = await _repository.broadcast(request);
      debugPrint('[NotificationController] broadcast — success: $detail');
      // Refresh inbox so any admin-facing copies appear when available.
      await refresh();
      Get.snackbar(
        'Broadcast queued',
        detail,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationController] broadcast — ERROR: $e');
      Get.snackbar(
        'Broadcast Failed',
        'Could not send the broadcast. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isSendingBroadcast.value = false;
    }
  }

  /// Marks a single notification as read locally (used by the detail screen
  /// or when tapping an item). Returns the updated notification.
  void markOneReadLocally(int id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !notifications[index].isRead) {
      notifications[index] = _copyAsRead(notifications[index]);
      notifications.refresh();
      debugPrint(
        '[NotificationController] markOneReadLocally — id=$id marked read, '
        'unread now=$unreadCount',
      );
      // Keep the bell badge in sync after marking one as read.
      fetchUnreadCount();
    }
  }

  AppNotification _copyAsRead(AppNotification n) {
    return AppNotification(
      id: n.id,
      notificationType: n.notificationType,
      title: n.title,
      body: n.body,
      data: n.data,
      isRead: true,
      channelPushSent: n.channelPushSent,
      channelWhatsappSent: n.channelWhatsappSent,
      createdAt: n.createdAt,
    );
  }

  static String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }
}
