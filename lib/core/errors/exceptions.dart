/// Infrastructure-layer exceptions that get mapped to domain [Failure]s
/// inside repository implementations.
library;

class AppException implements Exception {
  final String message;
  final String? code;
  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection.',
    super.code = 'NETWORK_ERROR',
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out.',
    super.code = 'TIMEOUT',
  });
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException({
    super.message = 'Server error.',
    super.code = 'SERVER_ERROR',
    this.statusCode,
  });
}

class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication failed.',
    super.code = 'AUTH_ERROR',
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Unauthorized.',
    super.code = 'UNAUTHORIZED',
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found.',
    super.code = 'NOT_FOUND',
  });
}

class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache operation failed.',
    super.code = 'CACHE_ERROR',
  });
}

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  const ValidationException({
    super.message = 'Validation failed.',
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
  });
}
