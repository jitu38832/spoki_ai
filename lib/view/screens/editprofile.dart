import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/getprofile.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/login.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/language_options.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/payment/chat_freemium.dart';
import 'package:spokiai/payment/story_freemium.dart';
import 'package:spokiai/payment/SubscriptionService.dart';
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
  static const String _kAvatar = 'profile_avatar_asset';

  /// Default age for new accounts (user can change on the slider before save).
  static const int _defaultProfileAge = 22;

  /// Predefined avatar options shown in picker dialog.
  static const List<String> _avatarOptionPaths = <String>[
    'assets/images/male-1.jpeg',
    'assets/images/male-2.jpeg',
    'assets/images/male-3.jpeg',
    'assets/images/male-4.jpeg',
    'assets/images/female-1.jpeg',
    'assets/images/female-2.jpeg',
    'assets/images/female-3.jpeg',
    'assets/images/female-4.jpeg',
  ];

  String token = "";

  GetProfileResponse getProfileResponse = GetProfileResponse();

  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  String? _selectedGender;
  int _selectedAge = _defaultProfileAge;
  String? _selectedEnglishLevel;
  String? _selectedLanguage;
  String _selectedAvatarPath = _avatarOptionPaths.first;
  bool _isSavingProfile = false;

  bool _isUserNotFoundError(AppStates state) {
    final code = state.errorData?.code;
    final raw = (state.errorData?.message ?? state.error ?? '').toLowerCase();
    return code == 404 ||
        raw.contains('user not found') ||
        raw.contains('no user found');
  }

  Future<void> _forceLogoutToLogin() async {
    ChatFreemium.resetVolatileState();
    StoryFreemium.resetVolatileState();
    SubscriptionService.instance.clearSessionBillingState();
    PreferenceManager.clearPreferences();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    showToast(context: context, message: "Session expired. Please login again.");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  List<int> get _ageYears =>
      List<int>.generate(83, (i) => i + 13); // 13–95

  String? _displayGender(String? gender) {
    final g = gender?.trim().toLowerCase();
    if (g == 'male') return 'Male';
    if (g == 'female') return 'Female';
    return null;
  }

  String? _displayEnglishLevel(String? level) {
    final v = level?.trim().toLowerCase();
    if (v == 'beginner') return 'Beginner';
    if (v == 'intermediate') return 'Intermediate';
    if (v == 'fluent') return 'Fluent';
    return null;
  }

  String? get _normalizedEnglishLevel {
    final v = _selectedEnglishLevel?.trim().toLowerCase();
    if (v == 'beginner') return 'beginner';
    if (v == 'intermediate') return 'intermediate';
    if (v == 'fluent') return 'fluent';
    return null;
  }

  String? get _normalizedGender {
    final g = _selectedGender?.trim().toLowerCase();
    if (g == 'male') return 'male';
    if (g == 'female') return 'female';
    return null;
  }

  bool _isMaleAvatar(String path) => path.contains('/male-');

  List<String> _avatarOptionsByGender() {
    final g = _normalizedGender;
    if (g == 'male') {
      return _avatarOptionPaths.where(_isMaleAvatar).toList();
    }
    if (g == 'female') {
      return _avatarOptionPaths.where((p) => !_isMaleAvatar(p)).toList();
    }
    return <String>[];
  }

  void _syncAvatarToSelectedGender() {
    final filtered = _avatarOptionsByGender();
    if (filtered.isEmpty) return;
    if (!filtered.contains(_selectedAvatarPath)) {
      _selectedAvatarPath = filtered.first;
    }
  }

  @override
  void initState() {
    super.initState();
    token = PreferenceManager.getStringValue(key: "token") ?? "";
    _loadAvatarFromPrefs();
    _loadAgeFromPrefsIfValid();
    BlocProvider.of<AppCubit>(context).getProfile(token);
  }

  /// Restores age from local prefs when valid (helps if API fails); new users stay at [_defaultProfileAge].
  void _loadAgeFromPrefsIfValid() {
    final raw = PreferenceManager.getStringValue(key: _kAge)?.trim();
    if (raw == null || raw.isEmpty) return;
    final parsed = int.tryParse(raw);
    if (parsed != null && _ageYears.contains(parsed)) {
      _selectedAge = parsed;
    }
  }

  void _loadAvatarFromPrefs() {
    final avatar = PreferenceManager.getStringValue(key: _kAvatar);
    if (avatar != null &&
        avatar.isNotEmpty &&
        _avatarOptionPaths.contains(avatar)) {
      _selectedAvatarPath = avatar;
    }
    _syncAvatarToSelectedGender();
  }

  void _applyProfileDataFromApi(Data? d) {
    _selectedGender = _displayGender(d?.gender);
    final apiAge = d?.age;
    if (apiAge != null && _ageYears.contains(apiAge)) {
      _selectedAge = apiAge;
    }
    _selectedEnglishLevel = _displayEnglishLevel(d?.englishLevel);
    final language = d?.spokenLanguage?.trim();
    _selectedLanguage = (language == null || language.isEmpty) ? null : language;
    _syncAvatarToSelectedGender();
  }

  void _persistProfileExtras() {
    PreferenceManager.cacheProfileDisplayName(nameController.text);
    PreferenceManager.insertValue(
      key: _kGender,
      value: _selectedGender ?? '',
    );
    PreferenceManager.insertValue(
      key: _kAge,
      value: _selectedAge.toString(),
    );
    PreferenceManager.insertValue(
      key: _kEnglish,
      value: _selectedEnglishLevel ?? '',
    );
    PreferenceManager.insertValue(
      key: _kLanguage,
      value: _selectedLanguage ?? '',
    );
    PreferenceManager.insertValue(
      key: _kAvatar,
      value: _selectedAvatarPath,
    );
  }

  bool _validateExtrasForPostLogin() {
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      showToast(context: context, message: 'Please select gender');
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
    if (token.trim().isEmpty) {
      showToast(context: context, message: "Session expired. Please login again.");
      return;
    }

    final normalizedGender = _selectedGender?.trim().toLowerCase();
    final trimmedName = nameController.text.trim();
    final normalizedEnglish = _normalizedEnglishLevel;
    final trimmedLanguage = _selectedLanguage?.trim();

    final Map<String, dynamic> profileDetails = {
      "name": trimmedName,
      "gender": normalizedGender,
      "age": _selectedAge,
      "englishLevel": normalizedEnglish,
      "spokenLanguage": trimmedLanguage,
    }..removeWhere((key, value) =>
        value == null || (value is String && value.trim().isEmpty));

    if (profileDetails.isEmpty) {
      showToast(context: context, message: "No profile details to update.");
      return;
    }

    setState(() => _isSavingProfile = true);
    developer.log(
      "Calling update profile API",
      name: "Editprofile",
      error: profileDetails,
    );
    context.read<AppCubit>().updateProfile(
          token: token,
          profileDetails: profileDetails,
        );
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

  Future<void> _showAvatarPickerDialog() async {
    final List<String> genderAvatars = _avatarOptionsByGender();
    if (genderAvatars.isEmpty) {
      showToast(context: context, message: 'Please select gender first');
      return;
    }

    String tempSelected = _selectedAvatarPath;
    if (!genderAvatars.contains(tempSelected)) {
      tempSelected = genderAvatars.first;
    }

    final String? selectedPath = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: const Color(0xFF111B2D),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Change avatar',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(dialogContext),
                          borderRadius: BorderRadius.circular(14),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: genderAvatars.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final path = genderAvatars[index];
                        final selected = path == tempSelected;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              tempSelected = path;
                            });
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFFF8A65)
                                    : Colors.white.withOpacity(0.28),
                                width: selected ? 2.6 : 1.2,
                              ),
                              image: DecorationImage(
                                image: AssetImage(path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, tempSelected),
                        child: Text(
                          'Use this avatar',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selectedPath == null) return;
    setState(() {
      _selectedAvatarPath = selectedPath;
    });
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
          width: 28,
          height: 30,
          decoration: BoxDecoration(
            color: appColor.withOpacity(0.09),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: appColor, size: 17),
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
          height: 35,
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
              Icon(icon, color: selected ? Colors.white : appColor, size: 15),
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
          height: 38,
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
              padding: const EdgeInsets.symmetric(horizontal: 3),
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
    final double ageValue = _selectedAge.toDouble();
    return PopScope(
      canPop: !widget.isPostLoginSetup,
      child: Scaffold(
        backgroundColor: surfaceBg,
        body: BlocConsumer<AppCubit, AppStates>(
          listener: (context, state) async {
            if (state.status == AppStatus.getProfileSuccess) {
              getProfileResponse =
                  state.responseData?.response as GetProfileResponse;
              final d = getProfileResponse.data;
              emailController.text = d?.email?.toString() ?? "";
              nameController.text = d?.name?.toString() ?? "";
              PreferenceManager.cacheProfileDisplayName(d?.name);
              PreferenceManager.cacheProfileEmail(d?.email?.toString());
              setState(() {
                _applyProfileDataFromApi(d);
              });
            }

            if (state.status == AppStatus.getProfileError) {
              if (_isUserNotFoundError(state)) {
                await _forceLogoutToLogin();
                return;
              }
              showToast(
                  context: context,
                  message: state.errorData?.message.toString() ?? "");
            }

            if (_isSavingProfile &&
                state.status == AppStatus.updateProfileSuccess) {
              developer.log(
                "updateMe success",
                name: "Editprofile",
              );
              _persistProfileExtras();
              PreferenceManager.cacheProfileEmail(emailController.text.trim());
              if (!context.mounted) return;
              showToast(
                context: context,
                message: "Profile updated successfully",
                buttonColor: successColor,
              );
              setState(() => _isSavingProfile = false);
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
              return;
            }

            if (_isSavingProfile &&
                state.status == AppStatus.updateProfileError) {
              final message = state.errorData?.message.toString().trim().isNotEmpty ==
                      true
                  ? state.errorData!.message
                  : "Could not update profile. Please try again.";
              developer.log(
                "updateMe failed",
                name: "Editprofile",
                error: message,
              );
              if (!context.mounted) return;
              showToast(context: context, message: message);
              setState(() => _isSavingProfile = false);
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
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 34, 0, 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 20, 10, 8),
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
                                  const SizedBox(height: 36),
                                  Center(
                                    child: Text(
                                      'Choose profile photo',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: appColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Center(
                                    child: InkWell(
                                      onTap: _showAvatarPickerDialog,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: cardSurface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: appColor.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.cloud_upload_rounded,
                                              color: appColor,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Upload avatar',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: appColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  _sectionCard(
                                    children: [
                                      _sectionTitle(
                                          icon: Icons.person_rounded,
                                          title: "Full Name"),
                                      const SizedBox(height: 4),
                                      _outlinedField(
                                        child: TextField(
                                          controller: nameController,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: "Enter full name",
                                            hintStyle: TextStyle(color: textMuted),
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 8),
                                          ),
                                          style: TextStyle(color: textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  _sectionCard(
                                    children: [
                                      _sectionTitle(
                                          icon: Icons.male_rounded,
                                          title: "Gender"),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          _genderChip(
                                            label: "Male",
                                            icon: Icons.person,
                                            selected: _selectedGender == 'Male',
                                            onTap: () => setState(() {
                                              _selectedGender = 'Male';
                                              _syncAvatarToSelectedGender();
                                            }),
                                          ),
                                          const SizedBox(width: 8),
                                          _genderChip(
                                            label: "Female",
                                            icon: Icons.person_2_rounded,
                                            selected: _selectedGender == 'Female',
                                            onTap: () => setState(() {
                                              _selectedGender = 'Female';
                                              _syncAvatarToSelectedGender();
                                            }),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      _sectionTitle(
                                          icon: Icons.cake_rounded, title: "Age"),
                                      const SizedBox(height: 4),
                                      LayoutBuilder(
                                        builder: (context, sliderConstraints) {
                                          const double minAge = 13;
                                          const double maxAge = 95;
                                          const double bubbleSize = 40;
                                          final double progress =
                                              ((ageValue - minAge) /
                                                      (maxAge - minAge))
                                                  .clamp(0.0, 1.0);
                                          final double bubbleLeft =
                                              (sliderConstraints.maxWidth -
                                                      bubbleSize) *
                                                  progress;

                                          return SizedBox(
                                            height: 40,
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
                                                  child: IgnorePointer(
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
                                                                .withOpacity(
                                                                    0.22),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                    0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        '${ageValue.round()}',
                                                        style:
                                                            GoogleFonts.inter(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.white,
                                                        ),
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
                                  const SizedBox(height: 4),
                                  _sectionCard(
                                    children: [
                                      _sectionTitle(
                                        icon: Icons.chat_bubble_rounded,
                                        title: "English Level",
                                      ),
                                      const SizedBox(height: 4),
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
                                  const SizedBox(height: 4),
                                  _sectionCard(
                                    children: [
                                      _sectionTitle(
                                        icon: Icons.language_rounded,
                                        title: "Prefered Language",
                                      ),
                                      const SizedBox(height: 2),
                                      _outlinedField(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 0),
                                        child: InkWell(
                                          onTap: _showLanguagePicker,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: SizedBox(
                                            height: 30,
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
                                  const SizedBox(height: 5),
                                  button(
                                    context: context,
                                    width: double.infinity,
                                    title: "Save Changes",
                                    fontSize: 16 / 1.2,
                                    fontWeight: FontWeight.w700,
                                    isLoading: _isSavingProfile &&
                                        state.status ==
                                            AppStatus.updateProfileLoading,
                                    icon: Icons.save_rounded,
                                    height: 48,
                                    onPressed: _saveProfile,
                                  ),
                                ],
                              ),
                              Positioned(
                                top: -60,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: InkWell(
                                    onTap: _showAvatarPickerDialog,
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3.5,
                                        ),
                                        image: DecorationImage(
                                          image:
                                              AssetImage(_selectedAvatarPath),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
