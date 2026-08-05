import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/features/doctors/models/doctor.dart';
import 'package:admin/features/patients/models/baby_size.dart';
import 'package:admin/features/patients/models/paginated_patients.dart';
import 'package:admin/features/patients/models/patient.dart';
import 'package:admin/features/patients/models/patient_summary.dart';
import 'package:admin/features/patients/models/sos_event.dart';
import 'package:flutter/foundation.dart';

class PatientRepository {
  final ApiClient _apiClient;

  PatientRepository(this._apiClient);

  Future<PaginatedPatients> getPatients({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? doctorId,
    int? trimester,
    String? riskLevel,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
      if (doctorId != null) 'doctor_id': doctorId,
      if (trimester != null) 'trimester': trimester,
      if (riskLevel != null && riskLevel.isNotEmpty) 'risk_level': riskLevel,
    };

    debugPrint(
      '[PatientRepo] getPatients called — page=$page pageSize=$pageSize '
      'search=$search doctorId=$doctorId trimester=$trimester '
      'riskLevel=$riskLevel',
    );
    debugPrint('[PatientRepo] getPatients queryParameters=$queryParameters');

    final response = await _apiClient.get(
      ApiConstants.patients,
      queryParameters: queryParameters,
    );
    debugPrint(
      '[PatientRepo] getPatients response — status=${response.statusCode}',
    );
    return PaginatedPatients.fromJson(response.data);
  }

  /// Fetches the list of doctors (for the "Assigned Doctor" filter dropdown)
  /// using the existing accounts/doctors endpoint. Handles both paginated
  /// (`{count, next, previous, results}`) and plain list responses.
  Future<List<Doctor>> getDoctors() async {
    debugPrint('[PatientRepo] getDoctors called');
    final response = await _apiClient.get(ApiConstants.doctors);
    debugPrint(
      '[PatientRepo] getDoctors response — status=${response.statusCode}',
    );

    final List<dynamic> rawList;
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      rawList = data['results'] as List? ?? [];
    } else if (response.data is List) {
      rawList = response.data as List;
    } else {
      rawList = [];
    }

    final doctors = rawList.map((json) => Doctor.fromJson(json)).toList();
    debugPrint('[PatientRepo] getDoctors parsed — ${doctors.length} doctors');
    return doctors;
  }

  Future<Patient> getPatient(int id) async {
    final path = '${ApiConstants.accountsPatientsDetail}/$id/';
    debugPrint('[PatientRepo] getPatient called — id=$id path=$path');
    final response = await _apiClient.get(path);
    debugPrint(
      '[PatientRepo] getPatient response — status=${response.statusCode} body=${response.data}',
    );
    final parsed = Patient.fromJson(response.data);
    debugPrint(
      '[PatientRepo] getPatient parsed — id=${parsed.id} name=${parsed.name} '
      'isActive=${parsed.isActive}',
    );
    return parsed;
  }

  Future<PatientSummary> getPatientSummary(int id) async {
    debugPrint('[PatientRepo] getPatientSummary called — id=$id');
    final response = await _apiClient.get(
      ApiConstants.reportsPatientSummary,
      queryParameters: {'patient_id': id},
    );
    debugPrint(
      '[PatientRepo] getPatientSummary response — status=${response.statusCode}',
    );
    return PatientSummary.fromJson(response.data);
  }

  /// Updates the patient's account status (activate/deactivate) via
  /// PATCH /accounts/patients/{id}/ with body `{"is_active": <bool>}`.
  /// Returns the updated [Patient] from the server response.
  Future<Patient> updatePatientStatus(int id, bool isActive) async {
    final path = '${ApiConstants.accountsPatientsDetail}/$id/';
    final body = {'is_active': isActive};
    debugPrint(
      '[PatientRepo] updatePatientStatus called — id=$id isActive=$isActive',
    );
    debugPrint(
      '[PatientRepo] updatePatientStatus request — path=$path body=$body',
    );

    final response = await _apiClient.patch(path, data: body);
    debugPrint(
      '[PatientRepo] updatePatientStatus response — status=${response.statusCode} '
      'body=${response.data}',
    );

    final parsed = Patient.fromJson(response.data);
    debugPrint(
      '[PatientRepo] updatePatientStatus parsed — id=${parsed.id} '
      'isActive=${parsed.isActive}',
    );
    return parsed;
  }

  Future<void> assignDoctor(int patientId, int doctorId) async {
    final path =
        '${ApiConstants.accountsPatientsDetail}/$patientId${ApiConstants.accountsPatientAssignDoctorSuffix}';
    final body = {'doctor_id': doctorId};
    debugPrint(
      '[PatientRepo] assignDoctor called — patientId=$patientId doctorId=$doctorId',
    );
    debugPrint('[PatientRepo] assignDoctor request — path=$path body=$body');

    final response = await _apiClient.post(path, data: body);
    debugPrint(
      '[PatientRepo] assignDoctor response — status=${response.statusCode}',
    );
  }

  /// Fetches SOS event history for a patient using the role-scoped emergency
  /// endpoint with `?patient_id=`. Handles paginated responses.
  Future<List<SosEvent>> getSosHistory(int patientId) async {
    debugPrint('[PatientRepo] getSosHistory called — patientId=$patientId');
    final response = await _apiClient.get(
      ApiConstants.emergencySos,
      queryParameters: {'patient_id': patientId, 'page_size': 50},
    );
    debugPrint(
      '[PatientRepo] getSosHistory response — status=${response.statusCode}',
    );

    final List<dynamic> rawList;
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      rawList = data['results'] as List? ?? [];
    } else if (response.data is List) {
      rawList = response.data as List;
    } else {
      rawList = [];
    }

    final events = rawList.map((json) => SosEvent.fromJson(json)).toList();
    debugPrint('[PatientRepo] getSosHistory parsed — ${events.length} events');
    return events;
  }

  /// Fetches the baby-size reference for a specific gestational week.
  Future<BabySizeReference> getBabySize(int week) async {
    final path = '${ApiConstants.healthBabySizeDetail}/$week/';
    debugPrint('[PatientRepo] getBabySize called — week=$week path=$path');
    final response = await _apiClient.get(path);
    debugPrint(
      '[PatientRepo] getBabySize response — status=${response.statusCode}',
    );
    return BabySizeReference.fromJson(response.data);
  }

  Future<void> deletePatient(int id) async {
    final path = '${ApiConstants.accountsPatientsDetail}/$id/';
    debugPrint('[PatientRepo] deletePatient called — id=$id path=$path');
    final response = await _apiClient.delete(path);
    debugPrint(
      '[PatientRepo] deletePatient response — status=${response.statusCode}',
    );
  }
}
