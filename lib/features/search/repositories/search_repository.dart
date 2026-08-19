import 'package:admin/core/constants/api_constants.dart';
import 'package:admin/core/network/api_client.dart';
import 'package:admin/core/network/api_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/search_results.dart';

/// Repository for the admin global search feature.
///
/// Handles `GET /api/v1/reports/search/?q=<term>` — the admin-only endpoint
/// that searches across doctors, patients, and appointments in a single call.
///
/// Follows the same conventions as [SosRepository] / [NotificationRepository]:
/// debug logging, [ApiErrorMapper] for structured errors, and no hardcoded
/// URLs (all come from [ApiConstants]).
class SearchRepository {
  final ApiClient _apiClient;

  SearchRepository(this._apiClient);

  /// Minimum number of characters required before the backend will search.
  static const int minQueryLength = 2;

  /// Performs a cross-resource search for [query].
  ///
  /// [query] must be at least [minQueryLength] characters long (the backend
  /// returns a 400 otherwise — the controller enforces this before calling).
  ///
  /// The backend caps each category (doctors / patients / appointments) at 10
  /// results and returns them all in one payload; there is no pagination.
  Future<SearchResults> searchByQuery(String query) async {
    final trimmed = query.trim();
    final Map<String, dynamic> queryParameters = {
      'q': trimmed,
      // Request a generous per-category limit to surface more matches.
      if (_supportsLimit) 'limit': 10,
    };

    debugPrint(
      '[SearchRepo] searchByQuery called — '
      '${ApiConstants.reportsSearch} queryParameters=$queryParameters',
    );

    try {
      final response = await _apiClient.get(
        ApiConstants.reportsSearch,
        queryParameters: queryParameters,
      );
      debugPrint(
        '[SearchRepo] searchByQuery response — status=${response.statusCode}',
      );

      if (response.data is! Map<String, dynamic>) {
        debugPrint(
          '[SearchRepo] searchByQuery — unexpected response shape: '
          '${response.data.runtimeType}',
        );
        throw StateError(
          'Search API returned an unexpected response shape '
          '(expected Map, got ${response.data.runtimeType}).',
        );
      }

      final parsed = SearchResults.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
      debugPrint(
        '[SearchRepo] searchByQuery parsed — $parsed (query="$trimmed")',
      );
      return parsed;
    } on DioException catch (e) {
      debugPrint(
        '[SearchRepo] searchByQuery DioException — type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      debugPrint('[SearchRepo] searchByQuery error body=${e.response?.data}');
      final mapped = ApiErrorMapper.mapDioException(
        e,
        defaultMessage: 'Unable to search at the moment.',
      );
      debugPrint('[SearchRepo] searchByQuery error — $mapped');
      throw mapped;
    }
  }

  /// The backend search endpoint accepts a `limit` query param. We keep this
  /// as a constant switch so it can be flipped off if the deployed backend
  /// rejects the extra param — the search still works without it.
  static const bool _supportsLimit = true;
}
