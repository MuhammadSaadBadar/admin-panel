import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/admin_profile.dart';
import '../repositories/profile_repository.dart';

/// Controller for [AdminProfileScreen].
///
/// Loads the current admin's profile (`GET /auth/me/`) and saves edits
/// (`PATCH /auth/me/`). Exposes reactive state so the screen can render
/// loading / error / success states cleanly.
class ProfileController extends GetxController {
  final ProfileRepository _repository;

  ProfileController(this._repository);

  // ── State ──────────────────────────────────────────────────────────────
  final Rxn<AdminProfile> profile = Rxn<AdminProfile>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  final RxBool isSaving = false.obs;
  final RxnString saveError = RxnString();
  final RxBool saveSuccess = false.obs;

  // ── Actions ─────────────────────────────────────────────────────────────
  /// Fetches the current admin's profile from `GET /auth/me/`.
  Future<void> loadProfile() async {
    debugPrint('[ProfileController] loadProfile called');
    isLoading.value = true;
    error.value = null;

    try {
      final result = await _repository.getCurrentUser();
      profile.value = result;
      debugPrint(
        '[ProfileController] loadProfile — loaded profile '
        'id=${result.id} name="${result.fullName}"',
      );
    } catch (e) {
      debugPrint('[ProfileController] loadProfile — ERROR: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      debugPrint('[ProfileController] loadProfile — isLoading=false');
    }
  }

  /// Updates the admin's profile via `PATCH /auth/me/`.
  ///
  /// Returns `true` on success, `false` on failure (the error is stored in
  /// [saveError] for the UI to display).
  Future<bool> saveProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    debugPrint('[ProfileController] saveProfile called');
    isSaving.value = true;
    saveError.value = null;
    saveSuccess.value = false;

    try {
      final updated = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      profile.value = updated;
      saveSuccess.value = true;
      debugPrint(
        '[ProfileController] saveProfile — success id=${updated.id} '
        'name="${updated.fullName}"',
      );
      return true;
    } catch (e) {
      debugPrint('[ProfileController] saveProfile — ERROR: $e');
      saveError.value = e.toString();
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Resets transient save flags (used when the edit form is re-opened).
  void resetSaveState() {
    saveError.value = null;
    saveSuccess.value = false;
  }
}
