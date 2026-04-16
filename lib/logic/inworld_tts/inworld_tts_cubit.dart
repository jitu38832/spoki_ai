import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokiai/core/config/inworld_tts_config.dart';
import 'package:spokiai/core/inworld_tts_audio_mapping.dart';
import 'package:spokiai/core/inworld_tts_voice_catalog.dart';
import 'package:spokiai/domain/repositories/inworld_tts_repository.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_state.dart';

/// Global Inworld TTS playback + voice settings (chat + story).
class InworldTtsCubit extends Cubit<InworldTtsState> {
  InworldTtsCubit(this._repository) : super(InworldTtsState.initial()) {
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: InworldTtsStatus.idle,
            clearPlaybackId: true,
            clearError: true,
          ),
        );
      }
    });
  }

  final InworldTtsRepository _repository;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completeSub;
  final Set<String> _prefetchKeysInProgress = <String>{};

  Future<void> loadPreferences() async {
    final male = await _repository.getMaleVoiceId();
    final female = await _repository.getFemaleVoiceId();
    final partner = await _repository.getPartnerGender();
    final audio = await _repository.getAudioEnabled();
    final speed = await _repository.getSpeedSlider();
    final temperature = await _repository.getTemperatureSlider();
    final model = await _repository.getSelectedModelId();
    emit(
      state.copyWith(
        maleVoiceId: male,
        femaleVoiceId: female,
        partnerGender: partner,
        audioEnabled: audio,
        speedSlider: speed,
        temperatureSlider: temperature,
        modelId: model,
        clearError: true,
      ),
    );
  }

  Future<void> setMaleVoice(String voiceId) async {
    final v = voiceId.trim();
    if (v.isEmpty || !isMaleInworldVoiceId(v)) return;
    await _repository.setMaleVoiceId(v);
    emit(state.copyWith(maleVoiceId: v, clearError: true));
  }

  Future<void> setFemaleVoice(String voiceId) async {
    final v = voiceId.trim();
    if (v.isEmpty || !isFemaleInworldVoiceId(v)) return;
    await _repository.setFemaleVoiceId(v);
    emit(state.copyWith(femaleVoiceId: v, clearError: true));
  }

  Future<void> setPartnerGender(String gender) async {
    final g = gender.trim().isEmpty ? 'Female' : gender.trim();
    await _repository.setPartnerGender(g);
    emit(state.copyWith(partnerGender: g, clearError: true));
  }

  Future<void> setAudioEnabled(bool enabled) async {
    await _repository.setAudioEnabled(enabled);
    emit(state.copyWith(audioEnabled: enabled, clearError: true));
    if (!enabled) {
      await _player.stop();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: InworldTtsStatus.idle,
            clearPlaybackId: true,
          ),
        );
      }
    }
  }

  Future<void> setSpeedSlider(double value) async {
    final v = value.clamp(0.0, 1.5);
    await _repository.setSpeedSlider(v);
    emit(state.copyWith(speedSlider: v, clearError: true));
  }

  Future<void> setTemperatureSlider(double value) async {
    final v = value.clamp(0.0, 1.5);
    await _repository.setTemperatureSlider(v);
    emit(state.copyWith(temperatureSlider: v, clearError: true));
  }

  Future<void> setModel(String modelId) async {
    final m = modelId.trim();
    if (m.isEmpty) return;
    await _repository.setSelectedModelId(m);
    emit(state.copyWith(modelId: m, clearError: true));
  }

  String _truncate(String text) {
    final t = text.trim();
    if (t.length <= InworldTtsConfig.maxTextLength) return t;
    return t.substring(0, InworldTtsConfig.maxTextLength);
  }

  List<String> _resolveVoiceIdsForPrefetch({
    String? prioritizeVoiceId,
    bool includeAllVoices = false,
  }) {
    final ordered = LinkedHashSet<String>();
    final p = prioritizeVoiceId?.trim();
    if (p != null && p.isNotEmpty && isKnownInworldVoiceId(p)) {
      ordered.add(p);
    }

    if (includeAllVoices) {
      for (final entry in allInworldTtsVoices) {
        ordered.add(entry.voiceId);
      }
      return ordered.toList(growable: false);
    }

    if (state.effectiveVoiceId.trim().isNotEmpty) {
      ordered.add(state.effectiveVoiceId.trim());
    }
    if (state.maleVoiceId.trim().isNotEmpty) {
      ordered.add(state.maleVoiceId.trim());
    }
    if (state.femaleVoiceId.trim().isNotEmpty) {
      ordered.add(state.femaleVoiceId.trim());
    }
    return ordered.toList(growable: false);
  }

  /// Warms the repository audio cache in background so first play is faster.
  Future<void> prefetchStoryAudio(
    String text, {
    String? prioritizeVoiceId,
    bool includeAllVoices = false,
  }) async {
    if (!InworldTtsConfig.hasCredentials) return;

    final t = _truncate(text);
    if (t.isEmpty) return;

    final modelId = state.modelId.isNotEmpty
        ? state.modelId
        : InworldTtsConfig.defaultModelId;
    final speakingRate = displaySpeedToSpeakingRate(state.speedSlider);
    final temperature = displayTemperatureToApi(state.temperatureSlider);
    final voiceIds = _resolveVoiceIdsForPrefetch(
      prioritizeVoiceId: prioritizeVoiceId,
      includeAllVoices: includeAllVoices,
    );
    if (voiceIds.isEmpty) return;

    for (final voiceId in voiceIds) {
      final key = [
        t,
        voiceId,
        modelId,
        speakingRate.toStringAsFixed(3),
        temperature.toStringAsFixed(3),
      ].join('||');
      if (_prefetchKeysInProgress.contains(key)) {
        continue;
      }
      _prefetchKeysInProgress.add(key);
      try {
        await _repository.synthesize(
          text: t,
          voiceId: voiceId,
          modelId: modelId,
          speakingRate: speakingRate,
          temperature: temperature,
        );
      } catch (_) {
        // Prefetch is best-effort. Runtime speak() will surface real errors.
      } finally {
        _prefetchKeysInProgress.remove(key);
      }
    }
  }

  /// [playbackId] — e.g. chat message id, or `'story'` for story screen.
  /// [voiceIdForPreview] — optional override for voice grid preview.
  Future<void> speak(
    String text, {
    String? playbackId,
    String? voiceIdForPreview,
  }) async {
    if (!state.audioEnabled) return;

    final t = _truncate(text);
    if (t.isEmpty) return;

    if (!InworldTtsConfig.hasCredentials) {
      emit(
        state.copyWith(
          status: InworldTtsStatus.error,
          playbackId: playbackId,
          errorMessage:
              'TTS API key missing. Set INWORLD_API_KEY when building the app.',
        ),
      );
      return;
    }

    await _player.stop();

    emit(
      state.copyWith(
        status: InworldTtsStatus.loading,
        playbackId: playbackId,
        clearError: true,
      ),
    );

    try {
      final voiceId = () {
        final o = voiceIdForPreview?.trim();
        if (o != null && o.isNotEmpty && isKnownInworldVoiceId(o)) {
          return o;
        }
        return state.effectiveVoiceId;
      }();
      final modelId = state.modelId.isNotEmpty
          ? state.modelId
          : InworldTtsConfig.defaultModelId;

      final speakingRate = displaySpeedToSpeakingRate(state.speedSlider);
      final temperature = displayTemperatureToApi(state.temperatureSlider);

      final bytes = await _repository.synthesize(
        text: t,
        voiceId: voiceId,
        modelId: modelId,
        speakingRate: speakingRate,
        temperature: temperature,
      );

      emit(
        state.copyWith(
          status: InworldTtsStatus.playing,
          playbackId: playbackId,
          clearError: true,
        ),
      );

      await _player.setPlaybackRate(1.0);
      await _player.play(BytesSource(bytes));
    } catch (e, st) {
      // ignore: avoid_print
      print('InworldTtsCubit.speak error: $e\n$st');
      emit(
        state.copyWith(
          status: InworldTtsStatus.error,
          playbackId: playbackId,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> stop() async {
    await _player.stop();
    if (!isClosed) {
      emit(
        state.copyWith(
          status: InworldTtsStatus.idle,
          clearPlaybackId: true,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _completeSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}
