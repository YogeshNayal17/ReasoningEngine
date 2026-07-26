import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../data/analysis_api.dart';
import '../../data/models/analyze_result.dart';

class AnalysisState {
  const AnalysisState({this.isLoading = false, this.result});

  final bool isLoading;

  /// Null until the first [AnalysisController.analyze] call completes.
  final Result<AnalyzeResult>? result;

  AnalysisState copyWith({bool? isLoading, Result<AnalyzeResult>? result}) {
    return AnalysisState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
    );
  }
}

/// Mirrors `OcrController`'s shape — same `Result<T>` pattern for an
/// operation (a network call, this time) with an expected failure mode.
class AnalysisController extends Notifier<AnalysisState> {
  late final AnalysisApi _api;

  @override
  AnalysisState build() {
    _api = ref.watch(analysisApiProvider);
    return const AnalysisState();
  }

  Future<void> analyze(String text) async {
    state = state.copyWith(isLoading: true);
    final result = await _api.analyze(text);
    state = AnalysisState(result: result);
  }
}

final analysisControllerProvider = NotifierProvider<AnalysisController, AnalysisState>(
  AnalysisController.new,
);
