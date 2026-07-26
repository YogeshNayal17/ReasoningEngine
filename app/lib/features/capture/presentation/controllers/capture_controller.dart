import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../data/capture_bridge.dart';

class CaptureState {
  const CaptureState({required this.hasPermission, this.capturedImage});

  const CaptureState.initial() : hasPermission = false, capturedImage = null;

  final bool hasPermission;

  /// The user's selected region, already cropped natively by the overlay's
  /// selection UI — ready to hand straight to OCR.
  final Uint8List? capturedImage;

  CaptureState copyWith({bool? hasPermission, Uint8List? capturedImage}) {
    return CaptureState(
      hasPermission: hasPermission ?? this.hasPermission,
      capturedImage: capturedImage ?? this.capturedImage,
    );
  }
}

/// Mirrors `OverlayController`'s shape. `refresh` both re-checks permission
/// and pulls any capture the native side produced while this app wasn't in
/// the foreground — the bubble tap (and the selection overlay that follows
/// it) happens in a Service with no direct line to a running Dart isolate,
/// so the cropped bytes wait in native memory (`PendingCaptureStore`) until
/// this resumes.
class CaptureController extends Notifier<CaptureState> {
  late final CaptureBridge _bridge;
  late final AppLogger _logger;

  @override
  CaptureState build() {
    _bridge = ref.watch(captureBridgeProvider);
    _logger = ref.watch(appLoggerProvider);
    unawaited(refresh());
    return const CaptureState.initial();
  }

  Future<void> refresh() async {
    await _refreshPermission();
    await _checkPendingCapture();
  }

  Future<void> requestPermission() async {
    try {
      final granted = await _bridge.requestPermission();
      state = state.copyWith(hasPermission: granted);
    } catch (error, stackTrace) {
      _logger.error('Failed to request capture permission', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _refreshPermission() async {
    try {
      final hasPermission = await _bridge.hasPermission();
      state = state.copyWith(hasPermission: hasPermission);
    } catch (error, stackTrace) {
      _logger.error('Failed to refresh capture permission', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _checkPendingCapture() async {
    try {
      final bytes = await _bridge.consumePendingCapture();
      if (bytes != null) {
        state = state.copyWith(capturedImage: bytes);
      }
    } catch (error, stackTrace) {
      _logger.error('Failed to check pending capture', error: error, stackTrace: stackTrace);
    }
  }
}

final captureControllerProvider = NotifierProvider<CaptureController, CaptureState>(
  CaptureController.new,
);
