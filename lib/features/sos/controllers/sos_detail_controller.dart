import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/sos_event.dart';
import '../repositories/sos_repository.dart';

/// Controller for the Admin SOS detail screen
/// ([EmergencySosDetailScreen]).
///
/// Loads a single SOS event from `GET /api/v1/emergency/sos/{id}/` and
/// exposes reactive state (loading / error / event). Supports resolving the
/// event or marking it as a false alarm via
/// `POST /api/v1/emergency/sos/{id}/resolve/`.
class SosDetailController extends GetxController {
  final SosRepository _repository;

  SosDetailController(this._repository);

  // ── State ──────────────────────────────────────────────────────────────
  final Rxn<SosEvent> event = Rxn<SosEvent>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  final RxBool isResolving = false.obs;
  final RxnString resolveError = RxnString();

  // ── Actions ─────────────────────────────────────────────────────────────
  /// Fetches the SOS event with [id] from `GET /emergency/sos/{id}/`.
  Future<void> loadEvent(int id) async {
    debugPrint('[SosDetailController] loadEvent called — id=$id');
    isLoading.value = true;
    error.value = null;

    try {
      final result = await _repository.getSosEvent(id);
      event.value = result;
      debugPrint(
        '[SosDetailController] loadEvent — loaded id=${result.id} '
        'patient="${result.patientName}" status=${result.status}',
      );
    } catch (e) {
      debugPrint('[SosDetailController] loadEvent — ERROR: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      debugPrint('[SosDetailController] loadEvent — isLoading=false');
    }
  }

  /// Resolves the event as `resolved`.
  ///
  /// Returns `true` on success (the updated event is propagated into [event]).
  Future<bool> resolveEvent(int id) {
    debugPrint('[SosDetailController] resolveEvent called — id=$id');
    return _applyResolution(id, 'resolved');
  }

  /// Marks the event as a `false_alarm`.
  ///
  /// Returns `true` on success (the updated event is propagated into [event]).
  Future<bool> markFalseAlarm(int id) {
    debugPrint('[SosDetailController] markFalseAlarm called — id=$id');
    return _applyResolution(id, 'false_alarm');
  }

  Future<bool> _applyResolution(int id, String status) async {
    isResolving.value = true;
    resolveError.value = null;
    try {
      final updated = await _repository.resolveSosEvent(id, status);
      event.value = updated;
      debugPrint(
        '[SosDetailController] _applyResolution — id=$id now '
        'status=${updated.status}',
      );
      Get.snackbar(
        status == 'resolved' ? 'Incident Resolved' : 'Marked as False Alarm',
        'SOS event #$id has been updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      debugPrint('[SosDetailController] _applyResolution — ERROR: $e');
      resolveError.value = e.toString();
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
