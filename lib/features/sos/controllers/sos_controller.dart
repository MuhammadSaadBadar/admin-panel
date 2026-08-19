import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/sos_event.dart';
import '../repositories/sos_repository.dart';

/// Controller for the Admin SOS list screen ([EmergencySosScreen]).
///
/// Loads all SOS events from `GET /api/v1/emergency/sos/` and exposes
/// reactive state (loading / error / events). Supports client-side filter
/// tabs (All / Active / Resolved / False Alarm) and an inline resolve action
/// that calls `POST /api/v1/emergency/sos/{id}/resolve/`.
class SosController extends GetxController {
  final SosRepository _repository;

  SosController(this._repository);

  // ── State ──────────────────────────────────────────────────────────────
  final RxList<SosEvent> events = <SosEvent>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  final RxString selectedFilter = 'All'.obs;

  /// Whether any resolve request is currently in flight (used to disable
  /// action buttons and show a spinner).
  final RxBool isResolving = false.obs;

  // ── Computed ────────────────────────────────────────────────────────────
  List<SosEvent> get filteredEvents {
    final filter = selectedFilter.value;
    switch (filter) {
      case 'Active':
        return events.where((e) => e.isActive).toList();
      case 'Resolved':
        return events.where((e) => e.isResolved).toList();
      case 'False Alarm':
        return events.where((e) => e.isFalseAlarm).toList();
      case 'All':
      default:
        return events.toList();
    }
  }

  int get activeCount => events.where((e) => e.isActive).length;
  int get resolvedCount => events.where((e) => e.isResolved).length;
  int get falseAlarmCount => events.where((e) => e.isFalseAlarm).length;

  // ── Actions ─────────────────────────────────────────────────────────────
  /// Fetches all SOS events from the backend.
  Future<void> loadEvents() async {
    debugPrint('[SosController] loadEvents called');
    isLoading.value = true;
    error.value = null;

    try {
      final result = await _repository.getSosEvents();
      events.assignAll(result);
      debugPrint(
        '[SosController] loadEvents — loaded ${result.length} events, '
        'active=$activeCount resolved=$resolvedCount '
        'falseAlarm=$falseAlarmCount',
      );
    } catch (e) {
      debugPrint('[SosController] loadEvents — ERROR: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      debugPrint('[SosController] loadEvents — isLoading=false');
    }
  }

  /// Updates the active filter tab (client-side).
  void setFilter(String filter) {
    debugPrint('[SosController] setFilter — "$filter"');
    selectedFilter.value = filter;
  }

  /// Resolves an event as `resolved` and refreshes the list.
  ///
  /// Returns `true` on success (the updated event is propagated into [events]).
  Future<bool> resolveEvent(int id) async {
    debugPrint('[SosController] resolveEvent called — id=$id');
    return _applyResolution(id, 'resolved');
  }

  /// Marks an event as a `false_alarm` and refreshes the list.
  ///
  /// Returns `true` on success (the updated event is propagated into [events]).
  Future<bool> markFalseAlarm(int id) async {
    debugPrint('[SosController] markFalseAlarm called — id=$id');
    return _applyResolution(id, 'false_alarm');
  }

  Future<bool> _applyResolution(int id, String status) async {
    isResolving.value = true;
    try {
      final updated = await _repository.resolveSosEvent(id, status);
      final index = events.indexWhere((e) => e.id == id);
      if (index != -1) {
        events[index] = updated;
        events.refresh();
      }
      debugPrint(
        '[SosController] _applyResolution — id=$id now status=${updated.status}',
      );
      Get.snackbar(
        status == 'resolved' ? 'Incident Resolved' : 'Marked as False Alarm',
        'SOS event #$id has been updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      debugPrint('[SosController] _applyResolution — ERROR: $e');
      Get.snackbar(
        'Update Failed',
        'Could not update the SOS event. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isResolving.value = false;
    }
  }
}
