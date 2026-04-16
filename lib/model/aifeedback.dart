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

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
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
  final String? practiceAudioUrl;
  final String? audioUrl;
  final String? practiceUrl;
  final String? sourceAudioUrl;
  final String? practiceWord;
  final String? practiceHeardAs;
  final double? segmentStartRatio;
  final double? segmentEndRatio;

  const AiFeedbackPronunciation({
    required this.word,
    required this.phonetic,
    required this.score,
    required this.status,
    this.practiceAudioUrl,
    this.audioUrl,
    this.practiceUrl,
    this.sourceAudioUrl,
    this.practiceWord,
    this.practiceHeardAs,
    this.segmentStartRatio,
    this.segmentEndRatio,
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

    Map<String, dynamic>? hint;
    final h = json['practiceSegmentHint'];
    if (h is Map<String, dynamic>) {
      hint = h;
    } else if (h is Map) {
      hint = Map<String, dynamic>.from(h);
    }

    String? pickStr(dynamic v) {
      final t = _str(v).trim();
      return t.isEmpty ? null : t;
    }

    double? ratio(dynamic v) {
      final n = _num(v);
      if (n == null) return null;
      return n.clamp(0.0, 1.0);
    }

    return AiFeedbackPronunciation(
      word: _str(json['word']).trim(),
      phonetic: _str(json['phonetic']).trim(),
      score: scoreVal.clamp(0, 100),
      status: _str(json['status']).trim(),
      practiceAudioUrl: pickStr(json['practiceAudioUrl']),
      audioUrl: pickStr(json['audioUrl']),
      practiceUrl: pickStr(json['practiceUrl']),
      sourceAudioUrl: pickStr(json['sourceAudioUrl']),
      practiceWord: pickStr(json['practiceWord']),
      practiceHeardAs: pickStr(json['practiceHeardAs']),
      segmentStartRatio:
          ratio(
            json['practiceSegmentStartRatio'] ??
                hint?['startRatio'] ??
                json['startRatio'],
          ),
      segmentEndRatio:
          ratio(
            json['practiceSegmentEndRatio'] ??
                hint?['endRatio'] ??
                json['endRatio'],
          ),
    );
  }

  String? get playbackUrl {
    for (final v in [practiceAudioUrl, audioUrl, practiceUrl, sourceAudioUrl]) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  bool get hasSegmentHint =>
      segmentStartRatio != null &&
      segmentEndRatio != null &&
      segmentEndRatio! > segmentStartRatio!;

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

class AiFeedbackCorrectSentence {
  final String incorrect;
  final String corrected;
  final String tip;

  const AiFeedbackCorrectSentence({
    required this.incorrect,
    required this.corrected,
    required this.tip,
  });

  bool get isEmpty =>
      incorrect.trim().isEmpty &&
      corrected.trim().isEmpty &&
      tip.trim().isEmpty;
}

class AiFeedbackImproveSentence {
  final String sentence;
  final String tip;

  const AiFeedbackImproveSentence({
    required this.sentence,
    required this.tip,
  });

  bool get isEmpty => sentence.trim().isEmpty && tip.trim().isEmpty;
}

/// `type: "ai"` payload (grammar / pronunciation / vocabulary blocks).
class AiFeedbackAiPayload {
  final AiFeedbackGrammar grammar;
  final AiFeedbackPronunciation pronunciation;
  final AiFeedbackVocabulary vocabulary;
  final AiFeedbackCorrectSentence correctSentence;
  final AiFeedbackImproveSentence improveSentence;
  final List<String> moreWaysToSay;
  final String? timestamp;

  /// Full corrected sentence as one string (backend should place last in response / UI).
  final String? fullCorrectedSentence;

  const AiFeedbackAiPayload({
    required this.grammar,
    required this.pronunciation,
    required this.vocabulary,
    required this.correctSentence,
    required this.improveSentence,
    required this.moreWaysToSay,
    this.timestamp,
    this.fullCorrectedSentence,
  });

  factory AiFeedbackAiPayload.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    final f1 = _str(json['fullCorrectedSentence']).trim();
    final f2 = _str(json['fullSentence']).trim();
    final full = f1.isNotEmpty ? f1 : (f2.isNotEmpty ? f2 : null);
    final grammar = AiFeedbackGrammar.fromJson(asMap(json['grammar']));
    final pronunciation =
        AiFeedbackPronunciation.fromJson(asMap(json['pronunciation']));
    final vocabulary = AiFeedbackVocabulary.fromJson(asMap(json['vocabulary']));

    final csMap = asMap(json['correctSentence']);
    final csIncorrect =
        _str(csMap?['incorrect'] ?? grammar.original).trim();
    final csCorrected =
        _str(csMap?['corrected'] ?? grammar.corrected).trim();
    final csTip = _str(csMap?['tip']).trim();

    final improveMap = asMap(json['improveSentence']);
    final improveSentenceText =
        _str(improveMap?['sentence'] ?? full ?? '').trim();
    final improveTip = _str(improveMap?['tip']).trim();

    final directMoreWays = _stringList(json['moreWaysToSay']);
    final fallbackMoreWays = vocabulary.suggestions
        .map((e) => e.improvement.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final moreWays = directMoreWays.isNotEmpty ? directMoreWays : fallbackMoreWays;

    return AiFeedbackAiPayload(
      grammar: grammar,
      pronunciation: pronunciation,
      vocabulary: vocabulary,
      correctSentence: AiFeedbackCorrectSentence(
        incorrect: csIncorrect,
        corrected: csCorrected,
        tip: csTip,
      ),
      improveSentence: AiFeedbackImproveSentence(
        sentence: improveSentenceText,
        tip: improveTip,
      ),
      moreWaysToSay: moreWays,
      timestamp: json['timestamp']?.toString(),
      fullCorrectedSentence: full,
    );
  }
}
