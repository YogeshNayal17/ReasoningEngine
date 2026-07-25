import '../error/app_failure.dart';

/// Functional-style result type for operations that can fail.
///
/// Repositories and data sources return `Result<T>` instead of throwing,
/// so callers handle failures explicitly (via [when]) instead of
/// try/catch spreading across the UI layer.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = ResultSuccess<T>;

  const factory Result.failure(AppFailure failure) = ResultError<T>;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    final self = this;
    return switch (self) {
      ResultSuccess<T>() => success(self.value),
      ResultError<T>() => failure(self.failure),
    };
  }
}

final class ResultSuccess<T> extends Result<T> {
  const ResultSuccess(this.value);

  final T value;
}

final class ResultError<T> extends Result<T> {
  const ResultError(this.failure);

  final AppFailure failure;
}
