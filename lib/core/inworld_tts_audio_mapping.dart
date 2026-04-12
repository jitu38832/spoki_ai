// Maps Voice Settings UI values (0…1.5, normal at 1) to Inworld TTS API.

/// Display speed 0 = slow, 1 = normal, 1.5 = fast → `audioConfig.speakingRate` in [0.5, 1.5].
double displaySpeedToSpeakingRate(double display) {
  final d = display.clamp(0.0, 1.5);
  if (d <= 1.0) {
    return 0.5 + 0.5 * d;
  }
  return 1.0 + (d - 1.0);
}

/// Display temperature 0…1.5 (normal at 1) → API `temperature` in (0, 2].
double displayTemperatureToApi(double display) {
  final d = display.clamp(0.0, 1.5);
  if (d <= 1.0) {
    return 0.1 + 0.9 * d;
  }
  return 1.0 + (d - 1.0) * 2.0;
}

String speedBandLabel(double display) {
  final d = display.clamp(0.0, 1.5);
  if (d < 0.85) return 'Slow';
  if (d < 1.15) return 'Normal';
  return 'Fast';
}

String temperatureBandLabel(double display) {
  final d = display.clamp(0.0, 1.5);
  if (d < 0.85) return 'Low';
  if (d < 1.15) return 'Balanced';
  return 'High';
}

/// Legacy slider was 0…1 with “normal” at 0.5 → new display 0…1.5 with normal at 1.
double migrateLegacySpeedSlider01(double legacy) {
  final v = legacy.clamp(0.0, 1.0);
  if (v <= 0.5) {
    return 2.0 * v;
  }
  return 1.0 + (v - 0.5);
}
