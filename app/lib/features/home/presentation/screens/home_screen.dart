import 'package:flutter/material.dart';

import '../../../overlay/presentation/widgets/overlay_control_panel.dart';

/// App landing screen. Composes feature widgets rather than owning logic
/// itself — right now that's just the overlay controls, so this stays a
/// thin shell as more feature panels are added.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reason AI')),
      body: const Center(
        child: OverlayControlPanel(),
      ),
    );
  }
}
