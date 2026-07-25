import 'package:flutter/material.dart';

/// Centered loading spinner for full-screen or section-level async states.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
