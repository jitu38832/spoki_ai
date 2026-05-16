import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/quiz_result_screen.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import '../../model/quizques.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/custom_widgets.dart';
import '../utils/preference_manager.dart';

class StoryQuizScreen extends StatefulWidget {
  final Map<String, dynamic> quizDetails;
  final Map<String, dynamic>? preloadedQuizData;

  const StoryQuizScreen({
    super.key,
    required this.quizDetails,
    this.preloadedQuizData,
  });

  @override
  State<StoryQuizScreen> createState() => _StoryQuizScreenState();
}

class _StoryQuizScreenState extends State<StoryQuizScreen> {
  int currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _isCorrect = false;
  String? _explanation;

  List<Questions> questions = [];
  bool isReviewMode = false;

  List<String> selectedAnswers = [];

  QuizQuesResponse quesResponse = QuizQuesResponse();
  String token = "";

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(initialTabIndex: 0),
      ),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    token = PreferenceManager.getStringValue(key: "token") ?? "";
    final pre = widget.preloadedQuizData;
    if (pre != null && pre.isNotEmpty) {
      try {
        quesResponse = QuizQuesResponse.fromJson({
          'success': true,
          'data': pre,
        });
        final q = quesResponse.data?.questions;
        if (q != null && q.isNotEmpty) {
          questions = List<Questions>.from(q);
          selectedAnswers = List.filled(questions.length, '');
        }
      } catch (_) {
        questions = [];
      }
    }
    if (questions.isEmpty) {
      BlocProvider.of<AppCubit>(context)
          .getQuizQues(token, widget.quizDetails);
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        if (selectedAnswers.length > currentQuestionIndex) {
          _loadSavedAnswer();
        } else {
          _selectedAnswer = null;
          _isAnswered = false;
          _isCorrect = false;
          _explanation = null;
        }
      });
    }
  }

  void _nextQuestion() async {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _isAnswered = false;
        _isCorrect = false;
        _explanation = null;
        _selectedAnswer = null;
      });
      if (isReviewMode) _loadSavedAnswer();
      return;
    }

    if (isReviewMode) {
      Navigator.pop(context);
      return;
    }

    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i].correctAnswer) {
        score++;
      }
    }

    final Map<String, dynamic> result = {"answers": selectedAnswers};

    final review = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          score: score,
          totalQuestions: questions.length,
          quizResult: const JsonEncoder.withIndent(' ').convert(result),
          id: quesResponse.data?.id.toString() ?? "",
          storyId: widget.quizDetails['storyId']?.toString() ??
              quesResponse.data?.inputParams?.storyId ??
              quesResponse.data?.story?.id ??
              '',
          storyTitle: quesResponse.data?.story?.title ??
              quesResponse.data?.metadata?.title ??
              '',
        ),
      ),
    );

    if (review == true) {
      setState(() {
        isReviewMode = true;
        currentQuestionIndex = 0;
      });
      _loadSavedAnswer();
    }
  }

  void _checkAnswer(String selected) {
    final correct = questions[currentQuestionIndex].correctAnswer;
    final explanations = questions[currentQuestionIndex].explanations ?? [];

    setState(() {
      _selectedAnswer = selected;
      _isAnswered = true;
      _isCorrect = selected == correct;

      if (selectedAnswers.length > currentQuestionIndex) {
        selectedAnswers[currentQuestionIndex] = selected;
      } else {
        selectedAnswers.add(selected);
      }

      if (explanations.isNotEmpty) {
        final correctExp = explanations.firstWhere(
          (e) => e.isCorrect == true,
          orElse: () => explanations.first,
        );
        _explanation = correctExp.explanation ?? "No explanation available.";
      } else {
        _explanation = "No explanation available.";
      }
    });
  }

  void _loadSavedAnswer() {
    if (selectedAnswers.length > currentQuestionIndex) {
      final selected = selectedAnswers[currentQuestionIndex];
      final correct = questions[currentQuestionIndex].correctAnswer;
      final explanations = questions[currentQuestionIndex].explanations ?? [];

      setState(() {
        _selectedAnswer = selected;
        _isAnswered = true;
        _isCorrect = selected == correct;

        if (explanations.isNotEmpty) {
          final correctExp = explanations.firstWhere(
            (e) => e.isCorrect == true,
            orElse: () => explanations.first,
          );
          _explanation =
              correctExp.explanation ?? "No explanation available.";
        } else {
          _explanation = "No explanation available.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goToHome();
      },
      child: Scaffold(
        backgroundColor: surfaceBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: _goToHome,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_rounded, color: warningColor, size: 22),
              const SizedBox(width: 8),
              const Text("Story Recall Quiz"),
            ],
          ),
          backgroundColor: surfaceBg,
        ),
        bottomNavigationBar: _buildBottomNav(),
        body: SafeArea(
          child: BlocConsumer<AppCubit, AppStates>(
            listener: (context, state) {
              if (state.status == AppStatus.getQuizQuesSuccess) {
                quesResponse =
                    state.responseData?.response as QuizQuesResponse;
                if (quesResponse.data?.questions?.isNotEmpty ?? false) {
                  setState(() {
                    questions = quesResponse.data!.questions!;
                    selectedAnswers = List.filled(questions.length, '');
                  });
                }
              }
            },
            builder: (context, state) {
              if (questions.isEmpty &&
                  state.status == AppStatus.getQuizQuesLoading) {
                return Center(
                    child:
                        CircularProgressIndicator(color: appColor));
              }
              if (questions.isEmpty) {
                return const Center(child: Text("No questions loaded"));
              }

              final currentQuestion = questions[currentQuestionIndex];
              final progress =
                  (currentQuestionIndex + 1) / questions.length;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgress(progress),
                    const SizedBox(height: 22),
                    SectionCard(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        currentQuestion.question ?? "",
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._buildOptions(currentQuestion),
                    if (_isAnswered) ...[
                      const SizedBox(height: 20),
                      _buildExplanation(),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Question ${currentQuestionIndex + 1} of ${questions.length}",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: appColor,
              ),
            ),
            const Spacer(),
            Text(
              "${(progress * 100).round()}%",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tealDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: surfaceMuted,
            valueColor: AlwaysStoppedAnimation(appColor),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptions(Questions currentQuestion) {
    return currentQuestion.options!.asMap().entries.map((entry) {
      int index = entry.key;
      String fullOption = entry.value;
      String letter = String.fromCharCode(65 + index);

      final isSelected = _selectedAnswer == fullOption;
      final isCorrectOption =
          fullOption == currentQuestion.correctAnswer;

      Color borderColor = surfaceMuted;
      Color bgColor = Colors.white;
      Color letterBg = surfaceMuted;

      if (_isAnswered) {
        if (isCorrectOption) {
          borderColor = successColor;
          bgColor = tealSoft;
          letterBg = successColor;
        } else if (isSelected && !_isCorrect) {
          borderColor = errorColor;
          bgColor = errorColor.withOpacity(0.08);
          letterBg = errorColor;
        }
      } else if (isSelected) {
        borderColor = appColor;
        bgColor = appColor.withOpacity(0.06);
        letterBg = appColor;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: (_isAnswered || isReviewMode)
              ? null
              : () => _checkAnswer(fullOption),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.4),
              boxShadow: isSelected || _isAnswered
                  ? [
                      BoxShadow(
                        color: borderColor.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: letterBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    fullOption,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildExplanation() {
    final color = _isCorrect ? successColor : warningColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              _isCorrect
                  ? Icons.check_rounded
                  : Icons.lightbulb_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCorrect ? "Correct!" : "Heads up",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _explanation ?? "",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final last = currentQuestionIndex == questions.length - 1;
    final nextLabel = isReviewMode
        ? (last ? "Done" : "Next")
        : (last ? "Submit" : "Next");
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          if (currentQuestionIndex > 0) ...[
            Expanded(
              child: outlineButton(
                context: context,
                width: double.infinity,
                title: "Previous",
                icon: Icons.arrow_back_rounded,
                onPressed: _previousQuestion,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: button(
              context: context,
              width: double.infinity,
              title: nextLabel,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              icon: last
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_rounded,
              isLoading: false,
              onPressed: _isAnswered ? _nextQuestion : null,
            ),
          ),
        ],
      ),
    );
  }
}
