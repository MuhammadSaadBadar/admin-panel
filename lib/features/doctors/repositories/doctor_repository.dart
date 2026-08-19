import 'dart:math';

import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/network/api_error_mapper.dart';
import 'package:admin/core/network/api_exceptions.dart';
import 'package:admin/features/doctors/models/doctor.dart';
import 'package:admin/features/doctors/models/doctor_invite_request.dart';
import 'package:admin/features/doctors/models/doctor_invite_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DoctorRepository {
  final ApiClient _apiClient;

  DoctorRepository(this._apiClient);

  /// Fetches the list of doctors.
  ///
  /// The backend `GET /api/v1/accounts/doctors/` endpoint supports pagination
  /// via `page_size` (DRF paginated response: `{ count, next, previous,
  /// results }`). We request a generous page size (default 50) so the
  /// dashboard has a meaningful working set for client-side search/filtering —
  /// the endpoint does **not** support server-side `q`/`specialization`/`status`
  /// filtering, only pagination.
  Future<List<Doctor>> getDoctors({int pageSize = 50}) async {
    final queryParameters = <String, dynamic>{'page_size': pageSize};
    debugPrint(
      '[DoctorRepo] getDoctors called — ${ApiConstants.doctors} '
      'queryParameters=$queryParameters',
    );
    final response = await _apiClient.get(
      ApiConstants.doctors,
      queryParameters: queryParameters,
    );
    debugPrint(
      '[DoctorRepo] getDoctors response — status=${response.statusCode}',
    );

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final count = data['count'];
      final results = data['results'] as List? ?? [];
      final doctors = results.map((json) => Doctor.fromJson(json)).toList();
      debugPrint(
        '[DoctorRepo] getDoctors parsed — ${doctors.length} doctors '
        '(total on server=$count)',
      );
      return doctors;
    } else if (response.data is List) {
      // Fallback for non-paginated response
      final doctors = (response.data as List)
          .map((json) => Doctor.fromJson(json))
          .toList();
      debugPrint('[DoctorRepo] getDoctors parsed — ${doctors.length} doctors');
      return doctors;
    } else {
      debugPrint('[DoctorRepo] getDoctors — unexpected response shape');
      return [];
    }
  }

  /// Sends a doctor invitation via `POST /api/v1/accounts/doctors/invite/`.
  ///
  /// The backend creates a pending `DoctorInvite` and emails an accept link
  /// to the doctor.
  ///
  /// ### Outcome classification
  /// - 2xx → [InviteOutcome.success]
  /// - 4xx validation → [InviteOutcome.knownServerError] with field errors
  /// - 4xx "already pending" → [InviteOutcome.success] with [alreadyPending]
  /// - 5xx → [InviteOutcome.knownServerError]
  /// - NetworkException (timeout/lost response) → ONE automatic retry with a
  ///   short timeout. If the retry returns "already pending", the original
  ///   attempt PROVABLY succeeded → [InviteOutcome.success].
  ///   Otherwise → [InviteOutcome.unknown].
  ///
  /// An [idempotencyKey] is generated and included in the request body so
  /// the backend can deduplicate retries. It is also logged to trace the
  /// same logical submission across (re)attempts.
  Future<DoctorInviteResponse> inviteDoctor(DoctorInviteRequest request) async {
    final path = ApiConstants.accountsDoctorsInvite;
    final idempotencyKey = _generateIdempotencyKey();
    debugPrint('[DoctorRepo] inviteDoctor called — path=$path');
    debugPrint(
      '[DoctorRepo] inviteDoctor payload — '
      'email=${_maskEmail(request.email)} '
      'specialization=${request.specialization} '
      'idempotencyKey=$idempotencyKey attempt=1',
    );

    try {
      final response = await _apiClient.post(
        path,
        data: {...request.toJson(), 'idempotency_key': idempotencyKey},
      );
      debugPrint(
        '[DoctorRepo] inviteDoctor response — status=${response.statusCode}',
      );
      debugPrint(
        '[DoctorRepo] inviteDoctor response body=${_sanitizeResponse(response.data)}',
      );

      final parsed = _parseResponse(response.data, InviteOutcome.success);
      debugPrint(
        '[DoctorRepo] inviteDoctor parsed — outcome=${parsed.outcome} '
        'alreadyPending=${parsed.alreadyPending} '
        'detail="${parsed.detail}"',
      );
      return parsed;
    } on DioException catch (e) {
      debugPrint(
        '[DoctorRepo] inviteDoctor DioException — '
        'type=${e.type} status=${e.response?.statusCode} '
        'message=${e.message}',
      );
      debugPrint('[DoctorRepo] inviteDoctor error body=${e.response?.data}');

      // ── Definitive 4xx/5xx → known server error ──────────────────────
      if (e.response?.statusCode != null) {
        final status = e.response!.statusCode!;
        if (status >= 400 && status < 500) {
          // "Already pending" → treat as success (invite exists).
          final body = e.response?.data;
          final parsed = _parseResponse(body, InviteOutcome.success);
          if (parsed.alreadyPending) {
            debugPrint(
              '[DoctorRepo] inviteDoctor — 4xx with "already pending" → '
              'classified as success.',
            );
            return parsed;
          }
          // True validation error → known server error.
          debugPrint('[DoctorRepo] inviteDoctor — 4xx validation error.');
          return _parseResponse(body, InviteOutcome.knownServerError);
        }
        if (status >= 500) {
          debugPrint('[DoctorRepo] inviteDoctor — 5xx server error.');
          return DoctorInviteResponse.outcome(
            InviteOutcome.knownServerError,
            detail: 'Server error. Please try again.',
          );
        }
      }

      // ── Network / timeout / unknown → auto-retry ONCE ─────────────────
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to send the doctor invitation.',
      );

      if (mapped is NetworkException) {
        debugPrint(
          '[DoctorRepo] inviteDoctor — NETWORK failure detected. '
          'Retrying once (attempt=2) with short timeout to confirm status.',
        );
        try {
          final retry = await _apiClient.post(
            path,
            data: {...request.toJson(), 'idempotency_key': idempotencyKey},
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 25),
          );
          debugPrint(
            '[DoctorRepo] inviteDoctor retry — status=${retry.statusCode}',
          );
          final parsed = _parseResponse(retry.data, InviteOutcome.success);
          debugPrint(
            '[DoctorRepo] inviteDoctor retry — outcome=${parsed.outcome} '
            'alreadyPending=${parsed.alreadyPending}',
          );
          return parsed;
        } on DioException catch (retryError) {
          final retryStatus = retryError.response?.statusCode;
          final retryBody = retryError.response?.data;

          // "Already pending" on retry → original PROVABLY succeeded.
          if (retryStatus != null && retryStatus >= 400 && retryStatus < 500) {
            final parsed = _parseResponse(retryBody, InviteOutcome.success);
            if (parsed.alreadyPending) {
              debugPrint(
                '[DoctorRepo] inviteDoctor — RETRY returned "already '
                'pending" — original attempt actually succeeded.',
              );
              return parsed;
            }
          }

          // Retry also failed → truly unknown.
          debugPrint(
            '[DoctorRepo] inviteDoctor — RETRY also failed '
            '(type=${retryError.type}). Outcome=unknown.',
          );
          return DoctorInviteResponse.outcome(
            InviteOutcome.unknown,
            detail: 'Unable to confirm the invitation was sent.',
          );
        }
      }

      // Non-network DioException (cancelled, etc.) → unknown.
      debugPrint(
        '[DoctorRepo] inviteDoctor — non-network DioException. '
        'Outcome=unknown.',
      );
      return DoctorInviteResponse.outcome(
        InviteOutcome.unknown,
        detail: 'Unable to confirm the invitation was sent.',
      );
    }
  }

  /// Queries the existing doctor list to verify whether an invite has been
  /// accepted (i.e. the doctor now appears in the list). If the doctor is
  /// found, the invite was processed. If not, the invite may still be
  /// pending (not yet accepted) or may not have been created.
  ///
  /// Returns `true` when the doctor is found (invite proven successful),
  /// `false` when not found (status uncertain — the invite may still be
  /// pending but unaccepted).
  Future<bool> verifyStatus(String email) async {
    debugPrint('[DoctorRepo] verifyStatus called — email=${_maskEmail(email)}');
    try {
      final doctors = await getDoctors();
      final found = doctors.any(
        (d) => d.email.toLowerCase() == email.toLowerCase(),
      );
      debugPrint(
        '[DoctorRepo] verifyStatus — doctor found=$found '
        '(searched ${doctors.length} doctors)',
      );
      return found;
    } catch (e) {
      debugPrint('[DoctorRepo] verifyStatus — query failed: $e');
      return false;
    }
  }

  Future<Doctor> getDoctor(int id) async {
    final path = '${ApiConstants.doctors}$id/';
    debugPrint('[DoctorRepo] getDoctor called — id=$id url=$path');
    final response = await _apiClient.get(path);
    debugPrint(
      '[DoctorRepo] getDoctor response — status=${response.statusCode}',
    );
    debugPrint(
      '[DoctorRepo] getDoctor response body=${_sanitizeResponse(response.data)}',
    );
    final doctor = Doctor.fromJson(response.data);
    debugPrint(
      '[DoctorRepo] getDoctor parsed — id=${doctor.id} name="${doctor.name}" '
      'specialization="${doctor.specialization}"',
    );
    return doctor;
  }

  Future<Doctor> createDoctor(Doctor doctor) async {
    debugPrint('[DoctorRepo] createDoctor called — ${doctor.name}');
    final response = await _apiClient.post(
      ApiConstants.doctors,
      data: doctor.toJson(),
    );
    debugPrint(
      '[DoctorRepo] createDoctor response — status=${response.statusCode}',
    );
    return Doctor.fromJson(response.data);
  }

  Future<Doctor> updateDoctor(int id, Doctor doctor) async {
    debugPrint('[DoctorRepo] updateDoctor called — id=$id');
    final response = await _apiClient.put(
      '${ApiConstants.doctors}$id/',
      data: doctor.toJson(),
    );
    debugPrint(
      '[DoctorRepo] updateDoctor response — status=${response.statusCode}',
    );
    return Doctor.fromJson(response.data);
  }

  /// Activates or deactivates a doctor via
  /// `PATCH /accounts/doctors/{id}/` with body `{is_active: <bool>}`.
  ///
  /// There is no delete endpoint in the backend — deactivation is the
  /// intended way to disable a doctor while preserving their history.
  /// Returns the updated [Doctor].
  Future<Doctor> toggleDoctorActive(int id, bool isActive) async {
    final path = '${ApiConstants.doctors}$id/';
    final body = {'is_active': isActive};
    debugPrint(
      '[DoctorRepo] toggleDoctorActive called — id=$id isActive=$isActive',
    );
    debugPrint(
      '[DoctorRepo] toggleDoctorActive request — path=$path body=$body',
    );

    final response = await _apiClient.patch(path, data: body);
    debugPrint(
      '[DoctorRepo] toggleDoctorActive response — status=${response.statusCode} '
      'body=${_sanitizeResponse(response.data)}',
    );

    var parsed = Doctor.fromJson(response.data);
    debugPrint(
      '[DoctorRepo] toggleDoctorActive parsed — id=${parsed.id} '
      'isActive=${parsed.isActive}',
    );

    // The PATCH endpoint returns only the fields that were updated (e.g.
    // `is_active`, `first_name`, ...) and may NOT include the doctor's `id`.
    // `Doctor.fromJson` defaults a missing `id` to 0, which would corrupt the
    // object stored in the controllers and cause the next toggle to PATCH
    // `/doctors/0/` (404). Preserve the requested doctor ID in that case.
    if (parsed.id == 0) {
      parsed = parsed.copyWith(id: id);
      debugPrint(
        '[DoctorRepo] toggleDoctorActive — response omitted id; '
        'preserving requested id=$id',
      );
    }
    return parsed;
  }

  Future<void> deleteDoctor(int id) async {
    debugPrint('[DoctorRepo] deleteDoctor called — id=$id');
    await _apiClient.delete('${ApiConstants.doctors}$id/');
    debugPrint('[DoctorRepo] deleteDoctor completed — id=$id');
  }

  // ── Idempotency + parsing helpers ─────────────────────────────────────

  /// Generates a best-effort idempotency key without adding external
  /// dependencies. Uses timestamp + random suffixes (adequate for dedupe of
  /// retries within the same submission).
  static String _generateIdempotencyKey() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'inv-$now-$rand';
  }

  /// Tolerantly parses a response body into a [DoctorInviteResponse].
  ///
  /// - Map body → parsed normally; `outcome` is applied after checking
  ///   [DoctorInviteResponse.alreadyPending] (a "already pending" body on a
  ///   non-2xx is still a success — the invite exists).
  /// - String body → `detail`, with [outcome].
  /// - Empty/non-map body → default `detail`, with [outcome].
  DoctorInviteResponse _parseResponse(
    dynamic data,
    InviteOutcome fallbackOutcome,
  ) {
    final DoctorInviteResponse raw;
    if (data is Map) {
      raw = DoctorInviteResponse.fromJson(data.cast<String, dynamic>());
    } else if (data is String && data.trim().isNotEmpty) {
      raw = DoctorInviteResponse(detail: data.trim());
    } else {
      raw = const DoctorInviteResponse(detail: 'Invite sent.');
    }

    // "Already pending" is always a success outcome (invite exists).
    final InviteOutcome effective = raw.alreadyPending
        ? InviteOutcome.success
        : fallbackOutcome;

    return DoctorInviteResponse(
      detail: raw.detail,
      errors: raw.errors,
      outcome: effective,
      alreadyPending: raw.alreadyPending,
    );
  }

  // ── Logging helpers ────────────────────────────────────────────────────

  /// Masks an email for debug logs (keep local-part partial, keep domain).
  static String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return '***';
    final local = email.substring(0, at);
    final domain = email.substring(at);
    final visible = local.length <= 2
        ? local
        : '${local[0]}***${local[local.length - 1]}';
    return '$visible$domain';
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
