import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/primary_button.dart';
import '../controllers/capture_controller.dart';

/// Lets the user grant the screen-capture (MediaProjection) permission.
/// There's no start/stop toggle here, unlike the overlay panel — capture
/// itself is one-shot and triggered by tapping the bubble, not from this
/// screen.
class CaptureControlPanel extends ConsumerWidget {
  const CaptureControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(captureControllerProvider);
    final controller = ref.read(captureControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            captureState.hasPermission ? Icons.check_circle : Icons.error_outline,
            size: 48,
            color: captureState.hasPermission ? Colors.green : colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            captureState.hasPermission
                ? 'Screen capture permission granted'
                : 'Reason AI needs the accessibility permission to capture your screen',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!captureState.hasPermission)
            PrimaryButton(
              label: 'Enable in Settings',
              onPressed: controller.requestPermission,
            )
          else
            const Text('Tap the bubble, then choose to select on-screen text or paste text to analyze.'),
        ],
      ),
    );
  }
}
