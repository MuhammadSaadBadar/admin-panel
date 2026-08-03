import 'package:flutter/material.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final NavigatorObserver routeObserver = _AppRouteObserver();

  static String? _currentRouteName;

  /// Navigate to a named route
  static Future<T?> navigateTo<T>(String route, {Object? arguments}) async {
    return await navigatorKey.currentState?.pushNamed<T>(
      route,
      arguments: arguments,
    );
  }

  /// Navigate to a named route and replace the current route
  static Future<T?> navigateToReplacement<T>(
    String route, {
    Object? arguments,
  }) async {
    return await navigatorKey.currentState?.pushReplacementNamed<T, T>(
      route,
      arguments: arguments,
    );
  }

  /// Navigate to a named route and remove all previous routes
  static Future<T?> navigateToAndRemoveUntil<T>(
    String route, {
    Object? arguments,
  }) async {
    return await navigatorKey.currentState?.pushNamedAndRemoveUntil<T>(
      route,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back to the previous screen
  static void goBack<T>([T? result]) {
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState?.pop<T>(result);
    }
  }

  /// Check if can go back
  static bool get canPop => navigatorKey.currentState?.canPop() ?? false;

  /// Pop until a specific route
  static void popUntil(RoutePredicate predicate) {
    navigatorKey.currentState?.popUntil(predicate);
  }

  /// Get the current route name
  static String? get currentRoute {
    return _currentRouteName;
  }
}

class _AppRouteObserver extends NavigatorObserver {
  void _updateCurrentRoute(Route<dynamic>? route) {
    AppRouter._currentRouteName = route?.settings.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateCurrentRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateCurrentRoute(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _updateCurrentRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateCurrentRoute(newRoute);
  }
}
