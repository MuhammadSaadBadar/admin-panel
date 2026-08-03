import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/features/doctors/models/doctor.dart';

class DoctorRepository {
  final ApiClient _apiClient;

  DoctorRepository(this._apiClient);

  Future<List<Doctor>> getDoctors() async {
    final response = await _apiClient.get(ApiConstants.doctors);
    return (response.data as List).map((json) => Doctor.fromJson(json)).toList();
  }

  Future<Doctor> getDoctor(int id) async {
    final response = await _apiClient.get('${ApiConstants.doctors}$id/');
    return Doctor.fromJson(response.data);
  }

  Future<Doctor> createDoctor(Doctor doctor) async {
    final response = await _apiClient.post(ApiConstants.doctors, data: doctor.toJson());
    return Doctor.fromJson(response.data);
  }

  Future<Doctor> updateDoctor(int id, Doctor doctor) async {
    final response = await _apiClient.put('${ApiConstants.doctors}$id/', data: doctor.toJson());
    return Doctor.fromJson(response.data);
  }

  Future<void> deleteDoctor(int id) async {
    await _apiClient.delete('${ApiConstants.doctors}$id/');
  }
}

