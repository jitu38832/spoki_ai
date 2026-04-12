import 'package:equatable/equatable.dart';
import 'package:spokiai/core/inworld_tts_voice_catalog.dart';

enum InworldTtsStatus { idle, loading, playing, error }

class InworldTtsState extends Equatable {
  const InworldTtsState({
    required this.status,
    required this.maleVoiceId,
    required this.femaleVoiceId,
    required this.partnerGender,
    required this.audioEnabled,
    required this.speedSlider,
    required this.temperatureSlider,
    required this.modelId,
    this.playbackId,
    this.errorMessage,
  });

  factory InworldTtsState.initial() => const InworldTtsState(
        status: InworldTtsStatus.idle,
        maleVoiceId: '',
        femaleVoiceId: '',
        partnerGender: 'Female',
        audioEnabled: true,
        speedSlider: 1.0,
        temperatureSlider: 1.0,
        modelId: '',
      );

  final InworldTtsStatus status;
  final String maleVoiceId;
  final String femaleVoiceId;
  final String partnerGender;
  final bool audioEnabled;
  /// Voice speed on UI scale 0…1.5 (slow → normal at 1 → fast).
  final double speedSlider;
  /// Voice temperature on UI scale 0…1.5 (normal at 1).
  final double temperatureSlider;
  final String modelId;
  final String? playbackId;
  final String? errorMessage;

  bool get isPartnerFemale =>
      partnerGender.toLowerCase().contains('female');

  String get effectiveVoiceId {
    if (isPartnerFemale) {
      if (femaleVoiceId.isNotEmpty &&
          isKnownInworldVoiceId(femaleVoiceId) &&
          isFemaleInworldVoiceId(femaleVoiceId)) {
        return femaleVoiceId;
      }
      return defaultInworldFemaleVoiceId;
    }
    if (maleVoiceId.isNotEmpty &&
        isKnownInworldVoiceId(maleVoiceId) &&
        isMaleInworldVoiceId(maleVoiceId)) {
      return maleVoiceId;
    }
    return defaultInworldMaleVoiceId;
  }

  bool isLoadingFor(String? id) =>
      status == InworldTtsStatus.loading && playbackId == id;

  bool isPlayingFor(String? id) =>
      status == InworldTtsStatus.playing && playbackId == id;

  InworldTtsState copyWith({
    InworldTtsStatus? status,
    String? maleVoiceId,
    String? femaleVoiceId,
    String? partnerGender,
    bool? audioEnabled,
    double? speedSlider,
    double? temperatureSlider,
    String? modelId,
    String? playbackId,
    String? errorMessage,
    bool clearPlaybackId = false,
    bool clearError = false,
  }) {
    return InworldTtsState(
      status: status ?? this.status,
      maleVoiceId: maleVoiceId ?? this.maleVoiceId,
      femaleVoiceId: femaleVoiceId ?? this.femaleVoiceId,
      partnerGender: partnerGender ?? this.partnerGender,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      speedSlider: speedSlider ?? this.speedSlider,
      temperatureSlider: temperatureSlider ?? this.temperatureSlider,
      modelId: modelId ?? this.modelId,
      playbackId: clearPlaybackId ? null : (playbackId ?? this.playbackId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        maleVoiceId,
        femaleVoiceId,
        partnerGender,
        audioEnabled,
        speedSlider,
        temperatureSlider,
        modelId,
        playbackId,
        errorMessage,
      ];
}
