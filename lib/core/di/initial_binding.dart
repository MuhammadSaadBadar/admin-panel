import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/services/local_storage_service.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/dashboard/controllers/dashboard_controller.dart';
import '../../features/dashboard/repositories/dashboard_repository.dart';
import '../../features/doctors/controllers/doctor_list_controller.dart';
import '../../features/doctors/repositories/doctor_repository.dart';
import '../../features/patients/controllers/patient_list_controller.dart';
import '../../features/patients/controllers/patient_registration_controller.dart';
import '../../features/patients/repositories/patient_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Core services
    Get.put<LocalStorageService>(LocalStorageService(), permanent: true);

    // 2. ApiClient Injection
    final storage = Get.find<LocalStorageService>();
    Get.lazyPut<ApiClient>(
      () => ApiClient(
        baseUrl: ApiConstants.baseUrl,
        interceptors: [
          AuthInterceptor(getToken: storage.getAccessTokenSync),
          LoggingInterceptor(),
        ],
      ),
      fenix: true,
    );

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
    Get.lazyPut<PatientListController>(
      () => PatientListController(Get.find<PatientRepository>()),
      fenix: true,
    );
    Get.lazyPut<PatientRegistrationController>(
      () => PatientRegistrationController(Get.find<AuthRepository>()),
      fenix: true,
    );
  }
}
