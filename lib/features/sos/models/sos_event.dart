import 'package:flutter/foundation.dart';

/// An emergency SOS event for the Admin SOS module.
///
/// Mapped from the `EmergencySOSEvent` schema in `Mama Health API.yaml`:
/// - `GET /api/v1/emergency/sos/` — list (admin sees all)
/// - `GET /api/v1/emergency/sos/{id}/` — single event
///
/// Fields: `id`, nested `patient` ({id, email, first_name, last_name}),
/// `latitude`, `longitude`, `status` (`active`|`resolved`|`false_alarm`),
/// `resolved_at`, `notes`, `created_at`.
class SosEvent {
  final int id;
  final int? patientId;
  final String? patientName;
  final String? patientEmail;
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
    this.patientEmail,
    this.latitude,
    this.longitude,
    this.status = 'active',
    this.resolvedAt,
    this.notes = '',
    this.createdAt = '',
  });

  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';
  bool get isFalseAlarm => status == 'false_alarm';

  /// A human-readable status label for the UI.
  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';
      case 'resolved':
        return 'Resolved';
      case 'false_alarm':
        return 'False Alarm';
      default:
        return status;
    }
  }

  /// Whether the event has usable GPS coordinates.
  bool get hasCoordinates =>
      latitude != null &&
      latitude!.isNotEmpty &&
      longitude != null &&
      longitude!.isNotEmpty;

  factory SosEvent.fromJson(Map<String, dynamic> json) {
    final patientRaw = json['patient'];
    int? patientId;
    String? patientName;
    String? patientEmail;
    if (patientRaw is Map) {
      patientId = (patientRaw['id'] as num?)?.toInt();
      final first = patientRaw['first_name']?.toString() ?? '';
      final last = patientRaw['last_name']?.toString() ?? '';
      patientName = [first, last].where((p) => p.isNotEmpty).join(' ');
      patientEmail = patientRaw['email']?.toString();
    }

    final event = SosEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      patientId: patientId,
      patientName: patientName,
      patientEmail: patientEmail,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      status: (json['status'] as String?) ?? 'active',
      resolvedAt: json['resolved_at']?.toString(),
      notes: (json['notes'] as String?) ?? '',
      createdAt: (json['created_at'] as String?) ?? '',
    );

    debugPrint(
      '[SosEvent.fromJson] parsed — id=${event.id} '
      'patient="${event.patientName}" status=${event.status} '
      'createdAt=${event.createdAt} hasCoords=${event.hasCoordinates}',
    );
    return event;
  }
}
