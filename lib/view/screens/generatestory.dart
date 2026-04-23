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
    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Generate Story"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroIntro(),
              const SizedBox(height: 20),
              _fieldLabel("What is your story about?"),
              const SizedBox(height: 8),
              _buildStoryDescriptionInput(),
              const SizedBox(height: 22),
              _fieldLabel("Story Length"),
              const SizedBox(height: 10),
              _buildStoryLengthSelection(),
              const SizedBox(height: 22),
              _fieldLabel("Genre"),
              const SizedBox(height: 10),
              _buildGenreDropdown(),
              const SizedBox(height: 22),
              _fieldLabel("Learning Level"),
              const SizedBox(height: 10),
              _buildLearningLevelSection(),
              const SizedBox(height: 28),
              BlocConsumer<AppCubit, AppStates>(
                listener: (context, state) {
                  if (state.status == AppStatus.generateStorySuccess) {
                    GenerateStoryResponse generateStoryResponse =
                        state.responseData?.response as GenerateStoryResponse;

                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return StorydescriptionScreen(
                            generateStoryResponse: generateStoryResponse);
                      },
                    ));
                  }

                  if (state.status == AppStatus.generateStoryError) {
                    showToast(
                        context: context,
                        message: state.errorData?.message.toString() ?? "");
                  }
                },
                builder: (context, state) {
                  final loading =
                      state.status == AppStatus.generateStoryLoading;
                  return button(
                    context: context,
                    width: double.infinity,
                    title:
                        loading ? "Crafting your story…" : "Generate Story",
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    isLoading: loading,
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () {
                      if (isValidation()) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        final storyDetails = {
                          "stroyDescription":
                              _storyDescriptionController.text.trim(),
                          "storyLength": _selectedLength.toLowerCase(),
                          "genre": _selectedGenre,
                          "style": _selectedStyle,
                          "learningLevel": _selectedLevel
                                  .toString()
                                  .contains('(')
                              ? _selectedLevel
                                  .toString()
                                  .split('(')[1]
                                  .replaceAll(')', '')
                                  .trim()
                                  .toLowerCase()
                              : _selectedLevel.toString().toLowerCase(),
                        };
                        BlocProvider.of<AppCubit>(context)
                            .generateStory(token, storyDetails);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIntro() {
    return GradientCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Craft your next story",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "AI tailors every story to your level and interests.",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      );

  Widget _buildStoryDescriptionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceMuted),
        boxShadow: softCardShadow(),
      ),
      child: TextField(
        controller: _storyDescriptionController,
        maxLines: 2,
        minLines: 1,
        cursorColor: appColor,
        decoration: InputDecoration(
          hintText: "e.g. A curious fox exploring the clouds…",
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(Icons.edit_rounded, color: appColor, size: 20),
        ),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _buildStoryLengthSelection() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(14),
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
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? brandGradient : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? brandShadow(opacity: 0.2, blur: 10)
                      : null,
                ),
                child: Center(
                  child: Text(
                    option,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : textSecondary,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: surfaceMuted),
        boxShadow: softCardShadow(),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGenre,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          border: InputBorder.none,
          prefixIcon:
              Icon(Icons.local_movies_rounded, color: appColor, size: 20),
        ),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: appColor),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        items: genres.map((genre) {
          return DropdownMenuItem(
            value: genre,
            child: Text(genre),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedGenre = value!;
          });
        },
      ),
    );
  }

  Widget _buildLearningLevelSection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 62,
      ),
      itemCount: _learningLevelLabels.length,
      itemBuilder: (context, index) {
        return _buildLevelButton(_learningLevelLabels[index]);
      },
    );
  }

  Widget _buildLevelButton(String label) {
    final isSelected = _selectedLevel == label;
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
          gradient: isSelected ? tealGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : surfaceMuted,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tealColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : softCardShadow(),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : textPrimary,
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
