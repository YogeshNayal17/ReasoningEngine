/// Mirrors the backend's `AnalyzeResponse` shape (`backend/app/schemas.py`).
/// Currently always mocked data — Milestone 7 will make the values real,
/// not the shape.
enum InsightKind { strength, question, context }

InsightKind _insightKindFromJson(String value) {
  return InsightKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => InsightKind.context,
  );
}

class KeyInsight {
  const KeyInsight({required this.kind, required this.title, required this.detail, this.tag});

  /// Drives which icon the UI shows next to this insight.
  final InsightKind kind;
  final String title;
  final String detail;

  /// A short badge shown next to the title, e.g. "Moderate". Absent for
  /// insights that don't have one.
  final String? tag;

  factory KeyInsight.fromJson(Map<String, dynamic> json) {
    return KeyInsight(
      kind: _insightKindFromJson(json['kind'] as String),
      title: json['title'] as String,
      detail: json['detail'] as String,
      tag: json['tag'] as String?,
    );
  }
}

class EvidenceItem {
  const EvidenceItem({required this.stance, required this.text, required this.source});

  /// One of "for" / "against" / "neutral" — matches the backend's `Literal`.
  final String stance;
  final String text;
  final String source;

  factory EvidenceItem.fromJson(Map<String, dynamic> json) {
    return EvidenceItem(
      stance: json['stance'] as String,
      text: json['text'] as String,
      source: json['source'] as String,
    );
  }
}

class AnalyzeResult {
  const AnalyzeResult({
    required this.claim,
    required this.whatThisMeans,
    required this.insights,
    required this.questions,
    required this.context,
    required this.evidence,
    required this.summary,
  });

  final String claim;
  final String whatThisMeans;
  final List<KeyInsight> insights;
  final List<String> questions;
  final List<String> context;
  final List<EvidenceItem> evidence;
  final String summary;

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) {
    return AnalyzeResult(
      claim: json['claim'] as String,
      whatThisMeans: json['what_this_means'] as String,
      insights: (json['insights'] as List<dynamic>)
          .map((item) => KeyInsight.fromJson(item as Map<String, dynamic>))
          .toList(),
      questions: (json['questions'] as List<dynamic>).cast<String>(),
      context: (json['context'] as List<dynamic>).cast<String>(),
      evidence: (json['evidence'] as List<dynamic>)
          .map((item) => EvidenceItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String,
    );
  }
}
