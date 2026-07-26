import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../data/capture_bridge.dart';

class CaptureState {
  const CaptureState({required this.hasPermission, this.lastCapture, this.croppedImage});

  const CaptureState.initial() : hasPermission = false, lastCapture = null, croppedImage = null;

  final bool hasPermission;
  final Uint8List? lastCapture;

  /// The user-selected crop of [lastCapture] (Milestone 4), fed to OCR.
  final Uint8List? croppedImage;

  CaptureState copyWith({bool? hasPermission, Uint8List? lastCapture, Uint8List? croppedImage}) {
    return CaptureState(
      hasPermission: hasPermission ?? this.hasPermission,
      lastCapture: lastCapture ?? this.lastCapture,
      croppedImage: croppedImage ?? this.croppedImage,
    );
  }
}

/// Mirrors `OverlayController`'s shape. `refresh` both re-checks permission
/// and pulls any capture the native side produced while this app wasn't in
/// the foreground — the bubble tap that triggers a capture happens in a
/// Service with no direct line to a running Dart isolate, so the captured
/// bytes wait in native memory (`PendingCaptureStore`) until this resumes.
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

  void setCroppedImage(Uint8List bytes) {
    state = state.copyWith(croppedImage: bytes);
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
        state = state.copyWith(lastCapture: bytes);
      }
    } catch (error, stackTrace) {
      _logger.error('Failed to check pending capture', error: error, stackTrace: stackTrace);
    }
  }
}

final captureControllerProvider = NotifierProvider<CaptureController, CaptureState>(
  CaptureController.new,
);
