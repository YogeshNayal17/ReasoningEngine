import 'analyze_result.dart';

/// A completed analysis the user chose to keep, with the time it was saved.
class SavedAnalysis {
  const SavedAnalysis({required this.savedAt, required this.analysis});

  final DateTime savedAt;
  final AnalyzeResult analysis;

  factory SavedAnalysis.fromJson(Map<String, dynamic> json) {
    return SavedAnalysis(
      savedAt: DateTime.parse(json['savedAt'] as String),
      analysis: AnalyzeResult.fromJson(json['analysis'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'savedAt': savedAt.toIso8601String(),
        'analysis': analysis.toJson(),
      };
}
