class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Backend field-level validation errors, keyed by snake_case API field
  /// name (e.g. `email`, `password`, `first_name`). Null when the failure
  /// carried no structured field errors (network, 5xx, unexpected shape).
  final Map<String, List<String>>? fieldErrors;

  ApiException(this.message, {this.statusCode, this.fieldErrors});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Unauthorized', statusCode: 401);
}

class NotFoundException extends ApiException {
  NotFoundException() : super('Not found', statusCode: 404);
}

class ServerException extends ApiException {
  ServerException() : super('Internal server error', statusCode: 500);
}

class NetworkException extends ApiException {
  NetworkException() : super('Network error');
}
