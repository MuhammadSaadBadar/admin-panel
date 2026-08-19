import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/network/api_exceptions.dart';
import '../models/search_results.dart';
import '../repositories/search_repository.dart';

/// Controller for the admin global search.
///
/// Responsibilities:
/// - Debounce keystrokes before hitting the network (avoids a request per key).
/// - Enforce a minimum query length ([SearchRepository.minQueryLength]) so no
///   request is made for trivial input.
/// - Guard against out-of-order responses via a request sequence counter.
/// - Cache recent queries in memory so re-typing a query is instant.
/// - Expose reactive loading / results / error state for the overlay UI.
class SearchController extends GetxController {
  final SearchRepository _repository;

  SearchController(this._repository);

  // ── Tunables ────────────────────────────────────────────────────────────
  /// Delay after the last keystroke before a request fires.
  static const Duration debounceDuration = Duration(milliseconds: 450);

  /// How many recent queries to keep in the in-memory cache.
  static const int maxCacheEntries = 5;

  // ── State ───────────────────────────────────────────────────────────────
  final Rxn<SearchResults> results = Rxn<SearchResults>();
  final RxBool isSearching = false.obs;
  final RxnString error = RxnString();
  final RxString query = ''.obs;

  /// True once the user has typed at least one search term (used to decide
  /// between the idle hint and the empty state).
  final RxBool hasSearched = false.obs;

  // ── Private ─────────────────────────────────────────────────────────────
  Timer? _debounceTimer;
  CancelToken? _cancelToken;
  int _requestSequence = 0;
  final Map<String, SearchResults> _cache = {};

  /// Current query (trimmed) — used by the UI and tests.
  String get currentQuery => query.value.trim();

  /// Whether the current query is long enough to search.
  bool get isValidQuery =>
      currentQuery.length >= SearchRepository.minQueryLength;

  /// Public entry point called from the search field's `onChanged`.
  ///
  /// Debounces rapid typing, updates [query], and schedules a network call
  /// only when the query is valid. Clears results when the query is too short.
  void onQueryChanged(String value) {
    query.value = value.trim();
    error.value = null;
    _debounceTimer?.cancel();

    if (!isValidQuery) {
      // Not enough characters — cancel any in-flight request and clear state.
      _cancelInFlight();
      hasSearched.value = false;
      results.value = null;
      debugPrint(
        '[SearchController] query below min length — cleared results.',
      );
      return;
    }

    hasSearched.value = true;

    // No-op guard: if we already have results for this exact query (and no
    // error), don't re-fetch.
    final cached = _cache[currentQuery];
    if (cached != null) {
      results.value = cached;
      debugPrint(
        '[SearchController] serving cached results for "$currentQuery".',
      );
      return;
    }

    _debounceTimer = Timer(debounceDuration, () => _search());
  }

  /// Runs the actual network search.
  Future<void> _search() async {
    final term = currentQuery;
    if (term.length < SearchRepository.minQueryLength) {
      debugPrint('[SearchController] _search — query too short, skipping.');
      return;
    }

    // Cancel the previous in-flight request (if any).
    _cancelInFlight();

    // Bump the sequence so stale responses are discarded.
    final sequence = ++_requestSequence;
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    isSearching.value = true;
    error.value = null;
    debugPrint('[SearchController] _search — fetching results for "$term".');

    try {
      final data = await _repository.searchByQuery(term);
      debugPrint('[SearchController] _search — response received for "$term".');
      if (sequence != _requestSequence) {
        debugPrint(
          '[SearchController] _search — discarding stale response '
          '(sequence $sequence != $_requestSequence).',
        );
        return;
      }
      _cache[term] = data;
      if (_cache.length > maxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
      results.value = data;
      debugPrint('[SearchController] _search — results set: $data');
    } on DioException {
      // CancelToken throws DioException.cancel — treat as a non-error.
      debugPrint('[SearchController] _search — request cancelled.');
    } catch (e, stackTrace) {
      debugPrint('[SearchController] _search — ERROR: $e');
      debugPrint('[SearchController] _search — stackTrace: $stackTrace');
      if (sequence != _requestSequence) {
        debugPrint('[SearchController] _search — stale error ignored.');
        return;
      }
      error.value = _friendlyError(e);
      debugPrint('[SearchController] _search — error surfaced: $e');
    } finally {
      if (sequence == _requestSequence) {
        isSearching.value = false;
      }
    }
  }

  /// Cancels any in-flight request.
  void _cancelInFlight() {
    final token = _cancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('New search started');
      debugPrint('[SearchController] previous request cancelled.');
    }
    _cancelToken = null;
  }

  /// Clears the search state and resets the field.
  void clear() {
    _debounceTimer?.cancel();
    _cancelInFlight();
    _requestSequence++;
    query.value = '';
    results.value = null;
    error.value = null;
    hasSearched.value = false;
    debugPrint('[SearchController] search cleared.');
  }

  /// Maps raw exceptions to a user-friendly message.
  String _friendlyError(Object e) {
    if (e is UnauthorizedException) {
      return 'Your session has expired. Please log in again.';
    }
    if (e is NetworkException) {
      return 'No internet connection. Please check your network and retry.';
    }
    if (e is ServerException) {
      return 'The server is busy or starting up. Please try again.';
    }
    if (e is ApiException) {
      return e.message;
    }
    return 'Unable to search at the moment. Please try again.';
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _cancelInFlight();
    super.onClose();
  }
}
