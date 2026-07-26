import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/analysis_controller.dart';

/// Minimal display of the `/analyze` response — not the full multi-tab
/// Core Claim / Analysis / Evidence / Summary experience from the product
/// mockup, which is a separate, larger UI task. This exists so a completed
/// analysis (currently always mocked) has somewhere to land, proving the
/// round trip to the backend actually works.
class AnalysisResultScreen extends ConsumerWidget {
  const AnalysisResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(analysisControllerProvider).result;
    final analysis = result?.when(success: (value) => value, failure: (_) => null);

    if (analysis == null) {
      return const Scaffold(body: Center(child: Text('No analysis available.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Core claim', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(analysis.claim, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          Text('Key insights', style: Theme.of(context).textTheme.labelLarge),
          for (final insight in analysis.insights)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(title: Text(insight.title), subtitle: Text(insight.detail)),
            ),
          const SizedBox(height: 24),
          Text('Evidence', style: Theme.of(context).textTheme.labelLarge),
          for (final item in analysis.evidence)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                leading: Icon(switch (item.stance) {
                  'for' => Icons.thumb_up,
                  'against' => Icons.thumb_down,
                  _ => Icons.remove,
                }),
                title: Text(item.text),
                subtitle: Text(item.source),
              ),
            ),
          const SizedBox(height: 24),
          Text('Summary', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(analysis.summary),
        ],
      ),
    );
  }
}
