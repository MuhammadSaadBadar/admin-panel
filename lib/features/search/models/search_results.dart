import 'package:admin/features/doctors/models/doctor.dart';
import 'package:admin/features/patients/models/patient.dart';

/// Results of a global admin search.
///
/// Mapped from the admin-only `GET /api/v1/reports/search/?q=<term>` response.
/// The backend caps each category at `limit` (default 10) and returns all
/// three groups in a single payload — no pagination.
///
/// Doctors & patients reuse the existing [Doctor] / [Patient] models since the
/// search endpoint returns the same account schema (id, email, first_name,
/// last_name, phone_number, is_active, nested doctor_profile / patient_profile).
/// Appointments come back in a reduced shape (id + patient/doctor names + date
/// + status), so they use the lightweight [AppointmentSearchHit] below.
class SearchResults {
  final List<Doctor> doctors;
  final List<Patient> patients;
  final List<AppointmentSearchHit> appointments;

  const SearchResults({
    this.doctors = const [],
    this.patients = const [],
    this.appointments = const [],
  });

  /// Overall number of hits across all categories.
  int get totalCount => doctors.length + patients.length + appointments.length;

  /// Whether every category is empty.
  bool get isEmpty => totalCount == 0;

  bool get hasDoctors => doctors.isNotEmpty;
  bool get hasPatients => patients.isNotEmpty;
  bool get hasAppointments => appointments.isNotEmpty;

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    final rawDoctors = json['doctors'];
    final rawPatients = json['patients'];
    final rawAppointments = json['appointments'];

    return SearchResults(
      doctors: rawDoctors is List
          ? rawDoctors
                .map((e) => Doctor.fromJson((e as Map).cast<String, dynamic>()))
                .toList()
          : const [],
      patients: rawPatients is List
          ? rawPatients
                .map(
                  (e) => Patient.fromJson((e as Map).cast<String, dynamic>()),
                )
                .toList()
          : const [],
      appointments: rawAppointments is List
          ? rawAppointments
                .map(
                  (e) => AppointmentSearchHit.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList()
          : const [],
    );
  }

  @override
  String toString() =>
      'SearchResults(doctors=${doctors.length}, '
      'patients=${patients.length}, appointments=${appointments.length})';
}

/// A lightweight appointment hit returned by the search endpoint.
///
/// Full [Appointment] objects aren't required for the result list; we only
/// need enough to render a row and navigate to the full detail screen on tap.
class AppointmentSearchHit {
  final int id;
  final String patientName;
  final String doctorName;
  final String scheduledAt;
  final String status;

  const AppointmentSearchHit({
    required this.id,
    this.patientName = '',
    this.doctorName = '',
    this.scheduledAt = '',
    this.status = 'unknown',
  });

  factory AppointmentSearchHit.fromJson(Map<String, dynamic> json) {
    // The backend may nest patient/doctor as objects ({first_name, last_name})
    // or as plain name strings. Handle both.
    String personName(dynamic person, {String fallback = ''}) {
      if (person is Map) {
        final first = person['first_name']?.toString() ?? '';
        final last = person['last_name']?.toString() ?? '';
        final joined = [first, last].where((p) => p.isNotEmpty).join(' ');
        return joined.isEmpty ? fallback : joined;
      }
      if (person is String && person.isNotEmpty) return person;
      return fallback;
    }

    final patient = json['patient'];
    final doctor = json['doctor'];

    return AppointmentSearchHit(
      id: (json['id'] as num?)?.toInt() ?? 0,
      patientName: patient == null
          ? (json['patient_name']?.toString() ?? '')
          : personName(patient),
      doctorName: doctor == null
          ? (json['doctor_name']?.toString() ?? '')
          : personName(doctor),
      scheduledAt:
          json['scheduled_at']?.toString() ??
          json['date']?.toString() ??
          json['slot']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'unknown',
    );
  }

  @override
  String toString() =>
      'AppointmentSearchHit(id=$id, patient=$patientName, doctor=$doctorName, '
      'status=$status)';
}
