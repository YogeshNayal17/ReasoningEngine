import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Isolates the screen-capture platform channel behind a plain Dart
/// interface, mirroring `OverlayBridge`. `requestPermission` returns the
/// grant result directly (unlike the overlay's fire-and-forget request)
/// because the native side awaits the system consent dialog before
/// resolving the platform channel call — no resume-polling needed for it.
abstract class CaptureBridge {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<Uint8List?> consumePendingCapture();
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
}

final captureBridgeProvider = Provider<CaptureBridge>((ref) {
  return MethodChannelCaptureBridge();
});
