import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

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

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Loads a single appointment by [id].
  Future<void> loadAppointment(int id) async {
    isLoading.value = true;
    error.value = null;
    debugPrint('[AppointmentDetailController] loadAppointment — id=$id');
    try {
      final result = await _repository.getAppointment(id);
      appointment.value = result;
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
    debugPrint(
      '[AppointmentDetailController] confirmAppointment — id=${current.id}',
    );
    await _performStatusUpdate(
      const AppointmentStatusUpdateRequest(status: AppointmentStatus.confirmed),
    );
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
    } catch (e) {
      debugPrint(
        '[AppointmentDetailController] rescheduleAppointment — ERROR: $e',
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
    } catch (e) {
      debugPrint('[AppointmentDetailController] updateDoctorNotes — ERROR: $e');
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
    } catch (e) {
      debugPrint('[AppointmentDetailController] markPaid — ERROR: $e');
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
    } catch (e) {
      debugPrint('[AppointmentDetailController] verifyPayment — ERROR: $e');
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
    } catch (e) {
      debugPrint('[AppointmentDetailController] Status update ERROR: $e');
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
