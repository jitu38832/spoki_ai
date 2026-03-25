import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/generatestory.dart';
import 'package:spokiai/view/screens/storyDescription.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/custom_navigator.dart';
import '../utils/custom_widgets.dart';
import 'dashboard.dart';

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
  String _selectedStyle = 'Random';
  String? _selectedLevel;

  String token = "";

  // Color scheme
  final Color purpleColor = const Color(0xFF9B59B6);
  final Color tealColor = const Color(0xFF1ABC9C);
  final Color lightBlue = const Color(0xFF87CEEB);
  final Color darkGrey = const Color(0xFF2C3E50);
  final Color greenColor = const Color(0xFF4CAF50);

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
  @override
  void initState() {
    token = PreferenceManager.getStringValue(key: "token") ?? "";

    print(token);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Generate Story",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        // Centers the title
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Icon & text color
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Logo and App Name
                // _buildHeader(),
                // const SizedBox(height: 32),

                // Story Description Input
                _buildStoryDescriptionInput(),
                const SizedBox(height: 24),

                // Story Length Selection
                _buildStoryLengthSelection(),
                const SizedBox(height: 24),

                // Genre dropdown

                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textRoboto(
                            text: "Select Genre",
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                        const SizedBox(height: 10),
                        _buildGenreDropdown(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.transparent),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        _buildLearningLevelSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                SpaceWidget(height: 20),
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
                    return state.status == AppStatus.generateStoryLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: appColor,
                            ),
                          )
                        : Card(
                            elevation: 6,
                            shadowColor: appColor.withOpacity(0.8),
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: appColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // CustomNavigator.push(
                                    //   context: context,
                                    //   screen:  StorydescriptionScreen()
                                    // );

                                    if (isValidation()) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();

                                      Map<String, dynamic> storyDetails = {
                                        "stroyDescription":
                                            _storyDescriptionController.text
                                                .toString()
                                                .trim(),
                                        "storyLength": _selectedLength
                                            .toString()
                                            .toLowerCase(),
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
                                            : _selectedLevel
                                                .toString()
                                                .toLowerCase(),
                                        // "provider": "openai"
                                      };

                                      print(storyDetails);
                                      BlocProvider.of<AppCubit>(context)
                                          .generateStory(token, storyDetails);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Center(
                                    child: textInter(
                                      text: "Generate Story",
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/images/iv_app_icon2.png',
            height: MediaQuery.of(context).size.height * 0.2,
          )
        ],
      ),
    );
  }

  Widget _buildStoryDescriptionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2, // <-- Increased border width
        ),
        borderRadius: BorderRadius.circular(12),

        // ---- Shadow added ----
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _storyDescriptionController,
        maxLines: 1,
        decoration: InputDecoration(
          hintText: "Describe your Story...",
          hintStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 20,
          ),
        ),
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildStoryLengthSelection() {
    return Card(
      elevation: 6,
      shadowColor: appColor.withOpacity(0.8),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            color: appColor),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: _buildLengthButton('Short',
                    isSelected: _selectedLength == 'Short'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLengthButton('Medium',
                    isSelected: _selectedLength == 'Medium'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLengthButton('Long',
                    isSelected: _selectedLength == 'Long'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLengthButton(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLength = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? orangeColor : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            textInter(
              text: label,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreDropdown() {
    return Card(
      elevation: 6,
      shadowColor: appColor.withOpacity(0.8),
      child: Container(
        decoration: BoxDecoration(
          color: appColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedGenre,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: InputBorder.none,
            hintText: "Select Genre",
            hintStyle: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
          ),
          icon: const SizedBox.shrink(),
          dropdownColor: Colors.black,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
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
      ),
    );
  }

  static const List<String> _learningLevelLabels = [
    'Level 1 (Starter)',
    'Level 2 (Beginner)',
    'Level 3 (Intermediate)',
    'Level 4 (Fluent)',
  ];

  TextStyle _levelButtonLabelStyle() {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.25,
    );
  }

  /// Row height for the learning-level grid from actual label wrapping at this width.
  double _learningLevelMainAxisExtent(BuildContext context, double gridMaxWidth) {
    const crossAxisSpacing = 10.0;
    const horizontalPadding = 4.0;
    const verticalPaddingTotal = 16.0;
    const safety = 6.0;

    final cellWidth = (gridMaxWidth - crossAxisSpacing) / 2;
    final textMaxWidth =
        (cellWidth - horizontalPadding * 2).clamp(48.0, double.infinity);

    final textScaler = MediaQuery.textScalerOf(context);
    final style = _levelButtonLabelStyle();
    var maxTextHeight = 0.0;
    for (final label in _learningLevelLabels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(maxWidth: textMaxWidth);
      maxTextHeight = max(maxTextHeight, painter.size.height);
    }

    return max(56.0, maxTextHeight + verticalPaddingTotal + safety);
  }

  Widget _buildLearningLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textInter(
          text: "Learning Level",
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: darkGrey,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final mainExtent =
                _learningLevelMainAxisExtent(context, constraints.maxWidth);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: mainExtent,
              ),
              itemCount: _learningLevelLabels.length,
              itemBuilder: (context, index) {
                return _buildLevelButton(_learningLevelLabels[index]);
              },
            );
          },
        ),
      ],
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
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 6,
        shadowColor: isSelected
            ? orangeColor.withOpacity(0.8)
            : Colors.black.withOpacity(0.7),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? orangeColor : Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? orangeColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: _levelButtonLabelStyle(),
            textAlign: TextAlign.center,
            maxLines: 4,
            softWrap: true,
            overflow: TextOverflow.clip,
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateStoryButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: appColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: greenColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // CustomNavigator.push(
            //   context: context,
            //   screen:  StoryDescriptionScreen(storyTitle: 'The Clockmakers Secret', storyContent: 'Test Description', wordCount: 100,)
            // );
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: textInter(
              text: "Generate Story",
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  bool isValidation() {
    if (_storyDescriptionController.text.toString().trim().isEmpty) {
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
