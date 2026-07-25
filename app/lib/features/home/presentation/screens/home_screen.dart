import 'package:flutter/material.dart';

/// Temporary placeholder screen.
///
/// Proves the app boots with theming, routing, and DI wired up end to end.
/// Replaced by the real capture/reasoning flow in later milestones.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reason AI')),
      body: const Center(
        child: Text('Reason AI'),
      ),
    );
  }
}
