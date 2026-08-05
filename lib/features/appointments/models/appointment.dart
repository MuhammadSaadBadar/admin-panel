/// Appointment-related models mirroring the Mama Health API schemas.
///
/// API contract (from `Mama Health API.yaml`):
///   GET    /api/v1/appointments/                    -> paginated `{count,next,previous,results}`
///   GET    /api/v1/appointments/{id}/               -> single `Appointment`
///   POST   /api/v1/appointments/{id}/status/        -> body `{status, cancellation_reason?}`
///   PATCH  /api/v1/appointments/{id}/reschedule/    -> body `{scheduled_at, duration_minutes?}`
///   PATCH  /api/v1/appointments/{id}/doctor-notes/  -> body `{doctor_notes}`
///
/// `patient` and `doctor` are nested `BriefUser` objects (id, email, first_name,
/// last_name) — never flat name strings.

/// Nested patient/doctor object inside an [Appointment].
class BriefUser {
  final int id;
  final String email;
  final String firstName;
  final String lastName;

  const BriefUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  String get fullName {
    final parts = [firstName, lastName].where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Unknown' : parts.join(' ');
  }

  factory BriefUser.fromJson(Map<String, dynamic> json) => BriefUser(
    id: json['id'] ?? 0,
    email: json['email'] ?? '',
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
  };
}

/// Appointment statuses enforced by the server state machine.
enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  noShow,
  unknown;

  /// Parses a raw API string into the enum. Falls back to [AppointmentStatus
  /// .unknown] for unrecognized values so the UI never crashes on new statuses.
  static AppointmentStatus fromApi(String? raw) {
    if (raw == null) return AppointmentStatus.unknown;
    switch (raw.toLowerCase()) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.unknown;
    }
  }

  /// The API string value for this status (used in request bodies).
  String get apiValue {
    switch (this) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.noShow:
        return 'no_show';
      case AppointmentStatus.unknown:
        return 'unknown';
    }
  }

  String get displayLabel {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No-show';
      case AppointmentStatus.unknown:
        return 'Unknown';
    }
  }

  /// Whether this status is terminal (no further transitions allowed).
  bool get isTerminal =>
      this == AppointmentStatus.completed ||
      this == AppointmentStatus.cancelled ||
      this == AppointmentStatus.noShow;
}

/// Appointment types.
enum AppointmentType {
  inPerson,
  videoConsultation,
  unknown;

  static AppointmentType fromApi(String? raw) {
    if (raw == null) return AppointmentType.unknown;
    switch (raw.toLowerCase()) {
      case 'in_person':
        return AppointmentType.inPerson;
      case 'video_consultation':
        return AppointmentType.videoConsultation;
      default:
        return AppointmentType.unknown;
    }
  }

  String get displayLabel {
    switch (this) {
      case AppointmentType.inPerson:
        return 'In-Person';
      case AppointmentType.videoConsultation:
        return 'Video Consultation';
      case AppointmentType.unknown:
        return 'Appointment';
    }
  }
}

/// A single appointment as returned by the API.
class Appointment {
  final int id;
  final BriefUser patient;
  final BriefUser doctor;
  final AppointmentType appointmentType;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final AppointmentStatus status;
  final String meetingLink;
  final String reason;
  final String doctorNotes;
  final String cancellationReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Appointment({
    required this.id,
    required this.patient,
    required this.doctor,
    required this.appointmentType,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    required this.meetingLink,
    required this.reason,
    required this.doctorNotes,
    required this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] ?? 0,
    patient: json['patient'] is Map
        ? BriefUser.fromJson((json['patient'] as Map).cast<String, dynamic>())
        : const BriefUser(id: 0, email: '', firstName: 'Unknown', lastName: ''),
    doctor: json['doctor'] is Map
        ? BriefUser.fromJson((json['doctor'] as Map).cast<String, dynamic>())
        : const BriefUser(id: 0, email: '', firstName: 'Unknown', lastName: ''),
    appointmentType: AppointmentType.fromApi(json['appointment_type']),
    scheduledAt: json['scheduled_at'] != null
        ? DateTime.tryParse(json['scheduled_at'].toString())
        : null,
    durationMinutes: json['duration_minutes'] ?? 0,
    status: AppointmentStatus.fromApi(json['status']),
    meetingLink: json['meeting_link'] ?? '',
    reason: json['reason'] ?? '',
    doctorNotes: json['doctor_notes'] ?? '',
    cancellationReason: json['cancellation_reason'] ?? '',
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient': patient.toJson(),
    'doctor': doctor.toJson(),
    'appointment_type': appointmentType.name,
    'scheduled_at': scheduledAt?.toIso8601String(),
    'duration_minutes': durationMinutes,
    'status': status.apiValue,
    'meeting_link': meetingLink,
    'reason': reason,
    'doctor_notes': doctorNotes,
    'cancellation_reason': cancellationReason,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  /// Whether this appointment is in the future.
  bool get isUpcoming {
    final scheduled = scheduledAt;
    if (scheduled == null) return false;
    return scheduled.isAfter(DateTime.now());
  }
}

/// Paginated appointments response wrapper, matching the API's
/// `{count, next, previous, results}` shape.
class PaginatedAppointments {
  final int count;
  final String? next;
  final String? previous;
  final List<Appointment> results;

  const PaginatedAppointments({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedAppointments.fromJson(Map<String, dynamic> json) =>
      PaginatedAppointments(
        count: json['count'] ?? 0,
        next: json['next'],
        previous: json['previous'],
        results: json['results'] is List
            ? (json['results'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map(Appointment.fromJson)
                  .toList()
            : const [],
      );
}

/// Request body for `POST /appointments/{id}/status/`.
class AppointmentStatusUpdateRequest {
  final AppointmentStatus status;
  final String? cancellationReason;

  const AppointmentStatusUpdateRequest({
    required this.status,
    this.cancellationReason,
  });

  Map<String, dynamic> toJson() => {
    'status': status.apiValue,
    if (cancellationReason != null && cancellationReason!.trim().isNotEmpty)
      'cancellation_reason': cancellationReason!.trim(),
  };
}

/// Request body for `PATCH /appointments/{id}/reschedule/`.
class AppointmentRescheduleRequest {
  final DateTime scheduledAt;
  final int? durationMinutes;

  const AppointmentRescheduleRequest({
    required this.scheduledAt,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
    'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    if (durationMinutes != null) 'duration_minutes': durationMinutes,
  };
}

/// Request body for `PATCH /appointments/{id}/doctor-notes/`.
class DoctorNotesRequest {
  final String doctorNotes;

  const DoctorNotesRequest({required this.doctorNotes});

  Map<String, dynamic> toJson() => {'doctor_notes': doctorNotes};
}
