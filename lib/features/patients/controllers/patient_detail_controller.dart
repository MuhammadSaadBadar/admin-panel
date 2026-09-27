import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/baby_size.dart';
import '../models/patient.dart';
import '../models/patient_summary.dart';
import '../models/sos_event.dart';
import '../repositories/patient_repository.dart';

class PatientDetailController extends GetxController {
  final PatientRepository _repository;

  PatientDetailController(this._repository);

  final Rxn<Patient> patient = Rxn<Patient>();
  final Rxn<PatientSummary> patientSummary = Rxn<PatientSummary>();
  final RxList<SosEvent> sosHistory = <SosEvent>[].obs;
  final Rxn<BabySizeReference> babySize = Rxn<BabySizeReference>();
  final RxList<dynamic> bloodPressureHistory = <dynamic>[].obs;
  final RxList<dynamic> bloodSugarHistory = <dynamic>[].obs;

  final RxBool isLoadingPatient = false.obs;
  final RxBool isLoadingSummary = false.obs;
  final RxBool isLoadingSos = false.obs;
  final RxBool isLoadingBabySize = false.obs;
  final RxBool isUpdatingStatus = false.obs;

  final RxnString patientError = RxnString();
  final RxnString summaryError = RxnString();
  final RxnString sosError = RxnString();
  final RxnString babySizeError = RxnString();
  final RxnString statusUpdateError = RxnString();

  Future<void> loadPatient(int id) async {
    isLoadingPatient.value = true;
    patientError.value = null;
    try {
      debugPrint(
        '[PatientDetailController] Fetching patient details for ID: $id',
      );
      final result = await _repository.getPatient(id);
      patient.value = result;
    } catch (e) {
      debugPrint(
        '[PatientDetailController] Error fetching patient details: $e',
      );
      patientError.value = e.toString();
    } finally {
      isLoadingPatient.value = false;
    }
  }

  Future<void> loadPatientSummary(int id) async {
    isLoadingSummary.value = true;
    summaryError.value = null;
    try {
      debugPrint(
        '[PatientDetailController] Fetching patient summary for ID: $id',
      );
      final result = await _repository.getPatientSummary(id);
      patientSummary.value = result;
    } catch (e) {
      debugPrint(
        '[PatientDetailController] Error fetching patient summary: $e',
      );
      summaryError.value = e.toString();
    } finally {
      isLoadingSummary.value = false;
    }
  }

  Future<void> loadAllData(int id) async {
    // Patient + summary must load first — baby-size lookup depends on
    // pregnancyProgress from the summary (currentWeek). SOS + blood
    // trackers are independent and load concurrently after.
    await loadPatient(id);
    await loadPatientSummary(id);
    await Future.wait([
      loadSosHistory(id),
      loadBabySizeForPatient(id),
      loadBloodPressureHistory(id),
      loadBloodSugarHistory(id),
    ]);
  }

  Future<void> loadSosHistory(int id) async {
    isLoadingSos.value = true;
    sosError.value = null;
    try {
      debugPrint('[PatientDetailController] Fetching SOS history for ID: $id');
      final result = await _repository.getSosHistory(id);
      sosHistory.assignAll(result);
      debugPrint(
        '[PatientDetailController] SOS history loaded — ${result.length} events',
      );
    } catch (e) {
      debugPrint('[PatientDetailController] Error fetching SOS history: $e');
      sosError.value = e.toString();
    } finally {
      isLoadingSos.value = false;
    }
  }

