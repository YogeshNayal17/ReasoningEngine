import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../data/capture_bridge.dart';

class CaptureState {
  const CaptureState({required this.hasPermission, this.capturedImage, this.pastedText});

  const CaptureState.initial() : hasPermission = false, capturedImage = null, pastedText = null;

  final bool hasPermission;

  /// The user's selected region, already cropped natively by the overlay's
  /// selection UI — ready to hand straight to OCR.
  final Uint8List? capturedImage;

  /// Text read from the system clipboard when the user picks "from
  /// clipboard/text" in the bubble menu instead of selecting a region —
  /// an alternate path to the same result screen that skips OCR entirely.
  final String? pastedText;

  CaptureState copyWith({bool? hasPermission, Uint8List? capturedImage, String? pastedText}) {
    return CaptureState(
      hasPermission: hasPermission ?? this.hasPermission,
      capturedImage: capturedImage ?? this.capturedImage,
      pastedText: pastedText ?? this.pastedText,
    );
  }
}

/// Mirrors `OverlayController`'s shape. `refresh` re-checks permission and
/// pulls anything the native side produced while this app wasn't in the
/// foreground: a cropped capture, or a request to read the clipboard. Both
/// originate from a Service with no direct line to a running Dart isolate,
/// so they wait (in `PendingCaptureStore`/`PendingClipboardRequestStore`)
/// until this resumes.
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
    await _checkPendingClipboardRequest();
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

  Future<void> _checkPendingClipboardRequest() async {
    try {
      final requested = await _bridge.consumePendingClipboardRequest();
      if (!requested) return;
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      state = state.copyWith(pastedText: data?.text ?? '');
    } catch (error, stackTrace) {
      _logger.error('Failed to read clipboard text', error: error, stackTrace: stackTrace);
    }
  }
}

final captureControllerProvider = NotifierProvider<CaptureController, CaptureState>(
  CaptureController.new,
);
