import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/primary_button.dart';
import '../controllers/overlay_controller.dart';

/// Lets the user grant the overlay permission and toggle the floating
/// bubble on/off. Observes app lifecycle because granting the permission
/// happens in a system Settings screen outside the app — the only way to
/// learn the result is to re-check when the user comes back.
class OverlayControlPanel extends ConsumerStatefulWidget {
  const OverlayControlPanel({super.key});

  @override
  ConsumerState<OverlayControlPanel> createState() => _OverlayControlPanelState();
}

class _OverlayControlPanelState extends ConsumerState<OverlayControlPanel> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(overlayControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
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
