import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Isolates the screen-capture platform channel behind a plain Dart
/// interface, mirroring `OverlayBridge`. `requestPermission` is
/// fire-and-forget on the native side (it just opens system Settings, since
/// enabling an AccessibilityService has no in-app consent dialog) — the
/// resume-refresh pattern in `CaptureController` is what actually picks up
/// the grant once the user comes back.
abstract class CaptureBridge {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<Uint8List?> consumePendingCapture();
  Future<bool> consumePendingClipboardRequest();
}

class MethodChannelCaptureBridge implements CaptureBridge {
  MethodChannelCaptureBridge() : _channel = const MethodChannel('com.reasonai.reason_ai/capture');

  final MethodChannel _channel;

  @override
  Future<bool> hasPermission() async {
    return await _channel.invokeMethod<bool>('hasPermission') ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  @override
  Future<Uint8List?> consumePendingCapture() {
    return _channel.invokeMethod<Uint8List>('consumePendingCapture');
  }

  @override
  Future<bool> consumePendingClipboardRequest() async {
    return await _channel.invokeMethod<bool>('consumePendingClipboardRequest') ?? false;
  }
}

final captureBridgeProvider = Provider<CaptureBridge>((ref) {
  return MethodChannelCaptureBridge();
});
