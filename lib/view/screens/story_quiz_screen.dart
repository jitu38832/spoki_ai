import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/view/screens/quiz_result_screen.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import '../../model/quizques.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/custom_widgets.dart';
import '../utils/preference_manager.dart';

class StoryQuizScreen extends StatefulWidget {
  Map<String, dynamic> quizDetails = {};

  StoryQuizScreen({super.key, required this.quizDetails});

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

  @override
  void initState() {
    super.initState();
    token = PreferenceManager.getStringValue(key: "token") ?? "";
    BlocProvider.of<AppCubit>(context).getQuizQues(token, widget.quizDetails);
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        // Load the saved state for previous question
        if (selectedAnswers.length > currentQuestionIndex) {
          _loadSavedAnswer();
        } else {
          // If no answer yet (shouldn't happen normally)
          _selectedAnswer = null;
          _isAnswered = false;
          _isCorrect = false;
          _explanation = null;
        }
      });
    }
  }

  void _nextQuestion() async {
    // NEXT QUESTION
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _isAnswered = false;
        _isCorrect = false;
        _explanation = null;
        _selectedAnswer = null;
      });

      if (isReviewMode) {
        _loadSavedAnswer();
      }
      return;
    }

    // ================= SUBMIT / DONE =================
    if (isReviewMode) {
      Navigator.pop(context);
      return;
    }

    // NORMAL SUBMIT MODE
    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i].correctAnswer) {
        score++;
      }
    }

    final Map<String, dynamic> result = {
      "answers": selectedAnswers,
    };

    final review = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          score: score,
          totalQuestions: questions.length,
          quizResult: const JsonEncoder.withIndent(' ').convert(result),
          id: quesResponse.data?.id.toString() ?? "",
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

      // Save answer
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

        // === Always show correct explanation in review mode too ===
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar:  Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Previous Button
            Expanded(
              child: Card(
                elevation: currentQuestionIndex > 0 ? 6 : 2,
                shadowColor: appColor.withOpacity(0.8),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: currentQuestionIndex > 0 ? appColor : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: currentQuestionIndex > 0 ? _previousQuestion : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_back, color: Colors.white),
                          const SizedBox(width: 8),
                          textInter(
                            text: "PREVIOUS",
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Next / Submit / Done Button
            Expanded(
              child: Card(
                elevation: 6,
                shadowColor: appColor.withOpacity(0.8),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: appColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isAnswered ? _nextQuestion : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          textInter(
                            text: isReviewMode
                                ? (currentQuestionIndex < questions.length - 1
                                ? "NEXT"
                                : "DONE")
                                : (currentQuestionIndex < questions.length - 1
                                ? "NEXT"
                                : "SUBMIT"),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            textInter(
              text: "Story Recall Quiz",
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              textAlign: TextAlign.left,
            ),
            Image.asset(
              "assets/images/iv_bulb.png",
              height: 30,
              width: 30,
            )
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: BlocConsumer<AppCubit, AppStates>(
            listener: (context, state) {
              if (state.status == AppStatus.getQuizQuesSuccess) {
                quesResponse = state.responseData?.response as QuizQuesResponse;
                if (quesResponse.data?.questions?.isNotEmpty ?? false) {
                  setState(() {
                    questions = quesResponse.data!.questions!;
                  });
                }
              }
            },
            builder: (context, state) {
              if (state.status == AppStatus.getQuizQuesLoading) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (questions.isEmpty) {
                return const Center(child: Text("No questions loaded"));
              }

              final currentQuestion = questions[currentQuestionIndex];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Question ${currentQuestionIndex + 1} of ${questions.length}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),

                    textInter(
                      text: currentQuestion.question ?? "",
                      fontSize: 18,
                      maxLines: 5,
                      textAlign: TextAlign.start,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 30),

                    ...currentQuestion.options!.asMap().entries.map((entry) {
                      int index = entry.key;
                      String fullOption = entry.value;
                      String letter = String.fromCharCode(65 + index);
                      String optionText = fullOption.trim();

                      final isSelected = _selectedAnswer == fullOption;
                      final isCorrectOption = fullOption == currentQuestion.correctAnswer;

                      Color borderColor = Colors.grey[300]!;
                      Color bgColor = Colors.grey[200]!;

                      if (_isAnswered) {
                        if (isSelected && _isCorrect) {
                          borderColor = Colors.green;
                          bgColor = Colors.green[50]!;
                        } else if (isSelected && !_isCorrect) {
                          borderColor = Colors.red;
                          bgColor = Colors.red[50]!;
                        } else if (isCorrectOption) {
                          borderColor = Colors.green;
                          bgColor = Colors.green[50]!;
                        }
                      } else if (isSelected) {
                        borderColor = appColor;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: (_isAnswered || isReviewMode)
                              ? null
                              : () => _checkAnswer(fullOption),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                                width: _isAnswered && (isSelected || isCorrectOption)
                                    ? 3
                                    : (isSelected ? 2 : 1),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _isAnswered
                                        ? (isCorrectOption
                                        ? Colors.green
                                        : (isSelected && !_isCorrect
                                        ? Colors.red
                                        : Colors.grey[400]))
                                        : (isSelected ? appColor : Colors.grey[400]),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    letter,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: textInter(
                                    text: optionText,
                                    fontSize: 16,
                                    maxLines: 5,
                                    textAlign: TextAlign.start,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    // Explanation
                    if (_isAnswered) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          // color: _isCorrect ? Colors.green[50] : Colors.red[50],
                          color: _isCorrect ? Colors.green[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCorrect ? Colors.green : Colors.green,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _isCorrect?SizedBox():   textInter(
                              text: "Correct Answer:",
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              maxLines: 10,
                              color: Colors.black,
                            ),
                            _isCorrect?SizedBox(): SizedBox(
                              height: 10,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _isCorrect?  Icon(
                                  _isCorrect ? Icons.check_circle : Icons.error,
                                  color: _isCorrect ? Colors.green : Colors.red,
                                ):SizedBox(),
                                _isCorrect?  const SizedBox(width: 12):SizedBox(),
                                Expanded(
                                  child: textInter(
                                    text: _explanation ?? "No explanation available.",
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    maxLines: 10,
                                    textAlign: TextAlign.start,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // Previous & Next Buttons Row
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}