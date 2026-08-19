import 'package:admin/core/network/api_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/medicine_reminder.dart';
import '../repositories/patient_repository.dart';

/// Controller for the Medication Management module.
///
/// Manages:
/// - `GET /api/v1/medicines/reminders/?patient_id=` — list reminders
/// - `POST /api/v1/medicines/reminders/` — create reminder
/// - `PATCH /api/v1/medicines/reminders/{id}/` — update reminder
/// - `DELETE /api/v1/medicines/reminders/{id}/` — delete reminder
/// - `GET /api/v1/medicines/intake-logs/?patient_id=` — list intake logs
///
/// Follows the same reactive pattern as [DietPlanController].
class MedicationController extends GetxController {
  final PatientRepository _repository;

  MedicationController(this._repository);

  // ── State ──────────────────────────────────────────────────────────────
  final RxList<MedicineReminder> reminders = <MedicineReminder>[].obs;
  final RxList<MedicineIntakeLog> intakeLogs = <MedicineIntakeLog>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSaving = false.obs;
  final RxnString error = RxnString();

  int _patientId = 0;

  // ── Initialiser ────────────────────────────────────────────────────────
  /// Sets the target patient ID and loads reminders + logs.
  Future<void> load(int patientId) async {
    _patientId = patientId;
    debugPrint('[MedicationController] load called — patientId=$patientId');
    isLoading.value = true;
    error.value = null;

    try {
      final results = await Future.wait<Object?>([
        _repository.getMedicineReminders(patientId),
        _repository.getMedicineIntakeLogs(patientId),
      ]);
      reminders.assignAll(results[0] as List<MedicineReminder>);
      intakeLogs.assignAll(results[1] as List<MedicineIntakeLog>);
      debugPrint(
        '[MedicationController] load — ${reminders.length} reminders, '
        '${intakeLogs.length} intake logs',
      );
    } catch (e) {
      debugPrint('[MedicationController] load — ERROR: $e');
      error.value = _errorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Pull-to-refresh without flipping the full-screen loading state.
  Future<void> refresh() async {
    if (_patientId <= 0) return;
    debugPrint('[MedicationController] refresh called');
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    try {
      final results = await Future.wait<Object?>([
        _repository.getMedicineReminders(_patientId),
        _repository.getMedicineIntakeLogs(_patientId),
      ]);
      reminders.assignAll(results[0] as List<MedicineReminder>);
      intakeLogs.assignAll(results[1] as List<MedicineIntakeLog>);
      error.value = null;
      debugPrint(
        '[MedicationController] refresh — ${reminders.length} reminders, '
        '${intakeLogs.length} logs',
      );
    } catch (e) {
      debugPrint('[MedicationController] refresh — ERROR: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  // ── Reminder CRUD ──────────────────────────────────────────────────────

  /// Creates a new medicine reminder. Returns the created [MedicineReminder]
  /// on success, or `null` on failure.
  Future<MedicineReminder?> createReminder(
    MedicineReminderRequest request,
  ) async {
    debugPrint('[MedicationController] createReminder called');
    isSaving.value = true;
    try {
      final reminder = await _repository.createMedicineReminder(request);
      reminders.insert(0, reminder);
      debugPrint(
        '[MedicationController] createReminder — success id=${reminder.id}',
      );
      Get.snackbar(
        'Reminder created',
        '${reminder.medicineName} — ${reminder.dosage}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return reminder;
    } catch (e) {
      debugPrint('[MedicationController] createReminder — ERROR: $e');
      _showError('Unable to create the reminder.', e);
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  /// Updates an existing reminder. Returns the updated [MedicineReminder] on
  /// success, or `null` on failure.
  Future<MedicineReminder?> updateReminder(
    int id,
    MedicineReminderRequest request,
  ) async {
    debugPrint('[MedicationController] updateReminder called — id=$id');
    isSaving.value = true;
    try {
      final reminder = await _repository.updateMedicineReminder(id, request);
      final index = reminders.indexWhere((r) => r.id == id);
      if (index != -1) reminders[index] = reminder;
      debugPrint(
        '[MedicationController] updateReminder — success id=${reminder.id}',
      );
      Get.snackbar(
        'Reminder updated',
        '${reminder.medicineName} — ${reminder.dosage}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return reminder;
    } catch (e) {
      debugPrint('[MedicationController] updateReminder — ERROR: $e');
      _showError('Unable to update the reminder.', e);
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  /// Toggles the active state of a reminder. Returns the updated reminder.
  Future<MedicineReminder?> toggleActive(int id, bool isActive) async {
    debugPrint(
      '[MedicationController] toggleActive — id=$id isActive=$isActive',
    );
    try {
      final reminder = await _repository.setReminderActive(id, isActive);
      final index = reminders.indexWhere((r) => r.id == id);
      if (index != -1) reminders[index] = reminder;
      debugPrint(
        '[MedicationController] toggleActive — success id=${reminder.id} '
        'isActive=${reminder.isActive}',
      );
      return reminder;
    } catch (e) {
      debugPrint('[MedicationController] toggleActive — ERROR: $e');
      _showError('Unable to update the reminder status.', e);
      return null;
    }
  }

  /// Deletes a reminder. Returns `true` on success.
  Future<bool> deleteReminder(int id) async {
    debugPrint('[MedicationController] deleteReminder called — id=$id');
    try {
      await _repository.deleteMedicineReminder(id);
      reminders.removeWhere((r) => r.id == id);
      debugPrint('[MedicationController] deleteReminder — success id=$id');
      Get.snackbar(
        'Reminder deleted',
        'The reminder has been removed.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      debugPrint('[MedicationController] deleteReminder — ERROR: $e');
      _showError('Unable to delete the reminder.', e);
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void _showError(String message, Object error) {
    final detail = error is ApiException ? error.message : error.toString();
    Get.snackbar(
      message,
      detail,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  static String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }
}
