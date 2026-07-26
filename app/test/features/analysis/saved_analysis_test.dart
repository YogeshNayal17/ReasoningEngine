import 'package:flutter_test/flutter_test.dart';
import 'package:reason_ai/features/analysis/data/models/analyze_result.dart';
import 'package:reason_ai/features/analysis/data/models/saved_analysis.dart';

void main() {
  test('SavedAnalysis round-trips through JSON', () {
    const analysis = AnalyzeResult(
      claim: 'claim',
      whatThisMeans: 'what it means',
      insights: [KeyInsight(kind: InsightKind.strength, title: 'Strength', detail: 'detail', tag: 'Moderate')],
      questions: ['question one'],
      context: ['context note'],
      evidence: [EvidenceItem(stance: 'for', text: 'evidence text', source: 'source')],
      summary: 'summary',
    );
    final saved = SavedAnalysis(savedAt: DateTime.utc(2024, 1, 2, 3, 4), analysis: analysis);

    final restored = SavedAnalysis.fromJson(saved.toJson());

    expect(restored.savedAt, equals(saved.savedAt));
    expect(restored.analysis.claim, equals('claim'));
    expect(restored.analysis.insights.single.tag, equals('Moderate'));
    expect(restored.analysis.evidence.single.stance, equals('for'));
  });
}
