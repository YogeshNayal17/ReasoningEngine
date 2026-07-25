import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reason_ai/features/overlay/data/overlay_bridge.dart';
import 'package:reason_ai/features/overlay/presentation/controllers/overlay_controller.dart';

class FakeOverlayBridge implements OverlayBridge {
  bool hasPermissionValue = false;
  bool isRunningValue = false;
  bool startResult = true;
  int requestPermissionCalls = 0;

  @override
  Future<bool> hasPermission() async => hasPermissionValue;

  @override
  Future<void> requestPermission() async {
    requestPermissionCalls++;
  }

  @override
  Future<bool> start() async {
    if (startResult) {
      isRunningValue = true;
    }
    return startResult;
  }

  @override
  Future<void> stop() async {
    isRunningValue = false;
  }

  @override
  Future<bool> isRunning() async => isRunningValue;
}

void main() {
  late FakeOverlayBridge bridge;
  late ProviderContainer container;

  setUp(() {
    bridge = FakeOverlayBridge();
    container = ProviderContainer(
      overrides: [overlayBridgeProvider.overrideWithValue(bridge)],
    );
    addTearDown(container.dispose);
  });

  test('refresh reflects the bridge permission and running state', () async {
    bridge.hasPermissionValue = true;
    bridge.isRunningValue = true;

    await container.read(overlayControllerProvider.notifier).refresh();

    final state = container.read(overlayControllerProvider);
    expect(state.hasPermission, isTrue);
    expect(state.isRunning, isTrue);
  });

  test('startOverlay sets isRunning when the bridge reports success', () async {
    bridge.startResult = true;

    await container.read(overlayControllerProvider.notifier).startOverlay();

    expect(container.read(overlayControllerProvider).isRunning, isTrue);
  });

  test('startOverlay leaves isRunning false when the bridge reports failure', () async {
    bridge.startResult = false;

    await container.read(overlayControllerProvider.notifier).startOverlay();

    expect(container.read(overlayControllerProvider).isRunning, isFalse);
  });

  test('stopOverlay sets isRunning to false', () async {
    bridge
      ..hasPermissionValue = true
      ..isRunningValue = true;
    await container.read(overlayControllerProvider.notifier).refresh();

    await container.read(overlayControllerProvider.notifier).stopOverlay();

    expect(container.read(overlayControllerProvider).isRunning, isFalse);
  });

  test('requestPermission delegates to the bridge', () async {
    await container.read(overlayControllerProvider.notifier).requestPermission();

    expect(bridge.requestPermissionCalls, 1);
  });
}
