import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/network/api_error_mapper.dart';
import 'package:admin/core/network/api_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_profile.dart';

/// Repository for the Admin Profile module.
///
/// Handles:
/// - `GET /auth/me/` — fetch the current admin's profile
/// - `PATCH /auth/me/` — update profile contact fields
/// - `POST /auth/password/change/` — change the admin's password
///
/// Follows the same conventions as [DoctorRepository]: debug logging,
/// [ApiErrorMapper] for structured errors, and sanitized response bodies.
class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

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
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final path = ApiConstants.authPasswordChange;
    // Password values are intentionally NOT logged (sensitive).
    debugPrint(
      '[ProfileRepo] changePassword called — path=$path '
      'old_password_len=${oldPassword.length} '
      'new_password_len=${newPassword.length}',
    );

    try {
      final response = await _apiClient.post(
        path,
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );
      debugPrint(
        '[ProfileRepo] changePassword response — status=${response.statusCode}',
      );
      debugPrint(
        '[ProfileRepo] changePassword response body=${_sanitizeResponse(response.data)}',
      );
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
      debugPrint('[ProfileRepo] changePassword error — $mapped');
      throw mapped;
    }
  }

  // ── Logging helpers ────────────────────────────────────────────────────

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
