/// Response models for the Diet Plan feature.
///
/// Mapped from the `Mama Health API.yaml` schemas:
/// - `DietPlan` (response) — `id`, `patient`, `created_by`, `is_active`,
///   `hydration_recommendation_ml`, `notes`, `meals[]`, `foods_to_avoid[]`,
///   `created_at`, `updated_at`.
/// - `DietPlanRequest` (create body) — `patient_id`, `hydration_recommendation_ml`,
///   `notes`, `meals[]`, `foods_to_avoid[]`.
///
/// Endpoints (all in [ApiConstants]):
/// - `GET /api/v1/diet/plans/?patient_id=` — list (paginated)
/// - `GET /api/v1/diet/plans/active/?patient_id=` — active plan (404 if none)
/// - `POST /api/v1/diet/plans/` — create (auto-deactivates previous active)
/// - `GET/PUT/PATCH/DELETE /api/v1/diet/plans/{id}/` — single-plan ops
class DietPlan {
  final int id;
  final int hydrationRecommendationMl;
  final bool isActive;
  final String notes;
  final List<DietPlanMeal> meals;
  final List<DietFoodToAvoid> foodsToAvoid;
  final DietPlanAuthor? createdBy;
  final String createdAt;
  final String updatedAt;

  const DietPlan({
    required this.id,
    this.hydrationRecommendationMl = 0,
    this.isActive = false,
    this.notes = '',
    this.meals = const [],
    this.foodsToAvoid = const [],
    this.createdBy,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    return DietPlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      hydrationRecommendationMl:
          (json['hydration_recommendation_ml'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? false,
      notes: (json['notes'] as String?) ?? '',
      meals: _parseMeals(json['meals']),
      foodsToAvoid: _parseFoods(json['foods_to_avoid']),
      createdBy: json['created_by'] is Map
          ? DietPlanAuthor.fromJson(
              (json['created_by'] as Map).cast<String, dynamic>(),
            )
          : null,
      createdAt: (json['created_at'] as String?) ?? '',
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }

  static List<DietPlanMeal> _parseMeals(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DietPlanMeal.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  static List<DietFoodToAvoid> _parseFoods(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DietFoodToAvoid.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}

/// A single meal entry in a diet plan (`{id, meal_type, description}`).
class DietPlanMeal {
  final int id;
  final String mealType;
  final String description;

  const DietPlanMeal({this.id = 0, this.mealType = '', this.description = ''});

  factory DietPlanMeal.fromJson(Map<String, dynamic> json) => DietPlanMeal(
    id: (json['id'] as num?)?.toInt() ?? 0,
    mealType: (json['meal_type'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
  );
}

/// A "food to avoid" entry (`{id, food_name, reason}`).
class DietFoodToAvoid {
  final int id;
  final String foodName;
  final String reason;

  const DietFoodToAvoid({this.id = 0, this.foodName = '', this.reason = ''});

  factory DietFoodToAvoid.fromJson(Map<String, dynamic> json) =>
      DietFoodToAvoid(
        id: (json['id'] as num?)?.toInt() ?? 0,
        foodName: (json['food_name'] as String?) ?? '',
        reason: (json['reason'] as String?) ?? '',
      );
}

/// The author (doctor/admin) who created the plan (`{id, email, first_name,
/// last_name}`).
class DietPlanAuthor {
  final int id;
  final String email;
  final String firstName;
  final String lastName;

  const DietPlanAuthor({
    this.id = 0,
    this.email = '',
    this.firstName = '',
    this.lastName = '',
  });

  factory DietPlanAuthor.fromJson(Map<String, dynamic> json) => DietPlanAuthor(
    id: (json['id'] as num?)?.toInt() ?? 0,
    email: (json['email'] as String?) ?? '',
    firstName: (json['first_name'] as String?) ?? '',
    lastName: (json['last_name'] as String?) ?? '',
  );

  String get name => '$firstName $lastName'.trim();
}

/// A paginated diet-plan list response (`{count, next, previous, results}`).
class PaginatedDietPlans {
  final int count;
  final String? next;
  final String? previous;
  final List<DietPlan> results;

  const PaginatedDietPlans({
    required this.count,
    this.next,
    this.previous,
    this.results = const [],
  });

  factory PaginatedDietPlans.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List? ?? [];
    return PaginatedDietPlans(
      count: (json['count'] as num?)?.toInt() ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: rawResults
          .whereType<Map>()
          .map((e) => DietPlan.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// Request body for creating/updating a diet plan.
///
/// On create, `patient_id` is **required** for a doctor/admin actor. On PATCH,
/// omit fields you don't want to change — but note `meals`/`foods_to_avoid`,
/// when present, **fully replace** the existing set (the backend does not merge
/// or diff).
class DietPlanRequest {
  final int? patientId;
  final int hydrationRecommendationMl;
  final String notes;
  final List<DietPlanMealInput> meals;
  final List<DietFoodAvoidInput> foodsToAvoid;

  const DietPlanRequest({
    this.patientId,
    this.hydrationRecommendationMl = 0,
    this.notes = '',
    this.meals = const [],
    this.foodsToAvoid = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      if (patientId != null) 'patient_id': patientId,
      'hydration_recommendation_ml': hydrationRecommendationMl,
      'notes': notes,
      'meals': meals.map((m) => m.toJson()).toList(),
      'foods_to_avoid': foodsToAvoid.map((f) => f.toJson()).toList(),
    };
  }
}

/// A meal row in a [DietPlanRequest] (`{meal_type, description}`).
class DietPlanMealInput {
  final String mealType;
  final String description;

  const DietPlanMealInput({required this.mealType, required this.description});

  Map<String, dynamic> toJson() => {
    'meal_type': mealType,
    'description': description,
  };
}

/// A "food to avoid" row in a [DietPlanRequest] (`{food_name, reason}`).
class DietFoodAvoidInput {
  final String foodName;
  final String reason;

  const DietFoodAvoidInput({required this.foodName, required this.reason});

  Map<String, dynamic> toJson() => {'food_name': foodName, 'reason': reason};
}
