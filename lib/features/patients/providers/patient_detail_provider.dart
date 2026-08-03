import 'package:admin/features/patients/models/patient.dart';
import 'package:admin/features/patients/repositories/patient_repository.dart';
import 'package:flutter/material.dart';

class PatientDetailProvider extends ChangeNotifier {
  final PatientRepository _repository;

  Patient? _patient;
  bool _isLoading = false;
  String? _error;

  PatientDetailProvider(this._repository);

  Patient? get patient => _patient;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatient(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patient = await _repository.getPatient(id);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
