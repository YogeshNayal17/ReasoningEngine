import 'package:flutter/material.dart';

/// Shared feedback for result-screen actions that don't have real
/// functionality yet (share, save, follow-up question, ...) — an honest
/// "not yet" rather than a silently dead button.
void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Coming soon')),
  );
}
