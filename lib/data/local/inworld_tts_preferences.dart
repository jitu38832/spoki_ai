import 'package:shared_preferences/shared_preferences.dart';
import 'package:spokiai/core/config/inworld_tts_config.dart';
import 'package:spokiai/core/inworld_tts_audio_mapping.dart';
import 'package:spokiai/core/inworld_tts_voice_catalog.dart';

/// Persists Inworld TTS options: per-gender voices, partner gender, audio on/off, speed.
abstract class InworldTtsPreferences {
  Future<String> getMaleVoiceId();
  Future<void> setMaleVoiceId(String voiceId);

  Future<String> getFemaleVoiceId();
  Future<void> setFemaleVoiceId(String voiceId);

  Future<String> getPartnerGender();
  Future<void> setPartnerGender(String gender);

  Future<bool> getAudioEnabled();
  Future<void> setAudioEnabled(bool enabled);

  /// Voice Settings: 0 = slow, 1 = normal, 1.5 = fast.
  Future<double> getSpeedSlider();
  Future<void> setSpeedSlider(double value);

  /// Voice Settings: 0…1.5 (normal at 1), maps to API temperature.
  Future<double> getTemperatureSlider();
  Future<void> setTemperatureSlider(double value);

  Future<String> getModelId();
  Future<void> setModelId(String modelId);
}

class InworldTtsPreferencesImpl implements InworldTtsPreferences {
  static const _maleKey = 'inworld_tts_male_voice_id';
  static const _femaleKey = 'inworld_tts_female_voice_id';
  static const _legacyVoiceKey = 'inworld_tts_voice_id';
  static const _partnerGenderKey = 'inworld_tts_partner_gender';
  static const _audioEnabledKey = 'inworld_tts_audio_enabled';
  static const _speedDisplayKey = 'inworld_tts_speed_display';
  static const _legacySpeedKey = 'inworld_tts_speed_slider';
  static const _temperatureKey = 'inworld_tts_temperature_display';
  static const _modelKey = 'inworld_tts_model_id';

  Future<void> _migrateLegacyIfNeeded(SharedPreferences p) async {
    if (p.getString(_maleKey) != null || p.getString(_femaleKey) != null) {
      return;
    }
    final legacy = p.getString(_legacyVoiceKey)?.trim();
    if (legacy == null || legacy.isEmpty || !isKnownInworldVoiceId(legacy)) {
      return;
    }
    if (isMaleInworldVoiceId(legacy)) {
      await p.setString(_maleKey, legacy);
    } else if (isFemaleInworldVoiceId(legacy)) {
      await p.setString(_femaleKey, legacy);
    }
  }

  @override
  Future<String> getMaleVoiceId() async {
    final p = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(p);
    final s = p.getString(_maleKey)?.trim();
    if (s != null &&
        s.isNotEmpty &&
        isKnownInworldVoiceId(s) &&
        isMaleInworldVoiceId(s)) {
      return s;
    }
    return defaultInworldMaleVoiceId;
  }

  @override
  Future<void> setMaleVoiceId(String voiceId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_maleKey, voiceId.trim());
  }

  @override
  Future<String> getFemaleVoiceId() async {
    final p = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(p);
    final s = p.getString(_femaleKey)?.trim();
    if (s != null &&
        s.isNotEmpty &&
        isKnownInworldVoiceId(s) &&
        isFemaleInworldVoiceId(s)) {
      return s;
    }
    return defaultInworldFemaleVoiceId;
  }

  @override
  Future<void> setFemaleVoiceId(String voiceId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_femaleKey, voiceId.trim());
  }

  @override
  Future<String> getPartnerGender() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_partnerGenderKey)?.trim();
    if (s != null && s.isNotEmpty) return s;
    return 'Female';
  }

  @override
  Future<void> setPartnerGender(String gender) async {
    final p = await SharedPreferences.getInstance();
    final g = gender.trim().isEmpty ? 'Female' : gender.trim();
    await p.setString(_partnerGenderKey, g);
  }

  @override
  Future<bool> getAudioEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_audioEnabledKey) ?? true;
  }

  @override
  Future<void> setAudioEnabled(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_audioEnabledKey, enabled);
  }

  @override
  Future<double> getSpeedSlider() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getDouble(_speedDisplayKey);
    if (v != null) return v.clamp(0.0, 1.5);
    final legacy = p.getDouble(_legacySpeedKey);
    if (legacy != null) {
      final m = migrateLegacySpeedSlider01(legacy);
      await p.setDouble(_speedDisplayKey, m);
      return m;
    }
    return 1.0;
  }

  @override
  Future<void> setSpeedSlider(double value) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_speedDisplayKey, value.clamp(0.0, 1.5));
  }

  @override
  Future<double> getTemperatureSlider() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getDouble(_temperatureKey);
    if (v == null) return 1.0;
    return v.clamp(0.0, 1.5);
  }

  @override
  Future<void> setTemperatureSlider(double value) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_temperatureKey, value.clamp(0.0, 1.5));
  }

  @override
  Future<String> getModelId() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_modelKey)?.trim();
    if (s != null && s.isNotEmpty) return s;
    return InworldTtsConfig.defaultModelId;
  }

  @override
  Future<void> setModelId(String modelId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_modelKey, modelId.trim());
  }
}
