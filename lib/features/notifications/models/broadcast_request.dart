/// The target audience for a broadcast notification.
///
/// Maps to the `target_role` field of `BroadcastRequest`:
/// - [everyone] → `null` (both patients and doctors)
/// - [patients] → `"patient"`
/// - [doctors] → `"doctor"`
///
/// Admins themselves are never recipients of a broadcast.
enum BroadcastTargetRole { everyone, patients, doctors }

/// A broadcast notification request sent by an admin via
/// `POST /api/v1/notifications/broadcast/`.
///
/// The backend fans out asynchronously via Celery and returns `202 Accepted`
/// immediately, before delivery actually happens. `target_role` is optional:
/// omit it (or send null) to reach both patients and doctors.
class BroadcastRequest {
  final String title;
  final String body;
  final BroadcastTargetRole targetRole;

  const BroadcastRequest({
    required this.title,
    required this.body,
    this.targetRole = BroadcastTargetRole.everyone,
  });

  /// Serializes to the backend payload. When [targetRole] is [everyone],
  /// `target_role` is omitted (which the backend treats as "everyone").
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'title': title, 'body': body};
    switch (targetRole) {
      case BroadcastTargetRole.everyone:
        break;
      case BroadcastTargetRole.patients:
        json['target_role'] = 'patient';
        break;
      case BroadcastTargetRole.doctors:
        json['target_role'] = 'doctor';
        break;
    }
    return json;
  }
}
