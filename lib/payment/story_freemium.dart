import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:spokiai/model/story_freemium_quota.dart';
import 'package:spokiai/payment/SubscriptionScreen.dart';
import 'package:spokiai/payment/chat_freemium.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/repository/app_repository.dart';

/// Story / quiz aloud / gated generation — quotas from `users/me/story-freemium`; premium aligns with [ChatFreemium].
class StoryFreemium {
  StoryFreemium._();

  static const int freeUsesDefault = 2;

  /// Genres permitted on the free tier (short stories only — server authoritative).
  static const Set<String> _freeGenreSlugs = {
    'adventure',
    'science fiction',
    'sciencefiction',
    'sci-fi',
    'sci fi',
    'scifi',
    'mystery',
    'drama',
    'historical',
  };

  /// Fallback when quota API unreachable: JSON map `{ playback_key → start count }`.
  static const String _keyTtsStartsByPlayback = 'story_freemium_tts_starts_json';

  static StoryFreemiumQuota? _serverQuota;
  static bool _usingLocalFallback = true;

  static Future<bool> syncFromBackend(AppRepository repo, String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      _usingLocalFallback = true;
      _serverQuota = null;
      return false;
    }
    try {
      _serverQuota = await repo.getStoryFreemiumQuota(trimmed);
      _usingLocalFallback = false;
      return true;
    } catch (e, st) {
      developer.log('story freemium: sync failed → $e',
          name: 'StoryFreemium', stackTrace: st);
      _usingLocalFallback = true;
      _serverQuota = null;
      return false;
    }
  }

  static bool get _hasQuotaFromApi => !_usingLocalFallback && _serverQuota != null;

  static bool _premium() =>
      ChatFreemium.isPremiumUnlocked() ||
      (_hasQuotaFromApi && _serverQuota!.premium);

  static String normalizeGenreSlug(String raw) {
    var s = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final compact = s.replaceAll(RegExp(r'[\s_-]'), '');
    if (compact == 'sciencefiction' ||
        compact == 'scifi' ||
        (s.contains('sci') &&
            (s.contains('fi') || compact.contains('scifi')))) {
      return 'science fiction';
    }
    return s;
  }

  static bool isFreeGenre(String genre) =>
      _freeGenreSlugs.contains(normalizeGenreSlug(genre));

  static Map<String, int> _readLocalTtsStartsMap() {
    final raw =
        PreferenceManager.getStringValue(key: _keyTtsStartsByPlayback)?.trim();
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, int>{};
      decoded.forEach((k, v) {
        final key = '$k'.trim();
        if (key.isEmpty) return;
        final n = v is int ? v : int.tryParse('$v') ?? 0;
        if (n > 0) out[key] = n.clamp(0, 99999);
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  static int _localStartsForPlayback(String playbackKey) {
    final k = playbackKey.trim();
    if (k.isEmpty) return 99999;
    return _readLocalTtsStartsMap()[k] ?? 0;
  }

  static void _persistLocalTtsStartsMap(Map<String, int> map) {
    PreferenceManager.insertValue(
      key: _keyTtsStartsByPlayback,
      value: jsonEncode(map),
    );
  }

  /// Non‑premium: allowed when [genre] is in the free set and length is **short** (server enforces too).
  static bool canGenerateShortFreeGenreStory({
    required String genre,
    required String storyLengthLower,
  }) {
    if (_premium()) return true;
    return isFreeGenre(genre) && storyLengthLower == 'short';
  }

  static String? blockingReasonForStoryGenerate({
    required String genre,
    required String storyLengthLower,
  }) {
    if (_premium()) return null;
    if (!isFreeGenre(genre)) {
      return 'This genre requires Premium.';
    }
    if (storyLengthLower != 'short') {
      return 'Medium and long stories require Premium.';
    }
    return null;
  }

  /// Free tier allows [freeUsesDefault] listen-aloud **starts per** [playbackKey] when metering locally.
  static bool canStartStoryTtsPlayback(String playbackKey) {
    if (_premium()) return true;
    final k = playbackKey.trim();
    if (_hasQuotaFromApi) return true;
    if (k.isEmpty) return false;
    return _localStartsForPlayback(k) < freeUsesDefault;
  }

  /// Reserves one story listen toward [playbackKey] (`story:<id>`). Server caps starts per key.
  static Future<bool> consumeStoryTtsPlayback({
    required AppRepository repo,
    required String token,
    required String playbackKey,
    void Function(String message)? onToast,
  }) async {
    if (_premium()) return true;
    final trimmed = token.trim();
    final pb = playbackKey.trim();
    if (trimmed.isEmpty) {
      onToast?.call('Sign in to use story audio.');
      return false;
    }
    if (pb.isEmpty) {
      onToast?.call('Story audio is unavailable for this story.');
      return false;
    }
    if (_usingLocalFallback || _serverQuota == null) {
      if (!canStartStoryTtsPlayback(pb)) {
        onToast?.call(
            'Free tier allows $freeUsesDefault listen-aloud starts per story. Subscribe for Premium audio.');
        return false;
      }
      final map = {..._readLocalTtsStartsMap()};
      map[pb] = (map[pb] ?? 0) + 1;
      _persistLocalTtsStartsMap(map);
      return true;
    }

    final r = await repo.consumeStoryFreemium(
      trimmed,
      feature: 'story_tts',
      playbackKey: pb,
    );
    if (r.quota != null) _serverQuota = r.quota;
    if (r.allowed) return true;
    final msg = r.message?.trim().isNotEmpty == true
        ? r.message!
        : 'Could not start audio for this story.';
    onToast?.call(msg);
    return false;
  }

  static void promptSubscribe(
    BuildContext context, {
    required String message,
    VoidCallback? onReturn,
  }) {
    if (!context.mounted) return;
    showToast(context: context, message: message);
    Navigator.of(context)
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const SubscriptionScreen(),
      ),
    )
        .then((_) {
      if (context.mounted) onReturn?.call();
    });
  }

  static void resetVolatileState() {
    _serverQuota = null;
    _usingLocalFallback = true;
  }
}
