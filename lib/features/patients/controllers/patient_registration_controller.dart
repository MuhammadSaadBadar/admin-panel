import 'package:admin/core/network/api_exceptions.dart';
import 'package:admin/features/auth/models/patient_registration_request.dart';
import 'package:admin/features/auth/models/registration_response.dart';
import 'package:admin/features/auth/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Orchestrates the patient self-registration screen.
///
/// Responsibilities:
/// * Field-level client-side validation (email format, password strength,
///   required names/phone).
/// * Guards against duplicate in-flight submissions.
/// * Calls [AuthRepository.register] (the canonical Auth transport) and maps
///   the outcome into screen-friendly observable state.
///
/// The screen owns navigation and form controllers; this controller owns
/// *state* and *business rules* (separation of concerns).
class PatientRegistrationController extends GetxController {
  final AuthRepository _authRepository;

  PatientRegistrationController(this._authRepository);

  /// Per-field validation error messages, keyed by field name
  /// (`firstName`, `lastName`, `email`, `phoneNumber`, `password`).
  final RxMap<String, String> fieldErrors = <String, String>{}.obs;

  /// Top-level, non-field error (e.g. server `detail`, network failure).
  final RxnString error = RxnString();

  /// Backend confirmation message on successful registration.
  final RxnString successDetail = RxnString();

