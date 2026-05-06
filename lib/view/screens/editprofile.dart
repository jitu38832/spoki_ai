import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/getprofile.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/language_options.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';

import '../../viewmodel/cubit/appcubit.dart';
import '../utils/colors.dart';

class Editprofile extends StatefulWidget {
  /// When true (after login/signup), back is hidden and finishing opens [DashboardScreen].
  final bool isPostLoginSetup;

  const Editprofile({super.key, this.isPostLoginSetup = false});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  static const String _kGender = 'profile_gender';
  static const String _kAge = 'profile_age';
  static const String _kEnglish = 'profile_english_level';
  static const String _kLanguage = 'profile_spoken_language';

  String token = "";

  GetProfileResponse getProfileResponse = GetProfileResponse();

  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  String? _selectedGender;
  int? _selectedAge;
  String? _selectedEnglishLevel;
  String? _selectedLanguage;

  List<int> get _ageYears =>
      List<int>.generate(83, (i) => i + 13); // 13–95

  @override
  void initState() {
    super.initState();
    token = PreferenceManager.getStringValue(key: "token") ?? "";
    _loadProfileExtrasFromPrefs();
    BlocProvider.of<AppCubit>(context).getProfile(token);
  }

  void _loadProfileExtrasFromPrefs() {
    _selectedGender = PreferenceManager.getStringValue(key: _kGender);
    if (_selectedGender != null && _selectedGender!.isEmpty) {
      _selectedGender = null;
    }
    final ageStr = PreferenceManager.getStringValue(key: _kAge);
    _selectedAge = int.tryParse(ageStr ?? '');
    _selectedEnglishLevel =
        PreferenceManager.getStringValue(key: _kEnglish);
    if (_selectedEnglishLevel != null &&
        _selectedEnglishLevel!.isEmpty) {
      _selectedEnglishLevel = null;
    }
    _selectedLanguage = PreferenceManager.getStringValue(key: _kLanguage);
    if (_selectedLanguage != null && _selectedLanguage!.isEmpty) {
      _selectedLanguage = null;
    }
  }

  void _applyProfileDataFromApi(Data? d) {
    if (d == null) return;
    if (d.gender != null && d.gender!.isNotEmpty) {
      _selectedGender = d.gender;
    }
    if (d.age != null && _ageYears.contains(d.age)) {
      _selectedAge = d.age;
    }
    if (d.englishLevel != null && d.englishLevel!.isNotEmpty) {
      _selectedEnglishLevel = d.englishLevel;
    }
    if (d.spokenLanguage != null && d.spokenLanguage!.isNotEmpty) {
      _selectedLanguage = d.spokenLanguage;
    }
  }

  void _persistProfileExtras() {
    PreferenceManager.insertValue(
      key: _kGender,
      value: _selectedGender ?? '',
    );
    PreferenceManager.insertValue(
      key: _kAge,
      value: _selectedAge?.toString() ?? '',
    );
    PreferenceManager.insertValue(
      key: _kEnglish,
      value: _selectedEnglishLevel ?? '',
    );
    PreferenceManager.insertValue(
      key: _kLanguage,
      value: _selectedLanguage ?? '',
    );
  }

