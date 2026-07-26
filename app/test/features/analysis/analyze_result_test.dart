import 'package:flutter_test/flutter_test.dart';
import 'package:reason_ai/features/analysis/data/models/analyze_result.dart';

void main() {
  test('AnalyzeResult.fromJson parses the mocked backend shape', () {
    final json = {
      'claim': 'Some claim',
      'what_this_means': 'what it means',
      'insights': [
        {'kind': 'strength', 'title': 'Evidence strength', 'detail': 'detail text', 'tag': 'Moderate'},
      ],
      'questions': ['a question'],
      'context': ['a context note'],
      'evidence': [
        {'stance': 'neutral', 'text': 'evidence text', 'source': 'N/A'},
      ],
      'summary': 'summary text',
    };

    final result = AnalyzeResult.fromJson(json);

    expect(result.claim, equals('Some claim'));
    expect(result.whatThisMeans, equals('what it means'));
    expect(result.insights, hasLength(1));
    expect(result.insights.first.kind, equals(InsightKind.strength));
    expect(result.insights.first.title, equals('Evidence strength'));
    expect(result.insights.first.tag, equals('Moderate'));
    expect(result.questions, equals(['a question']));
    expect(result.context, equals(['a context note']));
    expect(result.evidence, hasLength(1));
    expect(result.evidence.first.stance, equals('neutral'));
    expect(result.summary, equals('summary text'));
  });

  test('KeyInsight.fromJson falls back to context kind for an unknown value', () {
    final insight = KeyInsight.fromJson({'kind': 'unknown', 'title': 't', 'detail': 'd'});

    expect(insight.kind, equals(InsightKind.context));
    expect(insight.tag, isNull);
  });
}
