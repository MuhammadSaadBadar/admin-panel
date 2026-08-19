/// Models for the Medicine Reminder / Medication History features.
///
/// Mapped from the `Mama Health API.yaml` schemas:
/// - `MedicineReminder` (response) — `id`, `patient`, `medicine_name`,
///   `dosage`, `times_per_day`, `reminder_times[]`, `start_date`, `end_date`,
///   `is_active`, `created_at`, `updated_at`.
/// - `MedicineReminderRequest` (create body) — `patient_id`, `medicine_name`,
///   `dosage`, `times_per_day`, `reminder_times[]`, `start_date`, `end_date`,
///   `is_active`.
/// - `MedicineIntakeLog` (response) — `id`, `reminder`, `scheduled_for`,
///   `status` (`pending`|`taken`|`skipped`), `taken_at`, `logged_at`.
///
/// Endpoints (all in [ApiConstants]):
/// - `GET/POST /api/v1/medicines/reminders/` — list / create
/// - `GET/PUT/PATCH/DELETE /api/v1/medicines/reminders/{id}/` — single
/// - `GET /api/v1/medicines/intake-logs/` — read-only adherence history
/// - `GET /api/v1/medicines/intake-logs/{id}/` — single log (read-only)
library;

/// Whether a dose was taken, skipped, or is still pending.
enum MedicineIntakeStatus { taken, skipped, pending }

/// Parses an intake-log `status` string into the enum (case-insensitive,
/// tolerant of the `pending` value that Celery auto-creates).
MedicineIntakeStatus medicineIntakeStatusFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'taken':
      return MedicineIntakeStatus.taken;
    case 'skipped':
      return MedicineIntakeStatus.skipped;
    case 'pending':
    default:
      return MedicineIntakeStatus.pending;
  }
}

/// A medicine reminder for a patient.
///
/// `patient` is returned as a nested object by the API; we only need the id,
/// so we parse it defensively (it may be an int, a map, or absent).
class MedicineReminder {
  final int id;
  final int patientId;
  final String medicineName;
  final String dosage;
  final int timesPerDay;
  final List<String> reminderTimes;
  final String startDate;
  final String endDate; // empty when null (ongoing reminder)
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const MedicineReminder({
    required this.id,
    this.patientId = 0,
    this.medicineName = '',
    this.dosage = '',
    this.timesPerDay = 0,
    this.reminderTimes = const [],
    this.startDate = '',
    this.endDate = '',
    this.isActive = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isOngoing => endDate.isEmpty;

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    // `patient` may be an int (nested id) or an object `{id, ...}`.
    int parsePatientId(dynamic patient) {
      if (patient is num) return patient.toInt();
      if (patient is Map) {
        final id = patient['id'];
        if (id is num) return id.toInt();
      }
      return 0;
    }

    List<String> parseTimes(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((t) => t.toString()).where((t) => t.isNotEmpty).toList();
    }

    return MedicineReminder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      patientId: parsePatientId(json['patient']),
      medicineName: (json['medicine_name'] as String?) ?? '',
      dosage: (json['dosage'] as String?) ?? '',
      timesPerDay: (json['times_per_day'] as num?)?.toInt() ?? 0,
      reminderTimes: parseTimes(json['reminder_times']),
      startDate: (json['start_date'] as String?) ?? '',
      endDate: (json['end_date'] as String?) ?? '',
      isActive: (json['is_active'] as bool?) ?? false,
      createdAt: (json['created_at'] as String?) ?? '',
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }
}

/// Create / update payload for a medicine reminder.
class MedicineReminderRequest {
  final int? patientId;
  final String medicineName;
  final String dosage;
  final int timesPerDay;
  final List<String> reminderTimes;
  final String startDate;
  final String? endDate;
  final bool isActive;

  const MedicineReminderRequest({
    this.patientId,
    this.medicineName = '',
    this.dosage = '',
    this.timesPerDay = 0,
    this.reminderTimes = const [],
    this.startDate = '',
    this.endDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      if (patientId != null) 'patient_id': patientId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'times_per_day': timesPerDay,
      'reminder_times': reminderTimes,
      'start_date': startDate,
      if (endDate != null && endDate!.isNotEmpty) 'end_date': endDate,
      'is_active': isActive,
    };
  }
}

/// A single intake-log entry (`{id, reminder, scheduled_for, status,
/// taken_at, logged_at}`).
class MedicineIntakeLog {
  final int id;
  final int reminderId;
  final String scheduledFor;
  final MedicineIntakeStatus status;
  final String takenAt;
  final String loggedAt;

  const MedicineIntakeLog({
    required this.id,
    this.reminderId = 0,
    this.scheduledFor = '',
    this.status = MedicineIntakeStatus.pending,
    this.takenAt = '',
    this.loggedAt = '',
  });

  factory MedicineIntakeLog.fromJson(Map<String, dynamic> json) {
    return MedicineIntakeLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      reminderId: (json['reminder'] as num?)?.toInt() ?? 0,
      scheduledFor: (json['scheduled_for'] as String?) ?? '',
      status: medicineIntakeStatusFromString(json['status']?.toString()),
      takenAt: (json['taken_at'] as String?) ?? '',
      loggedAt: (json['logged_at'] as String?) ?? '',
    );
  }
}

/// A paginated reminder-list response (`{count, next, previous, results}`).
class PaginatedMedicineReminders {
  final int count;
  final String? next;
  final String? previous;
  final List<MedicineReminder> results;

  const PaginatedMedicineReminders({
    required this.count,
    this.next,
    this.previous,
    this.results = const [],
  });

  factory PaginatedMedicineReminders.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List? ?? [];
    return PaginatedMedicineReminders(
      count: (json['count'] as num?)?.toInt() ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: rawResults
          .whereType<Map>()
          .map((e) => MedicineReminder.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// A paginated intake-log response (`{count, next, previous, results}`).
class PaginatedMedicineIntakeLogs {
  final int count;
  final String? next;
  final String? previous;
  final List<MedicineIntakeLog> results;

  const PaginatedMedicineIntakeLogs({
    required this.count,
    this.next,
    this.previous,
    this.results = const [],
  });

  factory PaginatedMedicineIntakeLogs.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List? ?? [];
    return PaginatedMedicineIntakeLogs(
      count: (json['count'] as num?)?.toInt() ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: rawResults
          .whereType<Map>()
          .map((e) => MedicineIntakeLog.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
