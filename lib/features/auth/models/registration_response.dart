/// Response envelope for `POST /api/v1/auth/register/`.
///
/// Backend contract:
/// - `201` → `{"detail": "Registration successful. Check your email to verify your account."}`
/// - `400` → `{"detail": "An account with this email already exists...", "errors": {"email": [...]}}`
///
/// All fields are nullable-safe with empty defaults so a structurally
/// unexpected (but parseable) body never crashes the caller.
class RegistrationResponse {
  final String detail;
  final Map<String, List<String>> errors;

  const RegistrationResponse({this.detail = '', this.errors = const {}});

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    // `detail` — present on 201 success and 400 duplicate-email failures.
    final rawDetail = json['detail'];
    final detail = rawDetail is String
        ? rawDetail
        : (rawDetail?.toString() ?? '');

    // `errors` — a map of field-name → list of human-readable messages.
    // May be absent, null, or not a map (e.g. DRF sometimes returns
    // top-level non-field errors as a bare list).
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

    return RegistrationResponse(detail: detail, errors: errors);
  }
}
