import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reason_ai/features/capture/data/capture_bridge.dart';
import 'package:reason_ai/features/capture/presentation/controllers/capture_controller.dart';

class FakeCaptureBridge implements CaptureBridge {
  bool hasPermissionValue = false;
  bool requestPermissionResult = true;
  Uint8List? pendingCapture;

  @override
  Future<bool> hasPermission() async => hasPermissionValue;

  @override
  Future<bool> requestPermission() async {
    hasPermissionValue = requestPermissionResult;
    return requestPermissionResult;
  }

  @override
  Future<Uint8List?> consumePendingCapture() async {
    final value = pendingCapture;
    pendingCapture = null;
    return value;
  }
}

void main() {
  late FakeCaptureBridge bridge;
  late ProviderContainer container;

  setUp(() {
    bridge = FakeCaptureBridge();
    container = ProviderContainer(
      overrides: [captureBridgeProvider.overrideWithValue(bridge)],
    );
    addTearDown(container.dispose);
  });

  test('refresh reflects permission and consumes a pending capture', () async {
    bridge.hasPermissionValue = true;
    bridge.pendingCapture = Uint8List.fromList([1, 2, 3]);

    await container.read(captureControllerProvider.notifier).refresh();

    final state = container.read(captureControllerProvider);
    expect(state.hasPermission, isTrue);
    expect(state.lastCapture, equals([1, 2, 3]));
  });

  test('a second refresh with no new capture leaves lastCapture unchanged', () async {
    bridge.pendingCapture = Uint8List.fromList([9]);
    await container.read(captureControllerProvider.notifier).refresh();
    final first = container.read(captureControllerProvider).lastCapture;

    await container.read(captureControllerProvider.notifier).refresh();

    expect(container.read(captureControllerProvider).lastCapture, same(first));
  });

  test('requestPermission updates hasPermission from a granted result', () async {
    bridge.requestPermissionResult = true;

    await container.read(captureControllerProvider.notifier).requestPermission();

    expect(container.read(captureControllerProvider).hasPermission, isTrue);
  });

  test('requestPermission reflects a denied result', () async {
    bridge.requestPermissionResult = false;

    await container.read(captureControllerProvider.notifier).requestPermission();

    expect(container.read(captureControllerProvider).hasPermission, isFalse);
  });

  test('setCroppedImage stores the cropped bytes without touching lastCapture', () async {
    bridge.pendingCapture = Uint8List.fromList([1, 2, 3]);
    await container.read(captureControllerProvider.notifier).refresh();

    container.read(captureControllerProvider.notifier).setCroppedImage(Uint8List.fromList([4, 5]));

    final state = container.read(captureControllerProvider);
    expect(state.croppedImage, equals([4, 5]));
    expect(state.lastCapture, equals([1, 2, 3]));
  });
}
