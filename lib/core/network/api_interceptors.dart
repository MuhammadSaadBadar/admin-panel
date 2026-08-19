import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import '../routes/route_names.dart';

/// Result of a successful token-refresh request. Kept in the network layer so
/// the interceptor does not depend on feature-level auth models.
class TokenRefreshResult {
  final String accessToken;
  final String? refreshToken;

  const TokenRefreshResult({required this.accessToken, this.refreshToken});
}

class AuthInterceptor extends Interceptor {
  /// Marker placed in [RequestOptions.extra] to prevent a replayed request
  /// from being refreshed (and retried) more than once.
  static const String retriedFlag = 'auth_retried';

  final String Function() getToken;
  final String? Function() getRefreshToken;
  final Future<TokenRefreshResult> Function(String refreshToken) refreshRequest;
  final Future<void> Function(String accessToken, String? refreshToken)
  onTokenRefreshed;
  final Future<void> Function() onLogoutRequired;

  Dio? _dio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  AuthInterceptor({
    required this.getToken,
    required this.getRefreshToken,
    required this.refreshRequest,
    required this.onTokenRefreshed,
    required this.onLogoutRequired,
  });

  /// Gives the interceptor a reference to the [Dio] instance it lives on, so
  /// it can replay queued requests through the full interceptor chain (which
  /// will attach the freshly-obtained token in [onRequest]).
  void setDio(Dio dio) {
    _dio = dio;
  }

  /// Whether [path] is a *public* auth endpoint that may legitimately return
  /// 401 and must never recurse into the refresh flow (login, refresh, logout,
  /// and the public password-reset steps).
  ///
  /// NOTE: This must match the PUBLIC endpoints only. Authenticated auth
  /// endpoints such as `/auth/me/` and `/auth/password/change/` are NOT public
  /// — they use the access token and must still trigger a token refresh on 401.
  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login/') ||
        path.contains('/auth/register/') ||
        path.contains('/auth/verify-email/') ||
        path.contains('/auth/resend-verification/') ||
        path.contains('/auth/token/refresh/') ||
        path.contains('/auth/logout/') ||
        path.contains('/auth/password/forgot/') ||
        path.contains('/auth/password/verify-otp/') ||
        path.contains('/auth/password/reset/');
  }

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
    final request = err.requestOptions;
    final status = err.response?.statusCode;

    // Only trigger refresh for 401s on protected endpoints.
    // Login/refresh/logout endpoints may legitimately return 401 and must
    // never recurse into the refresh flow.
    if (status != 401 || _isAuthEndpoint(request.path)) {
      handler.next(err);
      return;
    }

    debugPrint('[AUTH] 401 received for ${request.path} — attempting refresh.');

    // If this exact request was already retried with a fresh token and still
    // got a 401, the session is genuinely invalid — do not retry again.
    if (request.extra[retriedFlag] == true) {
      debugPrint(
        '[AUTH] Request ${request.path} already retried after refresh — '
        'session invalid. Failing request and logging out.',
      );
      _failQueued();
      _forceLogout();
      handler.next(err);
      return;
    }

    // Mark so the replayed request is refreshed at most once.
    request.extra[retriedFlag] = true;

    // Queue this request; it will be replayed once a fresh token is available.
    _pendingRequests.add(
      _PendingRequest(options: request, handler: handler, error: err),
    );

    // If a refresh is already in flight, this request simply waits. Only one
    // refresh runs regardless of how many requests 401 simultaneously.
    if (_isRefreshing) {
      debugPrint(
        '[AUTH] Refresh already in progress — queued ${request.path} '
        '(${_pendingRequests.length} queued).',
      );
      return;
    }

    _refreshAndReplay();
  }

  Future<void> _refreshAndReplay() async {
    final refreshToken = getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint('[AUTH] No refresh token available — cannot refresh session.');
      _failQueued();
      await _forceLogout();
      return;
    }

    _isRefreshing = true;
    debugPrint('[AUTH] Refreshing access token via /auth/token/refresh/ ...');

    try {
      final result = await refreshRequest(refreshToken);
      debugPrint('[AUTH] Refresh request succeeded — access token updated.');

      await onTokenRefreshed(result.accessToken, result.refreshToken);
      debugPrint('[AUTH] New tokens persisted to storage.');

      _isRefreshing = false;
      _replayQueued();
      debugPrint('[AUTH] All queued requests replayed with refreshed token.');
    } catch (e) {
      debugPrint('[AUTH] Refresh FAILED — reason: $e');
      _isRefreshing = false;
      _failQueued(refreshError: e);
      await _forceLogout();
    }
  }

  void _replayQueued() {
    final dio = _dio;
    final queue = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final pending in queue) {
      if (dio == null) {
        pending.handler.reject(pending.error);
        continue;
      }
      debugPrint(
        '[AUTH] Replaying ${pending.options.path} with refreshed token.',
      );
      dio
          .fetch(pending.options)
          .then((response) => pending.handler.resolve(response))
          .catchError((Object e) {
            pending.handler.reject(
              e is DioException
                  ? e
                  : DioException(requestOptions: pending.options, error: e),
            );
          });
    }
  }

  void _failQueued({Object? refreshError}) {
    final queue = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final pending in queue) {
      if (refreshError != null) {
        pending.handler.reject(
          DioException(requestOptions: pending.options, error: refreshError),
        );
      } else {
        pending.handler.reject(pending.error);
      }
    }
  }

  Future<void> _forceLogout() async {
    debugPrint('[AUTH] Logout triggered — refresh unsuccessful/not possible.');
    try {
      await onLogoutRequired();
      debugPrint('[AUTH] Local auth state cleared.');
    } catch (e) {
      debugPrint('[AUTH] Logout cleanup failed: $e');
    }

    if (Get.currentRoute != RouteNames.login) {
      debugPrint('[AUTH] Redirecting to /login.');
      Get.offAllNamed(RouteNames.login);
    }
  }
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;
  final DioException error;

  _PendingRequest({
    required this.options,
    required this.handler,
    required this.error,
  });
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
