import 'package:flutter_test/flutter_test.dart';
import 'package:reason_ai/features/analysis/data/models/analyze_result.dart';

void main() {
  test('AnalyzeResult.fromJson parses the mocked backend shape', () {
    final json = {
      'claim': 'Some claim',
      'insights': [
        {'title': 'Evidence strength', 'detail': 'detail text'},
      ],
      'evidence': [
        {'stance': 'neutral', 'text': 'evidence text', 'source': 'N/A'},
      ],
      'summary': 'summary text',
    };

    final result = AnalyzeResult.fromJson(json);

    expect(result.claim, equals('Some claim'));
    expect(result.insights, hasLength(1));
    expect(result.insights.first.title, equals('Evidence strength'));
    expect(result.evidence, hasLength(1));
    expect(result.evidence.first.stance, equals('neutral'));
    expect(result.summary, equals('summary text'));
  });
}
