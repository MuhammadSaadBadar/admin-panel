import 'package:admin/features/patients/models/patient.dart';

/// An emergency SOS event for a patient.
///
/// Mapped from `GET /api/v1/emergency/sos/?patient_id={id}` — each event has
/// status (`active`, `resolved`, `false_alarm`), optional coordinates/notes,
/// and timestamps.
class SosEvent {
  final int id;
  final int? patientId;
  final String? patientName;
  final String? latitude;
  final String? longitude;
  final String status;
  final String? resolvedAt;
  final String notes;
  final String createdAt;

  const SosEvent({
    required this.id,
    this.patientId,
    this.patientName,
    this.latitude,
    this.longitude,
    this.status = 'active',
    this.resolvedAt,
    this.notes = '',
    this.createdAt = '',
  });

  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';

  factory SosEvent.fromJson(Map<String, dynamic> json) {
    final patientRaw = json['patient'];
    int? patientId;
    String? patientName;
    if (patientRaw is Map) {
      patientId = patientRaw['id'];
      final first = patientRaw['first_name']?.toString() ?? '';
      final last = patientRaw['last_name']?.toString() ?? '';
      patientName = [first, last].where((p) => p.isNotEmpty).join(' ');
    }

    return SosEvent(
      id: json['id'] ?? 0,
      patientId: patientId,
      patientName: patientName,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      status: json['status'] ?? 'active',
      resolvedAt: json['resolved_at']?.toString(),
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

/// Convenience alias re-export so callers can refer to the patient model
/// without a second import if needed.
typedef PatientAlias = Patient;
