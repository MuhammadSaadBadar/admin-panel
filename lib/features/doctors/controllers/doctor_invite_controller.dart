import 'package:admin/core/network/api_exceptions.dart';
import 'package:admin/features/doctors/models/doctor_invite_request.dart';
import 'package:admin/features/doctors/models/doctor_invite_response.dart';
import 'package:admin/features/doctors/repositories/doctor_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// High-level UI state of the invitation submission.
///
/// `unknown` is deliberately separated from `knownError`: it means the server
/// MAY have created the invitation (timeout / lost response), so the UI must
/// offer a verify/retry path instead of a hard failure.
enum InviteSubmissionState {
  /// Form ready, no submission in progress.
  idle,

  /// A submission is in flight.
  submitting,

  /// The invitation was confirmed created (or already pending).
  success,

  /// The backend definitively rejected the request.
  knownError,

  /// The outcome is uncertain — the server may have created the invite.
  /// UI should offer "Check Status" / "Retry".
  unknown,
}

/// Orchestrates the "Invite Doctor" form.
///
/// Responsibilities:
/// * Field-level client-side validation (email format, specialization).
/// * Guards against duplicate in-flight submissions.
/// * Calls [DoctorRepository.inviteDoctor] (the canonical transport) and maps
///   the outcome into screen-friendly observable state.
/// * Distinguishes known errors from uncertain (`unknown`) outcomes so the UI
///   never presents a misleading hard failure when the server-side result is
///   in doubt.
///
/// The screen owns navigation and text controllers; this controller owns
/// *state* and *business rules* (separation of concerns).
class DoctorInviteController extends GetxController {
  final DoctorRepository _doctorRepository;

  DoctorInviteController(this._doctorRepository);

  /// Per-field validation error messages, keyed by field name (`email`,
  /// `specialization`).
  final RxMap<String, String> fieldErrors = <String, String>{}.obs;

  /// Top-level, non-field error (e.g. server `detail`, network failure).
  final RxnString error = RxnString();

  /// Backend confirmation message on successful invitation.
  final RxnString successDetail = RxnString();

  /// True while an invite request is in flight.
  final RxBool isLoading = false.obs;

  /// Current submission state — drives the UI (button, banners, actions).
  final Rx<InviteSubmissionState> submissionState =
      InviteSubmissionState.idle.obs;

  /// True when the reported success is actually an "already pending" invite.
  final RxBool alreadyPending = false.obs;

  /// Whether an "email may be delayed" hint should be shown.
  final RxBool showEmailDelayHint = false.obs;

  /// The email of the last attempted submission (used by verify/retry).
  String _lastEmail = '';
  String _lastSpecialization = '';

  @override
  void onInit() {
    super.onInit();
    debugPrint('[DoctorInviteController] Initialized.');
  }

  /// Clears validation errors for a single field as the user types.
  void clearFieldError(String field) {
    if (fieldErrors.containsKey(field)) {
      debugPrint(
        '[DoctorInviteController] Clearing validation error for "$field".',
      );
      fieldErrors.remove(field);
    }
  }

  /// Client-side validation. Returns true when every field passes;
  /// otherwise populates [fieldErrors] with messages safe to show inline.
  bool validate({required String email, required String specialization}) {
    fieldErrors.clear();

    final String trimmedEmail = email.trim();
    final String trimmedSpecialization = specialization.trim();

    final RegExp emailPattern = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');
    if (trimmedEmail.isEmpty) {
      fieldErrors['email'] = 'Email address is required.';
    } else if (!emailPattern.hasMatch(trimmedEmail)) {
      fieldErrors['email'] = 'Enter a valid email address.';
    }

    if (trimmedSpecialization.isEmpty) {
      fieldErrors['specialization'] = 'Specialization is required.';
    }

    if (fieldErrors.isNotEmpty) {
      debugPrint(
        '[DoctorInviteController] Validation failed — '
        '${fieldErrors.length} field error(s): ${fieldErrors.values}',
      );
      return false;
    }

    debugPrint('[DoctorInviteController] Validation passed.');
    return true;
  }