  bool _validateExtrasForPostLogin() {
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      showToast(context: context, message: 'Please select gender');
      return false;
    }
    if (_selectedAge == null) {
      showToast(context: context, message: 'Please select your age');
      return false;
    }
    if (_selectedEnglishLevel == null ||
        _selectedEnglishLevel!.isEmpty) {
      showToast(
          context: context, message: 'Please select your English level');
      return false;
    }
    if (_selectedLanguage == null || _selectedLanguage!.isEmpty) {
      showToast(
          context: context, message: 'Please select a language you speak');
      return false;
    }
    return true;
  }

  Future<void> _saveProfile() async {
    if (!context.mounted) return;
    if (widget.isPostLoginSetup) {
      if (!_validateExtrasForPostLogin()) return;
    }
    _persistProfileExtras();
    if (!context.mounted) return;
    if (widget.isPostLoginSetup) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  String _languageDisplay(String language) {
    if (language == 'Mandarin Chinese') return 'Chinese';
    return language;
  }

  String _languageFlag(String language) {
    switch (language) {
      case 'English':
        return '🇺🇸';
      case 'Spanish':
        return '🇪🇸';
      case 'French':
        return '🇫🇷';
      case 'Mandarin Chinese':
        return '🇨🇳';
      case 'Arabic':
        return '🇸🇦';
      case 'Hindi':
        return '🇮🇳';
      case 'Portuguese':
        return '🇵🇹';
      case 'Russian':
        return '🇷🇺';
      case 'German':
        return '🇩🇪';
      case 'Japanese':
        return '🇯🇵';
      case 'Italian':
        return '🇮🇹';
      case 'Korean':
        return '🇰🇷';
      default:
        return '🌐';
    }
  }

  Future<void> _showLanguagePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: surfaceBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Preferred Language',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: LanguageOptions.spokenLanguages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final language = LanguageOptions.spokenLanguages[index];
                      final isSelected = _selectedLanguage == language;
                      return InkWell(
                        onTap: () => Navigator.pop(context, language),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 72,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: appColor.withOpacity(0.45),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: appColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _languageFlag(language),
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _languageDisplay(language),
                                  style: GoogleFonts.inter(
                                    fontSize: 18 / 1.2,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: appColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedLanguage = selected);
    }
  }

  Widget _sectionCard({required List<Widget> children}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2F2F3F) : const Color(0xFFEAE5F7),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0xFF2D1769).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: appColor.withOpacity(0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: appColor, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16 / 1.2,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _outlinedField({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textFieldBorderColor),
      ),
      child: child,
    );
  }

  Widget _genderChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF5A35E5), Color(0xFF7E48F4)],
                  )
                : null,
            color: selected ? null : cardSurface,
            border: Border.all(
              color: selected ? Colors.transparent : textFieldBorderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : appColor, size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13 / 1.2,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelChip({
    required String label,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final double chipFontSize = label == "Intermediate" ? 11.2 : 12.2;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF5A35E5), Color(0xFF7E48F4)],
                  )
                : null,
            color: selected ? null : cardSurface,
            border: Border.all(
              color: selected ? Colors.transparent : textFieldBorderColor,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$emoji  $label',
                  style: GoogleFonts.inter(
                    fontSize: chipFontSize,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double ageValue = (_selectedAge ?? 22).toDouble();
    return PopScope(
      canPop: !widget.isPostLoginSetup,
      child: Scaffold(
        backgroundColor: surfaceBg,
        body: BlocConsumer<AppCubit, AppStates>(
          listener: (context, state) {
            if (state.status == AppStatus.getProfileSuccess) {
              getProfileResponse =
                  state.responseData?.response as GetProfileResponse;
              final d = getProfileResponse.data;
              emailController.text = d?.email?.toString() ?? "";
              nameController.text = d?.name?.toString() ?? "";
              setState(() {
                _applyProfileDataFromApi(d);
              });
            }

            if (state.status == AppStatus.getProfileError) {
              showToast(
                  context: context,
                  message: state.errorData?.message.toString() ?? "");
            }
          },
          builder: (context, state) {
            if (state.status == AppStatus.getProfileLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: appColor,
                ),
              );
            }
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 30, 0, 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 30, 10, 8),
                      decoration: BoxDecoration(
                        color: cardSurface,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2F2F3F)
                              : const Color(0xFFEAE5F7),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 40),
                                  Center(
                                    child: Text(
                                      "Upload Photo",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: appColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _sectionCard(
                                    children: [
                                      _sectionTitle(
                                          icon: Icons.person_rounded,
                                          title: "Full Name"),
                                      const SizedBox(height: 6),
                                      _outlinedField(
                                        child: TextField(
                                          controller: nameController,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: "Enter full name",
                                            hintStyle: TextStyle(color: textMuted),
                                          ),
                                          style: TextStyle(color: textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _sectionCard(
                                    children: [
                                      _sectionTitle(
                                          icon: Icons.male_rounded,
                                          title: "Gender"),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _genderChip(
                                            label: "Male",
                                            icon: Icons.person,
                                            selected: _selectedGender == 'Male',
                                            onTap: () => setState(
                                                () => _selectedGender = 'Male'),
                                          ),
                                          const SizedBox(width: 8),
                                          _genderChip(
                                            label: "Female",
                                            icon: Icons.person_2_rounded,
                                            selected: _selectedGender == 'Female',
                                            onTap: () => setState(
                                                () => _selectedGender = 'Female'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      _sectionTitle(
                                          icon: Icons.cake_rounded, title: "Age"),
                                      const SizedBox(height: 6),
                                      LayoutBuilder(
                                        builder: (context, sliderConstraints) {
                                          const double minAge = 13;
                                          const double maxAge = 95;
                                          const double bubbleSize = 44;
                                          final double progress =
                                              ((ageValue - minAge) /
                                                      (maxAge - minAge))
                                                  .clamp(0.0, 1.0);
                                          final double bubbleLeft =
                                              (sliderConstraints.maxWidth -
                                                      bubbleSize) *
                                                  progress;

                                          return SizedBox(
                                            height: 44,
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              alignment: Alignment.centerLeft,
                                              children: [
                                                SliderTheme(
                                                  data: SliderTheme.of(context)
                                                      .copyWith(
                                                    activeTrackColor: appColor,
                                                    inactiveTrackColor:
                                                        surfaceMuted,
                                                    trackHeight: 7,
                                                    thumbShape:
                                                        const RoundSliderThumbShape(
                                                      enabledThumbRadius: 0,
                                                    ),
                                                    overlayShape:
                                                        const RoundSliderOverlayShape(
                                                      overlayRadius: 0,
                                                    ),
                                                    showValueIndicator:
                                                        ShowValueIndicator.never,
                                                  ),
                                                  child: Slider(
                                                    min: minAge,
                                                    max: maxAge,
                                                    divisions: 82,
                                                    value: ageValue,
                                                    onChanged: (v) => setState(
                                                      () => _selectedAge =
                                                          v.round(),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: bubbleLeft,
                                                  child: Container(
                                                    width: bubbleSize,
                                                    height: bubbleSize,
                                                    decoration: BoxDecoration(
                                                      color: appColor,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 2,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: appColor
                                                              .withOpacity(0.22),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                              0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      '${ageValue.round()}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _sectionCard(
                                    children: [
                                      _sectionTitle(
                                        icon: Icons.chat_bubble_rounded,
                                        title: "English Level",
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _levelChip(
                                            label: "Beginner",
                                            emoji: "🐥",
                                            selected: _selectedEnglishLevel ==
                                                "Beginner",
                                            onTap: () => setState(
                                              () => _selectedEnglishLevel =
                                                  "Beginner",
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          _levelChip(
                                            label: "Intermediate",
                                            emoji: "🚀",
                                            selected: _selectedEnglishLevel ==
                                                "Intermediate",
                                            onTap: () => setState(
                                              () => _selectedEnglishLevel =
                                                  "Intermediate",
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          _levelChip(
                                            label: "Fluent",
                                            emoji: "🔥",
                                            selected:
                                                _selectedEnglishLevel == "Fluent",
                                            onTap: () => setState(
                                              () => _selectedEnglishLevel =
                                                  "Fluent",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _sectionCard(
                                    children: [
                                      _sectionTitle(
                                        icon: Icons.language_rounded,
                                        title: "Prefered Language",
                                      ),
                                      const SizedBox(height: 3),
                                      _outlinedField(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 0),
                                        child: InkWell(
                                          onTap: _showLanguagePicker,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: SizedBox(
                                            height: 34,
                                            child: Row(
                                              children: [
                                                Text(
                                                  _languageFlag(
                                                      _selectedLanguage ?? ''),
                                                  style: const TextStyle(
                                                      fontSize: 18),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _selectedLanguage == null
                                                        ? "Select language"
                                                        : _languageDisplay(
                                                            _selectedLanguage!),
                                                    style: TextStyle(
                                                      color: _selectedLanguage ==
                                                              null
                                                          ? textMuted
                                                          : textPrimary,
                                                      fontSize: 12.5,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: appColor,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  button(
                                    context: context,
                                    width: double.infinity,
                                    title: "Save Changes",
                                    fontSize: 16 / 1.2,
                                    fontWeight: FontWeight.w700,
                                    isLoading: false,
                                    icon: Icons.save_rounded,
                                    onPressed: _saveProfile,
                                  ),
                                ],
                              ),
                              Positioned(
                                top: -60,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: 104,
                                    height: 104,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 96,
                                          height: 96,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3.5,
                                            ),
                                            image: const DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/boy1.png'),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: -2,
                                          bottom: 12,
                                          child: Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: appColor,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
