import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/di/initial_binding.dart';
import 'core/routes/route_names.dart';
import 'core/routes/routes.dart';
import 'core/services/local_storage_service.dart';
import 'core/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  runApp(const MamaHealthProApp());
}

class MamaHealthProApp extends StatelessWidget {
  const MamaHealthProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mama Health',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      initialRoute: RouteNames.root,
      // GetX handles routing — no onGenerateRoute or navigatorKey needed.
      getPages: AppRoutes.pages,
      defaultTransition: Transition.fadeIn,
    );
  }
}
