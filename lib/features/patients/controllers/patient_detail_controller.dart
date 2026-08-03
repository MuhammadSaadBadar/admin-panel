import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/patient.dart';
import '../models/patient_summary.dart';
import '../repositories/patient_repository.dart';

class PatientDetailController extends GetxController {
  final PatientRepository _repository;

  PatientDetailController(this._repository);

  final Rxn<Patient> patient = Rxn<Patient>();
  final Rxn<PatientSummary> patientSummary = Rxn<PatientSummary>();
  
  final RxBool isLoadingPatient = false.obs;
  final RxBool isLoadingSummary = false.obs;
  
  final RxnString patientError = RxnString();
  final RxnString summaryError = RxnString();

  Future<void> loadPatient(int id) async {
    isLoadingPatient.value = true;
    patientError.value = null;
    try {
      debugPrint('[PatientDetailController] Fetching patient details for ID: $id');
      final result = await _repository.getPatient(id);
      patient.value = result;
    } catch (e) {
      debugPrint('[PatientDetailController] Error fetching patient details: $e');
      patientError.value = e.toString();
    } finally {
      isLoadingPatient.value = false;
    }
  }

  Future<void> loadPatientSummary(int id) async {
    isLoadingSummary.value = true;
    summaryError.value = null;
    try {
      debugPrint('[PatientDetailController] Fetching patient summary for ID: $id');
      final result = await _repository.getPatientSummary(id);
      patientSummary.value = result;
    } catch (e) {
      debugPrint('[PatientDetailController] Error fetching patient summary: $e');
      summaryError.value = e.toString();
    } finally {
      isLoadingSummary.value = false;
    }
  }
  
  Future<void> loadAllData(int id) async {
    // We can fetch both concurrently to save time
    await Future.wait([
      loadPatient(id),
      loadPatientSummary(id),
    ]);
  }
}
