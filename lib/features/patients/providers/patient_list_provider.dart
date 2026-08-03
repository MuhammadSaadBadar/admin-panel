import 'package:flutter/material.dart';
import 'package:admin/features/patients/models/patient.dart';
import 'package:admin/features/patients/repositories/patient_repository.dart';

class PatientListProvider extends ChangeNotifier {
  final PatientRepository _repository;

  List<Patient> _patients = [];
  bool _isLoading = false;
  String? _error;

  PatientListProvider(this._repository);

  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paginatedPatients = await _repository.getPatients();
      _patients = paginatedPatients.results;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deletePatient(int id) async {
    try {
      await _repository.deletePatient(id);
      _patients.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

