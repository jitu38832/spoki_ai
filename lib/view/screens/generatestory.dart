import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/generatestory.dart';
import 'package:spokiai/view/screens/storyDescription.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/custom_widgets.dart';

class GenerateStoryScreen extends StatefulWidget {
  const GenerateStoryScreen({super.key});

  @override
  State<GenerateStoryScreen> createState() => _GenerateStoryScreenState();
}

class _GenerateStoryScreenState extends State<GenerateStoryScreen> {
  static const Color _bg = Color(0xFFF2EEFC);
  static const Color _mainCard = Color(0xFFF7F5FC);
  static const Color _innerCard = Color(0xFFF8F6FD);
  static const Color _border = Color(0xFFE3DCF3);
  static const Color _textPrimary = Color(0xFF0F1230);
  static const Color _textSecondary = Color(0xFF5F6077);
  static const Color _purpleA = Color(0xFF4C18E8);
  static const Color _purpleB = Color(0xFF8F4FFF);
  final TextEditingController _storyDescriptionController =
      TextEditingController();
  String _selectedLength = 'Short';
  String _selectedGenre = 'Fantasy';
  final String _selectedStyle = 'Random';
  String? _selectedLevel;

  String token = "";

  final List<String> genres = [
    'Adventure',
    'Fantasy',
    'Science Fiction',
    'Mystery',
    'Thriller',
    'Horror',
    'Drama',
    'Historical',
    'Comedy',
    'Motivational'
  ];

  static const List<String> _learningLevelLabels = [
    'Level 1 (Starter)',
    'Level 2 (Beginner)',
    'Level 3 (Intermediate)',
    'Level 4 (Fluent)',
  ];

  static const List<String> _lengthOptions = ['Short', 'Medium', 'Long'];

  static const Map<String, IconData> _genreIcons = {
    'Adventure': Icons.terrain_rounded,
    'Fantasy': Icons.castle_rounded,
    'Science Fiction': Icons.rocket_launch_rounded,
    'Mystery': Icons.search_rounded,
    'Thriller': Icons.gavel_rounded,
    'Horror': Icons.emoji_emotions_rounded,
    'Drama': Icons.theater_comedy_rounded,
    'Historical': Icons.account_balance_rounded,
    'Comedy': Icons.sentiment_very_satisfied_rounded,
    'Motivational': Icons.star_rounded,
  };

  static const Map<String, Color> _genreColors = {
    'Adventure': Color(0xFF3F51D8),
    'Fantasy': Color(0xFF7E2EDD),
    'Science Fiction': Color(0xFF17A2C6),
    'Mystery': Color(0xFFFF9800),
    'Thriller': Color(0xFFEA3A3A),
    'Horror': Color(0xFF2A2F36),
    'Drama': Color(0xFF2CA33A),
    'Historical': Color(0xFF8A5A33),
    'Comedy': Color(0xFFFFB300),
    'Motivational': Color(0xFFE53D83),
  };

  @override
  void initState() {
    token = PreferenceManager.getStringValue(key: "token") ?? "";
    super.initState();
  }

