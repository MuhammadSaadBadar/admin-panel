import 'package:flutter/material.dart';
import 'package:admin/features/doctors/models/doctor.dart';
import 'package:admin/features/doctors/repositories/doctor_repository.dart';

class DoctorFormProvider extends ChangeNotifier {
  final DoctorRepository _repository;

  bool _isLoading = false;
  String? _error;

  DoctorFormProvider(this._repository);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createDoctor(Doctor doctor) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createDoctor(doctor);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDoctor(int id, Doctor doctor) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateDoctor(id, doctor);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

