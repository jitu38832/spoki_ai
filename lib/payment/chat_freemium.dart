import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:spokiai/model/chat_freemium_quota.dart';
import 'package:spokiai/payment/SubscriptionScreen.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/repository/app_repository.dart';

/// Outcome after consuming (or reserving) one free-tier chat unit from the backend.
class ChatFreemiumGateResult {
  const ChatFreemiumGateResult.consumed()
      : consumed = true,
        shouldPromptSubscribe = false,
        toastMessage = null;

  const ChatFreemiumGateResult.blockedPaywall({this.toastMessage})
      : consumed = false,
        shouldPromptSubscribe = true;

  const ChatFreemiumGateResult.blockedTransient({this.toastMessage})
      : consumed = false,
        shouldPromptSubscribe = false;

  final bool consumed;
  final bool shouldPromptSubscribe;
  final String? toastMessage;
}

/// Free-tier limits for chat-only features — **premium for chat/UI is strictly from the quota API**
/// (`GET users/me/chat-freemium` → `data.premium`). Local `premium_subscribed` is not trusted here
/// (IAP restores are device-global and bypass account binding). Fallback mode uses persisted counters
/// only when the quota API fails.
class ChatFreemium {
  ChatFreemium._();

  static const int freeUsesPerFeature = 2;

  static const String keyTranslateUses = 'chat_freemium_translate_uses';
  static const String keyImproveUses = 'chat_freemium_improve_sentence_uses';
  static const String keyVoiceUses = 'chat_freemium_voice_tts_uses';

  static ChatFreemiumQuota? _serverQuota;

  /// When true, metering uses SharedPreferences mirrors of the counters (development / no API yet).
  static bool _usingLocalFallback = true;

