import 'package:admin/core/network/api_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../repositories/profile_repository.dart';

/// Controller for [ChangePasswordScreen].
///
/// Calls `POST /auth/password/change/` and surfaces backend validation
/// messages (including structured field errors) to the UI.
class ChangePasswordController extends GetxController {
  final ProfileRepository _repository;

  ChangePasswordController(this._repository);

  // ── State ──────────────────────────────────────────────────────────────
  final RxBool isChanging = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool success = false.obs;

  /// Backend field-level validation errors keyed by API field name
  /// (e.g. `old_password`, `new_password`).
  final RxMap<String, List<String>> fieldErrors = <String, List<String>>{}.obs;

  // ── Actions ─────────────────────────────────────────────────────────────
  /// Changes the admin's password via `POST /auth/password/change/`.
  ///
  /// Returns `true` on success, `false` on failure. On failure, structured
  /// backend field errors (if any) are stored in [fieldErrors] and a general
  /// message in [errorMessage].
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    debugPrint('[ChangePasswordController] changePassword called');

    // Prevent duplicate submissions while an attempt is in-flight.
    if (isChanging.value) {
      debugPrint(
        '[ChangePasswordController] changePassword — already in progress, '
        'ignoring duplicate call.',
      );
      return false;
    }

    isChanging.value = true;
    errorMessage.value = null;
    success.value = false;
    fieldErrors.clear();

    try {
      await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      success.value = true;
      debugPrint(
        '[ChangePasswordController] changePassword — SUCCESS (${DateTime.now()})',
      );
      return true;
    } catch (e) {
      debugPrint('[ChangePasswordController] changePassword — ERROR: $e');
      errorMessage.value = _extractErrorMessage(e);
      return false;
    } finally {
      isChanging.value = false;
      debugPrint(
        '[ChangePasswordController] changePassword — isChanging=false',
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _extractErrorMessage(Object error) {
    if (error is ApiException) {
      // Surface structured field errors for the relevant fields.
      final errors = error.fieldErrors;
      if (errors != null && errors.isNotEmpty) {
        fieldErrors.assignAll(errors);
        debugPrint('[ChangePasswordController] field errors captured: $errors');
      }
      return error.message;
    }
    return error.toString();
  }
}
