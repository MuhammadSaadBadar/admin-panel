import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/appointment.dart';
import '../repositories/appointment_repository.dart';

/// Controller for the Appointments Dashboard + Appointment Details screens.
///
/// Manages the paginated appointment list with "Upcoming" / "Past" tab
/// filtering, and provides methods for status transitions, rescheduling,
/// and doctor notes on individual appointments.
class AppointmentController extends GetxController {
  final AppointmentRepository _repository;

  AppointmentController(this._repository);

  // ── State ──────────────────────────────────────────────────────────────
  final RxList<Appointment> appointments = <Appointment>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnString error = RxnString();
  final RxBool isProcessingAction = false.obs;

  /// Currently selected tab: 0 = Upcoming, 1 = Past.
  final RxInt selectedTabIndex = 0.obs;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  final int _pageSize = 20;

  bool get hasMore => _hasMore;

  // ── Computed ───────────────────────────────────────────────────────────

  /// Appointments filtered by the selected tab.
  List<Appointment> get filteredAppointments {
    final now = DateTime.now();
    if (selectedTabIndex.value == 0) {
      // Upcoming: non-terminal statuses + scheduled in the future
      return appointments.where((a) {
        if (a.status.isTerminal) return false;
        final scheduled = a.scheduledAt;
        return scheduled == null || scheduled.isAfter(now);
      }).toList();
    } else {
      // Past: terminal statuses OR past the scheduled time
      return appointments.where((a) {
        if (a.status.isTerminal) return true;
        final scheduled = a.scheduledAt;
        return scheduled != null && !scheduled.isAfter(now);
      }).toList();
    }
  }

