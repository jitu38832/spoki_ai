/// Inworld TTS `voice_id` values and UI labels (from product spec).
class InworldTtsVoiceEntry {
  const InworldTtsVoiceEntry({
    required this.voiceId,
    required this.displayName,
    this.subtitle = '',
    this.isDefault = false,
  });

  final String voiceId;
  final String displayName;
  final String subtitle;
  final bool isDefault;
}

/// Male voices (Inworld).
const List<InworldTtsVoiceEntry> kInworldMaleVoices = [
  InworldTtsVoiceEntry(
    voiceId: 'Jason',
    displayName: 'Jason',
    subtitle: 'Clear & Natural',
    isDefault: true,
  ),
  InworldTtsVoiceEntry(
    voiceId: 'Jonah',
    displayName: 'Jonah',
    subtitle: 'Deep & Confident',
  ),
  InworldTtsVoiceEntry(
    voiceId: 'Duncan',
    displayName: 'Duncan',
    subtitle: 'Warm & Steady',
  ),
  InworldTtsVoiceEntry(
    voiceId: 'Arjun',
    displayName: 'Arjun',
    subtitle: 'Friendly & Casual',
  ),
];

/// Female voices (Inworld).
const List<InworldTtsVoiceEntry> kInworldFemaleVoices = [
  InworldTtsVoiceEntry(
    voiceId: 'Loretta',
    displayName: 'Loretta',
    subtitle: 'Smooth & Expressive',
  ),
  InworldTtsVoiceEntry(
    voiceId: 'Nadia',
    displayName: 'Nadia',
    subtitle: 'Clear & Natural',
    isDefault: true,
  ),
  InworldTtsVoiceEntry(
    voiceId: 'Eleanor',
    displayName: 'Eleanor',
    subtitle: 'Soft & Clear',
  ),
  InworldTtsVoiceEntry(
    voiceId: 'Anjali',
    displayName: 'Anjali',
    subtitle: 'Bright & Friendly',
  ),
];

List<InworldTtsVoiceEntry> get allInworldTtsVoices => [
      ...kInworldMaleVoices,
      ...kInworldFemaleVoices,
    ];

bool isKnownInworldVoiceId(String id) {
  final t = id.trim();
  return allInworldTtsVoices.any((e) => e.voiceId == t);
}

bool isMaleInworldVoiceId(String id) {
  final t = id.trim();
  return kInworldMaleVoices.any((e) => e.voiceId == t);
}

bool isFemaleInworldVoiceId(String id) {
  final t = id.trim();
  return kInworldFemaleVoices.any((e) => e.voiceId == t);
}

String get defaultInworldMaleVoiceId =>
    kInworldMaleVoices.firstWhere((e) => e.isDefault).voiceId;

String get defaultInworldFemaleVoiceId =>
    kInworldFemaleVoices.firstWhere((e) => e.isDefault).voiceId;
