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
    // We can fetch both concurrently to save time. SOS + baby-size are
    // best-effort secondary loads; failures there must not block the core
    // patient + summary display.
    await Future.wait([
      loadPatient(id),
      loadPatientSummary(id),
      loadSosHistory(id),
      loadBabySizeForPatient(id),
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
        '[PatientDetailController] No current week available — skipping baby-size.',
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
