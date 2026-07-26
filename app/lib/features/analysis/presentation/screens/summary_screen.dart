import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../controllers/analysis_controller.dart';
import '../widgets/coming_soon.dart';

/// Final result screen. "Ask a follow-up question" / "Save this analysis" /
/// "Share" have no backing feature yet — they show a "Coming soon" snackbar
/// rather than doing nothing silently. "New selection" is the one action
/// that's real today: it just returns to Home, ready for another capture.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(analysisControllerProvider).result;
    final analysis = result?.when(success: (value) => value, failure: (_) => null);
    final colorScheme = Theme.of(context).colorScheme;

    if (analysis == null) {
      return const Scaffold(body: Center(child: Text('No analysis available.')));
    }

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: const Icon(Icons.check),
                ),
                const SizedBox(width: 12),
                Text('Summary', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text(analysis.summary, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            Text('What would you like to do?', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => showComingSoon(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Ask a follow-up question'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => showComingSoon(context),
              icon: const Icon(Icons.bookmark_border),
              label: const Text('Save this analysis'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => showComingSoon(context),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go(RoutePaths.home),
              icon: const Icon(Icons.crop_free),
              label: const Text('New selection'),
            ),
          ],
        ),
      ),
    );
  }
}
