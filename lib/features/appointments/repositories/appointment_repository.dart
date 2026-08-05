import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/features/appointments/models/appointment.dart';
import 'package:flutter/foundation.dart';

/// Repository for the Appointments API. All endpoints come from
/// [ApiConstants] — no hardcoded URLs.
class AppointmentRepository {
  final ApiClient _apiClient;

  AppointmentRepository(this._apiClient);

  /// Fetches a paginated list of appointments.
  ///
  /// For an admin caller, the API returns all appointments. Optional
  /// `patientId` / `doctorId` narrow the list (admin only).
  Future<PaginatedAppointments> getAppointments({
    int page = 1,
    int pageSize = 20,
    int? patientId,
    int? doctorId,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (patientId != null) 'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
    };

    debugPrint(
      '[AppointmentRepo] getAppointments called — page=$page pageSize=$pageSize '
      'patientId=$patientId doctorId=$doctorId',
    );
    debugPrint(
      '[AppointmentRepo] getAppointments queryParameters=$queryParameters',
    );

    final response = await _apiClient.get(
      ApiConstants.appointments,
      queryParameters: queryParameters,
    );
    debugPrint(
      '[AppointmentRepo] getAppointments response — status=${response.statusCode} '
      'body=${response.data}',
    );

    final parsed = PaginatedAppointments.fromJson(response.data);
    debugPrint(
      '[AppointmentRepo] getAppointments parsed — count=${parsed.count} '
      'returned=${parsed.results.length}',
    );
    return parsed;
  }

  /// Fetches a single appointment by id.
  Future<Appointment> getAppointment(int id) async {
    final path = '${ApiConstants.appointmentsDetail}/$id/';
    debugPrint('[AppointmentRepo] getAppointment called — id=$id path=$path');

    final response = await _apiClient.get(path);
    debugPrint(
      '[AppointmentRepo] getAppointment response — status=${response.statusCode} '
      'body=${response.data}',
    );

    final parsed = Appointment.fromJson(response.data);
    debugPrint(
      '[AppointmentRepo] getAppointment parsed — id=${parsed.id} '
      'status=${parsed.status.displayLabel}',
    );
    return parsed;
  }

  /// Updates an appointment's status via the server's state machine.
  ///
  /// `POST /appointments/{id}/status/` with body `{status, cancellation_reason?}`.
  /// Only `cancelled` accepts a reason.
  Future<Appointment> updateAppointmentStatus(
    int id,
    AppointmentStatusUpdateRequest request,
  ) async {
    final path =
        '${ApiConstants.appointmentsDetail}/$id${ApiConstants.appointmentStatusSuffix}';
    final body = request.toJson();
    debugPrint(
      '[AppointmentRepo] updateAppointmentStatus called — id=$id body=$body',
    );
    debugPrint('[AppointmentRepo] updateAppointmentStatus path=$path');

    final response = await _apiClient.post(path, data: body);
    debugPrint(
      '[AppointmentRepo] updateAppointmentStatus response — '
      'status=${response.statusCode} body=${response.data}',
    );

    final parsed = Appointment.fromJson(response.data);
    debugPrint(
      '[AppointmentRepo] updateAppointmentStatus parsed — id=${parsed.id} '
      'status=${parsed.status.displayLabel}',
    );
    return parsed;
  }

  /// Reschedules an appointment (only valid while `pending` or `confirmed`).
  ///
  /// `PATCH /appointments/{id}/reschedule/` with body `{scheduled_at, ...}`.
  Future<Appointment> rescheduleAppointment(
    int id,
    AppointmentRescheduleRequest request,
  ) async {
    final path =
        '${ApiConstants.appointmentsDetail}/$id${ApiConstants.appointmentRescheduleSuffix}';
    final body = request.toJson();
    debugPrint(
      '[AppointmentRepo] rescheduleAppointment called — id=$id body=$body',
    );
    debugPrint('[AppointmentRepo] rescheduleAppointment path=$path');

    final response = await _apiClient.patch(path, data: body);
    debugPrint(
      '[AppointmentRepo] rescheduleAppointment response — '
      'status=${response.statusCode} body=${response.data}',
    );

    final parsed = Appointment.fromJson(response.data);
    debugPrint(
      '[AppointmentRepo] rescheduleAppointment parsed — id=${parsed.id} '
      'scheduled=${parsed.scheduledAt}',
    );
    return parsed;
  }

  /// Sets doctor consultation notes (fully replaced, not appended).
  ///
  /// `PATCH /appointments/{id}/doctor-notes/` with body `{doctor_notes}`.
  Future<Appointment> setDoctorNotes(int id, String notes) async {
    final path =
        '${ApiConstants.appointmentsDetail}/$id${ApiConstants.appointmentDoctorNotesSuffix}';
    final body = {'doctor_notes': notes};
    debugPrint('[AppointmentRepo] setDoctorNotes called — id=$id');
    debugPrint('[AppointmentRepo] setDoctorNotes path=$path body=$body');

    final response = await _apiClient.patch(path, data: body);
    debugPrint(
      '[AppointmentRepo] setDoctorNotes response — status=${response.statusCode} '
      'body=${response.data}',
    );

    final parsed = Appointment.fromJson(response.data);
    debugPrint(
      '[AppointmentRepo] setDoctorNotes parsed — id=${parsed.id} '
      'notes="${parsed.doctorNotes}"',
    );
    return parsed;
  }
}
