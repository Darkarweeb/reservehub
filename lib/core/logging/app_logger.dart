import 'package:flutter/foundation.dart';

/// Centralized logging foundation for ReserveHub.
///
/// In production, replace the [_delegate] with a real logging backend
/// (e.g., Sentry, Datadog, Firebase Crashlytics) without changing call sites.
abstract class AppLogger {
  static _LogDelegate _delegate = _DefaultLogDelegate();

  /// Replace the delegate to swap logging backends (e.g., in tests or prod).
  static void setDelegate(_LogDelegate delegate) {
    _delegate = delegate;
  }

  static void debug(String message, {String? tag, Object? extra}) {
    _delegate.debug(message, tag: tag, extra: extra);
  }

  static void info(String message, {String? tag, Object? extra}) {
    _delegate.info(message, tag: tag, extra: extra);
  }

  static void warning(String message, {String? tag, Object? extra}) {
    _delegate.warning(message, tag: tag, extra: extra);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _delegate.error(message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _delegate.fatal(message, tag: tag, error: error, stackTrace: stackTrace);
  }
}

// ─── Delegate interface ───────────────────────────────────────────────────────

abstract class _LogDelegate {
  void debug(String message, {String? tag, Object? extra});
  void info(String message, {String? tag, Object? extra});
  void warning(String message, {String? tag, Object? extra});
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  });
  void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  });
}

// ─── Default (debug-only console) delegate ───────────────────────────────────

class _DefaultLogDelegate extends _LogDelegate {
  static const _reset = '\\x1B[0m';
  static const _grey = '\\x1B[90m';
  static const _cyan = '\\x1B[36m';
  static const _yellow = '\\x1B[33m';
  static const _red = '\\x1B[31m';
  static const _magenta = '\\x1B[35m';

  @override
  void debug(String message, {String? tag, Object? extra}) {
    if (kDebugMode) _print('$_grey[DEBUG]$_reset', tag, message, extra: extra);
  }

  @override
  void info(String message, {String? tag, Object? extra}) {
    if (kDebugMode) _print('$_cyan[INFO] $_reset', tag, message, extra: extra);
  }

  @override
  void warning(String message, {String? tag, Object? extra}) {
    if (kDebugMode) {
      _print('$_yellow[WARN] $_reset', tag, message, extra: extra);
    }
  }

  @override
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      _print('$_red[ERROR]$_reset', tag, message, error: error);
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
  }

  @override
  void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      _print('$_magenta[FATAL]$_reset', tag, message, error: error);
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
  }

  void _print(
    String level,
    String? tag,
    String message, {
    Object? extra,
    Object? error,
  }) {
    final tagStr = tag != null ? '[$tag] ' : '';
    final extraStr = extra != null ? ' | $extra' : '';
    final errorStr = error != null ? ' | ERROR: $error' : '';
    debugPrint('$level $tagStr$message$extraStr$errorStr');
  }
}
