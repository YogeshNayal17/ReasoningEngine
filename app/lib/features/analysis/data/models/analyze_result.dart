/// Mirrors the backend's `AnalyzeResponse` shape (`backend/app/schemas.py`).
/// Currently always mocked data — Milestone 7 will make the values real,
/// not the shape.
class KeyInsight {
  const KeyInsight({required this.title, required this.detail});

  final String title;
  final String detail;

  factory KeyInsight.fromJson(Map<String, dynamic> json) {
    return KeyInsight(
      title: json['title'] as String,
      detail: json['detail'] as String,
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
    required this.insights,
    required this.evidence,
    required this.summary,
  });

  final String claim;
  final List<KeyInsight> insights;
  final List<EvidenceItem> evidence;
  final String summary;

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) {
    return AnalyzeResult(
      claim: json['claim'] as String,
      insights: (json['insights'] as List<dynamic>)
          .map((item) => KeyInsight.fromJson(item as Map<String, dynamic>))
          .toList(),
      evidence: (json['evidence'] as List<dynamic>)
          .map((item) => EvidenceItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String,
    );
  }
}
