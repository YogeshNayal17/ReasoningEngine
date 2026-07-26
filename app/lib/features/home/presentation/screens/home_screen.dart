import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../capture/presentation/controllers/capture_controller.dart';
import '../../../capture/presentation/widgets/capture_control_panel.dart';
import '../../../overlay/presentation/controllers/overlay_controller.dart';
import '../../../overlay/presentation/widgets/overlay_control_panel.dart';

/// App landing screen. Composes feature widgets rather than owning their
/// logic itself, but does own two cross-feature concerns that don't belong
/// to either panel individually:
/// - re-checking overlay/capture permission on every app resume (both
///   permissions are granted outside the app, in a system UI), and
/// - navigating to the Analyzing screen when a new (already-cropped)
///   capture or a new pasted text arrives — selection itself happens
///   natively, before the app opens.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
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
      ref.read(captureControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CaptureState>(captureControllerProvider, (previous, next) {
      final hasNewCapture = next.capturedImage != null && next.capturedImage != previous?.capturedImage;
      final hasNewPastedText = next.pastedText != null && next.pastedText != previous?.pastedText;
      if (hasNewCapture || hasNewPastedText) {
        context.push(RoutePaths.analyzing);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reason AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Past analyses',
            onPressed: () => context.push(RoutePaths.savedAnalyses),
          ),
        ],
      ),
      body: const Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OverlayControlPanel(),
              Divider(height: 32),
              CaptureControlPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
