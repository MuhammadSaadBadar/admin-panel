import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../appointments/models/appointment.dart';
import '../../appointments/repositories/appointment_repository.dart';
import '../../patients/models/patient.dart';
import '../../patients/repositories/patient_repository.dart';
import '../models/doctor.dart';
import '../repositories/doctor_repository.dart';
import 'doctor_list_controller.dart';

/// Handles loading a single doctor's full details from the backend.
///
/// Follows the same reactive pattern as [PatientDetailController]:
/// holds an [Rx] doctor, loading flag, and error message, exposing a single
/// [loadDoctor] entry point that the UI calls once it knows the ID.
///
/// Also loads the doctor's assigned patients (`GET /accounts/patients/?doctor_id=`)
/// and appointments (`GET /appointments/?doctor_id=`) so the detail screen can
/// show a complete picture of the doctor's workload.
class DoctorDetailController extends GetxController {
  final DoctorRepository _repository;
  final PatientRepository _patientRepository;
  final AppointmentRepository _appointmentRepository;

  DoctorDetailController(
    this._repository,
    this._patientRepository,
    this._appointmentRepository,
  );

  // ── State ──────────────────────────────────────────────────────────────
  final Rxn<Doctor> doctor = Rxn<Doctor>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  final RxBool isTogglingActive = false.obs;

  // Assigned patients
  final RxList<Patient> assignedPatients = <Patient>[].obs;
  final RxBool isLoadingPatients = false.obs;
  final RxnString patientsError = RxnString();

  // Appointments
  final RxList<Appointment> appointments = <Appointment>[].obs;
  final RxBool isLoadingAppointments = false.obs;
  final RxnString appointmentsError = RxnString();

  // ── Actions ─────────────────────────────────────────────────────────────
  /// Fetches the full details for the doctor with [id], plus the doctor's
  /// assigned patients and appointments.
  ///
  /// Resets any previous error, sets [isLoading], performs the requests, and
  /// updates the reactive state on success or error on failure.
  Future<void> loadDoctor(int id) async {
    debugPrint('[DoctorDetailController] loadDoctor called — id=$id');
    isLoading.value = true;
    error.value = null;

    try {
      final result = await _repository.getDoctor(id);
      doctor.value = result;
      debugPrint(
        '[DoctorDetailController] loadDoctor — loaded doctor '
        'id=${result.id} name="${result.name}"',
      );

      // Load the doctor's assigned patients and appointments in parallel.
      await Future.wait([loadAssignedPatients(id), loadAppointments(id)]);
    } catch (e) {
      debugPrint('[DoctorDetailController] loadDoctor — ERROR: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      debugPrint('[DoctorDetailController] loadDoctor — isLoading=false');
    }
  }

  /// Activates or deactivates the currently-loaded doctor via
  /// `PATCH /accounts/doctors/{id}/`.
  ///
  /// On success, propagates the updated doctor to [DoctorListController] so the
  /// dashboard stays in sync even before a reload.
  Future<bool> toggleActive(int id, bool isActive) async {
    debugPrint(
      '[DoctorDetailController] toggleActive — id=$id isActive=$isActive',
    );
    isTogglingActive.value = true;
    try {
      final updated = await _repository.toggleDoctorActive(id, isActive);
      doctor.value = updated;
      debugPrint(
        '[DoctorDetailController] toggleActive — updated id=${updated.id} '
        'isActive=${updated.isActive}',
      );
      _syncListController(updated);
      Get.snackbar(
        isActive ? 'Doctor Activated' : 'Doctor Deactivated',
        '${updated.name} is now ${isActive ? 'active' : 'inactive'}.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      debugPrint('[DoctorDetailController] toggleActive — ERROR: $e');
      Get.snackbar(
        'Update Failed',
        'Could not update doctor status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isTogglingActive.value = false;
    }
  }

  /// Propagates a successfully-updated [updated] doctor into the shared
  /// [DoctorListController] so the dashboard stays in sync with the details
  /// screen even before a reload.
  void _syncListController(Doctor updated) {
    if (Get.isRegistered<DoctorListController>()) {
      final list = Get.find<DoctorListController>();
      final index = list.doctors.indexWhere((d) => d.id == updated.id);
      if (index != -1) {
        list.doctors[index] = updated;
        list.doctors.refresh();
        debugPrint(
          '[DoctorDetailController] _syncListController — synced '
          'id=${updated.id} isActive=${updated.isActive} to list controller',
        );
      }
    }
  }

  /// Fetches the patients assigned to this doctor via
  /// `GET /accounts/patients/?doctor_id={id}`.
  Future<void> loadAssignedPatients(int doctorId) async {
    debugPrint(
      '[DoctorDetailController] loadAssignedPatients — doctorId=$doctorId',
    );
    isLoadingPatients.value = true;
    patientsError.value = null;

    try {
      final paginated = await _patientRepository.getPatients(
        doctorId: doctorId,
        pageSize: 50,
      );
      assignedPatients.assignAll(paginated.results);
      debugPrint(
        '[DoctorDetailController] loadAssignedPatients — loaded '
        '${paginated.results.length} patients (total=${paginated.count})',
      );
    } catch (e) {
      debugPrint('[DoctorDetailController] loadAssignedPatients — ERROR: $e');
      patientsError.value = 'Failed to load assigned patients.';
    } finally {
      isLoadingPatients.value = false;
    }
  }

  /// Fetches the appointments for this doctor via
  /// `GET /appointments/?doctor_id={id}`.
  Future<void> loadAppointments(int doctorId) async {
    debugPrint(
      '[DoctorDetailController] loadAppointments — doctorId=$doctorId',
    );
    isLoadingAppointments.value = true;
    appointmentsError.value = null;

    try {
      final paginated = await _appointmentRepository.getAppointments(
        doctorId: doctorId,
        pageSize: 50,
      );
      appointments.assignAll(paginated.results);
      debugPrint(
        '[DoctorDetailController] loadAppointments — loaded '
        '${paginated.results.length} appointments (total=${paginated.count})',
      );
    } catch (e) {
      debugPrint('[DoctorDetailController] loadAppointments — ERROR: $e');
      appointmentsError.value = 'Failed to load appointments.';
    } finally {
      isLoadingAppointments.value = false;
    }
  }
}