  /// Loads the baby-size reference for the patient's current gestational week
  /// (from the summary), if available.
  Future<void> loadBabySizeForPatient(int id) async {
    final week = patientSummary.value?.pregnancyProgress?.currentWeek;
    if (week == null) {
      debugPrint(
        '[PatientDetailController] No current week available — skipping baby-size. patientSummary: ${patientSummary.value}, pregnancyProgress: ${patientSummary.value?.pregnancyProgress}',
      );
      return;
    }

    isLoadingBabySize.value = true;
    babySizeError.value = null;
    try {
      debugPrint(
        '[PatientDetailController] Fetching baby-size for week: $week',
      );
      final result = await _repository.getBabySize(week);
      debugPrint(
        '[PatientDetailController] Baby-size API response received: week=${result.week}, comparison="${result.sizeComparison}", length="${result.lengthCm}", weight="${result.weightGrams}", description="${result.description}"',
      );
      babySize.value = result;
      debugPrint(
        '[PatientDetailController] Baby-size loaded — week=${result.week} '
        'comparison="${result.sizeComparison}"',
      );
    } catch (e) {
      debugPrint('[PatientDetailController] Error fetching baby-size: $e');
      babySizeError.value = e.toString();
    } finally {
      isLoadingBabySize.value = false;
    }
}
  
  Future<void> loadBloodPressureHistory(int id) async {
    try {
      debugPrint('[PatientDetailController] Fetching blood pressure history for ID: $id');
      final result = await _repository.getBloodPressureHistory(id);
      bloodPressureHistory.assignAll(result);
      debugPrint(
          '[PatientDetailController] Blood pressure history loaded — ${result.length} readings',
      );
    } catch (e) {
      debugPrint('[PatientDetailController] Error fetching blood pressure history: $e');
    }
  }

  Future<void> loadBloodSugarHistory(int id) async {
    try {
      debugPrint('[PatientDetailController] Fetching blood sugar history for ID: $id');
      final result = await _repository.getBloodSugarHistory(id);
      bloodSugarHistory.assignAll(result);
      debugPrint(
          '[PatientDetailController] Blood sugar history loaded — ${result.length} readings',
      );
    } catch (e) {
      debugPrint('[PatientDetailController] Error fetching blood sugar history: $e');
    }
  }
  
  final RxBool isMarkingPaid = false.obs;

  /// Admin manually records that this patient has paid (no payment gateway).
  ///
  /// Calls `POST /accounts/patients/{id}/mark-paid/` with an optional
  /// transaction reference and received amount. On success the patient object
  /// is refreshed so the UI reflects the new paid state.
  Future<void> markPatientPaid({
    String? paymentReference,
    String? amountPaid,
  }) async {
    final currentPatient = patient.value;
    if (currentPatient == null) return;

    isMarkingPaid.value = true;
    try {
      debugPrint(
        '[PatientDetailController] markPatientPaid — id=${currentPatient.id}',
      );
      final updated = await _repository.markPatientPaid(
        currentPatient.id,
        paymentReference: paymentReference,
        amountPaid: amountPaid,
      );
      patient.value = updated;
      debugPrint(
        '[PatientDetailController] markPatientPaid — success id=${updated.id}',
      );
      Get.snackbar(
        'Payment Recorded',
        'This patient now has full access.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('[PatientDetailController] markPatientPaid — ERROR: $e');
      Get.snackbar(
        'Error',
        'Could not record payment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isMarkingPaid.value = false;
    }
  }

  Future<void> updateAccountStatus(bool isActive) async {
    final currentPatient = patient.value;
    if (currentPatient == null) return;

    isUpdatingStatus.value = true;
    statusUpdateError.value = null;

    try {
      debugPrint(
        '[PatientDetailController] Updating patient status for ID: ${currentPatient.id} to $isActive',
      );
      final updatedPatient = await _repository.updatePatientStatus(
        currentPatient.id,
        isActive,
      );
      patient.value = updatedPatient;
      debugPrint(
        '[PatientDetailController] Successfully updated patient status to ${updatedPatient.isActive}',
      );
    } catch (e) {
      debugPrint('[PatientDetailController] Error updating patient status: $e');
      statusUpdateError.value = e.toString();
      rethrow;
    } finally {
      isUpdatingStatus.value = false;
    }
  }
}
