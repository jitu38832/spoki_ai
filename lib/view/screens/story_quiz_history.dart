import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/quizhistory.dart';
import 'package:spokiai/view/screens/quiz_result_screen.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import '../../model/quizques.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/custom_widgets.dart';
import '../utils/preference_manager.dart';

class QuizHistoryScreen extends StatefulWidget {
  final String id;

  const QuizHistoryScreen({super.key, required this.id});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  int currentQuestionIndex = 0;

  List<QuestionsHistory> questions = [];
  List<String> userSelectedAnswers = [];
  Map<int, bool> isCorrectMap = {};

  QuizHistoryResponse quizHistoryResponse = QuizHistoryResponse();
  String token = "";

  @override
  void initState() {
    super.initState();
    token = PreferenceManager.getStringValue(key: "token") ?? "";
    BlocProvider.of<AppCubit>(context).quizHistory(token, widget.id);
  }

  void _processQuizHistory() {
    if (questions.isEmpty) return;

    userSelectedAnswers = List.filled(questions.length, "");
    isCorrectMap.clear();

    final userAnswers = quizHistoryResponse.data?.score?.userAnswers ?? [];

    for (var userAns in userAnswers) {
      int idx = userAns.questionIndex ?? -1;
      if (idx >= 0 && idx < questions.length) {
        userSelectedAnswers[idx] = userAns.userAnswer ?? "";
        isCorrectMap[idx] = userAns.isCorrect ?? false;
      }
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      // Navigate to result screen
      final scoreData = quizHistoryResponse.data?.score;
      if (scoreData != null && mounted) {
        Navigator.pop(context);
      }
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
                      onTap: _nextQuestion,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          textInter(
                            text: currentQuestionIndex < questions.length - 1
                                ? "NEXT"
                                : "Go Back",
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
              text: "Story Quiz History",
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            Image.asset("assets/images/iv_bulb.png", height: 30, width: 30),
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
              if (state.status == AppStatus.quizHistorySuccess) {
                quizHistoryResponse =
                state.responseData?.response as QuizHistoryResponse;
                if (quizHistoryResponse.data?.questions?.isNotEmpty ?? false) {
                  setState(() {
                    questions = quizHistoryResponse.data!.questions!;
                    _processQuizHistory();
                  });
                }
              }
            },
            builder: (context, state) {
              if (state.status == AppStatus.quizHistoryLoading) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (questions.isEmpty) {
                return const Center(child: Text("No questions available"));
              }

              final currentQuestion = questions[currentQuestionIndex];
              final userAnswer = userSelectedAnswers[currentQuestionIndex];
              final wasCorrect = isCorrectMap[currentQuestionIndex] ?? false;

              // Safely get explanation
              final explanations = currentQuestion.explanations ?? [];
              String explanationText = "No explanation available.";

              if (explanations.isNotEmpty) {
                final correctExplanation = explanations.firstWhere(
                      (e) => e.isCorrect == true,
                  orElse: () => explanations.first, // fallback if somehow no isCorrect=true
                );
                explanationText = correctExplanation.explanation ?? "No explanation available.";
              }

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
                      maxLines: 10,
                      textAlign: TextAlign.start,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 30),

                    // Options (Review only - no interaction)
                    ...currentQuestion.options!.asMap().entries.map((entry) {
                      int index = entry.key;
                      String option = entry.value;
                      String letter = String.fromCharCode(65 + index);

                      bool isUserSelected = option == userAnswer;
                      bool isCorrectOption = option == currentQuestion.correctAnswer;

                      Color borderColor = Colors.grey[300]!;
                      Color bgColor = Colors.grey[100]!;
                      Color circleColor = Colors.grey[400]!;

                      // Correct answer always green
                      if (isCorrectOption) {
                        borderColor = Colors.green;
                        bgColor = Colors.green[50]!;
                        circleColor = Colors.green;
                      }

                      // User's wrong answer → red
                      if (isUserSelected && !wasCorrect) {
                        borderColor = Colors.red;
                        bgColor = Colors.red[50]!;
                        circleColor = Colors.red;
                      }

                      // User's correct answer → green circle (already handled above)
                      if (isUserSelected && wasCorrect) {
                        circleColor = Colors.green;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: (isUserSelected || isCorrectOption) ? 3 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: circleColor,
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
                              SizedBox(
                                width: MediaQuery.of(context).size.width*0.65,
                                child: textInter(
                                  text: option,
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
                      );
                    }).toList(),

                    const SizedBox(height: 30),

                    // Explanation Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: wasCorrect ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: wasCorrect ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            wasCorrect ? Icons.check_circle : Icons.error,
                            color: wasCorrect ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: textInter(
                              text: explanationText,
                              fontSize: 15,
                              maxLines: 5,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Previous & Next Buttons

                    const SizedBox(height: 40),
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