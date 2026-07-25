import 'package:flutter/material.dart';

/// Standard call-to-action button used across features.
///
/// Wraps [FilledButton] with a built-in loading state so async actions
/// (capturing a region, calling the reasoning API, ...) don't each
/// reimplement a spinner-vs-label swap.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
