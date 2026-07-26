/// Centralized route path constants.
///
/// A single source of truth for path strings avoids typos scattering
/// across features as more screens (capture, region select, reasoning
/// results) are added in later milestones.
abstract final class RoutePaths {
  static const String home = '/';
  static const String savedAnalyses = '/saved-analyses';
  static const String analyzing = '/analyzing';
  static const String coreClaim = '/core-claim';
  static const String analysis = '/analysis';
  static const String evidence = '/evidence';
  static const String summary = '/summary';
}
