class InworldTtsRequest {
  const InworldTtsRequest({
    required this.text,
    required this.voiceId,
    required this.modelId,
    this.speakingRate = 1.0,
    this.temperature = 1.0,
  });

  final String text;
  final String voiceId;
  final String modelId;
  /// Inworld `audioConfig.speakingRate`, typically [0.5, 1.5].
  final double speakingRate;
  /// Top-level `temperature` (API default 1.0).
  final double temperature;

  Map<String, dynamic> toJson() => {
        'text': text,
        'voiceId': voiceId,
        'modelId': modelId,
        'temperature': temperature,
        'audioConfig': {
          'speakingRate': speakingRate,
        },
      };
}

class InworldTtsResponse {
  const InworldTtsResponse({required this.audioContentBase64});

  final String audioContentBase64;

  factory InworldTtsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['audioContent'] ?? json['audio_content'];
    if (raw is! String || raw.trim().isEmpty) {
      throw FormatException('Missing or empty audioContent in TTS response');
    }
    return InworldTtsResponse(audioContentBase64: raw.trim());
  }
}
