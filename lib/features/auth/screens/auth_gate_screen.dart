import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/route_names.dart';
import '../services/auth_service.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveInitialRoute();
    });
  }

  Future<void> _resolveInitialRoute() async {
    final authService = Get.find<AuthService>();
    final isAuthenticated = await authService.isAuthenticated();

    final target = isAuthenticated ? RouteNames.dashboard : RouteNames.login;
    debugPrint(
      '[AuthGate] Initial route resolved isAuthenticated=$isAuthenticated -> $target',
    );

    if (!mounted) return;
    Get.offAllNamed(target);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
