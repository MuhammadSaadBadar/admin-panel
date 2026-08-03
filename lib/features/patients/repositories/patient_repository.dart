import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/features/patients/models/patient.dart';
import 'package:admin/features/patients/models/paginated_patients.dart';
import 'package:admin/features/patients/models/patient_summary.dart';

class PatientRepository {
  final ApiClient _apiClient;

  PatientRepository(this._apiClient);

  Future<PaginatedPatients> getPatients({int page = 1, int pageSize = 20}) async {
    final response = await _apiClient.get(
      ApiConstants.patients,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return PaginatedPatients.fromJson(response.data);
  }

  Future<Patient> getPatient(int id) async {
    final response = await _apiClient.get('${ApiConstants.patients}$id/');
    return Patient.fromJson(response.data);
  }

  Future<PatientSummary> getPatientSummary(int id) async {
    final response = await _apiClient.get(
      ApiConstants.reportsPatientSummary,
      queryParameters: {
        'patient_id': id,
      },
    );
    return PatientSummary.fromJson(response.data);
  }

  Future<void> deletePatient(int id) async {
    await _apiClient.delete('${ApiConstants.patients}$id/');
  }
}
