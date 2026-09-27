import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/features/doctors/models/doctor.dart';
import 'package:admin/features/patients/models/baby_size.dart';
import 'package:admin/features/patients/models/diet_plan.dart';
import 'package:admin/features/patients/models/medicine_reminder.dart';
import 'package:admin/features/patients/models/paginated_patients.dart';
import 'package:admin/features/patients/models/patient.dart';
import 'package:admin/features/patients/models/patient_summary.dart';
import 'package:admin/features/patients/models/sos_event.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PatientRepository {
  final ApiClient _apiClient;

  PatientRepository(this._apiClient);

  Future<PaginatedPatients> getPatients({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? doctorId,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
      if (doctorId != null) 'doctor_id': doctorId,
    };

    debugPrint(
      '[PatientRepo] getPatients called — page=$page pageSize=$pageSize '
      'search=$search doctorId=$doctorId',
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
  /// Admin manually marks a patient as paid via
  /// `POST /accounts/patients/{id}/mark-paid/`.
  ///
  /// This is the admin panel's manual payment confirmation (no payment gateway).
  /// The admin checks their JazzCash/EasyPaisa/bank account for a matching
  /// transfer and records the payment here, optionally noting a transaction
  /// reference and the amount actually received. Returns the updated [Patient].
  Future<Patient> markPatientPaid(
    int id, {
    String? paymentReference,
    String? amountPaid,
  }) async {
    final path =
        '${ApiConstants.accountsPatientsDetail}/$id${ApiConstants.accountsPatientMarkPaidSuffix}';
    final Map<String, dynamic> body = {
      if (paymentReference != null && paymentReference.isNotEmpty)
        'payment_reference': paymentReference,
      if (amountPaid != null && amountPaid.isNotEmpty)
        'amount_paid': amountPaid,
    };
    debugPrint(
      '[PatientRepo] markPatientPaid called — id=$id path=$path body=$body',
    );
    final response = await _apiClient.post(path, data: body);
    debugPrint(
      '[PatientRepo] markPatientPaid response — status=${response.statusCode}',
    );
    final patient = Patient.fromJson(response.data);
    debugPrint(
      '[PatientRepo] markPatientPaid parsed — id=${patient.id} '
      'isActive=${patient.isActive}',
    );
    return patient;
  }

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

  // ─────────────────────── Diet Plans ─────────────────────────────────────

  /// Fetches the full diet-plan history for a patient (active + inactive).
  ///
  /// `GET /api/v1/diet/plans/?patient_id=<id>` — admin sees all plans for the
  /// patient, newest first (paginated).
  Future<List<DietPlan>> getDietPlans(int patientId) async {
    debugPrint('[PatientRepo] getDietPlans called — patientId=$patientId');
    final response = await _apiClient.get(
      ApiConstants.dietPlans,
      queryParameters: {'patient_id': patientId, 'page_size': 100},
    );
    debugPrint(
      '[PatientRepo] getDietPlans response — status=${response.statusCode}',
    );

    final List<dynamic> rawList;
    if (response.data is Map<String, dynamic>) {
      rawList = (response.data as Map<String, dynamic>)['results'] as List? ?? [];
    } else if (response.data is List) {
      rawList = response.data as List;
    } else {
      rawList = [];
    }

    final results = rawList
        .whereType<Map>()
        .map((e) => DietPlan.fromJson(e.cast<String, dynamic>()))
        .toList();

    debugPrint('[PatientRepo] getDietPlans parsed — ${results.length} plans');
    return results;
  }

  /// Fetches the patient's currently active diet plan, or `null` if none.
  ///
  /// `GET /api/v1/diet/plans/active/?patient_id=<id>` — the backend returns
  /// `404` (with `{"detail": "No active diet plan found."}`) when the patient
  /// has no active plan, which we map to `null`.
  Future<DietPlan?> getActiveDietPlan(int patientId) async {
    debugPrint('[PatientRepo] getActiveDietPlan called — patientId=$patientId');
    try {
      final response = await _apiClient.get(
        ApiConstants.dietPlansActive,
        queryParameters: {'patient_id': patientId},
      );
      debugPrint(
        '[PatientRepo] getActiveDietPlan response — status=${response.statusCode}',
      );
      if (response.data is! Map<String, dynamic>) {
        debugPrint(
          '[PatientRepo] getActiveDietPlan — unexpected shape, returning null',
        );
        return null;
      }
      final plan = DietPlan.fromJson(response.data);
      debugPrint(
        '[PatientRepo] getActiveDietPlan parsed — id=${plan.id} '
        'isActive=${plan.isActive}',
      );
      return plan;
    } on DioException catch (e) {
      // 404 = "no active plan" for this patient. Anything else is unexpected
      // and rethrown so the controller can surface it.
      if (e.response?.statusCode == 404) {
        debugPrint(
          '[PatientRepo] getActiveDietPlan — 404, no active plan (null)',
        );
        return null;
      }
      debugPrint(
        '[PatientRepo] getActiveDietPlan DioException — status='
        '${e.response?.statusCode} message=${e.message}',
      );
      rethrow;
    }
  }

  /// Creates a new diet plan for a patient.
  ///
  /// `POST /api/v1/diet/plans/` — doctor/admin only. Creating a new plan
  /// **deactivates** (never deletes) any previous active plan for the patient.
  Future<DietPlan> createDietPlan(DietPlanRequest request) async {
    final payload = request.toJson();
    debugPrint(
      '[PatientRepo] createDietPlan called — ${ApiConstants.dietPlans} '
      'payload=$payload',
    );
    final response = await _apiClient.post(
      ApiConstants.dietPlans,
      data: payload,
    );
    debugPrint(
      '[PatientRepo] createDietPlan response — status=${response.statusCode}',
    );
    final plan = DietPlan.fromJson(response.data);
    debugPrint(
      '[PatientRepo] createDietPlan parsed — id=${plan.id} isActive=${plan.isActive}',
    );
    return plan;
  }

  /// Updates an existing diet plan via `PATCH /api/v1/diet/plans/{id}/`.
  ///
  /// Note: the backend treats `meals`/`foods_to_avoid` (when present) as a
  /// **full replacement** — send the complete desired list, not a diff.
  Future<DietPlan> updateDietPlan(int id, DietPlanRequest request) async {
    final path = '${ApiConstants.dietPlansDetail}/$id/';
    final payload = request.toJson();
    debugPrint(
      '[PatientRepo] updateDietPlan called — id=$id path=$path payload=$payload',
    );
    final response = await _apiClient.patch(path, data: payload);
    debugPrint(
      '[PatientRepo] updateDietPlan response — status=${response.statusCode}',
    );
    final plan = DietPlan.fromJson(response.data);
    debugPrint(
      '[PatientRepo] updateDietPlan parsed — id=${plan.id} isActive=${plan.isActive}',
    );
    return plan;
  }

  /// Deletes a diet plan via `DELETE /api/v1/diet/plans/{id}/`.
  ///
  /// This is a hard delete (doctor/admin only). To retire a plan while keeping
  /// its history, PATCH `is_active: false` instead.
  Future<void> deleteDietPlan(int id) async {
    final path = '${ApiConstants.dietPlansDetail}/$id/';
    debugPrint('[PatientRepo] deleteDietPlan called — id=$id path=$path');
    final response = await _apiClient.delete(path);
    debugPrint(
      '[PatientRepo] deleteDietPlan response — status=${response.statusCode}',
    );
  }

  // ─────────────────────── Medicine Reminders ─────────────────────────────

  /// Fetches the full medicine-reminder list for a patient.
  ///
  /// `GET /api/v1/medicines/reminders/?patient_id=<id>` — role-scoped, newest
  /// first (paginated).
  Future<List<MedicineReminder>> getMedicineReminders(int patientId) async {
    debugPrint(
      '[PatientRepo] getMedicineReminders called — patientId=$patientId',
    );
    final response = await _apiClient.get(
      ApiConstants.medicinesReminders,
      queryParameters: {'patient_id': patientId, 'page_size': 100},
    );
    debugPrint(
      '[PatientRepo] getMedicineReminders response — '
      'status=${response.statusCode}',
    );

    final List<dynamic> rawList;
    if (response.data is Map<String, dynamic>) {
      rawList = (response.data as Map<String, dynamic>)['results'] as List? ?? [];
    } else if (response.data is List) {
      rawList = response.data as List;
    } else {
      rawList = [];
    }

    final results = rawList
        .whereType<Map>()
        .map((e) => MedicineReminder.fromJson(e.cast<String, dynamic>()))
        .toList();

    debugPrint('[PatientRepo] getMedicineReminders parsed — ${results.length} reminders');
    return results;
  }

  /// Creates a new medicine reminder for a patient.
  ///
  /// `POST /api/v1/medicines/reminders/` — doctor/admin only. The backend
  /// starts the Celery Beat scan over `reminder_times` from `start_date`.
  Future<MedicineReminder> createMedicineReminder(
    MedicineReminderRequest request,
  ) async {
    final payload = request.toJson();
    debugPrint(
      '[PatientRepo] createMedicineReminder called — '
      '${ApiConstants.medicinesReminders} payload=$payload',
    );
    final response = await _apiClient.post(
      ApiConstants.medicinesReminders,
      data: payload,
    );
    debugPrint(
      '[PatientRepo] createMedicineReminder response — '
      'status=${response.statusCode}',
    );
    final reminder = MedicineReminder.fromJson(response.data);
    debugPrint(
      '[PatientRepo] createMedicineReminder parsed — id=${reminder.id} '
      'medicine="${reminder.medicineName}" isActive=${reminder.isActive}',
    );
    return reminder;
  }

  /// Updates an existing medicine reminder via
  /// `PATCH /api/v1/medicines/reminders/{id}/`.
  Future<MedicineReminder> updateMedicineReminder(
    int id,
    MedicineReminderRequest request,
  ) async {
    final path = '${ApiConstants.medicinesRemindersDetail}/$id/';
    final payload = request.toJson();
    debugPrint(
      '[PatientRepo] updateMedicineReminder called — id=$id path=$path '
      'payload=$payload',
    );
    final response = await _apiClient.patch(path, data: payload);
    debugPrint(
      '[PatientRepo] updateMedicineReminder response — '
      'status=${response.statusCode}',
    );
    final reminder = MedicineReminder.fromJson(response.data);
    debugPrint(
      '[PatientRepo] updateMedicineReminder parsed — id=${reminder.id} '
      'isActive=${reminder.isActive}',
    );
    return reminder;
  }

  /// Toggles a reminder's active state via
  /// `PATCH /api/v1/medicines/reminders/{id}/` with `{"is_active": <bool>}`.
  ///
  /// Deactivating stops future reminders while preserving intake history.
  Future<MedicineReminder> setReminderActive(int id, bool isActive) async {
    final path = '${ApiConstants.medicinesRemindersDetail}/$id/';
    final body = {'is_active': isActive};
    debugPrint(
      '[PatientRepo] setReminderActive called — id=$id isActive=$isActive',
    );
    debugPrint('[PatientRepo] setReminderActive path=$path body=$body');
    final response = await _apiClient.patch(path, data: body);
    debugPrint(
      '[PatientRepo] setReminderActive response — status=${response.statusCode}',
    );
    final reminder = MedicineReminder.fromJson(response.data);
    debugPrint(
      '[PatientRepo] setReminderActive parsed — id=${reminder.id} '
      'isActive=${reminder.isActive}',
    );
    return reminder;
  }

  /// Deletes a medicine reminder via
  /// `DELETE /api/v1/medicines/reminders/{id}/`.
  ///
  /// Hard deletes the reminder and its intake logs. To keep history, use
  /// [setReminderActive] with `false` instead.
  Future<void> deleteMedicineReminder(int id) async {
    final path = '${ApiConstants.medicinesRemindersDetail}/$id/';
    debugPrint(
      '[PatientRepo] deleteMedicineReminder called — id=$id path=$path',
    );
    final response = await _apiClient.delete(path);
    debugPrint(
      '[PatientRepo] deleteMedicineReminder response — '
      'status=${response.statusCode}',
    );
  }

  /// Fetches a patient's medicine intake logs (adherence history).
  ///
  /// `GET /api/v1/medicines/intake-logs/?patient_id=<id>` — read-only,
  /// newest first (paginated).
  Future<List<MedicineIntakeLog>> getMedicineIntakeLogs(int patientId) async {
    debugPrint(
      '[PatientRepo] getMedicineIntakeLogs called — patientId=$patientId',
    );
    final response = await _apiClient.get(
      ApiConstants.medicinesIntakeLogs,
      queryParameters: {'patient_id': patientId, 'page_size': 200},
    );
    debugPrint(
      '[PatientRepo] getMedicineIntakeLogs response — '
      'status=${response.statusCode}',
    );

    final List<dynamic> rawList;
    if (response.data is Map<String, dynamic>) {
      rawList = (response.data as Map<String, dynamic>)['results'] as List? ?? [];
    } else if (response.data is List) {
      rawList = response.data as List;
    } else {
      rawList = [];
    }

    final results = rawList
        .whereType<Map>()
        .map((e) => MedicineIntakeLog.fromJson(e.cast<String, dynamic>()))
        .toList();

    debugPrint('[PatientRepo] getMedicineIntakeLogs parsed — ${results.length} logs');
    return results;
   }

   Future<List<dynamic>> getBloodPressureHistory(int patientId) async {
     debugPrint('[PatientRepo] getBloodPressureHistory called — patientId=$patientId');
     final response = await _apiClient.get(
       ApiConstants.healthBloodPressure,
       queryParameters: {'patient_id': patientId, 'page_size': 100},
     );
     debugPrint('[PatientRepo] getBloodPressureHistory response — status=${response.statusCode}');
     if (response.data is Map<String, dynamic>) {
       final results = response.data['results'] as List?;
       return results ?? [];
     } else if (response.data is List) {
       return response.data as List<dynamic>;
     }
     return [];
   }

   Future<List<dynamic>> getBloodSugarHistory(int patientId) async {
     debugPrint('[PatientRepo] getBloodSugarHistory called — patientId=$patientId');
     final response = await _apiClient.get(
       ApiConstants.healthBloodSugar,
       queryParameters: {'patient_id': patientId, 'page_size': 100},
     );
     debugPrint('[PatientRepo] getBloodSugarHistory response — status=${response.statusCode}');
     if (response.data is Map<String, dynamic>) {
       final results = response.data['results'] as List?;
       return results ?? [];
     } else if (response.data is List) {
       return response.data as List<dynamic>;
     }
     return [];
   }
}
