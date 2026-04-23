import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/getprofile.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
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

  static const List<String> _englishLevels = [
    'Beginner',
    'Intermediate',
    'Fluent',
  ];

  static const List<String> _spokenLanguages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'Arabic',
    'Bengali',
    'Portuguese',
    'Russian',
    'Japanese',
    'German',
    'Korean',
    'Italian',
    'Turkish',
    'Vietnamese',
    'Thai',
    'Urdu',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Mandarin Chinese',
    'Other',
  ];

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

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: textFieldBorderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: textFieldBorderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: appColor, width: 1.5),
      ),
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.grey,
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return textRoboto(
      text: title,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: Colors.black,
    );
  }

  Widget _pillChoiceRow({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _pill(
              label: options[i],
              selected: selected == options[i],
              onTap: () => onSelect(options[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? appColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? appColor : textFieldBorderColor,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isPostLoginSetup,
      child: Scaffold(
        backgroundColor: surfaceBg,
        appBar: AppBar(
          automaticallyImplyLeading: !widget.isPostLoginSetup,
          title: Text(widget.isPostLoginSetup
              ? "Complete your profile"
              : "Edit Profile"),
          backgroundColor: surfaceBg,
        ),
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFieldWidget(
                    title: 'Name',
                    controller: nameController,
                    textFieldBorderColor: textFieldBorderColor,
                    textInputType: TextInputType.name,
                    textColor: Colors.black,
                    hint: 'Enter name',
                    maxLines: 1,
                    hintColor: Theme.of(context).colorScheme.secondary,
                    context: context,
                  ),
                  const SizedBox(height: 20),
                  TextFieldWidget(
                    title: 'Email Id',
                    controller: emailController,
                    textFieldBorderColor: textFieldBorderColor,
                    textInputType: TextInputType.emailAddress,
                    textColor: Colors.black,
                    hint: 'Enter Email Id',
                    maxLines: 1,
                    hintColor: Theme.of(context).colorScheme.secondary,
                    context: context,
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('Gender'),
                  const SizedBox(height: 10),
                  _pillChoiceRow(
                    options: const ['Male', 'Female'],
                    selected: _selectedGender,
                    onSelect: (v) => setState(() => _selectedGender = v),
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('Age (years)'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _selectedAge,
                    isExpanded: true,
                    decoration: _dropdownDecoration('Select age'),
                    hint: Text(
                      'Select age',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    items: _ageYears
                        .map(
                          (y) => DropdownMenuItem<int>(
                            value: y,
                            child: Text('$y'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAge = v),
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('What is your English level?'),
                  const SizedBox(height: 10),
                  _pillChoiceRow(
                    options: _englishLevels,
                    selected: _selectedEnglishLevel,
                    onSelect: (v) =>
                        setState(() => _selectedEnglishLevel = v),
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('Which language do you speak?'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage != null &&
                            _spokenLanguages.contains(_selectedLanguage)
                        ? _selectedLanguage
                        : null,
                    isExpanded: true,
                    decoration:
                        _dropdownDecoration('Select language'),
                    hint: Text(
                      'Select language',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    items: _spokenLanguages
                        .map(
                          (lang) => DropdownMenuItem<String>(
                            value: lang,
                            child: Text(lang),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedLanguage = v),
                  ),
                  const SizedBox(height: 36),
                  button(
                    context: context,
                    width: double.infinity,
                    title: widget.isPostLoginSetup
                        ? "Continue"
                        : "Update Profile",
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    isLoading: false,
                    icon: Icons.check_circle_rounded,
                    onPressed: () async {
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
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