  @override
  void dispose() {
    _storyDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? surfaceBg : _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: const EdgeInsets.fromLTRB(11, 16, 11, 14),
              decoration: BoxDecoration(
                color: isDark ? cardSurface : _mainCard,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark ? const Color(0xFF2F2F3F) : _border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: appColor.withOpacity(isDark ? 0.12 : 0.09),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.arrow_back_rounded, size: 30),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "Create Story",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? textPrimary : _textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.auto_awesome, color: appColor, size: 22),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _softSection(children: [
                    _buildTopicField(),
                    const SizedBox(height: 12),
                    _buildLengthTabs(),
                  ]),
                  const SizedBox(height: 12),
                  _softSection(children: [
                    _sectionTitle("Choose Story Genre"),
                    const SizedBox(height: 10),
                    _buildGenreDropdown(),
                  ]),
                  const SizedBox(height: 12),
                  _softSection(children: [
                    _sectionTitle("Select Your Level"),
                    const SizedBox(height: 10),
                    _buildLearningLevelSection(),
                  ]),
                  const SizedBox(height: 14),
                  BlocConsumer<AppCubit, AppStates>(
                    listener: (context, state) {
                      if (state.status == AppStatus.generateStorySuccess) {
                        GenerateStoryResponse generateStoryResponse =
                            state.responseData?.response as GenerateStoryResponse;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StorydescriptionScreen(
                              generateStoryResponse: generateStoryResponse,
                            ),
                          ),
                        );
                      }
                      if (state.status == AppStatus.generateStoryError) {
                        showToast(
                          context: context,
                          message: state.errorData?.message.toString() ?? "",
                        );
                      }
                    },
                    builder: (context, state) {
                      final loading =
                          state.status == AppStatus.generateStoryLoading;
                      return _bigGenerateButton(loading);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: isDark ? textSecondary : _textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Read the story and chat with AI to practice",
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? textSecondary : _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
      );

  Widget _softSection({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _innerCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildTopicField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _storyDescriptionController,
        maxLines: 1,
        minLines: 1,
        cursorColor: appColor,
        decoration: InputDecoration(
          hintText: "Enter a topic (e.g., travel, interview, daily life)",
          hintMaxLines: 2,
          isDense: true,
          hintStyle: GoogleFonts.inter(
            fontSize: 10.8,
            fontWeight: FontWeight.w500,
            color: textMuted,
            height: 1.2,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
      ),
    );
  }

  Widget _buildLengthTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: _lengthOptions.map((option) {
          final isSelected = _selectedLength == option;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedLength = option),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [_purpleA, _purpleB])
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: !isSelected
                      ? Border.all(color: Colors.transparent)
                      : null,
                ),
                child: Center(
                  child: Text(
                    option,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenreDropdown() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: InkWell(
        onTap: _showGenrePicker,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (_genreColors[_selectedGenre] ?? appColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _genreIcons[_selectedGenre] ?? Icons.auto_awesome_rounded,
                  color: _genreColors[_selectedGenre] ?? appColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedGenre,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? textSecondary : const Color(0xFF4D3E78),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGenrePicker() async {
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: ListView.separated(
              itemCount: genres.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final genre = genres[index];
                final icon = _genreIcons[genre] ?? Icons.auto_awesome_rounded;
                final color = _genreColors[genre] ?? appColor;
                final selected = _selectedGenre == genre;
                return InkWell(
                  onTap: () => Navigator.pop(context, genre),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 84,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: appColor.withOpacity(0.45)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            genre,
                            style: GoogleFonts.inter(
                              fontSize: 20 / 1.2,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: appColor.withOpacity(0.7),
                              width: 2,
                            ),
                            color: selected ? appColor : Colors.transparent,
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedGenre = selected);
    }
  }

  Widget _buildLearningLevelSection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 54,
      ),
      itemCount: _learningLevelLabels.length,
      itemBuilder: (context, index) {
        return _buildLevelButton(_learningLevelLabels[index]);
      },
    );
  }

  Widget _buildLevelButton(String label) {
    final isSelected = _selectedLevel == label;
    final display = label
        .replaceAll('Level 1 (', '')
        .replaceAll('Level 2 (', '')
        .replaceAll('Level 3 (', '')
        .replaceAll('Level 4 (', '')
        .replaceAll(')', '');
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = isSelected ? null : label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_purpleA, _purpleB])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : _border,
            width: 1.2,
          ),
        ),
        child: Text(
          display,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : _textPrimary,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.clip,
        ),
      ),
    );
  }

  Widget _bigGenerateButton(bool loading) {
    return InkWell(
      onTap: loading
          ? null
          : () {
              if (isValidation()) {
                FocusManager.instance.primaryFocus?.unfocus();
                final storyDetails = {
                  "stroyDescription": _storyDescriptionController.text.trim(),
                  "storyLength": _selectedLength.toLowerCase(),
                  "genre": _selectedGenre,
                  "style": _selectedStyle,
                  "learningLevel": _selectedLevel.toString().contains('(')
                      ? _selectedLevel
                          .toString()
                          .split('(')[1]
                          .replaceAll(')', '')
                          .trim()
                          .toLowerCase()
                      : _selectedLevel.toString().toLowerCase(),
                };
                BlocProvider.of<AppCubit>(context).generateStory(token, storyDetails);
              }
            },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_purpleA, _purpleB]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: brandShadow(opacity: 0.28, blur: 16),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      "Generate & Practice Story",
                      style: GoogleFonts.inter(
                        fontSize: 17 / 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  bool isValidation() {
    if (_storyDescriptionController.text.trim().isEmpty) {
      showToast(context: context, message: "Please enter story heading");
      return false;
    }
    if (_selectedLevel == null) {
      showToast(context: context, message: "Please select learning level");
      return false;
    }
    return true;
  }
}
