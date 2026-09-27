// lib/features/profile/controllers/profile_controller.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/features/profile/models/admin_profile.dart';
import 'package:admin/features/profile/models/payment_methods.dart';
import 'package:admin/features/profile/repositories/profile_repository.dart';

/// Controller for [AdminProfileScreen].
///
/// Loads the current admin's profile (`GET /auth/me/`) and saves edits
/// (`PATCH /auth/me/`). Also manages platform payment methods and commission
/// (`GET/PATCH /accounts/payment-methods/`).
class ProfileController extends GetxController {
  final ProfileRepository _repository;

  ProfileController(this._repository);

  // ── Profile State ─────────────────────────────────────────────────────────
  final Rxn<AdminProfile> profile = Rxn<AdminProfile>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  final RxBool isSaving = false.obs;
  final RxnString saveError = RxnString();
  final RxBool saveSuccess = false.obs;

  // ── Payment Methods / Commission State ──────────────────────────────────
  final Rxn<PaymentMethods> paymentMethods = Rxn<PaymentMethods>();
  final RxBool isLoadingPaymentMethods = false.obs;
  final RxnString paymentMethodsError = RxnString();

  final RxBool isUpdatingCommission = false.obs;
  final RxnString commissionUpdateError = RxnString();
  final RxBool commissionUpdateSuccess = false.obs;

  // Commission editing state
  final RxBool isEditingCommission = false.obs;
  final RxString commissionInput = ''.obs;
  final RxString commissionInputError = ''.obs;

  // Text controller for commission input
  final TextEditingController commissionTextController =
      TextEditingController();

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

  // ── Payment Methods / Commission Actions ──────────────────────────────

  /// Fetches platform payment methods including commission.
  Future<void> loadPaymentMethods() async {
    debugPrint('[ProfileController] loadPaymentMethods called');
    isLoadingPaymentMethods.value = true;
    paymentMethodsError.value = null;

    try {
      final result = await _repository.getPaymentMethods();
      paymentMethods.value = result;
      // Initialize commission input with current value
      if (result.commissionPercentage != null) {
        final value = result.commissionPercentage!.toStringAsFixed(2);
        commissionInput.value = value;
        commissionTextController.text = value;
      } else {
        commissionInput.value = '';
        commissionTextController.text = '';
      }
      debugPrint(
        '[ProfileController] loadPaymentMethods — '
        'commission=${result.commissionDisplay}',
      );
    } catch (e) {
      debugPrint('[ProfileController] loadPaymentMethods — ERROR: $e');
      paymentMethodsError.value = e.toString();
    } finally {
      isLoadingPaymentMethods.value = false;
    }
  }

  /// Updates the platform commission percentage.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> updateCommission(double percentage) async {
    debugPrint(
      '[ProfileController] updateCommission called — '
      'percentage=${percentage.toStringAsFixed(2)}%',
    );
    isUpdatingCommission.value = true;
    commissionUpdateError.value = null;
    commissionUpdateSuccess.value = false;

    try {
      final result = await _repository.updateCommission(percentage);
      paymentMethods.value = result;
      final value = result.commissionPercentage!.toStringAsFixed(2);
      commissionInput.value = value;
      commissionTextController.text = value;
      commissionUpdateSuccess.value = true;
      debugPrint(
        '[ProfileController] updateCommission — success '
        'commission=${result.commissionDisplay}',
      );
      return true;
    } catch (e) {
      debugPrint('[ProfileController] updateCommission — ERROR: $e');
      commissionUpdateError.value = e.toString();
      return false;
    } finally {
      isUpdatingCommission.value = false;
    }
  }

  /// Validates commission input.
  bool validateCommissionInput() {
    final input = commissionInput.value.trim();
    if (input.isEmpty) {
      commissionInputError.value = 'Commission percentage is required';
      return false;
    }
    final value = double.tryParse(input);
    if (value == null) {
      commissionInputError.value = 'Please enter a valid number';
      return false;
    }
    if (value < 0) {
      commissionInputError.value = 'Commission cannot be negative';
      return false;
    }
    if (value > 999.99) {
      commissionInputError.value = 'Commission cannot exceed 999.99%';
      return false;
    }
    commissionInputError.value = '';
    return true;
  }

  /// Saves the commission from the input field.
  Future<void> saveCommission() async {
    if (!validateCommissionInput()) return;
    final value = double.parse(commissionInput.value.trim());
    await updateCommission(value);
  }

  /// Toggles commission editing mode.
  void toggleCommissionEditing() {
    isEditingCommission.value = !isEditingCommission.value;
    if (!isEditingCommission.value) {
      // Reset input to current value when canceling
      final current = paymentMethods.value?.commissionPercentage;
      final value = current != null ? current.toStringAsFixed(2) : '';
      commissionInput.value = value;
      commissionTextController.text = value;
      commissionInputError.value = '';
      commissionUpdateError.value = null;
      commissionUpdateSuccess.value = false;
    } else {
      // When entering edit mode, set the text field to current value
      final current = paymentMethods.value?.commissionPercentage;
      final value = current != null ? current.toStringAsFixed(2) : '';
      commissionInput.value = value;
      commissionTextController.text = value;
      commissionInputError.value = '';
    }
  }

  /// Resets commission-related state.
  void resetCommissionState() {
    commissionUpdateError.value = null;
    commissionUpdateSuccess.value = false;
    commissionInputError.value = '';
  }

  // ── Combined Load ──────────────────────────────────────────────────────

  /// Loads both profile and payment methods.
  Future<void> loadAllData() async {
    await Future.wait([loadProfile(), loadPaymentMethods()]);
  }

  @override
  void onClose() {
    commissionTextController.dispose();
    super.onClose();
  }
}
