class PatientSummary {
  final PregnancyProgress? pregnancyProgress;
  final LatestBloodPressure? latestBloodPressure;
  final LatestBloodSugar? latestBloodSugar;
  final ActiveDietPlan? activeDietPlan;
  final List<UpcomingAppointment> upcomingAppointments;

  PatientSummary({
    this.pregnancyProgress,
    this.latestBloodPressure,
    this.latestBloodSugar,
    this.activeDietPlan,
    required this.upcomingAppointments,
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
            ? List<UpcomingAppointment>.from(json['upcoming_appointments'].map((x) => UpcomingAppointment.fromJson(x)))
            : [],
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

  factory PregnancyProgress.fromJson(Map<String, dynamic> json) => PregnancyProgress(
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

  factory LatestBloodPressure.fromJson(Map<String, dynamic> json) => LatestBloodPressure(
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

  factory LatestBloodSugar.fromJson(Map<String, dynamic> json) => LatestBloodSugar(
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

  factory UpcomingAppointment.fromJson(Map<String, dynamic> json) => UpcomingAppointment(
        id: json['id'] ?? 0,
        appointmentType: json['appointment_type'] ?? '',
        scheduledAt: json['scheduled_at'] ?? '',
        durationMinutes: json['duration_minutes'] ?? 0,
        status: json['status'] ?? '',
      );
}
