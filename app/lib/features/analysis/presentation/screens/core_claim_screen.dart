import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../controllers/analysis_controller.dart';
import '../widgets/coming_soon.dart';

/// First of four result screens (Core Claim → Analysis → Evidence →
/// Summary), matching the product mockup. Reads the completed analysis
/// straight from `analysisControllerProvider` rather than route
/// arguments — `AnalyzingScreen` only navigates here once that provider
/// already holds a successful result.
class CoreClaimScreen extends ConsumerWidget {
  const CoreClaimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(analysisControllerProvider).result;
    final analysis = result?.when(success: (value) => value, failure: (_) => null);
    final colorScheme = Theme.of(context).colorScheme;

    if (analysis == null) {
      return const Scaffold(body: Center(child: Text('No analysis available.')));
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showComingSoon(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Core Claim', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('"${analysis.claim}"', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 20),
            Text('What this means', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(analysis.whatThisMeans, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => context.push(RoutePaths.analysis),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('See full analysis'),
            ),
          ],
        ),
      ),
    );
  }
}
