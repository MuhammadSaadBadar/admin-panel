import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/doctor.dart';
import '../repositories/doctor_repository.dart';
import 'doctor_detail_controller.dart';

class DoctorListController extends GetxController {
  final DoctorRepository _repository;

  DoctorListController(this._repository);

  final RxList<Doctor> doctors = <Doctor>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  /// Guards against overlapping activation/deactivation requests so rapid
  /// toggling cannot fire concurrent PATCH calls (which caused a race
  /// condition where a second toggle could fail and corrupt the list view).
  final RxBool isTogglingActive = false.obs;

  // ── Search & Filter state ─────────────────────────────────────────────
  /// The current search text (case-insensitive matching across name, email,
  /// specialization, and ID). Reactive so the UI updates on every keystroke.
  final RxString searchQuery = ''.obs;

  /// The currently selected specialization filter. `''` means "All" / no filter.
  final RxString selectedSpecialization = ''.obs;

  /// The distinct, non-empty specializations present in the loaded doctors.
  /// Derived after each list load so the filter chips stay in sync with data.
  final RxList<String> availableSpecializations = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[DoctorListController] onInit — loading doctors');
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    isLoading.value = true;
    error.value = null;
    debugPrint('[DoctorListController] loadDoctors — request started');

    try {
      final list = await _repository.getDoctors();
      doctors.assignAll(list);
      _deriveSpecializations();
      debugPrint(
        '[DoctorListController] loadDoctors — loaded ${list.length} doctors, '
        'specializations=${availableSpecializations.length}',
      );
    } catch (e) {
      debugPrint('[DoctorListController] loadDoctors — ERROR: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      debugPrint('[DoctorListController] loadDoctors — isLoading=false');
    }
  }

  /// Lightweight refresh of the doctor list from the server.
  ///
  /// Unlike [loadDoctors], this does NOT flip [isLoading] (so the UI won't
  /// flash a full-screen spinner) and it does NOT blank the list if the fetch
  /// fails. It is intended to be called when returning to the dashboard so the
  /// list always reflects the latest server truth (e.g. a status change made
  /// from the details screen).
  Future<void> refreshFromServer() async {
    debugPrint('[DoctorListController] refreshFromServer — request started');
    try {
      final list = await _repository.getDoctors();
      doctors.assignAll(list);
      _deriveSpecializations();
      error.value = null;
      debugPrint(
        '[DoctorListController] refreshFromServer — loaded ${list.length} '
        'doctors, specializations=${availableSpecializations.length}',
      );
    } catch (e) {
      // Keep the existing list on transient errors — do not overwrite updated
      // data with an error/empty state.
      debugPrint('[DoctorListController] refreshFromServer — ERROR: $e');
    }
  }

  // ── Search & Filter actions ───────────────────────────────────────────
  /// Updates the reactive [searchQuery] as the user types (real-time).
  /// Matching is case-insensitive and spans name, email, specialization, and ID.
  void setSearchQuery(String value) {
    final trimmed = value.trim();
    debugPrint(
      '[DoctorListController] setSearchQuery — "$searchQuery" → "$trimmed"',
    );
    searchQuery.value = trimmed;
  }

  /// Toggles the selected [specialization] filter. Tapping an already-selected
  /// specialization deselects it (back to "All"). Tapping a new one replaces it.
  void toggleSpecialization(String specialization) {
    debugPrint(
      '[DoctorListController] toggleSpecialization — '
      'current="$selectedSpecialization" tapped="$specialization"',
    );
    if (selectedSpecialization.value == specialization) {
      selectedSpecialization.value = '';
      debugPrint(
        '[DoctorListController] toggleSpecialization — deselected '
        '(now All)',
      );
    } else {
      selectedSpecialization.value = specialization;
      debugPrint(
        '[DoctorListController] toggleSpecialization — '
        'selected="$specialization"',
      );
    }
  }

  /// Clears the search query and any selected specialization filter.
  void clearFilters() {
    debugPrint(
      '[DoctorListController] clearFilters — was '
      'search="$searchQuery" specialization="$selectedSpecialization"',
    );
    searchQuery.value = '';
    selectedSpecialization.value = '';
    debugPrint('[DoctorListController] clearFilters — filters cleared');
  }

