import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../data/models/analyze_result.dart';
import '../../data/models/saved_analysis.dart';
import '../../data/saved_analyses_repository.dart';

class SavedAnalysesState {
  const SavedAnalysesState({this.isLoading = false, this.items = const []});

  final bool isLoading;

  /// Newest first.
  final List<SavedAnalysis> items;

  SavedAnalysesState copyWith({bool? isLoading, List<SavedAnalysis>? items}) {
    return SavedAnalysesState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
    );
  }
}

class SavedAnalysesController extends Notifier<SavedAnalysesState> {
  late final SavedAnalysesRepository _repository;
  late final AppLogger _logger;

  @override
  SavedAnalysesState build() {
    _repository = ref.watch(savedAnalysesRepositoryProvider);
    _logger = ref.watch(appLoggerProvider);
    unawaited(refresh());
    return const SavedAnalysesState(isLoading: true);
  }

  /// Doesn't set `isLoading` before the `await` — `build()` calls this via
  /// `unawaited(refresh())`, and writing `state` before the first `await`
  /// would run synchronously inside `build()`, before it's returned its
  /// initial value, which crashes with "uninitialized provider".
  Future<void> refresh() async {
    try {
      final items = await _repository.loadAll();
      state = SavedAnalysesState(items: items.reversed.toList());
    } catch (error, stackTrace) {
      _logger.error('Failed to load saved analyses', error: error, stackTrace: stackTrace);
      state = const SavedAnalysesState();
    }
  }

  Future<void> save(AnalyzeResult analysis) async {
    try {
      await _repository.save(analysis);
      await refresh();
    } catch (error, stackTrace) {
      _logger.error('Failed to save analysis', error: error, stackTrace: stackTrace);
    }
  }
}

final savedAnalysesControllerProvider = NotifierProvider<SavedAnalysesController, SavedAnalysesState>(
  SavedAnalysesController.new,
);
