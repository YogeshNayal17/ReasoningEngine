import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../controllers/analysis_controller.dart';
import '../controllers/saved_analyses_controller.dart';

/// Lists past saved analyses. Tapping one feeds it into
/// `AnalysisController` (the same slot a live `/analyze` result would
/// occupy) and pushes the same Core Claim → Analysis → Evidence → Summary
/// flow used for a fresh analysis — those screens only ever read from that
/// provider, so nothing about them needs to know whether the result is
/// live or replayed from disk.
class SavedAnalysesScreen extends ConsumerWidget {
  const SavedAnalysesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedAnalysesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Past analyses')),
      body: switch ((state.isLoading, state.items.isEmpty)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (false, true) => const Center(child: Text('No saved analyses yet.')),
        (false, false) => ListView.separated(
            itemCount: state.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final saved = state.items[index];
              return ListTile(
                title: Text(saved.analysis.claim, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(_formatDate(saved.savedAt)),
                onTap: () {
                  ref.read(analysisControllerProvider.notifier).viewSaved(saved.analysis);
                  context.push(RoutePaths.coreClaim);
                },
              );
            },
          ),
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.year}-${pad(dateTime.month)}-${pad(dateTime.day)} '
        '${pad(dateTime.hour)}:${pad(dateTime.minute)}';
  }
}
