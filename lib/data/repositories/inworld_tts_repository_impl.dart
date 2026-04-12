import 'dart:typed_data';

import 'package:spokiai/data/local/inworld_tts_preferences.dart';
import 'package:spokiai/data/models/inworld_tts_models.dart';
import 'package:spokiai/data/sources/inworld_tts_remote_data_source.dart';
import 'package:spokiai/domain/repositories/inworld_tts_repository.dart';

class InworldTtsRepositoryImpl implements InworldTtsRepository {
  InworldTtsRepositoryImpl({
    required InworldTtsRemoteDataSource remoteDataSource,
    required InworldTtsPreferences preferences,
  })  : _remote = remoteDataSource,
        _prefs = preferences;

  final InworldTtsRemoteDataSource _remote;
  final InworldTtsPreferences _prefs;

  @override
  Future<Uint8List> synthesize({
    required String text,
    required String voiceId,
    required String modelId,
    required double speakingRate,
    required double temperature,
  }) =>
      _remote.synthesize(
        InworldTtsRequest(
          text: text,
          voiceId: voiceId,
          modelId: modelId,
          speakingRate: speakingRate,
          temperature: temperature,
        ),
      );

  @override
  Future<String> getMaleVoiceId() => _prefs.getMaleVoiceId();

  @override
  Future<void> setMaleVoiceId(String voiceId) =>
      _prefs.setMaleVoiceId(voiceId);

  @override
  Future<String> getFemaleVoiceId() => _prefs.getFemaleVoiceId();

  @override
  Future<void> setFemaleVoiceId(String voiceId) =>
      _prefs.setFemaleVoiceId(voiceId);

  @override
  Future<String> getPartnerGender() => _prefs.getPartnerGender();

  @override
  Future<void> setPartnerGender(String gender) =>
      _prefs.setPartnerGender(gender);

  @override
  Future<bool> getAudioEnabled() => _prefs.getAudioEnabled();

  @override
  Future<void> setAudioEnabled(bool enabled) =>
      _prefs.setAudioEnabled(enabled);

  @override
  Future<double> getSpeedSlider() => _prefs.getSpeedSlider();

  @override
  Future<void> setSpeedSlider(double value) =>
      _prefs.setSpeedSlider(value);

  @override
  Future<double> getTemperatureSlider() => _prefs.getTemperatureSlider();

  @override
  Future<void> setTemperatureSlider(double value) =>
      _prefs.setTemperatureSlider(value);

  @override
  Future<String> getSelectedModelId() => _prefs.getModelId();

  @override
  Future<void> setSelectedModelId(String modelId) =>
      _prefs.setModelId(modelId);
}
