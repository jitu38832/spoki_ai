import 'dart:typed_data';

abstract class InworldTtsRepository {
  Future<Uint8List> synthesize({
    required String text,
    required String voiceId,
    required String modelId,
    required double speakingRate,
    required double temperature,
  });

  Future<String> getMaleVoiceId();
  Future<void> setMaleVoiceId(String voiceId);

  Future<String> getFemaleVoiceId();
  Future<void> setFemaleVoiceId(String voiceId);

  Future<String> getPartnerGender();
  Future<void> setPartnerGender(String gender);

  Future<bool> getAudioEnabled();
  Future<void> setAudioEnabled(bool enabled);

  Future<double> getSpeedSlider();
  Future<void> setSpeedSlider(double value);

  Future<double> getTemperatureSlider();
  Future<void> setTemperatureSlider(double value);

  Future<String> getSelectedModelId();
  Future<void> setSelectedModelId(String modelId);
}
