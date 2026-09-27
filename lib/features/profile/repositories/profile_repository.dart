// lib/features/profile/repositories/profile_repository.dart

import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/network/api_error_mapper.dart';
import 'package:admin/core/network/api_exceptions.dart';
import 'package:admin/features/profile/models/admin_profile.dart';
import 'package:admin/features/profile/models/payment_methods.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Repository for the Admin Profile module.
///
/// Handles:
/// - `GET /auth/me/` — fetch the current admin's profile
/// - `PATCH /auth/me/` — update profile contact fields
/// - `POST /auth/password/change/` — change the admin's password
/// - `GET /accounts/payment-methods/` — fetch platform payment methods & commission
/// - `PATCH /accounts/payment-methods/` — update commission percentage
class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  // ── Profile ────────────────────────────────────────────────────────────────

  /// Fetches the current admin's profile via `GET /auth/me/`.
  Future<AdminProfile> getCurrentUser() async {
    final path = ApiConstants.authMe;
    debugPrint('[ProfileRepo] getCurrentUser called — path=$path');

    try {
      final response = await _apiClient.get(path);
      debugPrint(
        '[ProfileRepo] getCurrentUser response — status=${response.statusCode} '
        'body=${_sanitizeResponse(response.data)}',
      );

      final profile = AdminProfile.fromJson(response.data);
      debugPrint(
        '[ProfileRepo] getCurrentUser parsed — id=${profile.id} '
        'name="${profile.fullName}" role=${profile.role}',
      );
      return profile;
    } on DioException catch (e) {
      debugPrint(
        '[ProfileRepo] getCurrentUser DioException — type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to load your profile.',
      );
      debugPrint('[ProfileRepo] getCurrentUser error — $mapped');
      throw mapped;
    }
  }

  /// Updates the admin's profile contact fields via `PATCH /auth/me/`.
  ///
  /// The backend only accepts `first_name`, `last_name`, and `phone_number`
  /// on this endpoint — email/role are not editable here.
  Future<AdminProfile> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final path = ApiConstants.authMe;
    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
    };
    debugPrint('[ProfileRepo] updateProfile called — path=$path');
    debugPrint(
      '[ProfileRepo] updateProfile payload — '
      'first_name=${_maskName(firstName)} '
      'last_name=${_maskName(lastName)} '
      'phone_number=${_maskPhone(phoneNumber)}',
    );

    try {
      final response = await _apiClient.patch(path, data: body);
      debugPrint(
        '[ProfileRepo] updateProfile response — status=${response.statusCode} '
        'body=${_sanitizeResponse(response.data)}',
      );

      final profile = AdminProfile.fromJson(response.data);
      debugPrint(
        '[ProfileRepo] updateProfile parsed — id=${profile.id} '
        'name="${profile.fullName}"',
      );
      return profile;
    } on DioException catch (e) {
      debugPrint(
        '[ProfileRepo] updateProfile DioException — type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to update your profile.',
      );
      debugPrint('[ProfileRepo] updateProfile error — $mapped');
      throw mapped;
    }
  }

  /// Changes the admin's password via `POST /auth/password/change/`.
  ///
  /// Requires the current password plus the new one. The backend validates
  /// both (wrong old password returns a `400` with `old_password` field
  /// errors) — those are surfaced to the UI via [ApiException.fieldErrors].
  ///
  /// **Network-error retry:** On Render's free tier the backend may commit the
  /// password change and then drop / time out the response (cold start). When
  /// the first attempt fails at the *network* layer we retry once with short
  /// timeouts and treat these outcomes as success because they *prove* the
  /// change already happened server-side:
  ///   - a 2xx retry → the change succeeded;
  ///   - a 401/403 retry → the session was invalidated by the password change;
  ///   - a 400 with an `old_password` error → the old password no longer
  ///     matches, i.e. the change was already committed.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final path = ApiConstants.authPasswordChange;
    final body = {'old_password': oldPassword, 'new_password': newPassword};

    // Password values are intentionally NOT logged (sensitive).
    debugPrint(
      '[ProfileRepo] changePassword called — path=$path '
      'old_password_len=${oldPassword.length} '
      'new_password_len=${newPassword.length}',
    );

    try {
      await _postChangePassword(path, body);
    } on DioException catch (e) {
      debugPrint(
        '[ProfileRepo] changePassword DioException — type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      debugPrint('[ProfileRepo] changePassword error body=${e.response?.data}');
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to change your password.',
      );

      // Only retry when the failure is at the network layer (connection
      // drop / timeout) — the password may already have been changed.
      if (mapped is! NetworkException) {
        debugPrint(
          '[ProfileRepo] changePassword — non-network error, surfacing: $mapped',
        );
        throw mapped;
      }

      debugPrint(
        '[ProfileRepo] changePassword network failure detected — retrying '
        'once to confirm whether the password was changed server-side.',
      );
      try {
        await _postChangePassword(
          path,
          body,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
        );
        debugPrint(
          '[ProfileRepo] changePassword retry returned 2xx — treating as '
          'success.',
        );
        return;
      } on DioException catch (retryError) {
        debugPrint(
          '[ProfileRepo] changePassword retry DioException — '
          'type=${retryError.type} '
          'status=${retryError.response?.statusCode} '
          'message=${retryError.message}',
        );
        debugPrint(
          '[ProfileRepo] changePassword retry error '
          'body=${retryError.response?.data}',
        );

        final retryResponse = retryError.response;
        final retryStatus = retryError.response?.statusCode;

        // The session was invalidated by the password change → success.
        if (retryStatus == 401 || retryStatus == 403) {
          debugPrint(
            '[ProfileRepo] changePassword retry returned $retryStatus — '
            'session invalidated, password was changed. Treating as success.',
          );
          return;
        }

        // The old password no longer matches → the change was committed.
        if (retryStatus == 400 && _hasOldPasswordError(retryResponse)) {
          debugPrint(
            '[ProfileRepo] changePassword retry returned 400 with '
            'old_password error — the change was already committed. '
            'Treating as success.',
          );
          return;
        }

        // A definitive non-network HTTP error → surface the retry's error as
        // it is more accurate than the original network error.
        if (retryResponse != null) {
          final retryMapped = ApiErrorMapper.mapDioException(
            retryError,
            defaultMessage: 'Unable to change your password.',
          );
          debugPrint(
            '[ProfileRepo] changePassword retry produced a definitive error '
            '— surfacing: $retryMapped',
          );
          throw retryMapped;
        }

        // The retry also failed at the network layer — rethrow the original
        // network error.
        debugPrint(
          '[ProfileRepo] changePassword retry also failed at network layer — '
          'rethrowing original network error.',
        );
        throw mapped;
      }
    }
  }

  // ── Payment Methods / Commission ──────────────────────────────────────────

  /// Fetches platform payment methods including commission percentage
  /// via `GET /accounts/payment-methods/`.
  Future<PaymentMethods> getPaymentMethods() async {
    final path = ApiConstants.accountsPaymentMethods;
    debugPrint('[ProfileRepo] getPaymentMethods called — path=$path');

    try {
      final response = await _apiClient.get(path);
      debugPrint(
        '[ProfileRepo] getPaymentMethods response — status=${response.statusCode}',
      );

      final paymentMethods = PaymentMethods.fromJson(response.data);
      debugPrint(
        '[ProfileRepo] getPaymentMethods parsed — '
        'commission=${paymentMethods.commissionDisplay}',
      );
      return paymentMethods;
    } on DioException catch (e) {
      debugPrint(
        '[ProfileRepo] getPaymentMethods DioException — type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to load payment methods.',
      );
      debugPrint('[ProfileRepo] getPaymentMethods error — $mapped');
      throw mapped;
    }
  }

  /// Updates the platform commission percentage via `PATCH /accounts/payment-methods/`.
  ///
  /// Admin-only operation. The commission percentage is a platform-wide setting.
  Future<PaymentMethods> updateCommission(double percentage) async {
    final path = ApiConstants.accountsPaymentMethods;
    final body = {'commission_percentage': percentage.toStringAsFixed(2)};

    debugPrint(
      '[ProfileRepo] updateCommission called — path=$path '
      'percentage=${percentage.toStringAsFixed(2)}%',
    );

    try {
      final response = await _apiClient.patch(path, data: body);
      debugPrint(
        '[ProfileRepo] updateCommission response — status=${response.statusCode}',
      );

      final paymentMethods = PaymentMethods.fromJson(response.data);
      debugPrint(
        '[ProfileRepo] updateCommission parsed — '
        'commission=${paymentMethods.commissionDisplay}',
      );
      return paymentMethods;
    } on DioException catch (e) {
      debugPrint(
        '[ProfileRepo] updateCommission DioException — type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to update commission percentage.',
      );
      debugPrint('[ProfileRepo] updateCommission error — $mapped');
      throw mapped;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _postChangePassword(
    String path,
    Map<String, dynamic> body, {
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) async {
    final response = await _apiClient.post(
      path,
      data: body,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
    debugPrint(
      '[ProfileRepo] changePassword response — status=${response.statusCode}',
    );
    debugPrint(
      '[ProfileRepo] changePassword response '
      'body=${_sanitizeResponse(response.data)}',
    );
  }

  /// Returns true when a 400 response body carries a structured
  /// `old_password` field error, which proves the old password no longer
  /// matches (i.e. the password was already changed).
  bool _hasOldPasswordError(Response? response) {
    if (response?.data is! Map<String, dynamic>) return false;
    final data = response!.data as Map<String, dynamic>;

    // DRF `errors` envelope: {"errors": {"old_password": ["..."]}}
    final errors = data['errors'];
    if (errors is Map && errors.containsKey('old_password')) {
      return true;
    }

    // Flat shape: {"old_password": ["..."]}
    if (data.containsKey('old_password')) return true;

    // Non-field detail may mention the old password.
    final detail = data['detail'];
    return detail is String && detail.toLowerCase().contains('old_password');
  }

  // ── Logging helpers ───────────────────────────────────────────────────────

  /// Masks partial name (keep first char, mask the rest).
  static String _maskName(String name) {
    if (name.isEmpty) return '(empty)';
    return '${name[0]}***';
  }

  /// Masks a phone number (keep first 3 + last 2 digits).
  static String _maskPhone(String phone) {
    if (phone.isEmpty) return '(empty)';
    if (phone.length < 5) return '***';
    return '${phone.substring(0, 3)}***${phone.substring(phone.length - 2)}';
  }

  /// Sanitizes a response body for debug logs (prevents echoing tokens/emails).
  static Object? _sanitizeResponse(dynamic data) {
    if (data is Map) {
      final safe = <String, dynamic>{};
      data.forEach((key, value) {
        final k = key.toString();
        if (k.contains('token') ||
            k.contains('password') ||
            k.contains('email')) {
          safe[k] = '***';
        } else {
          safe[k] = value is Map || value is List ? '[redacted]' : value;
        }
      });
      return safe;
    }
    return data is String && data.length > 200
        ? '${data.substring(0, 200)}...[truncated]'
        : data;
  }
}
