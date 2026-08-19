// ============================================================================
// api_constants.dart — Mama Health API endpoint constants
// Base: Render free tier — first request after idle can take 20–50s, retry
// once on cold DB errors instead of failing immediately.
// ============================================================================

class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://mama-health-backend.onrender.com';
  static const String apiPrefix = '/api/v1';
  static const String swaggerDocsUrl = '$baseUrl/api/docs/';

  // ---------------- AUTH ----------------
  static const String authRegister =
      '$apiPrefix/auth/register/'; // POST — public patient signup, sends verification email
  static const String authVerifyEmail =
      '$apiPrefix/auth/verify-email/'; // POST — consumes emailed token
  static const String authResendVerification =
      '$apiPrefix/auth/resend-verification/'; // POST — re-sends verification email
  static const String authLogin =
      '$apiPrefix/auth/login/'; // POST — returns access + refresh JWT
  static const String authTokenRefresh =
      '$apiPrefix/auth/token/refresh/'; // POST — exchange refresh for new access token
  static const String authLogout =
      '$apiPrefix/auth/logout/'; // POST — blacklists refresh token
  static const String authPasswordForgot =
      '$apiPrefix/auth/password/forgot/'; // POST — step 1/3, emails OTP
  static const String authPasswordVerifyOtp =
      '$apiPrefix/auth/password/verify-otp/'; // POST — step 2/3, verifies OTP
  static const String authPasswordReset =
      '$apiPrefix/auth/password/reset/'; // POST — step 3/3, sets new password
  static const String authPasswordChange =
      '$apiPrefix/auth/password/change/'; // POST — authenticated password change
  static const String authMe =
      '$apiPrefix/auth/me/'; // GET/PATCH — current user + profile

  // ---------------- ACCOUNTS ----------------
  static const String accountsDoctorsInvite =
      '$apiPrefix/accounts/doctors/invite/'; // POST — admin invites a doctor
  static const String accountsDoctorsInviteAccept =
      '$apiPrefix/accounts/doctors/invite/accept/'; // POST — doctor accepts invite, sets password
  static const String accountsMePatientProfile =
      '$apiPrefix/accounts/me/patient-profile/'; // GET/PUT/PATCH — own patient profile
  static const String accountsMeDoctorProfile =
      '$apiPrefix/accounts/me/doctor-profile/'; // GET/PUT/PATCH — own doctor profile
  static const String accountsMeSubscription =
      '$apiPrefix/accounts/me/subscription/'; // GET — patient only, subscription status + payment methods (price shown to patient)
  static const String accountsPaymentMethods =
      '$apiPrefix/accounts/payment-methods/'; // GET (all) / PATCH (admin only) — platform JazzCash/EasyPaisa/bank details + subscription price/currency
  static const String accountsDoctors =
      '$apiPrefix/accounts/doctors/'; // GET — list doctors
  static const String accountsDoctorsDetail =
      '$apiPrefix/accounts/doctors'; // GET/PATCH — append '/{id}/'
  static const String accountsPatients =
      '$apiPrefix/accounts/patients/'; // GET — list patients (role-scoped)
  static const String accountsPatientsDetail =
      '$apiPrefix/accounts/patients'; // GET/PATCH — append '/{id}/'
  static const String accountsPatientAssignDoctorSuffix =
      '/assign-doctor/'; // POST — append to patient detail URL, admin assigns doctor
  static const String accountsPatientMarkPaidSuffix =
      '/mark-paid/'; // POST — append to patient detail URL, admin records manual payment {payment_reference?, amount_paid?}

  // ---------------- APPOINTMENTS ----------------
  static const String appointments =
      '$apiPrefix/appointments/'; // POST/GET — book / list appointments
  static const String appointmentsDetail =
      '$apiPrefix/appointments'; // GET/PATCH — append '/{id}/'
  static const String appointmentDoctorNotesSuffix =
      '/doctor-notes/'; // PATCH — append to appointment detail URL
  static const String appointmentRescheduleSuffix =
      '/reschedule/'; // PATCH — append to appointment detail URL
  static const String appointmentStatusSuffix =
      '/status/'; // POST — append to appointment detail URL, state machine
  static const String appointmentRateSuffix =
      '/rate/'; // POST — append to appointment detail URL, patient-only {score: 1-5, comment?}, completed appointments only
  static const String appointmentPaymentConfirmSuffix =
      '/payment/confirm/'; // POST — append to appointment detail URL, doctor/admin verifies payment received (also confirms appointment)
  static const String appointmentPaymentMarkPaidSuffix =
      '/payment/mark-paid/'; // POST — append to appointment detail URL, patient claims they paid the consultation fee

  // ---------------- HEALTH ----------------
  static const String healthPregnancyProgress =
      '$apiPrefix/health/pregnancy-progress/'; // GET — computed live from LMP/EDD
  static const String healthBloodPressure =
      '$apiPrefix/health/blood-pressure/'; // POST/GET — log/list BP readings
  static const String healthBloodPressureDetail =
      '$apiPrefix/health/blood-pressure'; // GET/PATCH/PUT/DELETE — append '/{id}/'
  static const String healthBloodSugar =
      '$apiPrefix/health/blood-sugar/'; // POST/GET — log/list blood sugar readings
  static const String healthBloodSugarDetail =
      '$apiPrefix/health/blood-sugar'; // GET/PATCH/PUT/DELETE — append '/{id}/'
  static const String healthSymptoms =
      '$apiPrefix/health/symptoms/'; // POST/GET — upserts by (patient, log_date)
  static const String healthSymptomsDetail =
      '$apiPrefix/health/symptoms'; // GET/PATCH/PUT/DELETE — append '/{id}/'
  static const String healthWaterIntake =
      '$apiPrefix/health/water-intake/'; // POST/GET — append-only water log
  static const String healthWaterIntakeToday =
      '$apiPrefix/health/water-intake/today/'; // GET — today's running total
  static const String healthWaterIntakeDetail =
      '$apiPrefix/health/water-intake'; // GET — append '/{id}/', no update/delete
  static const String healthKickSessions =
      '$apiPrefix/health/kick-sessions/'; // POST/GET — start / list kick-count sessions
  static const String healthKickSessionsDetail =
      '$apiPrefix/health/kick-sessions'; // GET — append '/{id}/'
  static const String healthKickSessionEndSuffix =
      '/end/'; // POST — append to session detail URL, ends session
  static const String healthKickSessionTapSuffix =
      '/tap/'; // POST — append to session detail URL, records one kick
  static const String healthBabySize =
      '$apiPrefix/health/baby-size/'; // GET — static reference data, all weeks
  static const String healthBabySizeDetail =
      '$apiPrefix/health/baby-size'; // GET — append '/{week}/', lookup by week number
  static const String healthSurgicalProcedures =
      '$apiPrefix/health/surgical-procedures/'; // POST/GET — log/list surgical records
  static const String healthSurgicalProceduresDetail =
      '$apiPrefix/health/surgical-procedures'; // GET/PATCH/PUT/DELETE — append '/{id}/'
  static const String healthExerciseVideos =
      '$apiPrefix/health/exercise-videos/'; // GET — read-only video reference list
  static const String healthExerciseVideosDetail =
      '$apiPrefix/health/exercise-videos'; // GET — append '/{id}/'

  // ---------------- DIET ----------------
  static const String dietPlans =
      '$apiPrefix/diet/plans/'; // POST/GET — create (doctor/admin) / list diet plans
  static const String dietPlansActive =
      '$apiPrefix/diet/plans/active/'; // GET — current active plan
  static const String dietPlansDetail =
      '$apiPrefix/diet/plans'; // GET/PUT/PATCH/DELETE — append '/{id}/'

  // ---------------- MEDICINES ----------------
  static const String medicinesReminders =
      '$apiPrefix/medicines/reminders/'; // POST/GET — create/list medicine reminders
  static const String medicinesRemindersDetail =
      '$apiPrefix/medicines/reminders'; // GET/PUT/PATCH/DELETE — append '/{id}/'
  static const String medicinesReminderLogIntakeSuffix =
      '/log-intake/'; // POST — append to reminder detail URL, logs taken/skipped
  static const String medicinesIntakeLogs =
      '$apiPrefix/medicines/intake-logs/'; // GET — read-only adherence history
  static const String medicinesIntakeLogsDetail =
      '$apiPrefix/medicines/intake-logs'; // GET — append '/{id}/'

  // ---------------- NOTIFICATIONS ----------------
  static const String notificationsBroadcast =
      '$apiPrefix/notifications/broadcast/'; // POST — admin only, async fan-out
  static const String notificationsSendToPatient =
      '$apiPrefix/notifications/send-to-patient/'; // POST — doctor only, to an assigned patient
  static const String notifications =
      '$apiPrefix/notifications/'; // GET — own inbox, newest first
  static const String notificationsMarkAllRead =
      '$apiPrefix/notifications/mark-all-read/'; // POST — marks all as read
  static const String notificationsUnreadCount =
      '$apiPrefix/notifications/unread-count/'; // GET — returns {"unread_count": N} for the bell badge
  static const String notificationsDetail =
      '$apiPrefix/notifications'; // GET — append '/{id}/'
  static const String notificationMarkReadSuffix =
      '/mark-read/'; // POST — append to notification detail URL

  // ---------------- HOSPITALS ----------------
  static const String hospitalsNearby =
      '$apiPrefix/hospitals/nearby/'; // GET — Google Places proxy, requires lat/lng, may 503

  // ---------------- AI ASSISTANT ----------------
  static const String aiSessions =
      '$apiPrefix/ai/sessions/'; // POST/GET — patient only, create/list chat sessions
  static const String aiSessionsDetail =
      '$apiPrefix/ai/sessions'; // GET — append '/{id}/'
  static const String aiSessionMessagesSuffix =
      '/messages/'; // GET/POST — append to session detail URL, history / send message, throttled 20/hr

  // ---------------- REPORTS ----------------
  static const String reportsPatientSummary =
      '$apiPrefix/reports/patient-summary/'; // GET — cross-app aggregation, computed live
  static const String reportsDoctorDashboard =
      '$apiPrefix/reports/doctor-dashboard/'; // GET — doctor-only, one call for the doctor app home screen
  static const String reportsAdminStats =
      '$apiPrefix/reports/admin/stats/'; // GET — admin only, dashboard counts.
  // Optional query params: ?date_from=YYYY-MM-DD&date_to=YYYY-MM-DD (date-picker filter).
  // Response also includes active_users_last_30_days and
  // new_patients_growth_percent (nullable until a full prior month exists).
  static const String reportsSearch =
      '$apiPrefix/reports/search/'; // GET — admin only, requires ?q= (min 2 chars)

  // ---------------- EMERGENCY ----------------
  static const String emergencySos =
      '$apiPrefix/emergency/sos/'; // POST/GET — patient only trigger; role-scoped list
  static const String emergencySosDetail =
      '$apiPrefix/emergency/sos'; // GET — append '/{id}/'
  static const String emergencySosResolveSuffix =
      '/resolve/'; // POST — append to SOS detail URL, resolves/dismisses

  // Legacy aliases kept for existing repositories until they are migrated.
  static const String login = authLogin;
  static const String logout = authLogout;
  static const String refreshToken = authTokenRefresh;
  static const String dashboardStats = reportsAdminStats;
  static const String doctors = accountsDoctors;
  static const String patients = accountsPatients;
}
