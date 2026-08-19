import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../doctors/models/doctor.dart';
import '../models/patient.dart';
import '../repositories/patient_repository.dart';

class PatientListController extends GetxController {
  final PatientRepository _repository;

  PatientListController(this._repository);

  final RxList<Patient> patients = <Patient>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnString error = RxnString();

  // ── Filter State ──────────────────────────────────────────────────────
  final RxString searchQuery = ''.obs;
  final Rxn<int> selectedDoctorId = Rxn<int>();

  // Options for the Assigned Doctor dropdown (populated from the API).
  final RxList<Doctor> doctors = <Doctor>[].obs;

  int _currentPage = 1;
  bool _hasMore = true;
  final int _pageSize = 20;

  Timer? _debounce;

  bool get hasMore => _hasMore;

  /// Whether any filter is currently active.
  bool get hasActiveFilters =>
      searchQuery.value.trim().isNotEmpty || selectedDoctorId.value != null;

  /// Patients after applying client-side search/filtering.
  ///
  /// The backend may not support all filter query params (e.g. `q`), so we
  /// always apply the search locally on top of whatever the API returns.
  /// This guarantees the UI reflects the search criteria immediately.
  List<Patient> get filteredPatients {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return patients.toList();

    return patients.where((p) {
      final name = p.name.toLowerCase();
      final email = p.email.toLowerCase();
      final phone = p.phoneNumber.toLowerCase();
      final id = p.id.toString();
      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          id.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadDoctors();
    loadPatients();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  // ── Filter Options ────────────────────────────────────────────────────
  Future<void> loadDoctors() async {
    debugPrint(
      '[PatientListController] Loading doctors for filter dropdown...',
    );
    try {
      final list = await _repository.getDoctors();
      doctors.assignAll(list);
      debugPrint('[PatientListController] Loaded ${list.length} doctors');
    } catch (e) {
      debugPrint('[PatientListController] Error loading doctors: $e');
      // Non-fatal: the dropdown will just show "All Doctors".
    }
  }

  // ── Search (debounced) ────────────────────────────────────────────────
  void updateSearch(String query) {
    debugPrint('[PatientListController] Search query updated: "$query"');
    searchQuery.value = query;

    // Debounce so we don't hit the API on every keystroke.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      debugPrint(
        '[PatientListController] Debounced search triggered: "$query"',
      );
      loadPatients();
    });
  }

  // ── Filters ───────────────────────────────────────────────────────────
  void setDoctor(int? doctorId) {
    debugPrint('[PatientListController] Doctor filter set: $doctorId');
    selectedDoctorId.value = doctorId;
    loadPatients();
  }

  void clearFilters() {
    debugPrint('[PatientListController] Clearing all filters');
    _debounce?.cancel();
    searchQuery.value = '';
    selectedDoctorId.value = null;
    loadPatients();
  }

  // ── Data Loading ──────────────────────────────────────────────────────
  Future<void> loadPatients() async {
    isLoading.value = true;
    error.value = null;
    _currentPage = 1;
    _hasMore = true;

    debugPrint(
      '[PatientListController] Load patients — search="${searchQuery.value}" '
      'doctorId=${selectedDoctorId.value}',
    );

    try {
      final paginated = await _repository.getPatients(
        page: _currentPage,
        pageSize: _pageSize,
        search: searchQuery.value,
        doctorId: selectedDoctorId.value,
      );
      patients.assignAll(paginated.results);
      _hasMore = paginated.next != null;
      debugPrint(
        '[PatientListController] Loaded ${paginated.results.length} patients '
        '(total=${paginated.count}, hasMore=$_hasMore)',
      );
    } catch (e) {
      debugPrint('[PatientListController] Error loading patients: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMorePatients() async {
    if (isLoading.value || isLoadingMore.value || !_hasMore) return;

    isLoadingMore.value = true;
    _currentPage++;

    try {
      debugPrint('[PatientListController] Fetching page $_currentPage');
      final paginated = await _repository.getPatients(
        page: _currentPage,
        pageSize: _pageSize,
        search: searchQuery.value,
        doctorId: selectedDoctorId.value,
      );
      patients.addAll(paginated.results);
      _hasMore = paginated.next != null;
      debugPrint(
        '[PatientListController] Appended page $_currentPage '
        '(${paginated.results.length} patients, hasMore=$_hasMore)',
      );
    } catch (e) {
      debugPrint('[PatientListController] Error loading more patients: $e');
      // Decrement page count so we can retry
      _currentPage--;
      error.value = e.toString();
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> deletePatient(int id) async {
    try {
      await _repository.deletePatient(id);
      patients.removeWhere((p) => p.id == id);
    } catch (e) {
      error.value = e.toString();
    }
  }
}
