class PatientSummary {
  final PregnancyProgress? pregnancyProgress;
  final LatestBloodPressure? latestBloodPressure;
  final LatestBloodSugar? latestBloodSugar;
  final ActiveDietPlan? activeDietPlan;
  final List<UpcomingAppointment> upcomingAppointments;
  final List<SymptomLog> recentSymptoms;
  final MedicineAdherence? medicineAdherence;

  PatientSummary({
    this.pregnancyProgress,
    this.latestBloodPressure,
    this.latestBloodSugar,
    this.activeDietPlan,
    required this.upcomingAppointments,
    this.recentSymptoms = const [],
    this.medicineAdherence,
  });

  factory PatientSummary.fromJson(Map<String, dynamic> json) => PatientSummary(
    pregnancyProgress: json['pregnancy_progress'] != null
        ? PregnancyProgress.fromJson(json['pregnancy_progress'])
        : null,
    latestBloodPressure: json['latest_blood_pressure'] != null
        ? LatestBloodPressure.fromJson(json['latest_blood_pressure'])
        : null,
    latestBloodSugar: json['latest_blood_sugar'] != null
        ? LatestBloodSugar.fromJson(json['latest_blood_sugar'])
        : null,
    activeDietPlan: json['active_diet_plan'] != null
        ? ActiveDietPlan.fromJson(json['active_diet_plan'])
        : null,
    upcomingAppointments: json['upcoming_appointments'] != null
        ? List<UpcomingAppointment>.from(
            json['upcoming_appointments'].map(
              (x) => UpcomingAppointment.fromJson(x),
            ),
          )
        : [],
    recentSymptoms: json['recent_symptoms'] != null
        ? List<SymptomLog>.from(
            json['recent_symptoms'].map((x) => SymptomLog.fromJson(x)),
          )
        : [],
    medicineAdherence: json['medicine_adherence'] != null
        ? MedicineAdherence.fromJson(json['medicine_adherence'])
        : null,
  );
}

class PregnancyProgress {
  final String? lmpDate;
  final String? eddDate;
  final int? currentWeek;
  final int? currentDay;
  final double? percentComplete;
  final int? trimester;
  final int? daysRemaining;

  PregnancyProgress({
    this.lmpDate,
    this.eddDate,
    this.currentWeek,
    this.currentDay,
    this.percentComplete,
    this.trimester,
    this.daysRemaining,
  });

  factory PregnancyProgress.fromJson(Map<String, dynamic> json) =>
      PregnancyProgress(
        lmpDate: json['lmp_date'],
        eddDate: json['edd_date'],
        currentWeek: json['current_week'],
        currentDay: json['current_day'],
        percentComplete: json['percent_complete']?.toDouble(),
        trimester: json['trimester'],
        daysRemaining: json['days_remaining'],
      );
}

class LatestBloodPressure {
  final int systolic;
  final int diastolic;
  final int pulse;
  final String recordedAt;
  final String notes;

  LatestBloodPressure({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.recordedAt,
    required this.notes,
  });

  factory LatestBloodPressure.fromJson(Map<String, dynamic> json) =>
      LatestBloodPressure(
        systolic: json['systolic'] ?? 0,
        diastolic: json['diastolic'] ?? 0,
        pulse: json['pulse'] ?? 0,
        recordedAt: json['recorded_at'] ?? '',
        notes: json['notes'] ?? '',
      );
}

class LatestBloodSugar {
  final int valueMgDl;
  final String readingContext;
  final String recordedAt;

  LatestBloodSugar({
    required this.valueMgDl,
    required this.readingContext,
    required this.recordedAt,
  });

  factory LatestBloodSugar.fromJson(Map<String, dynamic> json) =>
      LatestBloodSugar(
        valueMgDl: json['value_mg_dl'] ?? 0,
        readingContext: json['reading_context'] ?? '',
        recordedAt: json['recorded_at'] ?? '',
      );
}

class ActiveDietPlan {
  final bool isActive;
  final int hydrationRecommendationMl;
  final String notes;

  ActiveDietPlan({
    required this.isActive,
    required this.hydrationRecommendationMl,
    required this.notes,
  });

  factory ActiveDietPlan.fromJson(Map<String, dynamic> json) => ActiveDietPlan(
    isActive: json['is_active'] ?? false,
    hydrationRecommendationMl: json['hydration_recommendation_ml'] ?? 0,
    notes: json['notes'] ?? '',
  );
}

class UpcomingAppointment {
  final int id;
  final String appointmentType;
  final String scheduledAt;
  final int durationMinutes;
  final String status;

  UpcomingAppointment({
    required this.id,
    required this.appointmentType,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
  });

  factory UpcomingAppointment.fromJson(Map<String, dynamic> json) =>
      UpcomingAppointment(
        id: json['id'] ?? 0,
        appointmentType: json['appointment_type'] ?? '',
        scheduledAt: json['scheduled_at'] ?? '',
        durationMinutes: json['duration_minutes'] ?? 0,
        status: json['status'] ?? '',
      );
}

/// A single day's symptom log entry from `recent_symptoms`.
class SymptomLog {
  final int id;
  final String logDate;
  final List<SymptomItem> symptoms;
  final String notes;

  SymptomLog({
    required this.id,
    required this.logDate,
    this.symptoms = const [],
    this.notes = '',
  });

  factory SymptomLog.fromJson(Map<String, dynamic> json) => SymptomLog(
    id: json['id'] ?? 0,
    logDate: json['log_date'] ?? '',
    symptoms: json['symptoms'] != null
        ? List<SymptomItem>.from(
            json['symptoms'].map((x) => SymptomItem.fromJson(x)),
          )
        : [],
    notes: json['notes'] ?? '',
  );
}

/// A named symptom, e.g. `{"id": 4, "name": "Headache"}`.
class SymptomItem {
  final int id;
  final String name;

  SymptomItem({required this.id, required this.name});

  factory SymptomItem.fromJson(Map<String, dynamic> json) =>
      SymptomItem(id: json['id'] ?? 0, name: json['name'] ?? '');
}

/// Medicine adherence counters from `medicine_adherence`.
class MedicineAdherence {
  final int taken;
  final int skipped;
  final int pending;

  MedicineAdherence({
    required this.taken,
    required this.skipped,
    required this.pending,
  });

  factory MedicineAdherence.fromJson(Map<String, dynamic> json) =>
      MedicineAdherence(
        taken: json['taken'] ?? 0,
        skipped: json['skipped'] ?? 0,
        pending: json['pending'] ?? 0,
      );
}
