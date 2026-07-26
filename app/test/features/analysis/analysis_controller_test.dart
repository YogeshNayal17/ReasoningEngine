import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reason_ai/core/error/app_failure.dart';
import 'package:reason_ai/core/utils/result.dart';
import 'package:reason_ai/features/analysis/data/analysis_api.dart';
import 'package:reason_ai/features/analysis/data/models/analyze_result.dart';
import 'package:reason_ai/features/analysis/presentation/controllers/analysis_controller.dart';

class FakeAnalysisApi implements AnalysisApi {
  Result<AnalyzeResult>? nextResult;

  @override
  Future<Result<AnalyzeResult>> analyze(String text) async {
    return nextResult ?? const Result.failure(UnexpectedFailure('not configured'));
  }
}

void main() {
  late FakeAnalysisApi api;
  late ProviderContainer container;

  setUp(() {
    api = FakeAnalysisApi();
    container = ProviderContainer(overrides: [analysisApiProvider.overrideWithValue(api)]);
    addTearDown(container.dispose);
  });

  test('analyze stores a success result', () async {
    const analysis = AnalyzeResult(
      claim: 'claim',
      whatThisMeans: 'what it means',
      insights: [],
      questions: [],
      context: [],
      evidence: [],
      summary: 'summary',
    );
    api.nextResult = const Result.success(analysis);

    await container.read(analysisControllerProvider.notifier).analyze('some text');

    final state = container.read(analysisControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.result?.when(success: (value) => value.claim, failure: (_) => null), equals('claim'));
  });

  test('analyze stores a failure result', () async {
    api.nextResult = const Result.failure(NetworkFailure());

    await container.read(analysisControllerProvider.notifier).analyze('some text');

    final state = container.read(analysisControllerProvider);
    expect(
      state.result?.when(success: (_) => null, failure: (f) => f.message),
      equals('Could not reach the server.'),
    );
  });
}
