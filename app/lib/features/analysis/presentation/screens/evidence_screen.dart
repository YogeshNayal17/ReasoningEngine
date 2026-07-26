import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../data/models/analyze_result.dart';
import '../controllers/analysis_controller.dart';
import '../widgets/coming_soon.dart';

enum _EvidenceFilter { all, forStance, against, neutral }

const _sectionOrder = ['for', 'against', 'neutral'];
const _sectionTitles = {'for': 'Evidence For', 'against': 'Evidence Against', 'neutral': 'Neutral / Mixed'};
const _sectionColors = {'for': Colors.green, 'against': Colors.red, 'neutral': Colors.orange};

/// Third result screen — reached only by tapping the "Evidence" tab on
/// `AnalysisScreen`. Gets its own search icon and All/For/Against/Neutral
/// filter chips in the mockup, distinct enough from the other inline tabs
/// (Overview/Questions/Context) to warrant a dedicated pushed screen
/// rather than another case in that screen's tab switch.
class EvidenceScreen extends ConsumerStatefulWidget {
  const EvidenceScreen({super.key});

  @override
  ConsumerState<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends ConsumerState<EvidenceScreen> {
  _EvidenceFilter _filter = _EvidenceFilter.all;

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(analysisControllerProvider).result;
    final analysis = result?.when(success: (value) => value, failure: (_) => null);

    if (analysis == null) {
      return const Scaffold(body: Center(child: Text('No analysis available.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => showComingSoon(context)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (final filter in _EvidenceFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabel(filter)),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _EvidenceList(evidence: analysis.evidence, filter: _filter)),
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

  String _filterLabel(_EvidenceFilter filter) => switch (filter) {
        _EvidenceFilter.all => 'All',
        _EvidenceFilter.forStance => 'For',
        _EvidenceFilter.against => 'Against',
        _EvidenceFilter.neutral => 'Neutral',
      };
}

class _EvidenceList extends StatelessWidget {
  const _EvidenceList({required this.evidence, required this.filter});

  final List<EvidenceItem> evidence;
  final _EvidenceFilter filter;

  @override
  Widget build(BuildContext context) {
    final stanceFilter = switch (filter) {
      _EvidenceFilter.all => null,
      _EvidenceFilter.forStance => 'for',
      _EvidenceFilter.against => 'against',
      _EvidenceFilter.neutral => 'neutral',
    };

    if (stanceFilter != null) {
      final items = evidence.where((item) => item.stance == stanceFilter).toList();
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [for (final item in items) _EvidenceTile(item: item)],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final stance in _sectionOrder)
          if (evidence.any((item) => item.stance == stance)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(
                _sectionTitles[stance]!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _sectionColors[stance]),
              ),
            ),
            for (final item in evidence.where((item) => item.stance == stance)) _EvidenceTile(item: item),
          ],
      ],
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.item});

  final EvidenceItem item;

  @override
  Widget build(BuildContext context) {
    final color = _sectionColors[item.stance] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        title: Text(item.text),
        subtitle: Text('Source: ${item.source}'),
      ),
    );
  }
}