  /// The full list is always kept so switching tabs does not require a
  /// re-fetch. This getter shows/hides the empty-state message per tab.
  bool get hasAppointmentsInCurrentTab => filteredAppointments.isNotEmpty;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    debugPrint('[AppointmentController] onInit — loading appointments');
    loadAppointments();
  }

  // ── Tab Switching ──────────────────────────────────────────────────────

  void switchTab(int index) {
    debugPrint('[AppointmentController] switchTab — index=$index');
    selectedTabIndex.value = index;
  }

  // ── Data Loading ───────────────────────────────────────────────────────

  Future<void> loadAppointments() async {
    isLoading.value = true;
    error.value = null;
    _currentPage = 1;
    _hasMore = true;

    debugPrint('[AppointmentController] loadAppointments — page=$_currentPage');

    try {
      final paginated = await _repository.getAppointments(
        page: _currentPage,
        pageSize: _pageSize,
      );
      appointments.assignAll(paginated.results);
      _hasMore = paginated.next != null;
      debugPrint(
        '[AppointmentController] loadAppointments — loaded ${paginated.results.length} '
        'total=${paginated.count} hasMore=$_hasMore',
      );
    } catch (e) {
      debugPrint('[AppointmentController] loadAppointments — ERROR: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreAppointments() async {
    if (isLoading.value || isLoadingMore.value || !_hasMore) return;

    isLoadingMore.value = true;
    _currentPage++;

    debugPrint(
      '[AppointmentController] loadMoreAppointments — page=$_currentPage',
    );

    try {
      final paginated = await _repository.getAppointments(
        page: _currentPage,
        pageSize: _pageSize,
      );
      appointments.addAll(paginated.results);
      _hasMore = paginated.next != null;
      debugPrint(
        '[AppointmentController] loadMoreAppointments — appended ${paginated.results.length} '
        'hasMore=$_hasMore',
      );
    } catch (e) {
      debugPrint('[AppointmentController] loadMoreAppointments — ERROR: $e');
      // Retry this page
      _currentPage--;
      error.value = e.toString();
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────

  /// Confirm an appointment (`pending -> confirmed`).
  Future<void> confirmAppointment(int appointmentId) async {
    debugPrint(
      '[AppointmentController] confirmAppointment — id=$appointmentId',
    );
    await _performStatusUpdate(
      appointmentId,
      const AppointmentStatusUpdateRequest(status: AppointmentStatus.confirmed),
    );
  }

  /// Cancel an appointment with an optional reason.
  Future<void> cancelAppointment(int appointmentId, {String? reason}) async {
    debugPrint(
      '[AppointmentController] cancelAppointment — id=$appointmentId reason=$reason',
    );
    await _performStatusUpdate(
      appointmentId,
      AppointmentStatusUpdateRequest(
        status: AppointmentStatus.cancelled,
        cancellationReason: reason,
      ),
    );
  }

  /// Mark an appointment as completed.
  Future<void> completeAppointment(int appointmentId) async {
    debugPrint(
      '[AppointmentController] completeAppointment — id=$appointmentId',
    );
    await _performStatusUpdate(
      appointmentId,
      const AppointmentStatusUpdateRequest(status: AppointmentStatus.completed),
    );
  }

  /// Mark a patient as no-show.
  Future<void> markNoShow(int appointmentId) async {
    debugPrint('[AppointmentController] markNoShow — id=$appointmentId');
    await _performStatusUpdate(
      appointmentId,
      const AppointmentStatusUpdateRequest(status: AppointmentStatus.noShow),
    );
  }

  /// Reschedule an appointment.
  Future<void> rescheduleAppointment(
    int appointmentId,
    DateTime newDateTime, {
    int? durationMinutes,
  }) async {
    debugPrint(
      '[AppointmentController] rescheduleAppointment — id=$appointmentId '
      'newDate=$newDateTime duration=$durationMinutes',
    );

    isProcessingAction.value = true;
    try {
      final updated = await _repository.rescheduleAppointment(
        appointmentId,
        AppointmentRescheduleRequest(
          scheduledAt: newDateTime,
          durationMinutes: durationMinutes,
        ),
      );
      _replaceAppointmentInList(updated);
      debugPrint(
        '[AppointmentController] rescheduleAppointment — success id=${updated.id}',
      );
      Get.snackbar(
        'Rescheduled',
        'Appointment has been rescheduled.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('[AppointmentController] rescheduleAppointment — ERROR: $e');
      Get.snackbar(
        'Error',
        'Could not reschedule. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isProcessingAction.value = false;
    }
  }

  /// Update the doctor notes for an appointment.
  Future<void> updateDoctorNotes(int appointmentId, String notes) async {
    debugPrint('[AppointmentController] updateDoctorNotes — id=$appointmentId');
    isProcessingAction.value = true;
    try {
      final updated = await _repository.setDoctorNotes(appointmentId, notes);
      _replaceAppointmentInList(updated);
      debugPrint(
        '[AppointmentController] updateDoctorNotes — success id=${updated.id}',
      );
      Get.snackbar(
        'Saved',
        'Doctor notes have been updated.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('[AppointmentController] updateDoctorNotes — ERROR: $e');
      Get.snackbar(
        'Error',
        'Could not save notes. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isProcessingAction.value = false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<void> _performStatusUpdate(
    int appointmentId,
    AppointmentStatusUpdateRequest request,
  ) async {
    isProcessingAction.value = true;
    try {
      final updated = await _repository.updateAppointmentStatus(
        appointmentId,
        request,
      );
      _replaceAppointmentInList(updated);
      debugPrint(
        '[AppointmentController] Status update success — id=${updated.id} '
        'status=${updated.status.displayLabel}',
      );
      Get.snackbar(
        'Status Updated',
        'Appointment is now ${updated.status.displayLabel}.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('[AppointmentController] Status update ERROR: $e');
      Get.snackbar(
        'Error',
        'Could not update status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isProcessingAction.value = false;
    }
  }

  /// Finds and replaces the appointment at the same index in [appointments],
  /// preserving list identity so RxList observers react to the change.
  void _replaceAppointmentInList(Appointment updated) {
    final index = appointments.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      appointments[index] = updated;
      appointments.refresh();
    } else {
      // If not found (e.g. fetched from detailed endpoint), prepend it
      appointments.insert(0, updated);
    }
  }
}
