import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../data/models/analyze_result.dart';
import '../../data/models/saved_analysis.dart';
import '../controllers/analysis_controller.dart';
import '../controllers/saved_analyses_controller.dart';

enum _FilterTab { all, misleading, verified, mixed }

extension _FilterTabLabel on _FilterTab {
  String get label => switch (this) {
        _FilterTab.all => 'All',
        _FilterTab.misleading => 'Misleading',
        _FilterTab.verified => 'Verified',
        _FilterTab.mixed => 'Mixed',
      };
}

class SavedAnalysesScreen extends ConsumerStatefulWidget {
  const SavedAnalysesScreen({super.key});

  @override
  ConsumerState<SavedAnalysesScreen> createState() => _SavedAnalysesScreenState();
}

class _SavedAnalysesScreenState extends ConsumerState<SavedAnalysesScreen> {
  _FilterTab _activeFilter = _FilterTab.all;

  String _deriveVerdict(AnalyzeResult analysis) {
    final forCount = analysis.evidence.where((e) => e.stance == 'for').length;
    final against = analysis.evidence.where((e) => e.stance == 'against').length;
    if (forCount > against) return 'verified';
    if (against > forCount) return 'misleading';
    return 'mixed';
  }

  List<SavedAnalysis> _filtered(List<SavedAnalysis> items) => switch (_activeFilter) {
        _FilterTab.all => items,
        _FilterTab.misleading => items.where((s) => _deriveVerdict(s.analysis) == 'misleading').toList(),
        _FilterTab.verified => items.where((s) => _deriveVerdict(s.analysis) == 'verified').toList(),
        _FilterTab.mixed => items.where((s) => _deriveVerdict(s.analysis) == 'mixed').toList(),
      };

  int _count(_FilterTab tab, List<SavedAnalysis> items) => switch (tab) {
        _FilterTab.all => items.length,
        _ => items.where((s) => _deriveVerdict(s.analysis) == tab.label.toLowerCase()).length,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(savedAnalysesControllerProvider);
    final filtered = _filtered(state.items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veritas', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _FilterTab.values.map((tab) {
                  final count = _count(tab, state.items);
                  final isActive = _activeFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${tab.label} ($count)'),
                      selected: isActive,
                      onSelected: (_) => setState(() => _activeFilter = tab),
                      selectedColor: const Color(0xFF86F2E4),
                      checkmarkColor: const Color(0xFF006A61),
                      labelStyle: TextStyle(
                        color: isActive ? const Color(0xFF006A61) : const Color(0xFF45474C),
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: switch ((state.isLoading, state.items.isEmpty)) {
              (true, _) => const Center(child: CircularProgressIndicator()),
              (false, true) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No saved analyses yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
              (false, false) when filtered.isEmpty => Center(
                  child: Text('No ${_activeFilter.label.toLowerCase()} analyses.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                ),
              _ => ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ClaimCard(
                    saved: filtered[index],
                    verdict: _deriveVerdict(filtered[index].analysis),
                    onTap: () {
                      ref.read(analysisControllerProvider.notifier).viewSaved(filtered[index].analysis);
                      context.push(RoutePaths.coreClaim);
                    },
                  ),
                ),
            },
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.history),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.saved, required this.verdict, required this.onTap});

  final SavedAnalysis saved;
  final String verdict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color, icon) = _verdictStyle(verdict);
    final confidence = _confidence(saved.analysis);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(label,
                            style: TextStyle(
                                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$confidence% confidence',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF75777D))),
                  const Spacer(),
                  Text(_formatDate(saved.savedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF75777D))),
                ],
              ),
            ),
            // Claim text
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                saved.analysis.claim,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF191C1E),
                ),
              ),
            ),
            // Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                saved.analysis.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF45474C)),
              ),
            ),
            // Footer actions
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF75777D)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _confidence(AnalyzeResult analysis) {
    final total = analysis.evidence.length;
    if (total == 0) return 50;
    final forCount = analysis.evidence.where((e) => e.stance == 'for').length;
    return ((forCount / total) * 100).round();
  }

  (String, Color, IconData) _verdictStyle(String verdict) => switch (verdict) {
        'verified' => ('VERIFIED', const Color(0xFF006A61), Icons.check_circle_outline),
        'misleading' => ('MISLEADING', const Color(0xFFBA1A1A), Icons.warning_amber_outlined),
        _ => ('MIXED', const Color(0xFF856A00), Icons.help_outline),
      };

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 364) return '${diff.inDays ~/ 7}w';
    return '${diff.inDays ~/ 365}y';
  }
}
