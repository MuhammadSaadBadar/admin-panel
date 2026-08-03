import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/patient.dart';
import '../repositories/patient_repository.dart';

class PatientListController extends GetxController {
  final PatientRepository _repository;

  PatientListController(this._repository);

  final RxList<Patient> patients = <Patient>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnString error = RxnString();
  
  int _currentPage = 1;
  bool _hasMore = true;
  final int _pageSize = 20;

  bool get hasMore => _hasMore;

  @override
  void onInit() {
    super.onInit();
    loadPatients();
  }

  Future<void> loadPatients() async {
    isLoading.value = true;
    error.value = null;
    _currentPage = 1;
    _hasMore = true;
    
    try {
      debugPrint('[PatientListController] Fetching page $_currentPage');
      final paginated = await _repository.getPatients(page: _currentPage, pageSize: _pageSize);
      patients.assignAll(paginated.results);
      _hasMore = paginated.next != null;
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
      final paginated = await _repository.getPatients(page: _currentPage, pageSize: _pageSize);
      patients.addAll(paginated.results);
      _hasMore = paginated.next != null;
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
