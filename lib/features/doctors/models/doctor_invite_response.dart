/// Possible outcomes of a doctor-invitation submission.
///
/// The frontend MUST never present a definitive failure when the server-side
/// outcome is uncertain. Timeouts and lost responses are classified as
/// [InviteOutcome.unknown] so the UI can offer a safe verify/retry path
/// instead of a misleading "Network Error".
enum InviteOutcome {
  /// The invite was confirmed created — either a 2xx response, or a retry
  /// returned "already pending" which PROVES the original create succeeded.
  success,

  /// The backend definitively rejected the request (validation error, 5xx).
  /// There is no uncertainty — the invite was NOT created.
  knownServerError,

  /// The request may or may not have been processed (timeout, connection
  /// dropped, lost response). The UI must offer verify/retry rather than a
  /// hard failure.
  unknown,
}

/// Response envelope for `POST /api/v1/accounts/doctors/invite/`.
///
/// Backend contract:
/// - `201` → `{"detail": "Invite sent."}`
/// - `400` → `{"detail": "...", "errors": {"email": [...]}}`
/// - `400/409` (duplicate) → `{"detail": "... already pending ..."}`
///
/// All fields are nullable-safe with empty defaults so a structurally
/// unexpected (but parseable) body never crashes the caller.
class DoctorInviteResponse {
  final String detail;
  final Map<String, List<String>> errors;

  /// How the repository classified this attempt.
  final InviteOutcome outcome;

  /// True when the backend indicated an invite is already pending for this
  /// email (proves a previous attempt created it).
  final bool alreadyPending;

  const DoctorInviteResponse({
    this.detail = '',
    this.errors = const {},
    this.outcome = InviteOutcome.success,
    this.alreadyPending = false,
  });

  factory DoctorInviteResponse.fromJson(Map<String, dynamic> json) {
    final rawDetail = json['detail'];
    final detail = rawDetail is String
        ? rawDetail
        : (rawDetail?.toString() ?? '');

    final Map<String, List<String>> errors;
    final rawErrors = json['errors'];
    if (rawErrors is Map) {
      errors = rawErrors.map(
        (key, value) => MapEntry(
          key.toString(),
          value is List
              ? value.map((e) => e.toString()).toList()
              : <String>[value.toString()],
        ),
      );
    } else {
      errors = const {};
    }

    return DoctorInviteResponse(
      detail: detail,
      errors: errors,
      alreadyPending: _mentionsAlreadyPending(detail, errors),
    );
  }

  /// Convenience factory for an explicit outcome (used for network-unknown
  /// returns and manually-constructed states).
  factory DoctorInviteResponse.outcome(
    InviteOutcome outcome, {
    String detail = '',
    Map<String, List<String>> errors = const {},
    bool alreadyPending = false,
  }) {
    return DoctorInviteResponse(
      detail: detail,
      errors: errors,
      outcome: outcome,
      alreadyPending:
          alreadyPending ||
          (outcome == InviteOutcome.success && detail.isEmpty),
    );
  }

  static bool _mentionsAlreadyPending(
    String detail,
    Map<String, List<String>> errors,
  ) {
    final detailLower = detail.toLowerCase();
    if (detailLower.contains('already pending') ||
        detailLower.contains('already exists')) {
      return true;
    }
    final emailErrors = errors['email'];
    if (emailErrors != null) {
      return emailErrors.any(
        (e) =>
            e.toLowerCase().contains('already pending') ||
            e.toLowerCase().contains('already exists'),
      );
    }
    return false;
  }
}
