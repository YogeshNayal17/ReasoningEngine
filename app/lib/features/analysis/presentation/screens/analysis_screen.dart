import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../data/models/analyze_result.dart';
import '../controllers/analysis_controller.dart';
import '../widgets/coming_soon.dart';

enum _AnalysisTab { overview, evidence, questions, context }

IconData _iconForKind(InsightKind kind) => switch (kind) {
      InsightKind.strength => Icons.account_balance,
      InsightKind.question => Icons.help_outline,
      InsightKind.context => Icons.warning_amber_rounded,
    };

/// Second result screen. The "Evidence" tab doesn't show inline content
/// like the other three — it pushes the dedicated `EvidenceScreen`, which
/// has its own search/filter UI in the mockup distinct from a plain tab
/// body — then leaves the tab selection unchanged, so popping back lands
/// on whichever inline tab was showing before.
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  _AnalysisTab _tab = _AnalysisTab.overview;

  void _selectTab(_AnalysisTab tab) {
    if (tab == _AnalysisTab.evidence) {
      context.push(RoutePaths.evidence);
      return;
    }
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(analysisControllerProvider).result;
    final analysis = result?.when(success: (value) => value, failure: (_) => null);

    if (analysis == null) {
      return const Scaffold(body: Center(child: Text('No analysis available.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.expand_more),
            onPressed: () => showComingSoon(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _TabRow(selected: _tab, onSelected: _selectTab),
          Expanded(
            child: switch (_tab) {
              _AnalysisTab.overview => _OverviewTab(analysis: analysis),
              _AnalysisTab.questions => _StringListTab(items: analysis.questions, emptyText: 'No open questions.'),
              _AnalysisTab.context => _StringListTab(items: analysis.context, emptyText: 'No missing context noted.'),
              _AnalysisTab.evidence => const SizedBox.shrink(),
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () => context.push(RoutePaths.summary),
              child: const Text('View summary'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({required this.selected, required this.onSelected});

  final _AnalysisTab selected;
  final ValueChanged<_AnalysisTab> onSelected;

  static const _labels = {
    _AnalysisTab.overview: 'Overview',
    _AnalysisTab.evidence: 'Evidence',
    _AnalysisTab.questions: 'Questions',
    _AnalysisTab.context: 'Context',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final tab in _AnalysisTab.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_labels[tab]!),
                selected: selected == tab,
                onSelected: (_) => onSelected(tab),
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(color: selected == tab ? colorScheme.onPrimary : null),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.analysis});

  final AnalyzeResult analysis;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Key Insights', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final insight in analysis.insights)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Icon(_iconForKind(insight.kind)),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(insight.title)),
                  if (insight.tag != null)
                    Chip(
                      label: Text(insight.tag!, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              subtitle: Text(insight.detail),
            ),
          ),
      ],
    );
  }
}

class _StringListTab extends StatelessWidget {
  const _StringListTab({required this.items, required this.emptyText});

  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(item),
            ),
          ),
      ],
    );
  }
}
