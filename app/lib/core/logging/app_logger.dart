import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart' as pkg;

import '../config/app_environment.dart';

/// Abstraction over the logging backend used across the app.
///
/// Features depend on this interface instead of the `logger` package
/// directly, so the backend can later be swapped (e.g. for Sentry or
/// Crashlytics in production) without touching any call site.
abstract class AppLogger {
  void debug(String message);
  void info(String message);
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
}

class ConsoleAppLogger implements AppLogger {
  ConsoleAppLogger({required bool verbose})
      : _logger = pkg.Logger(
          level: verbose ? pkg.Level.debug : pkg.Level.warning,
          printer: pkg.PrettyPrinter(methodCount: 0),
        );

  final pkg.Logger _logger;

  @override
  void debug(String message) => _logger.d(message);

  @override
  void info(String message) => _logger.i(message);

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

final appLoggerProvider = Provider<AppLogger>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  return ConsoleAppLogger(verbose: env.verboseLogging);
});
