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

/// Payment state machine for the manual (no-gateway) payment flow.
///
/// The backend calculates the final amount (doctor fee + admin commission) and
/// drives status transitions. The frontend never trusts its own calculations —
/// it reflects whatever the API returns.
///
///   pending            — no payment required (free) OR patient hasn't paid yet
///   awaitingVerification — patient tapped "I have paid" (`patient_marked_paid_at`
///                          set); doctor/admin must verify
///   verified           — doctor/admin confirmed receipt (`confirmed_at` set);
///                          appointment is confirmed in the same call
///   rejected           — doctor/admin rejected the claim
enum PaymentState {
  pending,
  awaitingVerification,
  verified,
  rejected,
  none;

  /// Parses a raw payment `status` string from the API. Falls back to [none]
  /// when the payment object is absent (free consultation).
  static PaymentState fromApi(String? raw) {
    if (raw == null) return PaymentState.none;
    switch (raw.toLowerCase()) {
      case 'pending':
        return PaymentState.pending;
      case 'awaiting_verification':
        return PaymentState.awaitingVerification;
      case 'verified':
      case 'paid':
      case 'received':
        return PaymentState.verified;
      case 'rejected':
      case 'failed':
        return PaymentState.rejected;
      default:
        return PaymentState.none;
    }
  }

  String get displayLabel {
    switch (this) {
      case PaymentState.pending:
        return 'Pending';
      case PaymentState.awaitingVerification:
        return 'Awaiting Verification';
      case PaymentState.verified:
        return 'Verified / Paid';
      case PaymentState.rejected:
        return 'Rejected';
      case PaymentState.none:
        return 'No Payment';
    }
  }

  /// Whether the patient can still tap "I have paid".
  bool get patientCanMarkPaid =>
      this == PaymentState.pending || this == PaymentState.rejected;

  /// Whether a doctor/admin can verify this payment.
  bool get canVerify => this == PaymentState.awaitingVerification;
}

/// The nested `payment` object returned on an appointment.
///
/// Mirrors the backend `AppointmentPayment` serializer:
///   doctor_fee, commission_percentage, commission_amount, total_amount,
///   status, patient_marked_paid_at, confirmed_at, payment_reference
class AppointmentPaymentInfo {
  final String doctorFee;
  final String commissionPercentage;
  final String commissionAmount;
  final String totalAmount;
  final PaymentState status;
  final DateTime? patientMarkedPaidAt;
  final DateTime? confirmedAt;
  final String paymentReference;

  const AppointmentPaymentInfo({
    required this.doctorFee,
    required this.commissionPercentage,
    required this.commissionAmount,
    required this.totalAmount,
    required this.status,
    required this.patientMarkedPaidAt,
    required this.confirmedAt,
    required this.paymentReference,
  });

  factory AppointmentPaymentInfo.fromJson(Map<String, dynamic> json) =>
      AppointmentPaymentInfo(
        doctorFee: (json['doctor_fee'] ?? '').toString(),
        commissionPercentage: (json['commission_percentage'] ?? '').toString(),
        commissionAmount: (json['commission_amount'] ?? '').toString(),
        totalAmount: (json['total_amount'] ?? '').toString(),
        status: PaymentState.fromApi(json['status']?.toString()),
        patientMarkedPaidAt: json['patient_marked_paid_at'] != null
            ? DateTime.tryParse(json['patient_marked_paid_at'].toString())
            : null,
        confirmedAt: json['confirmed_at'] != null
            ? DateTime.tryParse(json['confirmed_at'].toString())
            : null,
        paymentReference: (json['payment_reference'] ?? '').toString(),
      );

  /// Total payable parsed as a double, or 0 if unparseable.
  double get totalAmountValue => double.tryParse(totalAmount) ?? 0;

  /// Whether a payment exists (i.e. the doctor has a consultation fee).
  bool get exists => status != PaymentState.none;

  /// Whether the appointment is effectively confirmed from a payment standpoint.
  bool get isConfirmed => status == PaymentState.verified;

  Map<String, dynamic> toJson() => {
    'doctor_fee': doctorFee,
    'commission_percentage': commissionPercentage,
    'commission_amount': commissionAmount,
    'total_amount': totalAmount,
    'status': status.name,
    'patient_marked_paid_at': patientMarkedPaidAt?.toIso8601String(),
    'confirmed_at': confirmedAt?.toIso8601String(),
    'payment_reference': paymentReference,
  };
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
  final AppointmentPaymentInfo? payment;
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
    required this.payment,
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
    payment: json['payment'] is Map
        ? AppointmentPaymentInfo.fromJson(
            (json['payment'] as Map).cast<String, dynamic>(),
          )
        : null,
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
    'payment': payment?.toJson(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  /// Whether this appointment is in the future.
  bool get isUpcoming {
    final scheduled = scheduledAt;
    if (scheduled == null) return false;
    return scheduled.isAfter(DateTime.now());
  }

  /// Convenience: whether a payment exists on this appointment.
  bool get hasPayment => payment?.exists ?? false;

  /// Convenience: whether the payment is awaiting doctor/admin verification.
  bool get paymentAwaitingVerification =>
      payment?.status == PaymentState.awaitingVerification;

  /// Whether the patient can mark this appointment as paid.
  bool get patientCanMarkPaid => payment?.status.patientCanMarkPaid ?? false;

  /// Whether a doctor/admin can verify this appointment's payment.
  bool get canVerifyPayment => payment?.status.canVerify ?? false;

  /// Whether `POST /appointments/{id}/status/` with `status=confirmed` is the
  /// correct backend call for this appointment (no payment attached — free
  /// consultation). When false, the only correct path to `confirmed` is via
  /// `POST .../payment/confirm/` after the patient marks the fee as paid.
  bool get canConfirmFreely => payment == null;

  /// Whether this appointment has a consultation fee that is not yet verified/paid.
  bool get isUnpaid => hasPayment && payment?.status != PaymentState.verified;
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
