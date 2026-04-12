import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/core/inworld_tts_audio_mapping.dart';
import 'package:spokiai/core/inworld_tts_voice_catalog.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_cubit.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_state.dart';
import '../utils/colors.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  bool _tabInited = false;
  bool _isMaleTab = true;

  static const _previewText =
      'Hello. This is how this voice sounds with your current settings.';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabInited) {
      _tabInited = true;
      final female =
          context.read<InworldTtsCubit>().state.isPartnerFemale;
      _isMaleTab = !female;
    }
  }

  int _indexForVoice(List<InworldTtsVoiceEntry> list, String voiceId) {
    final i = list.indexWhere((e) => e.voiceId == voiceId);
    return i >= 0 ? i : 0;
  }

  Future<void> _preview(InworldTtsVoiceEntry entry) async {
    final cubit = context.read<InworldTtsCubit>();
    if (!cubit.state.audioEnabled) return;
    await cubit.speak(
      _previewText,
      playbackId: '__voice_preview__',
      voiceIdForPreview: entry.voiceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Voice Settings',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0.8,
        toolbarHeight: 48,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: BlocConsumer<InworldTtsCubit, InworldTtsState>(
                listenWhen: (a, b) =>
                    b.status == InworldTtsStatus.error &&
                    (b.errorMessage?.isNotEmpty ?? false) &&
                    a.errorMessage != b.errorMessage,
                listener: (context, state) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage!)),
                  );
                },
                builder: (context, state) {
                  final maleList = kInworldMaleVoices;
                  final femaleList = kInworldFemaleVoices;
                  final voices = _isMaleTab ? maleList : femaleList;
                  final selectedVoiceId =
                      _isMaleTab ? state.maleVoiceId : state.femaleVoiceId;
                  final selectedIndex = _indexForVoice(voices, selectedVoiceId);

                  final speedLabel = speedBandLabel(state.speedSlider);
                  final tempLabel = temperatureBandLabel(state.temperatureSlider);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildGenderTabs(),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildVoicesCard(
                            voices: voices,
                            selectedIndex: selectedIndex,
                            state: state,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRangedSliderCard(
                          title: 'Voice Speed',
                          value: state.speedSlider,
                          bandLabel: speedLabel,
                          onChanged: (v) => unawaited(
                            context.read<InworldTtsCubit>().setSpeedSlider(v),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRangedSliderCard(
                          title: 'Voice Temperature',
                          value: state.temperatureSlider,
                          bandLabel: tempLabel,
                          onChanged: (v) => unawaited(
                            context
                                .read<InworldTtsCubit>()
                                .setTemperatureSlider(v),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Audio Mode',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildAudioModeSwitch(state.audioEnabled),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _buildContinueButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderTabs() {
    return Row(
      children: [
        Expanded(
          child: _tabButton(
            label: 'Male',
            selected: _isMaleTab,
            selectedColors: const [Color(0xFF2CE31D), Color(0xFF21C10D)],
            onTap: () => setState(() => _isMaleTab = true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tabButton(
            label: 'Female',
            selected: !_isMaleTab,
            selectedColors: const [Color(0xFF1F88CC), Color(0xFF2F6EE6)],
            onTap: () => setState(() => _isMaleTab = false),
          ),
        ),
      ],
    );
  }

  Widget _tabButton({
    required String label,
    required bool selected,
    required List<Color> selectedColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected
              ? LinearGradient(colors: selectedColors)
              : null,
          color: selected ? null : const Color(0xFFF1F1F1),
          border: Border.all(color: const Color(0xFFD8D8D8)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoicesCard({
    required List<InworldTtsVoiceEntry> voices,
    required int selectedIndex,
    required InworldTtsState state,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isMaleTab ? 'Male Voices' : 'Female Voices',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 6.0;
                final maxW = constraints.maxWidth;
                final maxH = constraints.maxHeight;
                final cellW = (maxW - spacing) / 2;
                final cellH = (maxH - spacing) / 2;
                final aspect =
                    (cellW / cellH.clamp(1.0, 999.0)).clamp(1.4, 4.2);
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: aspect,
                  ),
                  itemCount: voices.length,
                  itemBuilder: (context, index) {
                    final voice = voices[index];
                    final selected = selectedIndex == index;
                    final subtitle = voice.subtitle.isNotEmpty
                        ? voice.subtitle
                        : voice.displayName;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          final cubit = context.read<InworldTtsCubit>();
                          if (_isMaleTab) {
                            unawaited(cubit.setMaleVoice(voice.voiceId));
                          } else {
                            unawaited(cubit.setFemaleVoice(voice.voiceId));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? appColor
                                  : const Color(0xFFE2E2E2),
                              width: selected ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: _isMaleTab
                                    ? const Color(0xFFE1EEFF)
                                    : const Color(0xFFFFE9F4),
                                child: Icon(
                                  _isMaleTab ? Icons.man : Icons.woman,
                                  size: 14,
                                  color:
                                      _isMaleTab ? Colors.blue : Colors.pink,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      voice.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        height: 1.15,
                                      ),
                                    ),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        color: Colors.black45,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                icon: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: selected
                                      ? appColor
                                      : Colors.blue[300],
                                  size: 20,
                                ),
                                onPressed: state.audioEnabled
                                    ? () => _preview(voice)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangedSliderCard({
    required String title,
    required double value,
    required String bandLabel,
    required ValueChanged<double> onChanged,
  }) {
    final v = value.clamp(0.0, 1.5);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: appColor,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: appColor,
              trackHeight: 3,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              min: 0,
              max: 1.5,
              divisions: 15,
              label: v.toStringAsFixed(1),
              value: v,
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Slow (0)',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Normal (1)',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Fast (1.5)',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.center,
            child: Text(
              '${v.toStringAsFixed(1)} · $bandLabel',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioModeSwitch(bool audioOn) {
    return Row(
      children: [
        Expanded(
          child: _modeButton(
            label: 'On',
            selected: audioOn,
            onTap: () => unawaited(
                  context.read<InworldTtsCubit>().setAudioEnabled(true),
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _modeButton(
            label: 'Off',
            selected: !audioOn,
            onTap: () => unawaited(
                  context.read<InworldTtsCubit>().setAudioEnabled(false),
                ),
          ),
        ),
      ],
    );
  }

  Widget _modeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? appColor : const Color(0xFFC5C5C5),
              width: selected ? 2.5 : 1,
            ),
            color: selected
                ? appColor.withValues(alpha: 0.22)
                : const Color(0xFFF2F2F2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: appColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: selected ? const Color(0xFF1A237E) : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF5844E5), Color(0xFF2E9CF8)],
            ),
            boxShadow: [
              BoxShadow(
                color: appColor.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Center(
            child: Text(
              'Continue  \u2192',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