  /// True while a registration request is in flight.
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[PatientRegistrationController] Initialized.');
  }

  /// Clears validation errors for a single field as the user types.
  void clearFieldError(String field) {
    if (fieldErrors.containsKey(field)) {
      debugPrint(
        '[PatientRegistrationController] Clearing validation error for "$field".',
      );
      fieldErrors.remove(field);
    }
  }

  /// Client-side validation. Returns true when every field passes;
  /// otherwise populates [fieldErrors] with messages safe to show inline.
  bool validate({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) {
    fieldErrors.clear();

    final String trimmedFirstName = firstName.trim();
    final String trimmedLastName = lastName.trim();
    final String trimmedEmail = email.trim();
    final String trimmedPhone = phoneNumber.trim();

    if (trimmedFirstName.isEmpty) {
      fieldErrors['firstName'] = 'First name is required.';
    } else if (trimmedFirstName.length < 2) {
      fieldErrors['firstName'] = 'First name must be at least 2 characters.';
    }

    if (trimmedLastName.isEmpty) {
      fieldErrors['lastName'] = 'Last name is required.';
    } else if (trimmedLastName.length < 2) {
      fieldErrors['lastName'] = 'Last name must be at least 2 characters.';
    }

    final RegExp emailPattern = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');
    if (trimmedEmail.isEmpty) {
      fieldErrors['email'] = 'Email address is required.';
    } else if (!emailPattern.hasMatch(trimmedEmail)) {
      fieldErrors['email'] = 'Enter a valid email address.';
    }

    if (trimmedPhone.isEmpty) {
      fieldErrors['phoneNumber'] = 'Phone number is required.';
    } else if (trimmedPhone.length < 7) {
      fieldErrors['phoneNumber'] =
          'Phone number must be at least 7 digits (use full international format, e.g. +923001234567).';
    }

    if (password.isEmpty) {
      fieldErrors['password'] = 'Password is required.';
    } else if (password.length < 8) {
      fieldErrors['password'] = 'Password must be at least 8 characters.';
    } else if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      fieldErrors['password'] =
          'Password must include at least one letter and one number.';
    }

    if (fieldErrors.isNotEmpty) {
      debugPrint(
        '[PatientRegistrationController] Validation failed — '
        '${fieldErrors.length} field error(s): ${fieldErrors.values}',
      );
      return false;
    }

    debugPrint('[PatientRegistrationController] Validation passed.');
    return true;
  }

  /// Submits a patient registration to `POST /auth/register/`.
  ///
  /// Returns `true` on success (caller may then navigate), `false` on
  /// validation failure or API error. Guards against concurrent in-flight
  /// calls — a duplicate tap while loading is ignored.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    if (isLoading.value) {
      debugPrint(
        '[PatientRegistrationController] register() called while already in '
        'flight — duplicate submission ignored.',
      );
      return false;
    }

    // Re-run validation synchronously before any network I/O.
    if (!validate(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    )) {
      // Surface the actual validation message(s) instead of a generic
      // fallback so the user sees exactly what needs correcting.
      error.value = _formatFieldErrors(fieldErrors.values);
      debugPrint(
        '[PatientRegistrationController] Aborting submit — invalid form. '
        'User-facing error: "${error.value}"',
      );
      return false;
    }

    final request = PatientRegistrationRequest(
      email: email.trim(),
      password: password,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phoneNumber: phoneNumber.trim(),
    );

    debugPrint(
      '[PatientRegistrationController] register() started — '
      'email=${_maskEmail(request.email)} '
      'phone=+*** '
      'first_name=${request.firstName} last_name=${request.lastName}',
    );
    debugPrint('[PatientRegistrationController] password omitted from logs.');

    isLoading.value = true;
    error.value = null;
    debugPrint(
      '[PatientRegistrationController] State updated: loading=true, error=null.',
    );

    try {
      final RegistrationResponse response = await _authRepository.register(
        request,
      );

      debugPrint(
        '[PatientRegistrationController] Registration succeeded — '
        'detail="${response.detail}" errors=${response.errors.length}',
      );

      if (response.detail.isNotEmpty) {
        error.value = null;
        successDetail.value = response.detail;
        debugPrint(
          '[PatientRegistrationController] Backend confirmation: ${response.detail}',
        );
      }

      return true;
    } on ApiException catch (e) {
      if (e is NetworkException) {
        // By the time a NetworkException reaches here, the repository has
        // already retried once and the retry ALSO failed at the network
        // layer. The patient may or may not have been created server-side —
        // give the user an honest message and suggest checking the list.
        error.value =
            'Could not confirm the registration due to a network problem. '
            'Please check the patient list before retrying — the patient may '
            'have been created.';
        debugPrint(
          '[PatientRegistrationController] Registration network failure after '
          'retry — original message="$e"',
        );
        return false;
      }

      error.value = e.message;
      debugPrint(
        '[PatientRegistrationController] Registration failed (ApiException) — '
        'message="${e.message}" status=${e.statusCode} '
        'fieldErrors=${e.fieldErrors?.length ?? 0}',
      );

      // Surface backend snake_case field errors (e.g. duplicate email,
      // invalid phone) as inline errors on the matching local fields.
      _mapBackendFieldErrors(e.fieldErrors);

      // Fallback: when the payload carried no structured errors but the
      // detail message clearly indicates a duplicate, map it to email.
      if (e.fieldErrors == null && e.message.contains('already exists')) {
        fieldErrors['email'] = e.message;
      }

      return false;
    } catch (e, stackTrace) {
      error.value = 'An unexpected error occurred. Please try again.';
      debugPrint(
        '[PatientRegistrationController] Registration failed (unexpected) — error=$e',
      );
      debugPrint('[PatientRegistrationController] Stack trace: $stackTrace');
      return false;
    } finally {
      isLoading.value = false;
      debugPrint(
        '[PatientRegistrationController] State updated: loading=false.',
      );
    }
  }

  /// Formats one or more field-level messages into a user-facing top-level
  /// error string. A single message is shown verbatim; multiple messages
  /// are presented as a clear bulleted list.
  String _formatFieldErrors(Iterable<String> messages) {
    final List<String> unique = messages.toSet().toList();
    if (unique.length == 1) return unique.first;
    return unique.map((m) => '• $m').join('\n');
  }

  /// Maps backend snake_case field keys (DRF style) onto the local
  /// camelCase keys used by the screen's inline error widgets.
  void _mapBackendFieldErrors(Map<String, List<String>>? errors) {
    if (errors == null || errors.isEmpty) return;

    const Map<String, String> keyMapping = {
      'first_name': 'firstName',
      'last_name': 'lastName',
      'phone_number': 'phoneNumber',
    };

    errors.forEach((field, messages) {
      final String localKey = keyMapping[field] ?? field;
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
