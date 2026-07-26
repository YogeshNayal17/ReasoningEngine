import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/primary_button.dart';
import '../controllers/overlay_controller.dart';

/// Lets the user grant the overlay permission and toggle the floating
/// bubble on/off. Resume-triggered refresh (needed because granting the
/// permission happens in a system Settings screen outside the app) lives
/// on `HomeScreen`, which composes this alongside `CaptureControlPanel` and
/// needs the same resume hook — one observer instead of one per panel.
class OverlayControlPanel extends ConsumerWidget {
  const OverlayControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayState = ref.watch(overlayControllerProvider);
    final controller = ref.read(overlayControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overlayState.hasPermission ? Icons.check_circle : Icons.error_outline,
            size: 48,
            color: overlayState.hasPermission ? Colors.green : colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            overlayState.hasPermission
                ? 'Overlay permission granted'
                : 'Reason AI needs permission to draw over other apps',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!overlayState.hasPermission)
            PrimaryButton(
              label: 'Grant permission',
              onPressed: controller.requestPermission,
            )
          else
            PrimaryButton(
              label: overlayState.isRunning ? 'Stop bubble' : 'Start bubble',
              onPressed: overlayState.isRunning ? controller.stopOverlay : controller.startOverlay,
            ),
        ],
      ),
    );
  }
}
