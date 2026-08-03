import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import '../routes/route_names.dart';

class AuthInterceptor extends Interceptor {
  final String Function() getToken;

  AuthInterceptor({required this.getToken});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getToken();
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      debugPrint('[HTTP] AUTH header attached.');
    } else {
      debugPrint('[HTTP] AUTH header skipped — no token available.');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      debugPrint(
        '[HTTP] AUTH 401 received for ${err.requestOptions.path} — '
        'session is invalid or expired. Redirecting to login.',
      );
      // Clear any pending navigation and force the user back to the login screen.
      // The login controller will reset auth state on initialisation.
      Get.offAllNamed(RouteNames.login);
    }
    handler.next(err);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[HTTP] REQUEST ${options.method} ${options.path}');
    debugPrint('[HTTP] REQUEST HEADERS ${_sanitizeHeaders(options.headers)}');
    debugPrint('[HTTP] REQUEST QUERY ${options.queryParameters}');
    debugPrint('[HTTP] REQUEST BODY ${_sanitizePayload(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[HTTP] RESPONSE ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}',
    );
    debugPrint('[HTTP] RESPONSE BODY ${_sanitizePayload(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[HTTP] ERROR status=${err.response?.statusCode} method=${err.requestOptions.method} path=${err.requestOptions.path} message=${err.message}',
    );
    debugPrint('[HTTP] ERROR BODY ${_sanitizePayload(err.response?.data)}');
    handler.next(err);
  }

  String _sanitizePayload(dynamic data) {
    if (data == null) return 'null';
    if (data is! Map) return data.toString();

    final cloned = Map<String, dynamic>.from(data.cast<String, dynamic>());
    for (final key in [
      'password',
      'new_password',
      'old_password',
      'token',
      'access',
      'refresh',
      'refresh_token',
      'reset_token',
      'otp_code',
    ]) {
      if (cloned.containsKey(key)) {
        cloned[key] = '***';
      }
    }
    return cloned.toString();
  }

  String _sanitizeHeaders(Map<String, dynamic> headers) {
    final cloned = Map<String, dynamic>.from(headers);
    if (cloned.containsKey('Authorization')) {
      cloned['Authorization'] = 'Bearer ***';
    }
    return cloned.toString();
  }
}
