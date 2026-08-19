import 'package:admin/features/notifications/controllers/notification_controller.dart';
import 'package:admin/features/notifications/controllers/notification_detail_controller.dart';
import 'package:admin/features/notifications/repositories/notification_repository.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/services/local_storage_service.dart';
import '../../features/appointments/controllers/appointment_controller.dart';
import '../../features/appointments/controllers/appointment_detail_controller.dart';
import '../../features/appointments/repositories/appointment_repository.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/dashboard/controllers/dashboard_controller.dart';
import '../../features/dashboard/repositories/dashboard_repository.dart';
import '../../features/doctors/controllers/doctor_detail_controller.dart';
import '../../features/doctors/controllers/doctor_invite_controller.dart';
import '../../features/doctors/controllers/doctor_list_controller.dart';
import '../../features/doctors/repositories/doctor_repository.dart';
import '../../features/patients/controllers/diet_plan_controller.dart';
import '../../features/patients/controllers/medication_controller.dart';
import '../../features/patients/controllers/patient_list_controller.dart';
import '../../features/patients/controllers/patient_registration_controller.dart';
import '../../features/patients/repositories/patient_repository.dart';
import '../../features/profile/controllers/change_password_controller.dart';
import '../../features/profile/controllers/profile_controller.dart';
import '../../features/profile/repositories/profile_repository.dart';
import '../../features/search/controllers/search_controller.dart';
import '../../features/search/repositories/search_repository.dart';
import '../../features/sos/controllers/sos_controller.dart';
import '../../features/sos/controllers/sos_detail_controller.dart';
import '../../features/sos/repositories/sos_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Core services
    Get.put<LocalStorageService>(LocalStorageService(), permanent: true);

    // 2. ApiClient Injection
    final storage = Get.find<LocalStorageService>();
    final ApiClient apiClient = ApiClient(
      baseUrl: ApiConstants.baseUrl,
      interceptors: [LoggingInterceptor()],
    );

    // Note: The refresh request intentionally uses Get.find<AuthRepository>()
    // lazily (deferred until first 401) to avoid a circular dependency
    // between ApiClient ↔ AuthRepository.
    final authInterceptor = AuthInterceptor(
      getToken: storage.getAccessTokenSync,
      getRefreshToken: storage.getRefreshTokenSync,
      refreshRequest: (refreshToken) async {
        final repo = Get.find<AuthRepository>();
        final result = await repo.refreshToken(refreshToken);
        return TokenRefreshResult(
          accessToken: result.accessToken,
          refreshToken: result.refreshToken.isNotEmpty
              ? result.refreshToken
              : null,
        );
      },
      onTokenRefreshed: (accessToken, refreshToken) async {
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await storage.saveAuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
        } else {
          // The refresh endpoint returned only an access token; keep the
          // existing refresh token.
          await storage.setString(
            LocalStorageService.accessTokenKey,
            accessToken,
          );
        }
      },
      onLogoutRequired: () => storage.clearAuth(),
    );

    apiClient.attachInterceptor(authInterceptor);
    authInterceptor.setDio(apiClient.dio);

    Get.lazyPut<ApiClient>(() => apiClient, fenix: true);

    // 3. Repositories Injection
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<DashboardRepository>(
      () => DashboardRepository(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<DoctorRepository>(
      () => DoctorRepository(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<PatientRepository>(
      () => PatientRepository(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<AppointmentRepository>(
      () => AppointmentRepository(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepository(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<SosRepository>(
      () => SosRepository(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<NotificationRepository>(
      () => NotificationRepository(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<SearchRepository>(
      () => SearchRepository(Get.find<ApiClient>()),
      fenix: true,
    );

    // 4. Auth service
    Get.lazyPut<AuthService>(
      () => AuthService(
        Get.find<AuthRepository>(),
        Get.find<LocalStorageService>(),
      ),
      fenix: true,
    );

    // 5. Controllers Injection
    Get.lazyPut<DashboardController>(
      () => DashboardController(Get.find<DashboardRepository>()),
      fenix: true,
    );
    Get.lazyPut<DoctorListController>(
      () => DoctorListController(Get.find<DoctorRepository>()),
      fenix: true,
    );
    Get.lazyPut<DoctorDetailController>(
      () => DoctorDetailController(
        Get.find<DoctorRepository>(),
        Get.find<PatientRepository>(),
        Get.find<AppointmentRepository>(),
      ),
      fenix: true,
    );
    Get.lazyPut<DoctorInviteController>(
      () => DoctorInviteController(Get.find<DoctorRepository>()),
      fenix: true,
    );
    Get.lazyPut<PatientListController>(
      () => PatientListController(Get.find<PatientRepository>()),
      fenix: true,
    );
    Get.lazyPut<PatientRegistrationController>(
      () => PatientRegistrationController(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<DietPlanController>(
      () => DietPlanController(Get.find<PatientRepository>()),
      fenix: true,
    );
    Get.lazyPut<MedicationController>(
      () => MedicationController(Get.find<PatientRepository>()),
      fenix: true,
    );
    Get.lazyPut<AppointmentController>(
      () => AppointmentController(Get.find<AppointmentRepository>()),
      fenix: true,
    );
    Get.lazyPut<AppointmentDetailController>(
      () => AppointmentDetailController(Get.find<AppointmentRepository>()),
      fenix: true,
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(Get.find<ProfileRepository>()),
      fenix: true,
    );
    Get.lazyPut<ChangePasswordController>(
      () => ChangePasswordController(Get.find<ProfileRepository>()),
      fenix: true,
    );
    Get.lazyPut<SosController>(
      () => SosController(Get.find<SosRepository>()),
      fenix: true,
    );
    Get.lazyPut<SosDetailController>(
      () => SosDetailController(Get.find<SosRepository>()),
      fenix: true,
    );
    Get.lazyPut<NotificationController>(
      () => NotificationController(Get.find<NotificationRepository>()),
      fenix: true,
    );
    Get.lazyPut<NotificationDetailController>(
      () => NotificationDetailController(Get.find<NotificationRepository>()),
      fenix: true,
    );
    Get.lazyPut<SearchController>(
      () => SearchController(Get.find<SearchRepository>()),
      fenix: true,
    );
  }
}