  /// Load current limits from backend. Safe to await from Chat open or after IAP returns.
  static Future<bool> syncFromBackend(AppRepository repo, String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      _usingLocalFallback = true;
      _serverQuota = null;
      return false;
    }
    try {
      final q = await repo.getChatFreemiumQuota(trimmed);
      _serverQuota = q;
      _usingLocalFallback = false;
      return true;
    } catch (e, st) {
      developer.log(
        'chat freemium: sync failed, using prefs fallback → $e',
        name: 'ChatFreemium',
        stackTrace: st,
      );
      _usingLocalFallback = true;
      _serverQuota = null;
      return false;
    }
  }

  /// Backend-only entitlement for chat metering (persisted quotas + subscription on server).
  static bool get _hasAuthoritativeQuotaFromApi =>
      !_usingLocalFallback && _serverQuota != null;

  static bool isPremiumUnlocked() =>
      _hasAuthoritativeQuotaFromApi && (_serverQuota!.premium == true);

  static int _usesPrefs(String key) =>
      PreferenceManager.getIntegerValue(key: key) ?? 0;

  static int translateUses() {
    if (!_usingLocalFallback && _serverQuota != null) {
      return _serverQuota!.translateUsed;
    }
    return _usesPrefs(keyTranslateUses);
  }

  static int improveUses() {
    if (!_usingLocalFallback && _serverQuota != null) {
      return _serverQuota!.improveSentenceUsed;
    }
    return _usesPrefs(keyImproveUses);
  }

  static int voiceTtsUses() {
    if (!_usingLocalFallback && _serverQuota != null) {
      return _serverQuota!.voiceTtsUsed;
    }
    return _usesPrefs(keyVoiceUses);
  }

  static bool _underLimit(int used, int limit) => used < limit;

  static bool canUseTranslate() =>
      isPremiumUnlocked() || _underLimit(translateUses(), quotaTranslateLimit());

  static bool canUseImproveSentence() =>
      isPremiumUnlocked() ||
      _underLimit(improveUses(), quotaImproveSentenceLimit());

  /// True when aloud playback is allowed. `voice_tts` counts **successful chat voice switches**
  /// committed in Voice Settings (not individual message playbacks).
  static bool canStartChatVoicePlayback() =>
      isPremiumUnlocked() ||
      _underLimit(voiceTtsUses(), quotaVoiceTtsLimit());

  static bool showChatVoiceUi() => canStartChatVoicePlayback();

  /// Effective free tier cap for translate — server may override defaults.
  static int quotaTranslateLimit() {
    final q = _serverQuota;
    if (!_usingLocalFallback && q != null && q.translateLimit > 0) {
      return q.translateLimit;
    }
    return freeUsesPerFeature;
  }

  static int quotaImproveSentenceLimit() {
    final q = _serverQuota;
    if (!_usingLocalFallback && q != null && q.improveSentenceLimit > 0) {
      return q.improveSentenceLimit;
    }
    return freeUsesPerFeature;
  }

  static int quotaVoiceTtsLimit() {
    final q = _serverQuota;
    if (!_usingLocalFallback && q != null && q.voiceTtsLimit > 0) {
      return q.voiceTtsLimit;
    }
    return freeUsesPerFeature;
  }

  static void recordTranslateSuccess() {
    if (isPremiumUnlocked()) return;
    final n = translateUses() + 1;
    PreferenceManager.insertValue(key: keyTranslateUses, value: n);
  }

  /// When quota GET fails (`_usingLocalFallback`), approximate Improve Sentence use so the UI stays
  /// consistent until `syncFromBackend` works; authoritative count is always on Mongo via socket consume.
  static void recordImproveSentenceLocalFallbackMirror() {
    if (isPremiumUnlocked()) return;
    if (!_usingLocalFallback) return;
    final n = (_usesPrefs(keyImproveUses)) + 1;
    PreferenceManager.insertValue(key: keyImproveUses, value: n);
  }

  /// Fallback mirror when quotas API unavailable — increments on each **successful** consume for
  /// chat voice persona switch (same counter as backend `voice_tts`).
  static void recordVoicePlaybackStart() {
    if (isPremiumUnlocked()) return;
    final n = voiceTtsUses() + 1;
    PreferenceManager.insertValue(key: keyVoiceUses, value: n);
  }

  static ChatFreemiumGateResult _mapConsumeFailure(
      ChatFreemiumConsumeResult r) {
    final raw = r.message?.trim() ?? '';
    final msgLower = raw.toLowerCase();
    final looksTransient =
        raw.isEmpty ||
            msgLower.contains('could not verify') ||
            msgLower.contains('could not load') ||
            msgLower.contains('try again') ||
            msgLower.contains('timeout') ||
            msgLower.contains('network');
    if (looksTransient) {
      return ChatFreemiumGateResult.blockedTransient(
        toastMessage: raw.isNotEmpty ? r.message : 'Could not verify limits. Try again.',
      );
    }
    return ChatFreemiumGateResult.blockedPaywall(
      toastMessage: raw.isNotEmpty ? r.message : 'Subscribe for unlimited use.',
    );
  }

  /// Reserves one translate use on the server (or increments local prefs when in fallback mode).
  static Future<ChatFreemiumGateResult> consumeTranslate(
      AppRepository repo, String token) async {
    if (isPremiumUnlocked()) return const ChatFreemiumGateResult.consumed();

    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return const ChatFreemiumGateResult.blockedTransient(
          toastMessage: 'Sign in to save your usage.');
    }

    if (_usingLocalFallback || _serverQuota == null) {
      if (!canUseTranslate()) {
        return ChatFreemiumGateResult.blockedPaywall(
            toastMessage:
                'You used your $freeUsesPerFeature free translations.');
      }
      recordTranslateSuccess();
      return const ChatFreemiumGateResult.consumed();
    }

    final r =
        await repo.consumeChatFreemium(trimmed, ChatFreemiumConsumeFeatureApi.translate);
    if (r.quota != null) _serverQuota = r.quota;
    if (r.allowed) return const ChatFreemiumGateResult.consumed();
    return _mapConsumeFailure(r);
  }

  /// One unit per **successful switch** from the Voice Settings sheet (chat) to a persona that
  /// differs from the current [`InworldTtsState.effectiveVoiceId`]. Playback does **not** call this.
  static Future<ChatFreemiumGateResult> consumeVoiceTts(AppRepository repo, String token) async {
    if (isPremiumUnlocked()) return const ChatFreemiumGateResult.consumed();

    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return const ChatFreemiumGateResult.blockedTransient(
          toastMessage: 'Sign in to save your usage.');
    }

    if (_usingLocalFallback || _serverQuota == null) {
      if (!canStartChatVoicePlayback()) {
        return ChatFreemiumGateResult.blockedPaywall(
            toastMessage:
                'You used $freeUsesPerFeature free AI voice selections. Subscribe to pick another voice.',
        );
      }
      recordVoicePlaybackStart();
      return const ChatFreemiumGateResult.consumed();
    }

    final r =
        await repo.consumeChatFreemium(trimmed, ChatFreemiumConsumeFeatureApi.voiceTts);
    if (r.quota != null) _serverQuota = r.quota;
    if (r.allowed) return const ChatFreemiumGateResult.consumed();
    return _mapConsumeFailure(r);
  }

  static void promptSubscribe(
    BuildContext context, {
    required String message,
    VoidCallback? onReturnFromSubscription,
  }) {
    if (!context.mounted) return;
    showToast(context: context, message: message);
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => const SubscriptionScreen(),
      ),
    )
        .then((_) {
      if (context.mounted) onReturnFromSubscription?.call();
    });
  }

  /// After sign-out clears prefs, metering state is dropped — next login re-sync is required.
  static void resetVolatileState() {
    _serverQuota = null;
    _usingLocalFallback = true;
  }
}
