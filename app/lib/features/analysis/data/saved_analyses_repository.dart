import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'models/analyze_result.dart';
import 'models/saved_analysis.dart';

/// Persists saved analyses as a single JSON file in the app's documents
/// directory, via `path_provider` — already a dependency (Milestone 5's
/// OCR temp-file handling), so this needs no new package. A flat JSON file
/// is enough for a list that only ever grows by explicit user action; a
/// real database would be solving a problem this feature doesn't have.
abstract class SavedAnalysesRepository {
  Future<List<SavedAnalysis>> loadAll();
  Future<void> save(AnalyzeResult analysis);
}

class FileSavedAnalysesRepository implements SavedAnalysesRepository {
  static const _fileName = 'saved_analyses.json';

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  @override
  Future<List<SavedAnalysis>> loadAll() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    final decoded = jsonDecode(content) as List<dynamic>;
    return decoded.map((item) => SavedAnalysis.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> save(AnalyzeResult analysis) async {
    final existing = await loadAll();
    existing.add(SavedAnalysis(savedAt: DateTime.now(), analysis: analysis));
    final file = await _file();
    await file.writeAsString(jsonEncode(existing.map((item) => item.toJson()).toList()));
  }
}

final savedAnalysesRepositoryProvider = Provider<SavedAnalysesRepository>((ref) {
  return FileSavedAnalysesRepository();
});
