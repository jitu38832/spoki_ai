// ignore_for_file: public_member_api_docs

// Dart models for Socket.IO `aifeedback` payloads.
// TypeScript shapes (for server / contract), e.g.:
// AiFeedbackRequest = { text } | { message } | { content }
// AiFeedbackTyping = { type: 'typing'; status?; timestamp? }
// AiFeedbackUserEcho = { type: 'user'; text; timestamp? }
// AiFeedbackError = { type: 'error'; message; timestamp? }
// GrammarBlock = { original; errors: string[]; corrected }
// PronunciationBlock = { word; phonetic; score: number; status }
// VocabularyBlock = { suggestions: { original; improvement }[] }
// AiFeedbackAi = { type: 'ai'; grammar?; pronunciation?; vocabulary?; timestamp? }

String _str(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  if (v is String) return v;
  return v.toString();
}

List<String> _stringList(dynamic v) {
  if (v == null) return [];
  if (v is List) {
    return v.map((e) => _str(e).trim()).where((s) => s.isNotEmpty).toList();
  }
  return [];
}

class AiFeedbackGrammar {
  final String original;
  final List<String> errors;
  final String corrected;

  const AiFeedbackGrammar({
    required this.original,
    required this.errors,
    required this.corrected,
  });

  factory AiFeedbackGrammar.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AiFeedbackGrammar(original: '', errors: [], corrected: '');
    }
    return AiFeedbackGrammar(
      original: _str(json['original']).trim(),
      errors: _stringList(json['errors']),
      corrected: _str(json['corrected']).trim(),
    );
  }

  bool get isEmpty => original.isEmpty && corrected.isEmpty && errors.isEmpty;
}

class AiFeedbackPronunciation {
  final String word;
  final String phonetic;
  final double score;
  final String status;

  const AiFeedbackPronunciation({
    required this.word,
    required this.phonetic,
    required this.score,
    required this.status,
  });

  factory AiFeedbackPronunciation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AiFeedbackPronunciation(
        word: '',
        phonetic: '',
        score: 0,
        status: '',
      );
    }
    final s = json['score'];
    double scoreVal = 0;
    if (s is num) {
      scoreVal = s.toDouble();
    } else if (s != null) {
      scoreVal = double.tryParse(s.toString()) ?? 0;
    }
    return AiFeedbackPronunciation(
      word: _str(json['word']).trim(),
      phonetic: _str(json['phonetic']).trim(),
      score: scoreVal.clamp(0, 100),
      status: _str(json['status']).trim(),
    );
  }

  bool get isEmpty => word.isEmpty && phonetic.isEmpty && status.isEmpty;
}

class AiFeedbackVocabRow {
  final String original;
  final String improvement;

  const AiFeedbackVocabRow({
    required this.original,
    required this.improvement,
  });

  factory AiFeedbackVocabRow.fromJson(Map<String, dynamic> json) {
    final imp =
        _str(json['improvement'] ?? json['improved'] ?? json['suggestion']).trim();
    return AiFeedbackVocabRow(
      original: _str(json['original']).trim(),
      improvement: imp,
    );
  }
}

class AiFeedbackVocabulary {
  final List<AiFeedbackVocabRow> suggestions;

  const AiFeedbackVocabulary({required this.suggestions});

  factory AiFeedbackVocabulary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AiFeedbackVocabulary(suggestions: []);
    final list = json['suggestions'];
    if (list is! List) return const AiFeedbackVocabulary(suggestions: []);
    final rows = <AiFeedbackVocabRow>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        rows.add(AiFeedbackVocabRow.fromJson(item));
      } else if (item is Map) {
        rows.add(AiFeedbackVocabRow.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return AiFeedbackVocabulary(suggestions: rows);
  }

  bool get isEmpty => suggestions.isEmpty;
}

/// `type: "ai"` payload (grammar / pronunciation / vocabulary blocks).
class AiFeedbackAiPayload {
  final AiFeedbackGrammar grammar;
  final AiFeedbackPronunciation pronunciation;
  final AiFeedbackVocabulary vocabulary;
  final String? timestamp;

  const AiFeedbackAiPayload({
    required this.grammar,
    required this.pronunciation,
    required this.vocabulary,
    this.timestamp,
  });

  factory AiFeedbackAiPayload.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    return AiFeedbackAiPayload(
      grammar: AiFeedbackGrammar.fromJson(asMap(json['grammar'])),
      pronunciation:
          AiFeedbackPronunciation.fromJson(asMap(json['pronunciation'])),
      vocabulary: AiFeedbackVocabulary.fromJson(asMap(json['vocabulary'])),
      timestamp: json['timestamp']?.toString(),
    );
  }
}
