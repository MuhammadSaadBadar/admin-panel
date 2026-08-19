import 'package:admin/core/network/api_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/diet_plan.dart';
import '../repositories/patient_repository.dart';

/// Controller for the Diet Plan Management screens.
///
/// Loads the patient's diet-plan history (`GET /api/v1/diet/plans/?patient_id=`),
/// their current active plan (`GET /api/v1/diet/plans/active/?patient_id=`),
/// and supports create (`POST /api/v1/diet/plans/`), update
/// (`PATCH /api/v1/diet/plans/{id}/`), and delete (`DELETE /api/v1/diet/plans/{id}/`).
///
/// Follows the same reactive pattern as the other patient controllers: holds
/// [Rx] state (plans, activePlan, loading, error), exposes a [load] entry
/// point the UI calls once it knows the patientId, and rethrows mapped errors
/// for create/update/delete so the screens can surface them inline.
class DietPlanController extends GetxController {
  final PatientRepository _repository;

  DietPlanController(this._repository);

  // ── State ──────────────────────────────────────────────────────────────
  /// Full diet-plan history for the patient (active + inactive).
  final RxList<DietPlan> plans = <DietPlan>[].obs;

  /// The patient's currently active diet plan (null if none).
  final Rxn<DietPlan> activePlan = Rxn<DietPlan>();

  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  /// Whether a create/update/delete request is in flight.
  final RxBool isSaving = false.obs;

  /// The patient id this controller is scoped to.
  int _patientId = 0;

  int get patientId => _patientId;

  // ── Lifecycle ──────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    debugPrint('[DietPlanController] onInit');
  }

  /// Loads the full history + active plan for [patientId].
  Future<void> load(int patientId) async {
    debugPrint('[DietPlanController] load called — patientId=$patientId');
    _patientId = patientId;
    if (isLoading.value) {
      debugPrint('[DietPlanController] load — already loading, skip');
      return;
    }
    isLoading.value = true;
    error.value = null;

    try {
      // Load history and active plan in parallel.
      final results = await Future.wait<Object?>([
        _repository.getDietPlans(patientId),
        _repository.getActiveDietPlan(patientId),
      ]);
      final history = results[0] as List<DietPlan>;
      final active = results[1] as DietPlan?;

      plans.assignAll(history);
      activePlan.value = active;

      debugPrint(
        '[DietPlanController] load — ${history.length} plans, '
        'active=${active?.id ?? 'none'}',
      );
    } catch (e) {
      debugPrint('[DietPlanController] load — ERROR: $e');
      error.value = _errorMessage(e);
    } finally {
      isLoading.value = false;
      debugPrint('[DietPlanController] load — isLoading=false');
    }
  }

  /// Reloads history + active plan (used after create/update/delete).
  Future<void> refresh() async {
    if (_patientId == 0) return;
    debugPrint('[DietPlanController] refresh — patientId=$_patientId');
    isLoading.value = true;
    error.value = null;
    try {
      final results = await Future.wait<Object?>([
        _repository.getDietPlans(_patientId),
        _repository.getActiveDietPlan(_patientId),
      ]);
      plans.assignAll(results[0] as List<DietPlan>);
      activePlan.value = results[1] as DietPlan?;
      debugPrint(
        '[DietPlanController] refresh — ${plans.length} plans, '
        'active=${activePlan.value?.id ?? 'none'}',
      );
    } catch (e) {
      debugPrint('[DietPlanController] refresh — ERROR: $e');
      error.value = _errorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  /// Creates a new diet plan via the repository. Returns the created [DietPlan]
  /// on success, or `null` on failure (error surfaced via snackbar).
  Future<DietPlan?> createDietPlan(DietPlanRequest request) async {
    debugPrint(
      '[DietPlanController] createDietPlan called — '
      'hydration=${request.hydrationRecommendationMl} '
      'meals=${request.meals.length} foods=${request.foodsToAvoid.length}',
    );
    isSaving.value = true;
    try {
      final plan = await _repository.createDietPlan(request);
      debugPrint('[DietPlanController] createDietPlan — success id=${plan.id}');
      Get.snackbar(
        'Diet Plan Created',
        'The new diet plan has been saved.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      await refresh();
      return plan;
    } catch (e) {
      debugPrint('[DietPlanController] createDietPlan — ERROR: $e');
      _showError('Unable to create the diet plan.', e);
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  /// Updates an existing diet plan. Returns the updated [DietPlan] or `null`.
  Future<DietPlan?> updateDietPlan(int id, DietPlanRequest request) async {
    debugPrint(
      '[DietPlanController] updateDietPlan called — id=$id '
      'hydration=${request.hydrationRecommendationMl}',
    );
    isSaving.value = true;
    try {
      final plan = await _repository.updateDietPlan(id, request);
      debugPrint('[DietPlanController] updateDietPlan — success id=${plan.id}');
      Get.snackbar(
        'Diet Plan Updated',
        'The diet plan has been updated.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      await refresh();
      return plan;
    } catch (e) {
      debugPrint('[DietPlanController] updateDietPlan — ERROR: $e');
      _showError('Unable to update the diet plan.', e);
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  /// Deletes a diet plan. Returns `true` on success.
  Future<bool> deleteDietPlan(int id) async {
    debugPrint('[DietPlanController] deleteDietPlan called — id=$id');
    isSaving.value = true;
    try {
      await _repository.deleteDietPlan(id);
      debugPrint('[DietPlanController] deleteDietPlan — success id=$id');
      Get.snackbar(
        'Diet Plan Deleted',
        'The diet plan has been removed.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      // Remove locally and refresh active plan.
      plans.removeWhere((p) => p.id == id);
      if (activePlan.value?.id == id) {
        activePlan.value = null;
      }
      await refresh();
      return true;
    } catch (e) {
      debugPrint('[DietPlanController] deleteDietPlan — ERROR: $e');
      _showError('Unable to delete the diet plan.', e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  void _showError(String defaultMessage, Object error) {
    if (error is ApiException) {
      Get.snackbar(
        'Action Failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        'Action Failed',
        defaultMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  static String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }
}
