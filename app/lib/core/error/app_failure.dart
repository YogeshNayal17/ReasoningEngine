/// Base type for recoverable, user-facing failures.
///
/// Extend this per-feature as new failure cases emerge (e.g. an
/// `OcrFailure` once the OCR feature lands) rather than growing this file
/// into a catch-all.
sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Could not reach the server.']);
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}
