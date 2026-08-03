import 'package:flutter/material.dart';
import 'package:admin/features/doctors/models/doctor.dart';
import 'package:admin/features/doctors/repositories/doctor_repository.dart';

class DoctorListProvider extends ChangeNotifier {
  final DoctorRepository _repository;

  List<Doctor> _doctors = [];
  bool _isLoading = false;
  String? _error;

  DoctorListProvider(this._repository);

  List<Doctor> get doctors => _doctors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDoctors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _doctors = await _repository.getDoctors();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteDoctor(int id) async {
    try {
      await _repository.deleteDoctor(id);
      _doctors.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

