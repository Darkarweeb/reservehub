import './failures.dart';

/// A discriminated union representing either a successful [value] or a [Failure].
///
/// Usage:
/// ```dart
/// Result<User> result = await authRepository.signIn(email, password);
/// result.fold(
///   onSuccess: (user) => ...,
///   onFailure: (failure) => ...,
/// );
/// ```
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure_<T>;

  T? get valueOrNull => isSuccess ? (this as Success<T>).value : null;
  Failure? get failureOrNull =>
      isFailure ? (this as Failure_<T>).failure : null;

  /// Transforms the success value; passes failures through unchanged.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(value: final v) => Success(transform(v)),
      Failure_<T>(failure: final f) => Failure_(f),
    };
  }

  /// Chains async operations that also return a [Result].
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    return switch (this) {
      Success<T>(value: final v) => transform(v),
      Failure_<T>(failure: final f) => Failure_(f),
    };
  }

  /// Executes one of two callbacks depending on the outcome.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(value: final v) => onSuccess(v),
      Failure_<T>(failure: final f) => onFailure(f),
    };
  }

  /// Returns the value or throws the failure.
  T getOrThrow() {
    return switch (this) {
      Success<T>(value: final v) => v,
      Failure_<T>(failure: final f) => throw f,
    };
  }

  /// Returns the value or a default.
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T>(value: final v) => v,
      Failure_<T>() => defaultValue,
    };
  }
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

final class Failure_<T> extends Result<T> {
  final Failure failure;
  const Failure_(this.failure);

  @override
  String toString() => 'Failure_(${failure.toString()})';
}

// ─── Convenience constructors ────────────────────────────────────────────────

Result<T> success<T>(T value) => Success(value);
Result<T> failure<T>(Failure f) => Failure_(f);
