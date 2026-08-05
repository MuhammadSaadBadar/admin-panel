import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../doctors/models/doctor.dart';
import '../../doctors/repositories/doctor_repository.dart';
import '../controllers/patient_detail_controller.dart';
import '../repositories/patient_repository.dart';

class AssignDoctorController extends GetxController {
  final DoctorRepository _doctorRepository;
  final PatientRepository _patientRepository;

  AssignDoctorController(this._doctorRepository, this._patientRepository);

  // ── State ──────────────────────────────────────────────────────────────
  final RxList<Doctor> doctors = <Doctor>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAssigning = false.obs;
  final RxnString errorMessage = RxnString();

  final RxString searchQuery = ''.obs;
  final RxString selectedCity = 'All Cities'.obs;
  final Rxn<int> selectedDoctorId = Rxn<int>();

  int _patientId = 0;
  int get patientId => _patientId;

  static const List<String> cities = [
    'All Cities',
    'Lahore',
    'Karachi',
    'Multan',
    'Islamabad',
  ];

  // ── Computed ────────────────────────────────────────────────────────────
  List<Doctor> get filteredDoctors {
    var filtered = doctors.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      filtered = filtered
          .where((d) => d.name.toLowerCase().contains(q))
          .toList();
    }

    // Apply city filter
    if (selectedCity.value != 'All Cities') {
      filtered = filtered
          .where(
            (d) => d.city.toLowerCase() == selectedCity.value.toLowerCase(),
          )
          .toList();
    }

    return filtered;
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────
  void init(int patientId) {
    _patientId = patientId;
    debugPrint('[AssignDoctorCtrl] Initialized with patientId=$patientId');
    fetchDoctors();
  }

  // ── API Methods ─────────────────────────────────────────────────────────
  Future<void> fetchDoctors() async {
    isLoading.value = true;
    errorMessage.value = null;
    debugPrint('[AssignDoctorCtrl] Fetching doctors list...');

    try {
      final result = await _doctorRepository.getDoctors();
      doctors.assignAll(result);
      debugPrint('[AssignDoctorCtrl] Loaded ${result.length} doctors');
    } catch (e) {
      debugPrint('[AssignDoctorCtrl] Error fetching doctors: $e');
      errorMessage.value = 'Failed to load doctors. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String query) {
    debugPrint('[AssignDoctorCtrl] Search query updated: "$query"');
    searchQuery.value = query;
  }

  void updateCity(String city) {
    debugPrint('[AssignDoctorCtrl] City filter changed: "$city"');
    selectedCity.value = city;
  }

  void selectDoctor(int doctorId) {
    debugPrint('[AssignDoctorCtrl] Doctor selected: id=$doctorId');
    selectedDoctorId.value = doctorId;
  }

  Future<void> assignDoctor(int doctorId, String doctorName) async {
    if (_patientId == 0) {
      debugPrint('[AssignDoctorCtrl] ERROR — patientId is 0, cannot assign');
      Get.snackbar(
        'Error',
        'No patient selected.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isAssigning.value = true;
    debugPrint(
      '[AssignDoctorCtrl] Assigning doctor $doctorId to patient $_patientId...',
    );

    try {
      await _patientRepository.assignDoctor(_patientId, doctorId);
      debugPrint('[AssignDoctorCtrl] Doctor assigned successfully');

      Get.snackbar(
        'Success',
        '$doctorName has been assigned successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      // Refresh Patient Details if available
      if (Get.isRegistered<PatientDetailController>()) {
        debugPrint('[AssignDoctorCtrl] Refreshing patient details...');
        Get.find<PatientDetailController>().loadAllData(_patientId);
      }

      // Navigate back
      debugPrint('[AssignDoctorCtrl] Navigating back to patient details');
      Get.back();
    } catch (e) {
      debugPrint('[AssignDoctorCtrl] Error assigning doctor: $e');
      Get.snackbar(
        'Assignment Failed',
        'Could not assign doctor. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isAssigning.value = false;
    }
  }
}
