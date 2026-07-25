import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Isolates every Android-specific call (permission check, overlay
/// service start/stop) behind a plain Dart interface, so the rest of the
/// app — and tests — never touch a [MethodChannel] directly.
abstract class OverlayBridge {
  Future<bool> hasPermission();
  Future<void> requestPermission();
  Future<bool> start();
  Future<void> stop();
  Future<bool> isRunning();
}

class MethodChannelOverlayBridge implements OverlayBridge {
  MethodChannelOverlayBridge()
      : _channel = const MethodChannel('com.reasonai.reason_ai/overlay');

  final MethodChannel _channel;

  @override
  Future<bool> hasPermission() async {
    return await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
  }

  @override
  Future<void> requestPermission() {
    return _channel.invokeMethod<void>('requestOverlayPermission');
  }

  @override
  Future<bool> start() async {
    return await _channel.invokeMethod<bool>('startOverlay') ?? false;
  }

  @override
  Future<void> stop() {
    return _channel.invokeMethod<void>('stopOverlay');
  }

  @override
  Future<bool> isRunning() async {
    return await _channel.invokeMethod<bool>('isOverlayRunning') ?? false;
  }
}

final overlayBridgeProvider = Provider<OverlayBridge>((ref) {
  return MethodChannelOverlayBridge();
});
