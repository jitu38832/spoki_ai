import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:spokiai/core/inworld_secrets.dart';

/// Inworld TTS API configuration.
///
/// **Secrets (runtime):** Loads in this order:
/// 1. Compile-time `--dart-define=INWORLD_API_KEY=...` or `--dart-define-from-file=secrets.json`
/// 2. Project-root `secrets.json` (gitignored) when running on platforms with `dart:io`
/// 3. Bundled `assets/secrets.json` (needed for release mobile builds — copy from root before build)
///
/// Header format: `Authorization: Basic <credential>` where the key is either the full
/// `Basic …` value or the token to place after `Basic `.
class InworldTtsConfig {
  InworldTtsConfig._();

  static const String baseUrl = 'https://api.inworld.ai';
  static const String ttsPath = '/tts/v1/voice';

  static const String defaultVoiceId = 'Jason';
  static const String defaultModelId = 'inworld-tts-1.5-max';
  static const String chatModelId = defaultModelId;
  static const String storyModelId = 'inworld-tts-1.5-mini';
  static const int maxTextLength = 4000;

  static const String _compileTimeKey = String.fromEnvironment(
    'INWORLD_API_KEY',
    defaultValue: '',
  );

  static String _resolvedKey = '';

  /// Call from [main] before [runApp] so TTS sees the key from JSON assets / disk.
  static Future<void> loadSecrets() async {
    if (_compileTimeKey.trim().isNotEmpty) {
      _resolvedKey = _compileTimeKey.trim();
      return;
    }

    if (!kIsWeb) {
      final fromFile = await loadInworldKeyFromRootFile();
      if (fromFile != null && fromFile.isNotEmpty) {
        _resolvedKey = fromFile.trim();
        return;
      }
    }

    try {
      final raw = await rootBundle.loadString('assets/secrets.json');
      final j = jsonDecode(raw);
      if (j is Map<String, dynamic>) {
        final k = j['INWORLD_API_KEY']?.toString().trim() ?? '';
        if (k.isNotEmpty) {
          _resolvedKey = k;
          return;
        }
      }
    } catch (_) {}
  }

  static String get apiKeyFromEnv => _resolvedKey;

  static bool get hasCredentials => apiKeyFromEnv.trim().isNotEmpty;

  static String get authorizationHeaderValue {
    final k = apiKeyFromEnv.trim();
    if (k.isEmpty) return '';
    if (k.toLowerCase().startsWith('basic ')) return k;
    return 'Basic $k';
  }
}
