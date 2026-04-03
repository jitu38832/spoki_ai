import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  bool _isMaleTab = true;
  double _voiceSpeed = 0.5;
  bool _audioOn = true;

  int? _selectedMaleVoice = 0;
  int? _selectedFemaleVoice;

  final List<_VoiceItem> _maleVoices = const [
    _VoiceItem(name: 'David', subtitle: 'Clear & Natural'),
    _VoiceItem(name: 'James', subtitle: 'Deep & Confident'),
    _VoiceItem(name: 'Arjun', subtitle: 'Friendly & Casual'),
    _VoiceItem(name: 'Matthew', subtitle: 'Soft & Clear'),
  ];

  final List<_VoiceItem> _femaleVoices = const [
    _VoiceItem(name: 'Emma', subtitle: 'Soft & Clear'),
    _VoiceItem(name: 'Olivia', subtitle: 'Professional'),
    _VoiceItem(name: 'Sophia', subtitle: 'Energetic & Fast'),
    _VoiceItem(name: 'Sofia', subtitle: 'Bright & Friendly'),
  ];

  @override
  Widget build(BuildContext context) {
    final voices = _isMaleTab ? _maleVoices : _femaleVoices;
    final selectedIndex = _isMaleTab ? _selectedMaleVoice : _selectedFemaleVoice;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Voice Settings",
          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0.8,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Voice",
                  style: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _buildGenderTabs(),
              const SizedBox(height: 12),
              _buildVoicesCard(voices, selectedIndex),
              const SizedBox(height: 16),
              _buildSpeedCard(),
              const SizedBox(height: 18),
              Text("Audio Mode",
                  style: GoogleFonts.inter(fontSize: 38, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _buildAudioModeSwitch(),
              const Spacer(),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderTabs() {
    return Row(
      children: [
        Expanded(
          child: _tabButton(
            label: "Male",
            selected: _isMaleTab,
            selectedColors: const [Color(0xFF2CE31D), Color(0xFF21C10D)],
            onTap: () => setState(() => _isMaleTab = true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tabButton(
            label: "Female",
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
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
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoicesCard(List<_VoiceItem> voices, int? selectedIndex) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isMaleTab ? "Male Voices" : "Female Voices",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: voices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.6,
            ),
            itemBuilder: (context, index) {
              final voice = voices[index];
              final selected = selectedIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isMaleTab) {
                      _selectedMaleVoice = index;
                    } else {
                      _selectedFemaleVoice = index;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? appColor : const Color(0xFFE2E2E2),
                      width: selected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: _isMaleTab
                            ? const Color(0xFFE1EEFF)
                            : const Color(0xFFFFE9F4),
                        child: Icon(
                          _isMaleTab ? Icons.man : Icons.woman,
                          size: 16,
                          color: _isMaleTab ? Colors.blue : Colors.pink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voice.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              voice.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: Colors.black45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: selected ? appColor : Colors.blue[300],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedCard() {
    final speedLabel = _voiceSpeed < 0.34
        ? "Slow"
        : _voiceSpeed < 0.67
            ? "Normal"
            : "Fast";

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Voice Speed",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: appColor,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: appColor,
              trackHeight: 4,
            ),
            child: Slider(
              value: _voiceSpeed,
              onChanged: (v) => setState(() => _voiceSpeed = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Slow", style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
                Text("Normal", style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
                Text("Fast", style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.center,
            child: Text(
              speedLabel,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioModeSwitch() {
    return Row(
      children: [
        Expanded(
          child: _modeButton(
            label: "On",
            selected: _audioOn,
            onTap: () => setState(() => _audioOn = true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _modeButton(
            label: "Off",
            selected: !_audioOn,
            onTap: () => setState(() => _audioOn = false),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? const Color(0xFFD5CED0) : const Color(0xFFE8E1E3),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF5844E5), Color(0xFF2E9CF8)],
            ),
            boxShadow: [
              BoxShadow(
                color: appColor.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Center(
            child: Text(
              "Continue  \u2192",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceItem {
  final String name;
  final String subtitle;

  const _VoiceItem({required this.name, required this.subtitle});
}