  /// Sends a doctor invitation to `POST /api/v1/accounts/doctors/invite/`.
  ///
  /// Returns `true` on success (caller may then navigate), `false` on
  /// validation failure or API error. Guards against concurrent in-flight
  /// calls — a duplicate tap while loading is ignored.
  Future<bool> invite({
    required String email,
    required String specialization,
  }) async {
    if (isLoading.value) {
      debugPrint(
        '[DoctorInviteController] invite() called while already in flight — '
        'duplicate submission ignored.',
      );
      return false;
    }

    // Re-run validation synchronously before any network I/O.
    if (!validate(email: email, specialization: specialization)) {
      error.value = _formatFieldErrors(fieldErrors.values);
      debugPrint(
        '[DoctorInviteController] Aborting submit — invalid form. '
        'User-facing error: "${error.value}"',
      );
      return false;
    }

    final request = DoctorInviteRequest(
      email: email.trim(),
      specialization: specialization.trim(),
    );

    // Remember the last attempted submission so verify/retry can reuse it.
    _lastEmail = request.email;
    _lastSpecialization = request.specialization;

    debugPrint(
      '[DoctorInviteController] invite() started — '
      'email=${_maskEmail(request.email)} '
      'specialization=${request.specialization}',
    );

    isLoading.value = true;
    error.value = null;
    submissionState.value = InviteSubmissionState.submitting;
    debugPrint(
      '[DoctorInviteController] State updated: loading=true, error=null, '
      'state=submitting.',
    );

    try {
      final DoctorInviteResponse response = await _doctorRepository
          .inviteDoctor(request);

      debugPrint(
        '[DoctorInviteController] Repository returned — '
        'outcome=${response.outcome} '
        'detail="${response.detail}" '
        'errors=${response.errors.length} '
        'alreadyPending=${response.alreadyPending}',
      );

      switch (response.outcome) {
        case InviteOutcome.success:
          error.value = null;
          alreadyPending.value = response.alreadyPending;
          successDetail.value = response.detail.isNotEmpty
              ? response.detail
              : (response.alreadyPending
                    ? 'An invitation is already pending for this email.'
                    : 'Invitation sent.');
          showEmailDelayHint.value = !response.alreadyPending;
          submissionState.value = InviteSubmissionState.success;
          debugPrint(
            '[DoctorInviteController] Outcome=success '
            '(alreadyPending=${response.alreadyPending}). '
            'State -> success.',
          );
          return true;

        case InviteOutcome.knownServerError:
          error.value = response.detail.isNotEmpty
              ? response.detail
              : 'The server could not send the invitation. Please try again.';
          submissionState.value = InviteSubmissionState.knownError;
          debugPrint(
            '[DoctorInviteController] Outcome=knownServerError. '
            'State -> knownError. error="${error.value}"',
          );
          _mapBackendFieldErrors(response.errors);
          return false;

        case InviteOutcome.unknown:
          error.value = response.detail.isNotEmpty
              ? response.detail
              : 'We couldn\'t confirm whether the invitation was sent. '
                    'Please wait a moment and check status before retrying.';
          submissionState.value = InviteSubmissionState.unknown;
          debugPrint(
            '[DoctorInviteController] Outcome=unknown. State -> unknown. '
            'error="${error.value}"',
          );
          return false;
      }
    } on ApiException catch (e) {
      if (e is NetworkException) {
        // The repository has already retried once and the retry ALSO failed
        // at the network layer. The invite may or may not have been created
        // server-side — give the user an honest ("unknown") outcome.
        error.value =
            'Could not confirm whether the invitation was sent. Please wait '
            'a moment and check status before retrying.';
        submissionState.value = InviteSubmissionState.unknown;
        debugPrint(
          '[DoctorInviteController] Invitation network failure after retry — '
          'original message="$e" -> state=unknown.',
        );
        return false;
      }

      error.value = e.message;
      submissionState.value = InviteSubmissionState.knownError;
      debugPrint(
        '[DoctorInviteController] Invitation failed (ApiException) — '
        'message="${e.message}" status=${e.statusCode} '
        'fieldErrors=${e.fieldErrors?.length ?? 0} -> state=knownError.',
      );

      // Surface backend snake_case field errors (e.g. duplicate email) as
      // inline errors on the matching local fields.
      _mapBackendFieldErrors(e.fieldErrors);

      // Fallback: when the payload carried no structured errors but the
      // detail message clearly indicates a duplicate, map it to email.
      if (e.fieldErrors == null && e.message.contains('already exists')) {
        fieldErrors['email'] = e.message;
      }

      return false;
    } catch (e, stackTrace) {
      error.value = 'An unexpected error occurred. Please try again.';
      submissionState.value = InviteSubmissionState.unknown;
      debugPrint(
        '[DoctorInviteController] Invitation failed (unexpected) — error=$e '
        '-> state=unknown.',
      );
      debugPrint('[DoctorInviteController] Stack trace: $stackTrace');
      return false;
    } finally {
      isLoading.value = false;
      debugPrint('[DoctorInviteController] State updated: loading=false.');
    }
  }

