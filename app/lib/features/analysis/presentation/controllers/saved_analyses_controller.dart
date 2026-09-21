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
  @override
  SavedAnalysesState build() {
    // Watch so the notifier rebuilds (and reloads history) when the user changes.
    ref.watch(savedAnalysesRepositoryProvider);
    unawaited(refresh());
    return const SavedAnalysesState(isLoading: true);
  }

  Future<void> refresh() async {
    try {
      final items = await ref.read(savedAnalysesRepositoryProvider).loadAll();
      if (!ref.mounted) return;
      state = SavedAnalysesState(items: items.reversed.toList());
    } catch (error, stackTrace) {
      ref.read(appLoggerProvider).error('Failed to load saved analyses', error: error, stackTrace: stackTrace);
      if (ref.mounted) state = const SavedAnalysesState();
    }
  }

  Future<void> save(AnalyzeResult analysis) async {
    try {
      await ref.read(savedAnalysesRepositoryProvider).save(analysis);
      await refresh();
    } catch (error, stackTrace) {
      ref.read(appLoggerProvider).error('Failed to save analysis', error: error, stackTrace: stackTrace);
    }
  }
}

final savedAnalysesControllerProvider = NotifierProvider<SavedAnalysesController, SavedAnalysesState>(
  SavedAnalysesController.new,
);
