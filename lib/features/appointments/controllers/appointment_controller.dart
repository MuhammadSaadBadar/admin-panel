import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/network/api_error_mapper.dart';
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

  /// Currently selected tab: 0 = Upcoming, 1 = Unpaid, 2 = Past.
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
    } else if (selectedTabIndex.value == 1) {
      // Unpaid: non-cancelled appointments requiring payment that haven't been verified
      return appointments.where((a) {
        if (a.status == AppointmentStatus.cancelled) return false;
        return a.isUnpaid;
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
  ///
  /// The backend blocks `pending → confirmed` via `POST /status/` whenever the
  /// appointment has a payment that is not yet verified. When that is the
  /// case we route the call through `POST .../payment/confirm/`, which
  /// confirms both the payment and the appointment in one transaction.
  /// Only when the appointment is a free consultation (no payment) is the
  /// direct `/status/` call valid.
  Future<void> confirmAppointment(int appointmentId) async {
    debugPrint(
      '[AppointmentController] confirmAppointment — id=$appointmentId',
    );

    final cached = _findAppointment(appointmentId);
    final payment = cached?.payment;

    // No payment attached → free consultation. Use the direct status path.
    if (cached == null || cached.canConfirmFreely || payment == null) {
      debugPrint(
        '[AppointmentController] confirmAppointment — id=$appointmentId '
        'route=/status/ (free consultation or unknown)',
      );
      await _performStatusUpdate(
        appointmentId,
        const AppointmentStatusUpdateRequest(status: AppointmentStatus.confirmed),
      );
      return;
    }

    switch (payment.status) {
      case PaymentState.awaitingVerification:
        debugPrint(
          '[AppointmentController] confirmAppointment — id=$appointmentId '
          'route=/payment/confirm/ (awaiting verification)',
        );
        await verifyPayment(appointmentId);
        return;
      case PaymentState.verified:
        Get.snackbar(
          'Already Confirmed',
          'This appointment is already confirmed.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      case PaymentState.pending:
        Get.snackbar(
          'Awaiting Patient Payment',
          'The patient must tap "I Have Paid" first. Open the appointment '
          'and use "Verify Payment & Confirm" in the Payment section.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      case PaymentState.rejected:
        Get.snackbar(
          'Payment Rejected',
          'This payment was rejected. Ask the patient to resend and tap '
          '"I Have Paid" again before you can confirm.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      case PaymentState.none:
        await _performStatusUpdate(
          appointmentId,
          const AppointmentStatusUpdateRequest(
            status: AppointmentStatus.confirmed,
          ),
        );
        return;
    }
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

  /// Admin double-verifies the consultation fee was received. Sets the
  /// payment status to `verified` and the appointment status to `confirmed`
  /// in a single backend call.
  Future<void> verifyPayment(int appointmentId, {String? paymentReference}) async {
    debugPrint(
      '[AppointmentController] verifyPayment — id=$appointmentId',
    );
    final cached = _findAppointment(appointmentId);
    if (cached != null && !cached.canVerifyPayment) {
      debugPrint(
        '[AppointmentController] verifyPayment — not allowed '
        '(state=${cached.payment?.status.name ?? 'none'})',
      );
      return;
    }
    isProcessingAction.value = true;
    try {
      final updated = await _repository.verifyPayment(
        appointmentId,
        paymentReference: paymentReference,
      );
      _replaceAppointmentInList(updated);
      debugPrint(
        '[AppointmentController] verifyPayment — success id=${updated.id} '
        'paymentState=${updated.payment?.status.displayLabel} '
        'apptStatus=${updated.status.displayLabel}',
      );
      Get.snackbar(
        'Payment Verified',
        'Payment received and appointment confirmed.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } on DioException catch (e) {
      final apiException = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Could not verify payment.',
      );
      debugPrint('[AppointmentController] verifyPayment — ERROR: $e');
      debugPrint(
        '[AppointmentController] verifyPayment — raw body=${e.response?.data}',
      );
      Get.snackbar(
        'Error',
        apiException.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('[AppointmentController] verifyPayment — unexpected ERROR: $e');
      Get.snackbar(
        'Error',
        'Could not verify payment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isProcessingAction.value = false;
    }
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
    } on DioException catch (e) {
      final apiException = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Could not reschedule.',
      );
      debugPrint('[AppointmentController] rescheduleAppointment — ERROR: $e');
      debugPrint(
        '[AppointmentController] rescheduleAppointment — raw body=${e.response?.data}',
      );
      Get.snackbar(
        'Error',
        apiException.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint(
        '[AppointmentController] rescheduleAppointment — unexpected ERROR: $e',
      );
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
    } on DioException catch (e) {
      final apiException = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Could not save notes.',
      );
      debugPrint('[AppointmentController] updateDoctorNotes — ERROR: $e');
      debugPrint(
        '[AppointmentController] updateDoctorNotes — raw body=${e.response?.data}',
      );
      Get.snackbar(
        'Error',
        apiException.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint(
        '[AppointmentController] updateDoctorNotes — unexpected ERROR: $e',
      );
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
    } on DioException catch (e) {
      debugPrint('[AppointmentController] Status update ERROR: $e');
      debugPrint(
        '[AppointmentController] Status update raw body=${e.response?.data}',
      );

      // Intercept the backend's payment-not-verified 400.
      if (request.status == AppointmentStatus.confirmed &&
          e.response?.statusCode == 400) {
        final cached = _findAppointment(appointmentId);
        if (cached != null && cached.isUnpaid) {
          final paymentState = cached.payment?.status ?? PaymentState.none;
          final String title;
          final String msg;
          switch (paymentState) {
            case PaymentState.pending:
              title = 'Awaiting Patient Payment';
              msg = 'The patient has not yet submitted payment. This appointment '
                  'cannot be confirmed until the fee is paid and verified.';
              break;
            case PaymentState.awaitingVerification:
              title = 'Payment Awaiting Verification';
              msg = 'The patient has submitted payment. Please verify it in '
                  'the appointment details to confirm.';
              break;
            case PaymentState.rejected:
              title = 'Payment Rejected';
              msg = 'The payment was rejected. The patient must resubmit '
                  'before this appointment can be confirmed.';
              break;
            default:
              title = 'Payment Not Verified';
              msg = 'The consultation fee has not been verified. Please verify '
                  'the payment before confirming.';
          }
          Get.snackbar(
            title,
            msg,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 6),
          );
          return;
        }
      }

      final apiException = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Could not update status.',
      );
      Get.snackbar(
        'Error',
        apiException.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('[AppointmentController] Status update unexpected ERROR: $e');
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

  /// Returns the appointment with [id] from the in-memory list, or null if
  /// it is not cached (e.g. the user opened a deep-link and went straight to
  /// the details screen without ever listing).
  Appointment? _findAppointment(int id) {
    final index = appointments.indexWhere((a) => a.id == id);
    return index == -1 ? null : appointments[index];
  }

  /// Merge an externally-produced appointment (e.g. one returned from the
  /// details screen via `Get.back(result:)`) into the cached list. Used to
  /// keep the dashboard in sync with mutations made on the detail screen
  /// without triggering a full list refresh.
  void applyExternalUpdate(Appointment updated) {
    debugPrint(
      '[AppointmentController] applyExternalUpdate — id=${updated.id} '
      'status=${updated.status.displayLabel} '
      'payment=${updated.payment?.status.displayLabel ?? 'none'}',
    );
    _replaceAppointmentInList(updated);
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
