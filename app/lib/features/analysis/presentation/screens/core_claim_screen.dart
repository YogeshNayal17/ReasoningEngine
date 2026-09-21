import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../data/models/analyze_result.dart';
import '../controllers/analysis_controller.dart';
import '../controllers/chat_controller.dart';


class CoreClaimScreen extends ConsumerWidget {
  const CoreClaimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(analysisControllerProvider).result;
    final analysis = result?.when(success: (v) => v, failure: (_) => null);

    if (analysis == null) {
      return const Scaffold(body: Center(child: Text('No analysis available.')));
    }

    final nuanceScore = _nuanceScore(analysis);
    final credibilityScore = _credibilityScore(analysis);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reasoning Card', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Claim header
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8E3FB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CLAIM ANALYSIS',
                          style: TextStyle(
                            color: const Color(0xFF1E293B),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _BiasChip(analysis: analysis),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"${analysis.claim}"',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191C1E),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    analysis.whatThisMeans,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF45474C), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scores row
            Row(
              children: [
                Expanded(child: _ScoreCard(
                  label: 'Nuance Score',
                  value: '$nuanceScore%',
                  sublabel: 'Contextual complexity',
                  color: _scoreColor(nuanceScore),
                )),
                const SizedBox(width: 12),
                Expanded(child: _ScoreCard(
                  label: 'Credibility',
                  value: '$credibilityScore / 100',
                  sublabel: _credibilityLabel(credibilityScore),
                  color: _scoreColor(credibilityScore),
                )),
              ],
            ),
            const SizedBox(height: 12),

            // Credibility meter details
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Icons.speed_outlined, label: 'Credibility Meter'),
                  const SizedBox(height: 12),
                  _CredibilityBar(score: credibilityScore),
                  const SizedBox(height: 16),
                  _MetricRow(
                    label: 'Primary Source Transparency',
                    value: _transparencyLabel(analysis),
                  ),
                  const SizedBox(height: 8),
                  _MetricRow(
                    label: 'Evidence Replication & Audit',
                    value: _replicationLabel(analysis),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Logical fallacies / key insights
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Icons.warning_amber_outlined, label: 'Key Insights & Flags'),
                  const SizedBox(height: 12),
                  ...analysis.insights.map((insight) => _InsightRow(insight: insight)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Evidence strength
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Icons.balance_outlined, label: 'Evidence Strength'),
                  const SizedBox(height: 12),
                  ...analysis.evidence.map((e) => _EvidenceRow(item: e)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Emotional Manipulation Index (derived from "against" evidence weight)
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Icons.psychology_outlined, label: 'Emotional Context Index'),
                  const SizedBox(height: 12),
                  ...analysis.context.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFF006A61)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c, style: const TextStyle(fontSize: 13, color: Color(0xFF45474C)))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Summary + actions
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Icons.summarize_outlined, label: 'Summary'),
                  const SizedBox(height: 10),
                  Text(analysis.summary,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF191C1E), height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            OutlinedButton.icon(
              onPressed: () {
                ref.read(chatProvider.notifier).reset();
                context.push(RoutePaths.chat);
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Ask a Follow-up Question'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go(RoutePaths.home),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Analyze Another Claim'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.reasoning),
    );
  }

  int _nuanceScore(AnalyzeResult a) {
    final questions = a.questions.length;
    final context = a.context.length;
    return ((questions * 10 + context * 15 + 40).clamp(30, 95)).toInt();
  }

  int _credibilityScore(AnalyzeResult a) {
    final total = a.evidence.length;
    if (total == 0) return 50;
    final forCount = a.evidence.where((e) => e.stance == 'for').length;
    return ((forCount / total) * 100).clamp(10, 100).toInt();
  }

  Color _scoreColor(int score) {
    if (score >= 70) return const Color(0xFF006A61);
    if (score >= 40) return const Color(0xFF856A00);
    return const Color(0xFFBA1A1A);
  }

  String _credibilityLabel(int score) {
    if (score >= 70) return 'High credibility';
    if (score >= 40) return 'Moderate credibility';
    return 'Low credibility';
  }

  String _transparencyLabel(AnalyzeResult a) {
    final sources = a.evidence.where((e) => e.source != 'N/A').length;
    if (sources > 1) return 'Moderate';
    return 'Low';
  }

  String _replicationLabel(AnalyzeResult a) {
    final against = a.evidence.where((e) => e.stance == 'against').length;
    return against > 1 ? 'Contested' : 'Limited';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: child,
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E293B)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      );
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF75777D))),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(sublabel, style: const TextStyle(fontSize: 11, color: Color(0xFF45474C))),
          ],
        ),
      );
}

class _CredibilityBar extends StatelessWidget {
  const _CredibilityBar({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? const Color(0xFF006A61)
        : score >= 40
            ? const Color(0xFF856A00)
            : const Color(0xFFBA1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$score / 100',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            Text('${score >= 70 ? "High" : score >= 40 ? "Moderate" : "Low"}',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF45474C))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(value,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ),
        ],
      );
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});
  final KeyInsight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (insight.kind) {
      InsightKind.strength => (Icons.check_circle_outline, const Color(0xFF006A61)),
      InsightKind.question => (Icons.help_outline, const Color(0xFF856A00)),
      InsightKind.context => (Icons.warning_amber_outlined, const Color(0xFFBA1A1A)),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: Color(0xFF191C1E))),
                const SizedBox(height: 2),
                Text(insight.detail,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF45474C))),
                if (insight.tag != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(insight.tag!,
                          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.item});
  final EvidenceItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.stance) {
      'for' => (Icons.check_circle_outline, const Color(0xFF006A61)),
      'against' => (Icons.cancel_outlined, const Color(0xFFBA1A1A)),
      _ => (Icons.remove_circle_outline, const Color(0xFF75777D)),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.text,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF191C1E))),
                if (item.source != 'N/A')
                  _SourceLink(source: item.source),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.source});
  final String source;

  bool get _isUrl => source.startsWith('http://') || source.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (!_isUrl) {
      return Text(
        'Source: $source',
        style: const TextStyle(fontSize: 11, color: Color(0xFF75777D)),
      );
    }
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(source);
        if (uri != null) await launchUrl(uri);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.open_in_new, size: 11, color: Color(0xFF006A61)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              source,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF006A61),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF006A61),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BiasChip extends StatelessWidget {
  const _BiasChip({required this.analysis});
  final AnalyzeResult analysis;

  @override
  Widget build(BuildContext context) {
    final domain = analysis.domain;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEF0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        domain.name.toUpperCase(),
        style: const TextStyle(fontSize: 10, color: Color(0xFF45474C), fontWeight: FontWeight.w600),
      ),
    );
  }
}
