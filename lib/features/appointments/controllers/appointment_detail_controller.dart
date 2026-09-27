import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/network/api_error_mapper.dart';
import '../models/appointment.dart';
import '../models/payment_methods.dart';
import '../repositories/appointment_repository.dart';

/// Controller for the Appointment Details screen.
///
/// Fetches a single appointment by id and exposes the per-appointment
/// actions (status updates, reschedule, doctor notes). It reuses the
/// [AppointmentRepository] so no business logic is duplicated between the
/// Dashboard and Details screens.
class AppointmentDetailController extends GetxController {
  final AppointmentRepository _repository;

  AppointmentDetailController(this._repository);

  // ── State ──────────────────────────────────────────────────────────────
  final Rxn<Appointment> appointment = Rxn<Appointment>();
  final RxBool isLoading = false.obs;
  final RxBool isProcessingAction = false.obs;
  final RxnString error = RxnString();
  final Rxn<PlatformPaymentMethods> paymentMethods =
      Rxn<PlatformPaymentMethods>();
  final RxBool isPaymentMethodsLoading = false.obs;

  /// True once [loadAppointment] has resolved successfully at least once.
  /// Used by callers (e.g. the detail screen) to ignore the *first*
  /// emission from the worker and only react to subsequent mutations.
  bool hasLoadedOnce = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Loads a single appointment by [id].
  Future<void> loadAppointment(int id) async {
    isLoading.value = true;
    error.value = null;
    debugPrint('[AppointmentDetailController] loadAppointment — id=$id');
    try {
      final result = await _repository.getAppointment(id);
      appointment.value = result;
      hasLoadedOnce = true;
      debugPrint(
        '[AppointmentDetailController] loadAppointment — success id=${result.id} '
        'patient=${result.patient.fullName} status=${result.status.displayLabel}',
      );
    } catch (e) {
      debugPrint('[AppointmentDetailController] loadAppointment — ERROR: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> confirmAppointment() async {
    final current = appointment.value;
    if (current == null) {
      debugPrint(
        '[AppointmentDetailController] confirmAppointment — no appointment loaded',
      );
      return;
    }

    // No payment attached → free consultation. The backend accepts
    // `pending → confirmed` via `POST /appointments/{id}/status/`.
    if (current.canConfirmFreely) {
      debugPrint(
        '[AppointmentDetailController] confirmAppointment — id=${current.id} '
        '(free consultation, going through /status/)',
      );
      await _performStatusUpdate(
        const AppointmentStatusUpdateRequest(status: AppointmentStatus.confirmed),
      );
      return;
    }

    // Payment attached → the backend blocks `pending → confirmed` on
    // `/status/`. We must route through `POST .../payment/confirm/`, which
    // confirms the payment AND the appointment in one call.
    final payment = current.payment;
    if (payment == null) {
      // Defensive: should be unreachable because canConfirmFreely == false.
      return;
    }
    switch (payment.status) {
      case PaymentState.awaitingVerification:
        debugPrint(
          '[AppointmentDetailController] confirmAppointment — id=${current.id} '
          '(payment awaiting verification, routing to verifyPayment)',
        );
        await verifyPayment();
        return;
      case PaymentState.verified:
        debugPrint(
          '[AppointmentDetailController] confirmAppointment — id=${current.id} '
          '(payment already verified, appointment already confirmed)',
        );
        Get.snackbar(
          'Already Confirmed',
          'This appointment is already confirmed.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      case PaymentState.pending:
        debugPrint(
          '[AppointmentDetailController] confirmAppointment — id=${current.id} '
          '(payment not yet marked paid)',
        );
        Get.snackbar(
          'Awaiting Patient Payment',
          'The patient must tap "I Have Paid" first. '
          'Then use "Verify Payment & Confirm" in the Payment section.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      case PaymentState.rejected:
        debugPrint(
          '[AppointmentDetailController] confirmAppointment — id=${current.id} '
          '(payment was rejected)',
        );
        Get.snackbar(
          'Payment Rejected',
          'This payment was rejected. Ask the patient to resend and tap '
          '"I Have Paid" again before you can confirm.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      case PaymentState.none:
        // Treated as free consultation (same as payment == null).
        await _performStatusUpdate(
          const AppointmentStatusUpdateRequest(
            status: AppointmentStatus.confirmed,
          ),
        );
        return;
    }
  }

  /// Cancels the appointment with an optional reason.
  Future<void> cancelAppointment({String? reason}) async {
    final current = appointment.value;
    if (current == null) {
      debugPrint(
        '[AppointmentDetailController] cancelAppointment — no appointment loaded',
      );
      return;
    }
    debugPrint(
      '[AppointmentDetailController] cancelAppointment — id=${current.id} reason=$reason',
    );
    await _performStatusUpdate(
      AppointmentStatusUpdateRequest(
        status: AppointmentStatus.cancelled,
        cancellationReason: reason,
      ),
    );
  }

  Future<void> completeAppointment() async {
    final current = appointment.value;
    if (current == null) {
      debugPrint(
        '[AppointmentDetailController] completeAppointment — no appointment loaded',
      );
      return;
    }
    debugPrint(
      '[AppointmentDetailController] completeAppointment — id=${current.id}',
    );
    await _performStatusUpdate(
      const AppointmentStatusUpdateRequest(status: AppointmentStatus.completed),
    );
  }

  Future<void> markNoShow() async {
    final current = appointment.value;
    if (current == null) {
      debugPrint(
        '[AppointmentDetailController] markNoShow — no appointment loaded',
      );
      return;
    }
    debugPrint('[AppointmentDetailController] markNoShow — id=${current.id}');
    await _performStatusUpdate(
      const AppointmentStatusUpdateRequest(status: AppointmentStatus.noShow),
    );
  }

  /// Reschedules the appointment to [newDateTime].
  Future<void> rescheduleAppointment(
    DateTime newDateTime, {
    int? durationMinutes,
  }) async {
    final current = appointment.value;
    if (current == null) {
      debugPrint(
        '[AppointmentDetailController] rescheduleAppointment — no appointment loaded',
      );
      return;
    }
    debugPrint(
      '[AppointmentDetailController] rescheduleAppointment — id=${current.id} '
      'newDate=$newDateTime duration=$durationMinutes',
    );

    isProcessingAction.value = true;
    try {
      final updated = await _repository.rescheduleAppointment(
        current.id,
        AppointmentRescheduleRequest(
          scheduledAt: newDateTime,
          durationMinutes: durationMinutes,
        ),
      );
      appointment.value = updated;
      debugPrint(
        '[AppointmentDetailController] rescheduleAppointment — success id=${updated.id} '
        'scheduled=${updated.scheduledAt}',
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
      debugPrint(
        '[AppointmentDetailController] rescheduleAppointment — ERROR: $e',
      );
      debugPrint(
        '[AppointmentDetailController] rescheduleAppointment — raw body=${e.response?.data}',
      );
      Get.snackbar(
        'Error',
        apiException.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint(
        '[AppointmentDetailController] rescheduleAppointment — unexpected ERROR: $e',
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

  /// Updates the doctor consultation notes (fully replaced).
  Future<void> updateDoctorNotes(String notes) async {
    final current = appointment.value;
    if (current == null) {
      debugPrint(
        '[AppointmentDetailController] updateDoctorNotes — no appointment loaded',
      );
      return;
    }
    debugPrint(
      '[AppointmentDetailController] updateDoctorNotes — id=${current.id}',
    );
    isProcessingAction.value = true;
    try {
      final updated = await _repository.setDoctorNotes(current.id, notes);
      appointment.value = updated;
      debugPrint(
        '[AppointmentDetailController] updateDoctorNotes — success id=${updated.id}',
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
      debugPrint('[AppointmentDetailController] updateDoctorNotes — ERROR: $e');
      debugPrint(
        '[AppointmentDetailController] updateDoctorNotes — raw body=${e.response?.data}',
      );
      Get.snackbar(
        'Error',
        apiException.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint(
        '[AppointmentDetailController] updateDoctorNotes — unexpected ERROR: $e',
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

  // ── Payment workflow ──────────────────────────────────────────────────

  /// Loads the platform's configured payment methods (dynamic, never hardcoded).
  Future<void> loadPaymentMethods() async {
    if (isPaymentMethodsLoading.value) return;
    isPaymentMethodsLoading.value = true;
    debugPrint('[AppointmentDetailController] loadPaymentMethods called');
    try {
      final methods = await _repository.getPaymentMethods();
      paymentMethods.value = methods;
      debugPrint(
        '[AppointmentDetailController] loadPaymentMethods — success '
        'hasAny=${methods.hasAnyMethod} price=${methods.subscriptionPriceAmount}',
      );
    } catch (e) {
      debugPrint(
        '[AppointmentDetailController] loadPaymentMethods — ERROR: $e',
      );
    } finally {
      isPaymentMethodsLoading.value = false;
    }
  }

  /// Patient marks this appointment as paid (step 1 of the manual flow).
  ///
  /// Only allowed when the backend payment state is pending/rejected. After a
  /// successful call the appointment's payment enters "awaiting verification".
  Future<void> markPaid() async {
    final current = appointment.value;
    if (current == null || !current.patientCanMarkPaid) {
      debugPrint(
        '[AppointmentDetailController] markPaid — not allowed '
        '(state=${current?.payment?.status.name ?? 'none'})',
      );
      return;
    }
    isProcessingAction.value = true;
    debugPrint('[AppointmentDetailController] markPaid — id=${current.id}');
    try {
      final updated = await _repository.markPaid(current.id);
      appointment.value = updated;
      debugPrint(
        '[AppointmentDetailController] markPaid — success id=${updated.id} '
        'paymentState=${updated.payment?.status.displayLabel}',
      );
      Get.snackbar(
        'Payment Recorded',
        'Your payment is now awaiting verification.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } on DioException catch (e) {
      final apiException = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Could not record payment.',
      );
      debugPrint('[AppointmentDetailController] markPaid — ERROR: $e');
      debugPrint(
        '[AppointmentDetailController] markPaid — raw body=${e.response?.data}',
      );
      Get.snackbar(
        'Error',
        apiException.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint(
        '[AppointmentDetailController] markPaid — unexpected ERROR: $e',
      );
      Get.snackbar(
        'Error',
        'Could not record payment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isProcessingAction.value = false;
    }
  }

  /// Doctor/admin verifies the claimed payment was received (step 2).
  ///
  /// This confirms both the payment and the appointment in a single backend
  /// call. Only allowed when the payment is awaiting verification.
  Future<void> verifyPayment({String? paymentReference}) async {
    final current = appointment.value;
    if (current == null || !current.canVerifyPayment) {
      debugPrint(
        '[AppointmentDetailController] verifyPayment — not allowed '
        '(state=${current?.payment?.status.name ?? 'none'})',
      );
      return;
    }
    isProcessingAction.value = true;
    debugPrint(
      '[AppointmentDetailController] verifyPayment — id=${current.id}',
    );
    try {
      final updated = await _repository.verifyPayment(
        current.id,
        paymentReference: paymentReference,
      );
      appointment.value = updated;
      debugPrint(
        '[AppointmentDetailController] verifyPayment — success id=${updated.id} '
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
      debugPrint('[AppointmentDetailController] verifyPayment — ERROR: $e');
      debugPrint(
        '[AppointmentDetailController] verifyPayment — raw body=${e.response?.data}',
      );
      Get.snackbar(
        'Error',
        apiException.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint(
        '[AppointmentDetailController] verifyPayment — unexpected ERROR: $e',
      );
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

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<void> _performStatusUpdate(
    AppointmentStatusUpdateRequest request,
  ) async {
    final current = appointment.value;
    if (current == null) return;

    isProcessingAction.value = true;
    try {
      final updated = await _repository.updateAppointmentStatus(
        current.id,
        request,
      );
      appointment.value = updated;
      debugPrint(
        '[AppointmentDetailController] Status update success — id=${updated.id} '
        'status=${updated.status.displayLabel}',
      );
      Get.snackbar(
        'Status Updated',
        'Appointment is now ${updated.status.displayLabel}.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } on DioException catch (e) {
      debugPrint('[AppointmentDetailController] Status update ERROR: $e');
      debugPrint(
        '[AppointmentDetailController] Status update raw body=${e.response?.data}',
      );

      // Detect the backend's payment-verification block:
      //   POST /appointments/{id}/status/ returns 400 when the appointment
      //   has a payment that isn't yet confirmed and the requested transition
      //   is pending -> confirmed. Surface a meaningful message instead of a
      //   generic server error.
      if (request.status == AppointmentStatus.confirmed &&
          e.response?.statusCode == 400 &&
          current.isUnpaid) {
        final paymentState = current.payment?.status ?? PaymentState.none;
        final String title;
        final String msg;
        switch (paymentState) {
          case PaymentState.pending:
            title = 'Awaiting Patient Payment';
            msg = 'The patient has not yet submitted payment for this '
                'consultation. This appointment cannot be confirmed until '
                'the patient marks the fee as paid and you verify it.';
            break;
          case PaymentState.awaitingVerification:
            title = 'Payment Awaiting Verification';
            msg = 'The patient has submitted payment but it has not been '
                'verified yet. Use "Verify Payment & Confirm" in the '
                'Payment section to confirm this appointment.';
            break;
          case PaymentState.rejected:
            title = 'Payment Rejected';
            msg = 'This payment was rejected. The patient must resubmit '
                'payment before this appointment can be confirmed.';
            break;
          default:
            title = 'Payment Not Verified';
            msg = 'The consultation fee has not been verified. Please verify '
                'the payment before confirming this appointment.';
        }
        debugPrint(
          '[AppointmentDetailController] Status update blocked by unverified '
          'payment — paymentState=${paymentState.name}',
        );
        Get.snackbar(
          title,
          msg,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 6),
        );
        return;
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
      debugPrint(
        '[AppointmentDetailController] Status update unexpected ERROR: $e',
      );
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
}
