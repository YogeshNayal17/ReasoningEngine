/// Centralized route path constants.
///
/// A single source of truth for path strings avoids typos scattering
/// across features as more screens (capture, region select, reasoning
/// results) are added in later milestones.
abstract final class RoutePaths {
  static const String home = '/';
  static const String captureCrop = '/capture-crop';
  static const String ocrResult = '/ocr-result';
}
