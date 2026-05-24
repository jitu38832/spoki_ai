import 'package:spokiai/model/chat_freemium_quota.dart';

/// Server shape for `GET users/me/story-freemium` (see docs/story_freemium_api.md).
class StoryFreemiumQuota {
  const StoryFreemiumQuota({
    required this.premium,
    required this.storyGenerationUsed,
    required this.storyGenerationLimit,
    required this.storyFluentLevelUsed,
    required this.storyFluentLevelLimit,
    required this.storyTtsUsed,
    required this.storyTtsLimit,
    required this.storyQuizUsed,
    required this.storyQuizLimit,
  });

  final bool premium;
  final int storyGenerationUsed;
  final int storyGenerationLimit;
  final int storyFluentLevelUsed;
  final int storyFluentLevelLimit;
  final int storyTtsUsed;
  final int storyTtsLimit;
  final int storyQuizUsed;
  final int storyQuizLimit;

  static StoryFreemiumQuota fromBackendJson(dynamic root) {
    final map = ChatFreemiumQuota.unwrapData(root);
    final limits = _asMap(map['limits']);
    final used = _asMap(map['used']);
    final premium = map['premium'] == true ||
        map['isPremium'] == true ||
        map['subscribed'] == true;

    return StoryFreemiumQuota(
      premium: premium,
      storyGenerationUsed: _pickUsed(used, const [
        'story_generation',
        'storyGeneration',
        'generation',
      ]),
      storyGenerationLimit: _pickLimit(limits, const [
        'story_generation',
        'storyGeneration',
        'generation',
      ]),
      storyFluentLevelUsed: _pickUsed(used, const [
        'story_fluent_level',
        'storyFluentLevel',
        'fluent',
      ]),
      storyFluentLevelLimit: _pickLimit(limits, const [
        'story_fluent_level',
        'storyFluentLevel',
        'fluent',
      ]),
      storyTtsUsed:
          _pickUsed(used, const ['story_tts', 'storyTts', 'tts']),
      storyTtsLimit:
          _pickLimit(limits, const ['story_tts', 'storyTts', 'tts']),
      storyQuizUsed:
          _pickUsed(used, const ['story_quiz', 'storyQuiz', 'quiz']),
      storyQuizLimit:
          _pickLimit(limits, const ['story_quiz', 'storyQuiz', 'quiz']),
    );
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is! Map) return {};
    return Map<String, dynamic>.from(v.map((k, val) => MapEntry('$k', val)));
  }

  static int _pickUsed(Map<String, dynamic> src, List<String> keys) {
    for (final k in keys) {
      if (src.containsKey(k)) return _positiveInt(src[k]);
    }
    return 0;
  }

  static int _pickLimit(Map<String, dynamic> limits, List<String> keys) {
    for (final k in keys) {
      if (limits.containsKey(k)) {
        final n = _positiveInt(limits[k]);
        return n > 0 ? n : 2;
      }
    }
    return 2;
  }

  static int _positiveInt(dynamic v) {
    if (v is int) return v < 0 ? 0 : v;
    if (v is num) return v.toInt().clamp(0, 1 << 30);
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty) return 0;
    return int.tryParse(s) ?? 0;
  }
}

/// Result from `POST users/me/story-freemium/consume`.
class StoryFreemiumConsumeResult {
  StoryFreemiumConsumeResult({
    required this.allowed,
    required this.success,
    this.message,
    this.quota,
  });

  final bool allowed;
  final bool success;
  final String? message;
  final StoryFreemiumQuota? quota;

  static StoryFreemiumConsumeResult fromHttp(
    dynamic body, {
    int? httpStatusCode,
  }) {
    final map = body is Map
        ? Map<String, dynamic>.from(body.map((k, v) => MapEntry('$k', v)))
        : <String, dynamic>{};
    final nested = ChatFreemiumQuota.unwrapData(body);
    final okHttp = httpStatusCode != null &&
        httpStatusCode >= 200 &&
        httpStatusCode < 300;

    StoryFreemiumQuota? quota;
    try {
      if (nested.containsKey('limits') || nested.containsKey('used')) {
        quota = StoryFreemiumQuota.fromBackendJson(body);
      }
    } catch (_) {
      quota = null;
    }

    final denied = nested['allowed'] == false || map['allowed'] == false;
    var resolved = false;
    if (denied) {
      resolved = false;
    } else if (nested['allowed'] == true || map['allowed'] == true) {
      resolved = true;
    } else if (okHttp) {
      resolved = true;
    } else if (nested['premium'] == true || map['premium'] == true) {
      resolved = true;
    }

    final message = _msg(map) ?? _msg(nested);

    return StoryFreemiumConsumeResult(
      allowed: resolved,
      success:
          map['success'] == true || nested['success'] == true || okHttp,
      message: message,
      quota: quota,
    );
  }

  static String? _msg(Map<String, dynamic> map) {
    final m =
        map['message'] ?? map['error'] ?? map['detail'] ?? map['reason'];
    final t = m?.toString().trim() ?? '';
    return t.isEmpty ? null : t;
  }
}