  /// Verifies the current status of the last attempted invitation by querying
  /// the backend (read-only). Updates the state machine accordingly:
  /// - doctor found → success (invite was processed).
  /// - not found → remains uncertain; the invite may still be pending but
  ///   unaccepted, so we keep `unknown` with a clarified message.
  Future<void> verifyStatus() async {
    if (_lastEmail.isEmpty) {
      debugPrint('[DoctorInviteController] verifyStatus — no prior email.');
      error.value = 'Nothing to check. Please submit an invitation first.';
      return;
    }

    debugPrint(
      '[DoctorInviteController] verifyStatus — checking '
      'email=${_maskEmail(_lastEmail)}',
    );
    isLoading.value = true;
    error.value = null;

    try {
      final bool found = await _doctorRepository.verifyStatus(_lastEmail);
      if (found) {
        alreadyPending.value = false;
        successDetail.value =
            'The invitation for ${_maskEmail(_lastEmail)} has been '
            'successfully processed.';
        submissionState.value = InviteSubmissionState.success;
        debugPrint(
          '[DoctorInviteController] verifyStatus — found doctor. '
          'State -> success.',
        );
      } else {
        error.value =
            'The invitation may still be pending or the doctor list has not '
            'updated yet. Please wait a moment and try again.';
        submissionState.value = InviteSubmissionState.unknown;
        debugPrint(
          '[DoctorInviteController] verifyStatus — doctor not found '
          '(may still be pending). State stays unknown.',
        );
      }
    } catch (e) {
      error.value = 'Unable to check the invitation status. Please try again.';
      submissionState.value = InviteSubmissionState.unknown;
      debugPrint('[DoctorInviteController] verifyStatus — query failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Performs a manual, idempotent retry of the last attempted submission.
  /// Reuses the same email/specialization and relies on backend idempotency
  /// (duplicate → success) to avoid creating duplicates.
  Future<bool> retry() async {
    if (_lastEmail.isEmpty || _lastSpecialization.isEmpty) {
      debugPrint('[DoctorInviteController] retry — no prior submission.');
      error.value = 'Nothing to retry. Please submit an invitation first.';
      return false;
    }

    debugPrint(
      '[DoctorInviteController] retry — resubmitting '
      'email=${_maskEmail(_lastEmail)}',
    );
    return invite(email: _lastEmail, specialization: _lastSpecialization);
  }

  /// Resets transient state when the user edits a field (so stale banners
  /// don't linger).
  void resetTransientState() {
    error.value = null;
    successDetail.value = null;
    alreadyPending.value = false;
    showEmailDelayHint.value = false;
    submissionState.value = InviteSubmissionState.idle;
    debugPrint('[DoctorInviteController] Transient state reset -> idle.');
  }

  /// Formats one or more field-level messages into a user-facing top-level
  /// error string.
  String _formatFieldErrors(Iterable<String> messages) {
    final List<String> unique = messages.toSet().toList();
    if (unique.length == 1) return unique.first;
    return unique.map((m) => '• $m').join('\n');
  }

  /// Maps backend snake_case field keys (DRF style) onto the local
  /// camelCase keys used by the screen's inline error widgets.
  void _mapBackendFieldErrors(Map<String, List<String>>? errors) {
    if (errors == null || errors.isEmpty) return;

    errors.forEach((field, messages) {
      final String localKey = field == 'specialization'
          ? 'specialization'
          : field;
      if (messages.isNotEmpty) {
        fieldErrors[localKey] = messages.join(' ');
      }
    });
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${local[0]}***@$domain';
    return '${local.substring(0, 2)}***@$domain';
  }
}
