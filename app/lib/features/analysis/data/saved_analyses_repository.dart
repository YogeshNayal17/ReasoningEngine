import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../auth/presentation/controllers/auth_controller.dart';
import 'models/analyze_result.dart';
import 'models/saved_analysis.dart';

abstract class SavedAnalysesRepository {
  Future<List<SavedAnalysis>> loadAll();
  Future<void> save(AnalyzeResult analysis);
}

class FileSavedAnalysesRepository implements SavedAnalysesRepository {
  FileSavedAnalysesRepository(this._userId);

  final int _userId;

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/saved_analyses_$_userId.json');
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
  final userId = ref.watch(authProvider).user?.userId ?? 0;
  return FileSavedAnalysesRepository(userId);
});
