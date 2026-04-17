import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/core/inworld_tts_audio_mapping.dart';
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
  static const double _sliderMinValue = 0.8;
  static const double _sliderMaxValue = 1.2;
  static const double _sliderStep = 0.1;
  static const double _emotionMinValue = 0.0;
  static const double _emotionMaxValue = 1.5;
  static const String _previewPlaybackId = '__voice_preview__';
  static const String _storySofyLocalVoiceId = '__sofy_local_tts__';
  static const String _selectedVoicePrefKey =
      'voice_settings_selected_voice_id';
  static const InworldTtsVoiceEntry _storySofyEntry = InworldTtsVoiceEntry(
    voiceId: _storySofyLocalVoiceId,
    displayName: 'Sofy',
    subtitle: 'Classic & Friendly',
  );
  late final FlutterTts _sofyTts;
  String? _previewingVoiceId;
  bool _initialSlidersSet = false;
  bool _storyDefaultApplied = false;
  bool _isSofySelected = false;
  String? _singleSelectedVoiceId;
  bool _isSofyLocalLoading = false;
  bool _isSofyLocalPlaying = false;

  @override
  void initState() {
    super.initState();
    _sofyTts = FlutterTts();
    _sofyTts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _isSofyLocalLoading = false;
        _isSofyLocalPlaying = true;
      });
    });
    _sofyTts.setCompletionHandler(_resetSofyPreviewState);
    _sofyTts.setCancelHandler(_resetSofyPreviewState);
    _sofyTts.setErrorHandler((_) => _resetSofyPreviewState());
  }

  @override
  void dispose() {
    _sofyTts.stop();
    super.dispose();
  }

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
      _singleSelectedVoiceId = saved;
      _isSofySelected = saved == _storySofyLocalVoiceId;
    } else {
      _singleSelectedVoiceId = cubit.state.effectiveVoiceId;
      _isSofySelected = false;
    }
    if (widget.fromStory && !_storyDefaultApplied) {
      _storyDefaultApplied = true;
      if (_singleSelectedVoiceId == null || _singleSelectedVoiceId!.isEmpty) {
        _isSofySelected = true;
        _singleSelectedVoiceId = _storySofyLocalVoiceId;
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

  double _valueToSliderPosition(double value) {
    final v = value.clamp(_sliderMinValue, _sliderMaxValue);
    return (v - _sliderMinValue) / (_sliderMaxValue - _sliderMinValue);
  }

  double _emotionValueToSliderPosition(double value) {
    final v = value.clamp(_emotionMinValue, _emotionMaxValue);
    if (v <= 1.0) {
      // Map 0..1 into first half of the bar.
      return v / 2.0;
    }
    // Map 1..1.5 into second half of the bar.
    return 0.5 + (v - 1.0);
  }

  double _sliderPositionToValue(double position) {
    final p = position.clamp(0.0, 1.0);
    return _sliderMinValue + (p * (_sliderMaxValue - _sliderMinValue));
  }

  double _emotionSliderPositionToValue(double position) {
    final p = position.clamp(0.0, 1.0);
    if (p <= 0.5) {
      return p * 2.0;
    }
    return 1.0 + (p - 0.5);
  }

  double _quantizeSliderValue(double value) {
    final v = value.clamp(_sliderMinValue, _sliderMaxValue);
    final snapped =
        ((v - _sliderMinValue) / _sliderStep).round() * _sliderStep +
            _sliderMinValue;
    return snapped.clamp(_sliderMinValue, _sliderMaxValue);
  }

  double _quantizeEmotionSliderValue(double value) {
    final v = value.clamp(_emotionMinValue, _emotionMaxValue);
    if (v <= 1.0) {
      // 0, 0.25, 0.5, 0.75, 1
      return (v / 0.25).round() * 0.25;
    }
    // After 1: 1.25, 1.5
    return 1.0 + (((v - 1.0) / 0.25).round() * 0.25);
  }

  bool _isPreviewPlayingFor({
    required InworldTtsState state,
    required String voiceId,
  }) {
    if (widget.fromStory && voiceId == _storySofyLocalVoiceId) {
      return _previewingVoiceId == voiceId && _isSofyLocalPlaying;
    }
    final samePlayback = state.playbackId == _previewPlaybackId;
    return samePlayback &&
        state.status == InworldTtsStatus.playing &&
        _previewingVoiceId == voiceId;
  }

  bool _isPreviewLoadingFor({
    required InworldTtsState state,
    required String voiceId,
  }) {
    if (widget.fromStory && voiceId == _storySofyLocalVoiceId) {
      return _previewingVoiceId == voiceId && _isSofyLocalLoading;
    }
    final samePlayback = state.playbackId == _previewPlaybackId;
    return samePlayback &&
        state.status == InworldTtsStatus.loading &&
        _previewingVoiceId == voiceId;
  }

  Future<void> _togglePreview(
    InworldTtsVoiceEntry entry,
    InworldTtsState state,
  ) async {
    if (widget.fromStory && entry.voiceId == _storySofyLocalVoiceId) {
      await _toggleSofyPreview(entry);
      return;
    }
    final cubit = context.read<InworldTtsCubit>();
    if (!cubit.state.audioEnabled) return;
    await _stopSofyPreviewIfAny();
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

  void _resetSofyPreviewState() {
    if (!mounted) return;
    setState(() {
      _isSofyLocalLoading = false;
      _isSofyLocalPlaying = false;
      if (_previewingVoiceId == _storySofyLocalVoiceId) {
        _previewingVoiceId = null;
      }
    });
  }

  Future<void> _stopSofyPreviewIfAny() async {
    if (!_isSofyLocalLoading && !_isSofyLocalPlaying) return;
    await _sofyTts.stop();
    _resetSofyPreviewState();
  }

  Future<void> _toggleSofyPreview(InworldTtsVoiceEntry entry) async {
    if (_isSofyLocalLoading || _isSofyLocalPlaying) {
      await _sofyTts.stop();
      _resetSofyPreviewState();
      return;
    }

    if (!mounted) return;
    setState(() {
      _previewingVoiceId = entry.voiceId;
      _isSofyLocalLoading = true;
      _isSofyLocalPlaying = false;
    });
    await _sofyTts.stop();
    await _sofyTts.setLanguage('en-US');
    await _sofyTts.setSpeechRate(0.45);
    final res = await _sofyTts.speak(_previewTextFor(entry.displayName));
    if (res != 1) {
      _resetSofyPreviewState();
    }
  }

  Future<void> _selectSofyVoice() async {
    if (!widget.fromStory) return;
    if (mounted) {
      setState(() {
        _isSofySelected = true;
        _singleSelectedVoiceId = _storySofyLocalVoiceId;
      });
    }
  }

  String _resolveActiveSelectedVoiceId(
    InworldTtsState state,
    String selectedMale,
    String selectedFemale,
  ) {
    if (widget.fromStory && _isSofySelected) {
      return _storySofyLocalVoiceId;
    }
    final pinned = _singleSelectedVoiceId?.trim();
    if (pinned != null && pinned.isNotEmpty) {
      if (pinned == _storySofyLocalVoiceId) {
        return widget.fromStory
            ? pinned
            : (state.isPartnerFemale ? selectedFemale : selectedMale);
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
    await _stopSofyPreviewIfAny();
    await cubit.stop();

    if (widget.fromStory && voiceId == _storySofyLocalVoiceId) {
      PreferenceManager.insertValue(key: _selectedVoicePrefKey, value: voiceId);
      if (mounted) {
        Navigator.pop(context, {
          'playStoryTts': true,
          'useSofy': true,
          'selectedVoiceId': voiceId,
        });
      }
      return;
    }

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
        'useSofy': false,
        'selectedVoiceId': voiceId,
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7E7EE),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: BlocConsumer<InworldTtsCubit, InworldTtsState>(
          listenWhen: (a, b) =>
              a.status != b.status ||
              a.playbackId != b.playbackId ||
              a.errorMessage != b.errorMessage,
          listener: (context, state) {
            if (_previewingVoiceId == _storySofyLocalVoiceId &&
                (_isSofyLocalLoading || _isSofyLocalPlaying)) {
              return;
            }
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
            final speedLabel = speedBandLabel(state.speedSlider);
            final emotionLabel = temperatureBandLabel(state.temperatureSlider);
            final selectedMale = state.maleVoiceId.isNotEmpty
                ? state.maleVoiceId
                : defaultInworldMaleVoiceId;
            final selectedFemale = state.femaleVoiceId.isNotEmpty
                ? state.femaleVoiceId
                : defaultInworldFemaleVoiceId;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    _buildDialogHeader(),
                    Divider(height: 1, color: Colors.grey.shade300),
                    Expanded(
                      child: _buildVoiceListsArea(
                        state: state,
                        selectedMale: selectedMale,
                        selectedFemale: selectedFemale,
                      ),
                    ),
                    _buildSpeedSlider(
                      speedValue: state.speedSlider,
                      speedLabel: speedLabel,
                    ),
                    _buildEmotionSlider(
                      value: state.temperatureSlider,
                      label: emotionLabel,
                    ),
                    if (!widget.fromStory) _buildDoneButton(),
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
      padding: const EdgeInsets.fromLTRB(12, 6, 10, 4),
      child: SizedBox(
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7A5CFF), Color(0xFF4C40CC)],
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
                  size: 18,
                ),
              ),
            ),
            Text(
              'Choose Your Voice',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF242635),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F1F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF6C6E7A),
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final avatarRadius = (cardHeight * 0.26).clamp(8.0, 13.0);
    final avatarIconSize = (avatarRadius * 1.15).clamp(9.0, 15.0);
    final titleFont = (cardHeight * 0.27).clamp(10.8, 13.0);
    final subtitleFont = (cardHeight * 0.22).clamp(9.0, 10.5);
    final cardPadding = (cardHeight * 0.12).clamp(2.0, 6.0);
    final trailingButtonSize = (cardHeight * 0.52).clamp(17.0, 24.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(voice),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? appColor : const Color(0xFFE0E2EA),
              width: selected ? 1.4 : 1,
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
                    SizedBox(width: compact ? 4 : 6),
                    _trailingCircleButton(
                      icon: Icons.arrow_forward_rounded,
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
        final showOnlyGenderVoices = !widget.fromStory;
        final activeGenderVoices =
            state.isPartnerFemale ? kInworldFemaleVoices : kInworldMaleVoices;
        final activeGenderTitle =
            state.isPartnerFemale ? 'Female Voices' : 'Male Voices';
        final extraStoryCards = widget.fromStory ? 1 : 0;
        final totalCards = widget.fromStory
            ? (kInworldMaleVoices.length +
                kInworldFemaleVoices.length +
                extraStoryCards)
            : activeGenderVoices.length;
        final sectionCount = widget.fromStory ? 3 : 1;
        final sectionGap = widget.fromStory ? 1.0 : 2.0;
        const headingAndGapPerSection = 20.0;
        final cardGapCompact = widget.fromStory ? 1.0 : 2.0;

        final totalCardGaps = widget.fromStory
            ? (kInworldMaleVoices.length -
                    1 +
                    kInworldFemaleVoices.length -
                    1) *
                cardGapCompact
            : (activeGenderVoices.length - 1) * cardGapCompact;
        final fixedHeight = (sectionGap * (sectionCount - 1)) +
            (headingAndGapPerSection * sectionCount) +
            totalCardGaps;
        final rawCardHeight =
            (constraints.maxHeight - fixedHeight) / totalCards;

        // Tighten aggressively on small devices to avoid overflow.
        final cardHeight = rawCardHeight.clamp(24.0, 52.0);
        final compact = cardHeight <= 44;
        final hideSubtitle = widget.fromStory ? true : cardHeight <= 46;
        final commitSelectedVoice = activeSelectedVoiceId;

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
          child: Column(
            children: [
              if (widget.fromStory) ...[
                _buildVoiceSection(
                  title: 'Story Voice',
                  isMaleSection: false,
                  voices: const [_storySofyEntry],
                  selectedVoiceId: activeSelectedVoiceId,
                  state: state,
                  cardHeight: cardHeight,
                  compact: compact,
                  hideSubtitle: hideSubtitle,
                  rowGap: cardGapCompact,
                  onSelect: (_) {
                    unawaited(_stopSofyPreviewIfAny());
                    unawaited(_selectSofyVoice());
                  },
                  onCommit: (_) {
                    unawaited(_commitSelectionAndClose(commitSelectedVoice));
                  },
                ),
                SizedBox(height: sectionGap),
              ],
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
                    unawaited(_stopSofyPreviewIfAny());
                    if (mounted) {
                      setState(() {
                        _isSofySelected = false;
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
                    unawaited(_stopSofyPreviewIfAny());
                    if (mounted) {
                      setState(() {
                        _isSofySelected = false;
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
                    unawaited(_stopSofyPreviewIfAny());
                    if (mounted) {
                      setState(() {
                        _isSofySelected = false;
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
        );
      },
    );
  }

  Widget _buildEmotionSlider({
    required double value,
    required String label,
  }) {
    final v = value.clamp(_emotionMinValue, _emotionMaxValue);
    final sliderPos = _emotionValueToSliderPosition(v);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotion',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C2E3A),
            ),
          ),
          SizedBox(
            height: 16,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: appColor,
                inactiveTrackColor: const Color(0xFFD5D7E3),
                thumbColor: appColor,
                trackHeight: 2,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: sliderPos,
                min: 0,
                max: 1.0,
                divisions: 100,
                onChanged: (next) => unawaited(
                  context.read<InworldTtsCubit>().setTemperatureSlider(
                        _quantizeEmotionSliderValue(
                          _emotionSliderPositionToValue(next),
                        ),
                      ),
                ),
              ),
            ),
          ),
          _buildRangeMarkers(
            minText: '0.0x',
            midText: '1.0x',
            maxText: '1.5x',
          ),
          const SizedBox(height: 0),
        ],
      ),
    );
  }

  Widget _buildSpeedSlider({
    required double speedValue,
    required String speedLabel,
  }) {
    final v = speedValue.clamp(_sliderMinValue, _sliderMaxValue);
    final sliderPos = _valueToSliderPosition(v);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speed',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C2E3A),
            ),
          ),
          SizedBox(
            height: 16,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: appColor,
                inactiveTrackColor: const Color(0xFFD5D7E3),
                thumbColor: appColor,
                trackHeight: 2,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: sliderPos,
                min: 0,
                max: 1.0,
                divisions: 100,
                onChanged: (next) => unawaited(
                  context.read<InworldTtsCubit>().setSpeedSlider(
                        _quantizeSliderValue(_sliderPositionToValue(next)),
                      ),
                ),
              ),
            ),
          ),
          _buildRangeMarkers(
            minText: '0.8x',
            midText: '1.0x',
            maxText: '1.2x',
          ),
          const SizedBox(height: 0),
        ],
      ),
    );
  }

  Widget _buildRangeMarkers({
    required String minText,
    required String midText,
    required String maxText,
  }) {
    return Row(
      children: [
        Text(
          minText,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: const Color(0xFF7D8191),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          midText,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: const Color(0xFF7D8191),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          maxText,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: const Color(0xFF7D8191),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDoneButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: SizedBox(
        width: double.infinity,
        height: 30,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B5DF6), Color(0xFF3A33AF)],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
              child: Text(
                'Done',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
