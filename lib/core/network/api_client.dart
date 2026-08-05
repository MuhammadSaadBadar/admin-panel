import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({required String baseUrl, List<Interceptor>? interceptors}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (interceptors != null) {
      _dio.interceptors.addAll(interceptors);
    }
  }

  /// The underlying [Dio] instance. Exposed so the [AuthInterceptor] can
  /// replay queued requests (with a fresh token) after a successful refresh.
  Dio get dio => _dio;

  /// Attaches the [AuthInterceptor] to Dio so it can retry the original
  /// request through the same interceptor chain after a token refresh.
  void attachInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    debugPrint('BASE URL : ${_dio.options.baseUrl}');
    debugPrint('FULL URL : ${_dio.options.baseUrl}$path');
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) async {
    debugPrint('BASE URL : ${_dio.options.baseUrl}');
    debugPrint('FULL URL : ${_dio.options.baseUrl}$path');
    return await _dio.post(
      path,
      data: data,
      options: Options(
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}
