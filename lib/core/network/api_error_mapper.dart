import 'package:dio/dio.dart';

import 'api_exceptions.dart';

/// Shared helper that converts a [DioException] into an [ApiException].
///
/// Extracts DRF-style structured field errors (`{"detail": ..., "errors":
/// {"field": ["msg", ...]}}`) into the [ApiException.fieldErrors] map so
/// screens/controllers can surface backend validation messages inline.
class ApiErrorMapper {
  ApiErrorMapper._();

  static ApiException mapDioException(
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

    if (statusCode == 401) return UnauthorizedException();
    if (statusCode == 404) return NotFoundException();
    if (statusCode != null && statusCode >= 500) return ServerException();

    return ApiException(
      serverMessage ?? defaultMessage,
      statusCode: statusCode,
      fieldErrors: fieldErrors,
    );
  }

  static String? _extractServerMessage(dynamic data) {
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

  static Map<String, List<String>>? _extractFieldErrors(dynamic data) {
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
}
