import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reason_ai/features/capture/data/capture_bridge.dart';
import 'package:reason_ai/features/capture/presentation/controllers/capture_controller.dart';

class FakeCaptureBridge implements CaptureBridge {
  bool hasPermissionValue = false;
  bool requestPermissionResult = true;
  Uint8List? pendingCapture;
  bool pendingClipboardRequest = false;

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

  @override
  Future<bool> consumePendingClipboardRequest() async {
    final value = pendingClipboardRequest;
    pendingClipboardRequest = false;
    return value;
  }
}

void main() {
  late FakeCaptureBridge bridge;
  late ProviderContainer container;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    bridge = FakeCaptureBridge();
    container = ProviderContainer(
      overrides: [captureBridgeProvider.overrideWithValue(bridge)],
    );
    addTearDown(container.dispose);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  test('refresh reflects permission and consumes a pending capture', () async {
    bridge.hasPermissionValue = true;
    bridge.pendingCapture = Uint8List.fromList([1, 2, 3]);

    await container.read(captureControllerProvider.notifier).refresh();

    final state = container.read(captureControllerProvider);
    expect(state.hasPermission, isTrue);
    expect(state.capturedImage, equals([1, 2, 3]));
  });

  test('a second refresh with no new capture leaves capturedImage unchanged', () async {
    bridge.pendingCapture = Uint8List.fromList([9]);
    await container.read(captureControllerProvider.notifier).refresh();
    final first = container.read(captureControllerProvider).capturedImage;

    await container.read(captureControllerProvider.notifier).refresh();

    expect(container.read(captureControllerProvider).capturedImage, same(first));
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

  test('a pending clipboard request reads the clipboard into pastedText', () async {
    // Settle the notifier's own build-time refresh() first. It races this
    // test's explicit refresh() below, and unlike the other steps (which
    // resolve in one microtask), the clipboard step awaits a real platform
    // channel round trip — long enough for the two calls to fall out of
    // the lockstep that otherwise makes the race harmless.
    await container.read(captureControllerProvider.notifier).refresh();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': 'hello from clipboard'};
        }
        return null;
      },
    );
    bridge.pendingClipboardRequest = true;

    await container.read(captureControllerProvider.notifier).refresh();

    expect(container.read(captureControllerProvider).pastedText, equals('hello from clipboard'));
  });

  test('no pending clipboard request leaves pastedText null', () async {
    bridge.pendingClipboardRequest = false;

    await container.read(captureControllerProvider.notifier).refresh();

    expect(container.read(captureControllerProvider).pastedText, isNull);
  });
}
