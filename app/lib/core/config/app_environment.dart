import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable, strongly-typed snapshot of build-time configuration.
///
/// Values come from `--dart-define-from-file=env/<name>.json` rather than
/// a bundled `.env` asset — see `env/README.md` for why, and for how to
/// add a new value.
class AppEnvironment {
  const AppEnvironment({
    required this.name,
    required this.apiBaseUrl,
    required this.verboseLogging,
  });

  factory AppEnvironment.fromDartDefines() => const AppEnvironment(
        name: String.fromEnvironment('ENV_NAME', defaultValue: 'dev'),
        apiBaseUrl: String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:8000',
        ),
        verboseLogging: bool.fromEnvironment(
          'ENABLE_VERBOSE_LOGGING',
          defaultValue: true,
        ),
      );

  final String name;
  final String apiBaseUrl;
  final bool verboseLogging;

  bool get isProduction => name == 'prod';
}

/// Exposes [AppEnvironment] through Riverpod instead of letting features
/// read `String.fromEnvironment` directly, so tests can override it with
/// `ProviderScope(overrides: [appEnvironmentProvider.overrideWithValue(...)])`.
final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  return AppEnvironment.fromDartDefines();
});
