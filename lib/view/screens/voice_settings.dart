import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/core/inworld_tts_voice_catalog.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_cubit.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_state.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import '../utils/colors.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({
    super.key,
    this.fromStory = false,
  });

  final bool fromStory;

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  static const String _previewPlaybackId = '__voice_preview__';
  /// Legacy local Flutter-TTS row (removed); migrate prefs to Inworld.
  static const String _legacyLocalStoryVoiceId = '__sofy_local_tts__';
  static const String _selectedVoicePrefKey =
      'voice_settings_selected_voice_id';
  String? _previewingVoiceId;
  bool _initialSlidersSet = false;
  bool _storyDefaultApplied = false;
  String? _singleSelectedVoiceId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialSlidersSet) return;
    _initialSlidersSet = true;
    final cubit = context.read<InworldTtsCubit>();
    unawaited(cubit.setSpeedSlider(1.0));
    unawaited(cubit.setTemperatureSlider(1.0));
    final saved =
        PreferenceManager.getStringValue(key: _selectedVoicePrefKey)?.trim();
    if (saved != null && saved.isNotEmpty) {
      if (saved == _legacyLocalStoryVoiceId) {
        _singleSelectedVoiceId = cubit.state.effectiveVoiceId;
        PreferenceManager.insertValue(
          key: _selectedVoicePrefKey,
          value: _singleSelectedVoiceId!,
        );
      } else {
        _singleSelectedVoiceId = saved;
      }
    } else {
      _singleSelectedVoiceId = cubit.state.effectiveVoiceId;
    }
    if (widget.fromStory && !_storyDefaultApplied) {
      _storyDefaultApplied = true;
      if (_singleSelectedVoiceId == null || _singleSelectedVoiceId!.isEmpty) {
        _singleSelectedVoiceId = cubit.state.effectiveVoiceId;
      }
    }

    // Chat screen: enforce gender-consistent default voice selection.
    if (!widget.fromStory) {
      final isFemale = cubit.state.isPartnerFemale;
      final selected = _singleSelectedVoiceId?.trim();
      final validForGender = selected != null &&
          selected.isNotEmpty &&
          ((isFemale && isFemaleInworldVoiceId(selected)) ||
              (!isFemale && isMaleInworldVoiceId(selected)));
      if (!validForGender) {
        _singleSelectedVoiceId =
            isFemale ? defaultInworldFemaleVoiceId : defaultInworldMaleVoiceId;
      }
    }
  }

  String _previewTextFor(String voiceName) {
    return 'Hi, I am $voiceName. How may I help you?';
  }

  bool _isPreviewPlayingFor({
    required InworldTtsState state,
    required String voiceId,
  }) {
    final samePlayback = state.playbackId == _previewPlaybackId;
    return samePlayback &&
        state.status == InworldTtsStatus.playing &&
        _previewingVoiceId == voiceId;
  }

  bool _isPreviewLoadingFor({
    required InworldTtsState state,
    required String voiceId,
  }) {
    final samePlayback = state.playbackId == _previewPlaybackId;
    return samePlayback &&
        state.status == InworldTtsStatus.loading &&
        _previewingVoiceId == voiceId;
  }

  Future<void> _togglePreview(
    InworldTtsVoiceEntry entry,
    InworldTtsState state,
  ) async {
    final cubit = context.read<InworldTtsCubit>();
    if (!cubit.state.audioEnabled) return;
    final isSameVoicePlaying = _isPreviewPlayingFor(
      state: state,
      voiceId: entry.voiceId,
    );

    if (isSameVoicePlaying) {
      await cubit.stop();
      if (mounted) {
        setState(() => _previewingVoiceId = null);
      }
      return;
    }

    if (mounted) {
      setState(() => _previewingVoiceId = entry.voiceId);
    }
    await cubit.speak(
      _previewTextFor(entry.displayName),
      playbackId: _previewPlaybackId,
      voiceIdForPreview: entry.voiceId,
    );
  }

  String _resolveActiveSelectedVoiceId(
    InworldTtsState state,
    String selectedMale,
    String selectedFemale,
  ) {
    final pinned = _singleSelectedVoiceId?.trim();
    if (pinned != null && pinned.isNotEmpty) {
      if (pinned == _legacyLocalStoryVoiceId) {
        return state.isPartnerFemale ? selectedFemale : selectedMale;
      }
      if (widget.fromStory) {
        if (isKnownInworldVoiceId(pinned)) return pinned;
      } else {
        if (state.isPartnerFemale && isFemaleInworldVoiceId(pinned)) {
          return pinned;
        }
        if (!state.isPartnerFemale && isMaleInworldVoiceId(pinned)) {
          return pinned;
        }
      }
    }
    return state.isPartnerFemale ? selectedFemale : selectedMale;
  }

  Future<void> _commitSelectionAndClose(String voiceId) async {
    final cubit = context.read<InworldTtsCubit>();
    await cubit.stop();

    if (isMaleInworldVoiceId(voiceId)) {
      await cubit.setMaleVoice(voiceId);
      await cubit.setPartnerGender('Male');
    } else if (isFemaleInworldVoiceId(voiceId)) {
      await cubit.setFemaleVoice(voiceId);
      await cubit.setPartnerGender('Female');
    }
    PreferenceManager.insertValue(key: _selectedVoicePrefKey, value: voiceId);

    if (!mounted) return;
    if (widget.fromStory) {
      Navigator.pop(context, {
        'playStoryTts': true,
        'selectedVoiceId': voiceId,
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: BlocConsumer<InworldTtsCubit, InworldTtsState>(
          listenWhen: (a, b) =>
              a.status != b.status ||
              a.playbackId != b.playbackId ||
              a.errorMessage != b.errorMessage,
          listener: (context, state) {
            final previewEnded = _previewingVoiceId != null &&
                (state.playbackId != _previewPlaybackId ||
                    state.status == InworldTtsStatus.idle ||
                    state.status == InworldTtsStatus.error);
            if (previewEnded && mounted) {
              setState(() => _previewingVoiceId = null);
            }
            if (state.status == InworldTtsStatus.error &&
                (state.errorMessage?.isNotEmpty ?? false)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            final selectedMale = state.maleVoiceId.isNotEmpty
                ? state.maleVoiceId
                : defaultInworldMaleVoiceId;
            final selectedFemale = state.femaleVoiceId.isNotEmpty
                ? state.femaleVoiceId
                : defaultInworldFemaleVoiceId;

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: cardSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: surfaceMuted.withOpacity(0.8)),
                ),
                child: Column(
                  children: [
                    _buildDialogHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                decoration: BoxDecoration(
                                  color: cardSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: surfaceMuted.withOpacity(0.9),
                                  ),
                                ),
                                child: _buildVoiceListsArea(
                                  state: state,
                                  selectedMale: selectedMale,
                                  selectedFemale: selectedFemale,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildVoiceSettingsCard(state),
                            const SizedBox(height: 8),
                            _buildVoiceOnOffCard(state),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 12, 6),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D3BBF), Color(0xFF6D3BBF)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: appColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Voice',
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Select how your AI coach sounds',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F1F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF6C6E7A),
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSection({
    required String title,
    required bool isMaleSection,
    required List<InworldTtsVoiceEntry> voices,
    required String selectedVoiceId,
    required InworldTtsState state,
    required double cardHeight,
    required bool compact,
    required bool hideSubtitle,
    required double rowGap,
    required ValueChanged<InworldTtsVoiceEntry> onSelect,
    required ValueChanged<InworldTtsVoiceEntry> onCommit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: compact ? 16 : 18,
          child: Row(
            children: [
              CircleAvatar(
                radius: compact ? 8 : 10,
                backgroundColor: isMaleSection
                    ? const Color(0xFFE5EFFF)
                    : const Color(0xFFFBE4F6),
                child: Icon(
                  isMaleSection ? Icons.man : Icons.woman,
                  size: compact ? 10 : 12,
                  color: isMaleSection
                      ? const Color(0xFF5C89E5)
                      : const Color(0xFFE26EC7),
                ),
              ),
              SizedBox(width: compact ? 3 : 5),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C2E3A),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: rowGap),
        for (var i = 0; i < voices.length; i++) ...[
          SizedBox(
            height: cardHeight,
            child: _buildVoiceTile(
              voice: voices[i],
              isMaleSection: isMaleSection,
              selected: selectedVoiceId == voices[i].voiceId,
              state: state,
              cardHeight: cardHeight,
              compact: compact,
              hideSubtitle: hideSubtitle,
              onSelect: onSelect,
              onCommit: onCommit,
            ),
          ),
          if (i != voices.length - 1) SizedBox(height: rowGap),
        ],
      ],
    );
  }

  Widget _buildVoiceTile({
    required InworldTtsVoiceEntry voice,
    required bool isMaleSection,
    required bool selected,
    required InworldTtsState state,
    required double cardHeight,
    required bool compact,
    required bool hideSubtitle,
    required ValueChanged<InworldTtsVoiceEntry> onSelect,
    required ValueChanged<InworldTtsVoiceEntry> onCommit,
  }) {
    final isPreviewActive =
        _isPreviewPlayingFor(state: state, voiceId: voice.voiceId);
    final isPreviewLoading =
        _isPreviewLoadingFor(state: state, voiceId: voice.voiceId);
    final avatarRadius = 20.0;
    final avatarIconSize = 19.0;
    final titleFont = 13.2;
    final subtitleFont = 11.2;
    final cardPadding = 7.0;
    final trailingButtonSize = 39.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(voice),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F1FE) : const Color(0xFFFAFAFD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? appColor : const Color(0xFFE0E2EA),
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: isMaleSection
                    ? const Color(0xFFE5EFFF)
                    : const Color(0xFFFBE4F6),
                child: Icon(
                  isMaleSection ? Icons.man : Icons.woman,
                  size: avatarIconSize,
                  color: isMaleSection
                      ? const Color(0xFF5C89E5)
                      : const Color(0xFFE26EC7),
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voice.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: titleFont,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF222433),
                      ),
                    ),
                    if (!hideSubtitle && !(compact && selected))
                      Text(
                        voice.subtitle.isNotEmpty
                            ? voice.subtitle
                            : voice.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: subtitleFont,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          color: const Color(0xFF676C7D),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  _trailingCircleButton(
                    icon: isPreviewActive
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: appColor,
                    size: trailingButtonSize,
                    isLoading: isPreviewLoading,
                    onTap: state.audioEnabled
                        ? () => _togglePreview(voice, state)
                        : null,
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    _trailingCircleButton(
                      icon: Icons.check_rounded,
                      color: Colors.white,
                      size: trailingButtonSize,
                      backgroundColor: appColor,
                      borderColor: appColor,
                      onTap: () => onCommit(voice),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailingCircleButton({
    required IconData icon,
    required Color color,
    required double size,
    Color backgroundColor = const Color(0xFFE9EAF2),
    Color borderColor = const Color(0xFFD7DAE6),
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor),
        ),
        child: isLoading
            ? Padding(
                padding: EdgeInsets.all((size * 0.24).clamp(3.5, 7.0)),
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(icon, color: color, size: (size * 0.56).clamp(10.0, 16.0)),
      ),
    );
  }

  Widget _buildVoiceListsArea({
    required InworldTtsState state,
    required String selectedMale,
    required String selectedFemale,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final activeSelectedVoiceId =
            _resolveActiveSelectedVoiceId(state, selectedMale, selectedFemale);
        final showOnlyGenderVoices = widget.fromStory;
        final activeGenderVoices =
            state.isPartnerFemale ? kInworldFemaleVoices : kInworldMaleVoices;
        final activeGenderTitle =
            state.isPartnerFemale ? 'Female Voices' : 'Male Voices';
        final sectionGap = 8.0;
        const headingAndGapPerSection = 28.0;
        const cardGapCompact = 8.0;

        final int totalCards;
        final int sectionCount;
        final double totalCardGaps;
        if (widget.fromStory) {
          totalCards = activeGenderVoices.length;
          sectionCount = 1;
          totalCardGaps = activeGenderVoices.length <= 1
              ? 0.0
              : (activeGenderVoices.length - 1) * cardGapCompact;
        } else {
          totalCards =
              kInworldMaleVoices.length + kInworldFemaleVoices.length;
          sectionCount = 2;
          totalCardGaps = (kInworldMaleVoices.length -
                      1 +
                      kInworldFemaleVoices.length -
                      1) *
                  cardGapCompact;
        }
        final fixedHeight = (sectionGap * (sectionCount - 1)) +
            (headingAndGapPerSection * sectionCount) +
            totalCardGaps;
        final rawCardHeight = totalCards > 0
            ? (constraints.maxHeight - fixedHeight) / totalCards
            : 64.0;

        // Tighten aggressively on small devices to avoid overflow.
        final cardHeight = rawCardHeight.clamp(58.0, 76.0);
        final compact = false;
        final hideSubtitle = false;
        final commitSelectedVoice = activeSelectedVoiceId;

        return Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
          child: SingleChildScrollView(
            child: Column(
              children: [
              if (showOnlyGenderVoices)
                _buildVoiceSection(
                  title: activeGenderTitle,
                  isMaleSection: !state.isPartnerFemale,
                  voices: activeGenderVoices,
                  selectedVoiceId: activeSelectedVoiceId,
                  state: state,
                  cardHeight: cardHeight,
                  compact: compact,
                  hideSubtitle: hideSubtitle,
                  rowGap: cardGapCompact,
                  onSelect: (voice) {
                    if (mounted) {
                      setState(() {
                        _singleSelectedVoiceId = voice.voiceId;
                      });
                    }
                  },
                  onCommit: (_) {
                    unawaited(_commitSelectionAndClose(commitSelectedVoice));
                  },
                )
              else ...[
                _buildVoiceSection(
                  title: 'Male Voices',
                  isMaleSection: true,
                  voices: kInworldMaleVoices,
                  selectedVoiceId: activeSelectedVoiceId,
                  state: state,
                  cardHeight: cardHeight,
                  compact: compact,
                  hideSubtitle: hideSubtitle,
                  rowGap: cardGapCompact,
                  onSelect: (voice) {
                    if (mounted) {
                      setState(() {
                        _singleSelectedVoiceId = voice.voiceId;
                      });
                    }
                  },
                  onCommit: (_) {
                    unawaited(_commitSelectionAndClose(commitSelectedVoice));
                  },
                ),
                SizedBox(height: sectionGap),
                _buildVoiceSection(
                  title: 'Female Voices',
                  isMaleSection: false,
                  voices: kInworldFemaleVoices,
                  selectedVoiceId: activeSelectedVoiceId,
                  state: state,
                  cardHeight: cardHeight,
                  compact: compact,
                  hideSubtitle: hideSubtitle,
                  rowGap: cardGapCompact,
                  onSelect: (voice) {
                    if (mounted) {
                      setState(() {
                        _singleSelectedVoiceId = voice.voiceId;
                      });
                    }
                  },
                  onCommit: (_) {
                    unawaited(_commitSelectionAndClose(commitSelectedVoice));
                  },
                ),
              ],
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildVoiceSettingsCard(InworldTtsState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceMuted.withOpacity(0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_outlined, color: appColor, size: 18),
              const SizedBox(width: 7),
              Text(
                'Voice Settings',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Speed',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 6),
          _threeOptionSegment(
            selectedIndex: state.speedSlider <= 0.85
                ? 0
                : state.speedSlider >= 0.95
                    ? 2
                    : 1,
            labels: const ['Slow', 'Medium', 'Fast'],
            icons: const [
              Icons.slow_motion_video,
              Icons.graphic_eq,
              Icons.rocket_launch
            ],
            onChanged: (i) {
              final value = i == 0 ? 0.8 : i == 1 ? 0.9 : 1.0;
              unawaited(context.read<InworldTtsCubit>().setSpeedSlider(value));
            },
          ),
          const SizedBox(height: 8),
          Text('Emotion',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 6),
          _threeOptionSegment(
            selectedIndex: state.temperatureSlider <= 0.75
                ? 0
                : state.temperatureSlider >= 0.85
                    ? 2
                    : 1,
            labels: const ['Calm', 'Natural', 'Expressive'],
            icons: const [
              Icons.eco_outlined,
              Icons.sentiment_satisfied,
              Icons.auto_awesome
            ],
            onChanged: (i) {
              final value = i == 0 ? 0.7 : i == 1 ? 0.8 : 0.9;
              unawaited(
                  context.read<InworldTtsCubit>().setTemperatureSlider(value));
            },
          ),
        ],
      ),
    );
  }

  Widget _threeOptionSegment({
    required int selectedIndex,
    required List<String> labels,
    required List<IconData> icons,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E4EE)),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFEFE9FD) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 16,
                      color: selected ? appColor : const Color(0xFF6E7183),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      labels[index],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? appColor : const Color(0xFF3E4051),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVoiceOnOffCard(InworldTtsState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceMuted.withOpacity(0.9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.volume_up_rounded, color: const Color(0xFF22A766), size: 18),
              const SizedBox(width: 7),
              Text(
                'Voice On / Off',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _voiceSwitchRow(
            icon: Icons.volume_up_rounded,
            title: 'Voice On',
            enabled: state.audioEnabled,
            iconBg: appColor,
            onChanged: (v) =>
                unawaited(context.read<InworldTtsCubit>().setAudioEnabled(v)),
          ),
          const SizedBox(height: 6),
          _voiceSwitchRow(
            icon: Icons.volume_off_rounded,
            title: 'Voice Off',
            enabled: !state.audioEnabled,
            iconBg: const Color(0xFF9AA0B6),
            onChanged: (v) =>
                unawaited(context.read<InworldTtsCubit>().setAudioEnabled(!v)),
          ),
        ],
      ),
    );
  }

  Widget _voiceSwitchRow({
    required IconData icon,
    required String title,
    required bool enabled,
    required Color iconBg,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E4EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          Switch(
            value: enabled,
            activeColor: Colors.white,
            activeTrackColor: appColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFA9ABC3),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

}
