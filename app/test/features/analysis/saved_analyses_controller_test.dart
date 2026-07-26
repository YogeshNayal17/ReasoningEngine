import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reason_ai/features/analysis/data/models/analyze_result.dart';
import 'package:reason_ai/features/analysis/data/models/saved_analysis.dart';
import 'package:reason_ai/features/analysis/data/saved_analyses_repository.dart';
import 'package:reason_ai/features/analysis/presentation/controllers/saved_analyses_controller.dart';

const _analysis = AnalyzeResult(
  claim: 'claim',
  whatThisMeans: 'what it means',
  insights: [],
  questions: [],
  context: [],
  evidence: [],
  summary: 'summary',
);

class FakeSavedAnalysesRepository implements SavedAnalysesRepository {
  List<SavedAnalysis> stored = [];

  @override
  Future<List<SavedAnalysis>> loadAll() async => stored;

  @override
  Future<void> save(AnalyzeResult analysis) async {
    stored = [...stored, SavedAnalysis(savedAt: DateTime.utc(2024, 1, stored.length + 1), analysis: analysis)];
  }
}

void main() {
  late FakeSavedAnalysesRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeSavedAnalysesRepository();
    container = ProviderContainer(overrides: [savedAnalysesRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
  });

  test('refresh loads saved analyses newest first', () async {
    repository.stored = [
      SavedAnalysis(savedAt: DateTime.utc(2024, 1, 1), analysis: _analysis),
      SavedAnalysis(savedAt: DateTime.utc(2024, 1, 2), analysis: _analysis),
    ];

    await container.read(savedAnalysesControllerProvider.notifier).refresh();

    final state = container.read(savedAnalysesControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.items, hasLength(2));
    expect(state.items.first.savedAt, equals(DateTime.utc(2024, 1, 2)));
  });

  test('save appends to the repository and refreshes state', () async {
    await container.read(savedAnalysesControllerProvider.notifier).save(_analysis);

    final state = container.read(savedAnalysesControllerProvider);
    expect(repository.stored, hasLength(1));
    expect(state.items, hasLength(1));
  });
}
