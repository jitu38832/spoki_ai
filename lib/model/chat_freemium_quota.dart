// Shapes documented in docs/chat_freemium_api.md (GET + consume responses).

class ChatFreemiumQuota {
  const ChatFreemiumQuota({
    required this.premium,
    required this.translateUsed,
    required this.translateLimit,
    required this.improveSentenceUsed,
    required this.improveSentenceLimit,
    required this.voiceTtsUsed,
    required this.voiceTtsLimit,
  });

  final bool premium;

  /// Times each feature has been used (lifetime or billing period — server decides).
  final int translateUsed;
  final int translateLimit;
  final int improveSentenceUsed;
  final int improveSentenceLimit;
  final int voiceTtsUsed;
  final int voiceTtsLimit;

  static ChatFreemiumQuota fromBackendJson(dynamic root) {
    final map = unwrapData(root);
    final limits = _asStringKeyMap(map['limits']) ?? {};
    final used = _asStringKeyMap(map['used']) ?? {};
    final premium = map['premium'] == true ||
        map['isPremium'] == true ||
        map['subscribed'] == true;

    return ChatFreemiumQuota(
      premium: premium,
      translateUsed: _pickUsed(used, const [
        'translate',
        'translateUses',
        'translate_uses',
      ]),
      translateLimit: _pickLimit(limits, const [
        'translate',
        'translateLimit',
        'translate_limit',
      ]),
      improveSentenceUsed: _pickUsed(used, const [
        'improve_sentence',
        'improveSentence',
        'improve_sentence_uses',
      ]),
      improveSentenceLimit: _pickLimit(limits, const [
        'improve_sentence',
        'improveSentence',
        'improve_sentence_limit',
      ]),
      voiceTtsUsed: _pickUsed(used, const [
        'voice_tts',
        'voiceTts',
        'voice',
      ]),
      voiceTtsLimit: _pickLimit(limits, const [
        'voice_tts',
        'voiceTts',
        'voice',
      ]),
    );
  }

  /// JSON root may be `{ "data": { ... } }` or flat `{ "premium", "limits", "used" }`.
  static Map<String, dynamic> unwrapData(dynamic root) {
    if (root is! Map) return {};
    final m =
        Map<String, dynamic>.from(root.map((k, v) => MapEntry('$k', v)));
    final inner = m['data'];
    if (inner is Map) {
      return Map<String, dynamic>.from(inner.map((k, v) => MapEntry('$k', v)));
    }
    return m;
  }

  ChatFreemiumQuota copyWith({
    bool? premium,
    int? translateUsed,
    int? translateLimit,
    int? improveSentenceUsed,
    int? improveSentenceLimit,
    int? voiceTtsUsed,
    int? voiceTtsLimit,
  }) {
    return ChatFreemiumQuota(
      premium: premium ?? this.premium,
      translateUsed: translateUsed ?? this.translateUsed,
      translateLimit: translateLimit ?? this.translateLimit,
      improveSentenceUsed: improveSentenceUsed ?? this.improveSentenceUsed,
      improveSentenceLimit: improveSentenceLimit ?? this.improveSentenceLimit,
      voiceTtsUsed: voiceTtsUsed ?? this.voiceTtsUsed,
      voiceTtsLimit: voiceTtsLimit ?? this.voiceTtsLimit,
    );
  }

  static Map<String, dynamic>? _asStringKeyMap(dynamic v) {
    if (v is! Map) return null;
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

/// Result of `POST users/me/chat-freemium/consume`.
class ChatFreemiumConsumeResult {
  ChatFreemiumConsumeResult({
    required this.allowed,
    required this.success,
    this.message,
    this.quota,
  });

  /// Server explicitly denies use (quota / not entitled).
  final bool allowed;

  /// Raw success flag when present (`success` in JSON).
  final bool success;
  final String? message;

  /// Updated snapshot after consume; may be omitted.
  final ChatFreemiumQuota? quota;

  static ChatFreemiumConsumeResult fromHttp(
    dynamic body, {
    int? httpStatusCode,
  }) {
    final map =
        body is Map ? Map<String, dynamic>.from(body.map((k, v) => MapEntry('$k', v))) : <String, dynamic>{};
    final nested = ChatFreemiumQuota.unwrapData(body);
    final success = map['success'] == true ||
        map['ok'] == true ||
        nested['success'] == true ||
        httpStatusCode == 200 ||
        httpStatusCode == 201;

    ChatFreemiumQuota? quota;
    if (nested.isNotEmpty ||
        map.containsKey('limits') ||
        map.containsKey('used')) {
      quota = ChatFreemiumQuota.fromBackendJson(body);
    }

    bool? resolvedAllowed =
        nested.containsKey('allowed') ? nested['allowed'] == true : null;
    resolvedAllowed ??=
        map.containsKey('allowed') ? map['allowed'] == true : null;
    if (nested['permission'] == 'denied' ||
        map['permission'] == 'denied') {
      resolvedAllowed = false;
    }

    var allowed = false;
    if (httpStatusCode == 403 || resolvedAllowed == false) {
      allowed = false;
    } else if (resolvedAllowed == true) {
      allowed = true;
    } else if (quota?.premium == true && success) {
      allowed = true;
    } else if (quota != null && success) {
      allowed = success;
    } else if (success &&
        httpStatusCode != null &&
        httpStatusCode >= 200 &&
        httpStatusCode < 300) {
      allowed = true;
    }

    final message = _extractMessage(map) ?? _extractMessage(nested);

    return ChatFreemiumConsumeResult(
      allowed: allowed,
      success: success,
      message: message,
      quota: quota,
    );
  }

  static String? _extractMessage(Map<String, dynamic> map) {
    final dynamic m =
        map['message'] ?? map['error'] ?? map['detail'] ?? map['reason'];
    if (m == null) return null;
    final text = '$m'.trim();
    return text.isEmpty ? null : text;
  }
}

enum ChatFreemiumConsumeFeatureApi {
  translate,
  improveSentence,
  voiceTts;

  String get wireValue => switch (this) {
        ChatFreemiumConsumeFeatureApi.translate => 'translate',
        ChatFreemiumConsumeFeatureApi.improveSentence => 'improve_sentence',
        ChatFreemiumConsumeFeatureApi.voiceTts => 'voice_tts',
      };
}