  /// The list of doctors after applying the active search query and
  /// specialization filter. This is the single source of truth for the
  /// dashboard grid — the UI must not re-implement filtering logic.
  List<Doctor> get filteredDoctors {
    final query = searchQuery.value.toLowerCase();
    final spec = selectedSpecialization.value;

    List<Doctor> result = doctors;
    if (query.isNotEmpty) {
      result = result.where((d) {
        return d.name.toLowerCase().contains(query) ||
            d.email.toLowerCase().contains(query) ||
            d.specialization.toLowerCase().contains(query) ||
            d.id.toString().contains(query);
      }).toList();
    }
    if (spec.isNotEmpty) {
      result = result.where((d) => d.specialization == spec).toList();
    }
    return result;
  }

  /// Number of doctors that match the active search/filter criteria.
  int get filteredCount => filteredDoctors.length;

  /// Derives the distinct, non-empty specializations from the loaded doctors
  /// so the filter chips stay in sync with the current dataset.
  void _deriveSpecializations() {
    final specs =
        doctors
            .map((d) => d.specialization)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    availableSpecializations.assignAll(specs);
    debugPrint(
      '[DoctorListController] _deriveSpecializations — '
      'specializations=$specs',
    );
  }

  /// Propagates a successfully-updated [updated] doctor into the shared
  /// [DoctorDetailController] so the details screen stays in sync with the
  /// dashboard even before a reload.
  void _syncDetailController(Doctor updated) {
    if (Get.isRegistered<DoctorDetailController>()) {
      final detail = Get.find<DoctorDetailController>();
      if (detail.doctor.value?.id == updated.id) {
        detail.doctor.value = updated;
        debugPrint(
          '[DoctorListController] _syncDetailController — synced '
          'id=${updated.id} isActive=${updated.isActive} to detail controller',
        );
      }
    }
  }

  Future<void> deleteDoctor(int id) async {
    debugPrint('[DoctorListController] deleteDoctor — id=$id');
    try {
      await _repository.deleteDoctor(id);
      doctors.removeWhere((d) => d.id == id);
      debugPrint('[DoctorListController] deleteDoctor — removed id=$id');
    } catch (e) {
      debugPrint('[DoctorListController] deleteDoctor — ERROR: $e');
      error.value = e.toString();
    }
  }

  /// Activates or deactivates a doctor via the repository, then updates the
  /// in-memory list so the UI reflects the new state immediately.
  ///
  /// Guards against overlapping requests via [isTogglingActive], propagates the
  /// updated doctor to [DoctorDetailController], and does NOT pollute
  /// [error] on a toggle failure (the error state is reserved for list-load
  /// failures only).
  ///
  /// Returns `true` on success, `false` on failure (error surfaced via snackbar).
  Future<bool> toggleActive(int id, bool isActive) async {
    if (isTogglingActive.value) {
      debugPrint(
        '[DoctorListController] toggleActive — BUSY (isTogglingActive), '
        'ignoring id=$id isActive=$isActive',
      );
      return false;
    }

    debugPrint(
      '[DoctorListController] toggleActive — id=$id isActive=$isActive',
    );
    isTogglingActive.value = true;
    try {
      final updated = await _repository.toggleDoctorActive(id, isActive);
      final index = doctors.indexWhere((d) => d.id == id);
      if (index != -1) {
        doctors[index] = updated;
        doctors.refresh();
      }
      debugPrint(
        '[DoctorListController] toggleActive — updated id=$id '
        'isActive=${updated.isActive}',
      );
      _syncDetailController(updated);
      Get.snackbar(
        isActive ? 'Doctor Activated' : 'Doctor Deactivated',
        '${updated.name} is now ${isActive ? 'active' : 'inactive'}.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      debugPrint('[DoctorListController] toggleActive — ERROR: $e');
      // NOTE: intentionally NOT setting error.value here — a toggle failure is
      // not a list-load failure, and setting it would hide the whole board
      // behind the "Failed to load doctors" error screen unnecessarily.
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
}
