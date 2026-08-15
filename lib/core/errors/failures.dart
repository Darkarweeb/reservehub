/// Base class for all domain-level failures.
/// Extend this to create typed failures per feature.
abstract class Failure {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const Failure({required this.message, this.code, this.stackTrace});

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}

// ─── Network ────────────────────────────────────────────────────────────────

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection.',
    super.code = 'NETWORK_ERROR',
    super.stackTrace,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'The request timed out. Please try again.',
    super.code = 'TIMEOUT',
    super.stackTrace,
  });
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({
    super.message = 'An unexpected server error occurred.',
    super.code = 'SERVER_ERROR',
    this.statusCode,
    super.stackTrace,
  });
}

// ─── Authentication ──────────────────────────────────────────────────────────

class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed.',
    super.code = 'AUTH_ERROR',
    super.stackTrace,
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'You are not authorized to perform this action.',
    super.code = 'UNAUTHORIZED',
    super.stackTrace,
  });
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure({
    super.message = 'Your session has expired. Please sign in again.',
    super.code = 'SESSION_EXPIRED',
    super.stackTrace,
  });
}

// ─── Validation ──────────────────────────────────────────────────────────────

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  const ValidationFailure({
    super.message = 'Validation failed.',
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.stackTrace,
  });
}

// ─── Data ────────────────────────────────────────────────────────────────────

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
    super.code = 'NOT_FOUND',
    super.stackTrace,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to read or write local cache.',
    super.code = 'CACHE_ERROR',
    super.stackTrace,
  });
}

class ParseFailure extends Failure {
  const ParseFailure({
    super.message = 'Failed to parse response data.',
    super.code = 'PARSE_ERROR',
    super.stackTrace,
  });
}

// ─── Business ────────────────────────────────────────────────────────────────

class ConflictFailure extends Failure {
  const ConflictFailure({
    required super.message,
    super.code = 'CONFLICT',
    super.stackTrace,
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'You do not have permission to perform this action.',
    super.code = 'PERMISSION_DENIED',
    super.stackTrace,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred.',
    super.code = 'UNKNOWN',
    super.stackTrace,
  });
}
