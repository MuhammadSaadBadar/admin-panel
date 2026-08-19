import 'package:admin/features/appointments/screens/appointment_details_screen.dart';
import 'package:admin/features/appointments/screens/appointments_dashboard_screen.dart';
import 'package:admin/features/auth/screens/auth_gate_screen.dart';
import 'package:admin/features/auth/screens/otp_verification_screen.dart';
import 'package:admin/features/auth/screens/reset_password_screen.dart';
import 'package:admin/features/notifications/screens/compose_broadcast_screen.dart';
import 'package:admin/features/notifications/screens/notification_detail_screen.dart';
import 'package:admin/features/notifications/screens/notifications_screen.dart';
import 'package:admin/features/patients/screens/assign_doctor_screen.dart';
import 'package:admin/features/patients/screens/create_diet_plan_screen.dart';
import 'package:admin/features/patients/screens/diet_plan_management_screen.dart';
import 'package:admin/features/patients/screens/medication_editor_screen.dart';
import 'package:admin/features/patients/screens/medication_history_screen.dart';
import 'package:admin/features/patients/screens/medication_intake_detail_screen.dart';
import 'package:admin/features/patients/screens/medication_reminders_screen.dart';
import 'package:admin/features/patients/screens/patient_register_screen.dart';
import 'package:admin/features/sos/screens/emergency_sos_detail_screen.dart';
import 'package:admin/features/sos/screens/emergency_sos_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/doctors/screens/doctor_dashboard_screen.dart';
import '../../features/doctors/screens/doctor_detail_screen.dart';
import '../../features/doctors/screens/doctor_form_screen.dart';
import '../../features/patients/screens/patient_dashboard_screen.dart';
import '../../features/patients/screens/patient_detail_screen.dart';
import '../../features/profile/screens/admin_profile_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../widgets/custom_appbar.dart';
import 'route_names.dart';

/// All app routes declared as a GetX [GetPage] list.
///
/// Register via [GetMaterialApp.getPages].
/// Navigate with [Get.toNamed], [Get.offAllNamed], etc. — no Navigator stack
/// bloating, and back-stack is managed automatically by GetX.
class AppRoutes {
  AppRoutes._();

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: RouteNames.root,
      page: () => const AuthGateScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.otpVerification,
      page: () => const OTPVerificationScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.resetPassword,
      page: () => const ResetPasswordScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.dashboard,
      page: () => const AdminDashboard(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.doctors,
      page: () => const DoctorManagementScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.doctorDetail,
      page: () => const DoctorDetailsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.doctorForm,
      page: () => const InviteDoctorScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.patients,
      page: () => const PatientManagementScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.patientDetail,
      page: () => const PatientDetailsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.dietPlans,
      page: () => const DietPlanManagementScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.dietPlansCreate,
      page: () => const CreateDietPlanScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.medicationReminders,
      page: () => const MedicationRemindersScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.medicationEditor,
      page: () => const MedicationEditorScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.medicationHistory,
      page: () => const MedicationHistoryScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.medicationIntakeDetail,
      page: () => const MedicationIntakeDetailScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.registerPatient,
      page: () => const RegisterPatientScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    // Add to the pages list
    GetPage(
      name: RouteNames.assignDoctor,
      page: () => const AssignDoctorScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.appointments,
      page: () => const AppointmentManagementScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.appointmentDetail,
      page: () => const AppointmentDetailsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.profile,
      page: () => const AdminProfileScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.profileChangePassword,
      page: () => const ChangePasswordScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.sos,
      page: () => const EmergencySosScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.sosDetail,
      page: () => const EmergencySosDetailScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    // GetPage(
    //   name: RouteNames.reports,
    //   page: () {
    //     final args = Get.arguments;
    //     if (args is int) return PatientReportsScreen(patientId: args);
    //     return const _ComingSoonScreen(
    //       title: 'Reports',
    //       message: 'Choose a patient to view reports.',
    //     );
    //   },
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 250),
    // ),
    GetPage(
      name: RouteNames.reportDetail,
      page: () => const _ComingSoonScreen(
        title: 'Report Detail',
        message: 'Report detail is not implemented yet.',
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.notifications,
      page: () => const NotificationsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.notificationDetail,
      page: () => const NotificationDetailScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.notificationBroadcast,
      page: () => const ComposeBroadcastScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: RouteNames.settings,
      page: () => const _ComingSoonScreen(
        title: 'Settings',
        message: 'Settings screen is not implemented yet.',
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
  ];
}

// ─────────────────────────────────────────────
// Internal placeholder screens
// ─────────────────────────────────────────────

class _ComingSoonScreen extends StatelessWidget {
  final String title;
  final String message;

  const _ComingSoonScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
