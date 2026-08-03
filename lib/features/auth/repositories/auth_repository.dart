import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/network/api_exceptions.dart';
import 'package:admin/features/auth/models/login_request.dart';
import 'package:admin/features/auth/models/login_response.dart';
import 'package:admin/features/auth/models/patient_registration_request.dart';
import 'package:admin/features/auth/models/registration_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<LoginResponse> login(LoginRequest request) async {
    final path = ApiConstants.authLogin;
    debugPrint('[AuthRepo] Login request start path=$path');
    debugPrint('[AuthRepo] Login payload email=${_maskEmail(request.email)}');

    try {
      final response = await _apiClient.post(path, data: request.toJson());
      debugPrint('[AuthRepo] Login response status=${response.statusCode}');
      debugPrint(
        '[AuthRepo] Login response body=${_sanitizeResponse(response.data)}',
      );
      return LoginResponse.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    } on DioException catch (e) {
      _logDioError('Login', e);
      throw _mapDioException(e, defaultMessage: 'Unable to login.');
    }
  }

  Future<RegistrationResponse> register(
    PatientRegistrationRequest request,
  ) async {
    final path = ApiConstants.authRegister;
    debugPrint('[AuthRepo] Register request start path=$path');
    debugPrint(
      '[AuthRepo] Register payload '
      'email=${_maskEmail(request.email)} '
      'first_name=${request.firstName} last_name=${request.lastName} '
      'phone=${_maskPhone(request.phoneNumber)} password=***',
    );

    try {
      final response = await _apiClient.post(path, data: request.toJson());
      debugPrint('[AuthRepo] Register response status=${response.statusCode}');
      debugPrint(
        '[AuthRepo] Register response body=${_sanitizeResponse(response.data)}',
      );
      return RegistrationResponse.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    } on DioException catch (e) {
      _logDioError('Register', e);
      throw _mapDioException(e, defaultMessage: 'Unable to register patient.');
    }
  }

  Future<void> forgotPassword(String email) async {
    final path = ApiConstants.authPasswordForgot;
    debugPrint('[AuthRepo] Forgot password request start path=$path');
    debugPrint('[AuthRepo] Forgot password payload email=${_maskEmail(email)}');

    try {
      final response = await _apiClient.post(path, data: {'email': email});
      debugPrint(
        '[AuthRepo] Forgot password response status=${response.statusCode}',
      );
      debugPrint(
        '[AuthRepo] Forgot password response body=${_sanitizeResponse(response.data)}',
      );
    } on DioException catch (e) {
      _logDioError('Forgot password', e);
      throw _mapDioException(
        e,
        defaultMessage: 'Unable to request password reset code.',
      );
    }
  }

  Future<String> verifyPasswordOtp({
    required String email,
    required String otpCode,
  }) async {
    final path = ApiConstants.authPasswordVerifyOtp;
    debugPrint('[AuthRepo] OTP verify request start path=$path');
    debugPrint(
      '[AuthRepo] OTP verify payload email=${_maskEmail(email)} otp=******',
    );

    try {
      final response = await _apiClient.post(
        path,
        data: {'email': email, 'otp_code': otpCode},
      );
      debugPrint(
        '[AuthRepo] OTP verify response status=${response.statusCode}',
      );
      debugPrint(
        '[AuthRepo] OTP verify response body=${_sanitizeResponse(response.data)}',
      );

      final body = (response.data as Map).cast<String, dynamic>();
      final token = body['reset_token'] as String?;
      if (token == null || token.isEmpty) {
        throw ApiException(
          'Reset token not returned by verification endpoint.',
        );
      }
      return token;
    } on DioException catch (e) {
      _logDioError('OTP verify', e);
      throw _mapDioException(e, defaultMessage: 'Unable to verify OTP code.');
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final path = ApiConstants.authPasswordReset;
    debugPrint('[AuthRepo] Reset password request start path=$path');
    debugPrint('[AuthRepo] Reset password payload token=*** new_password=***');

    try {
      final response = await _apiClient.post(
        path,
        data: {'token': token, 'new_password': newPassword},
      );
      debugPrint(
        '[AuthRepo] Reset password response status=${response.statusCode}',
      );
      debugPrint(
        '[AuthRepo] Reset password response body=${_sanitizeResponse(response.data)}',
      );
    } on DioException catch (e) {
      _logDioError('Reset password', e);
      throw _mapDioException(e, defaultMessage: 'Unable to reset password.');
    }
  }

  Future<void> logout({required String refreshToken}) async {
    final path = ApiConstants.authLogout;
    debugPrint('[AuthRepo] Logout request start path=$path');
    debugPrint('[AuthRepo] Logout payload refresh=***');

    try {
      final response = await _apiClient.post(
        path,
        data: {'refresh': refreshToken},
      );
      debugPrint('[AuthRepo] Logout response status=${response.statusCode}');
      debugPrint(
        '[AuthRepo] Logout response body=${_sanitizeResponse(response.data)}',
      );
    } on DioException catch (e) {
      _logDioError('Logout', e);
      throw _mapDioException(e, defaultMessage: 'Unable to logout.');
    }
  }

  Future<LoginResponse> refreshToken(String refreshToken) async {
    final path = ApiConstants.authTokenRefresh;
    debugPrint('[AuthRepo] Refresh token request start path=$path');
    debugPrint('[AuthRepo] Refresh token payload refresh=***');

    try {
      final response = await _apiClient.post(
        path,
        data: {'refresh': refreshToken},
      );
      debugPrint(
        '[AuthRepo] Refresh token response status=${response.statusCode}',
      );
      debugPrint(
        '[AuthRepo] Refresh token response body=${_sanitizeResponse(response.data)}',
      );
      return LoginResponse.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    } on DioException catch (e) {
      _logDioError('Refresh token', e);
      throw _mapDioException(e, defaultMessage: 'Unable to refresh token.');
    }
  }

  void _logDioError(String action, DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    debugPrint('[AuthRepo] $action error status=$status message=${e.message}');
    debugPrint('[AuthRepo] $action error body=${_sanitizeResponse(data)}');
  }

  ApiException _mapDioException(
    DioException e, {
    required String defaultMessage,
  }) {
    final statusCode = e.response?.statusCode;
    final serverMessage = _extractServerMessage(e.response?.data);
    final fieldErrors = _extractFieldErrors(e.response?.data);

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException();
    }

    if (statusCode == 401) {
      return UnauthorizedException();
    }
    if (statusCode == 404) {
      return NotFoundException();
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerException();
    }

    return ApiException(
      serverMessage ?? defaultMessage,
      statusCode: statusCode,
      fieldErrors: fieldErrors,
    );
  }

  String? _extractServerMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      final errors = data['errors'];
      if (errors != null) return errors.toString();
    }
    return null;
  }

  /// Extracts the standard DRF `errors` envelope
  /// (`{"detail": ..., "errors": {"field": ["msg", ...]}}`) into a
  /// field-name → list-of-messages map. Returns null when the payload
  /// carries no structured field errors.
  Map<String, List<String>>? _extractFieldErrors(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final rawErrors = data['errors'];
    if (rawErrors is! Map) return null;

    final Map<String, List<String>> result = {};
    rawErrors.forEach((key, value) {
      if (value is List) {
        result[key.toString()] = value.map((e) => e.toString()).toList();
      } else {
        result[key.toString()] = <String>[value.toString()];
      }
    });
    return result.isEmpty ? null : result;
  }

  String _maskPhone(String phone) {
    if (phone.length <= 3) return '***';
    return '${phone.substring(0, 3)}***';
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${local[0]}***@$domain';
    return '${local.substring(0, 2)}***@$domain';
  }

  String _sanitizeResponse(dynamic data) {
    if (data == null) return 'null';
    if (data is! Map) return data.toString();

    final map = Map<String, dynamic>.from(data.cast<String, dynamic>());
    for (final key in [
      'access',
      'refresh',
      'token',
      'refresh_token',
      'reset_token',
    ]) {
      if (map.containsKey(key)) {
        map[key] = '***';
      }
    }
    return map.toString();
  }
}
