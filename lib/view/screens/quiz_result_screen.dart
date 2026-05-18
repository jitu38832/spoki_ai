import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokiai/model/submitquiz.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/quiz_flow_result_layout.dart';
import 'package:spokiai/view/screens/story_practice_chat_screen.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/preference_manager.dart';

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String quizResult;
  final String id;
  final String storyId;
  final String storyTitle;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.quizResult,
    required this.id,
    this.storyId = '',
    this.storyTitle = '',
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  String token = "";
  SubmitQuizResponse submitQuizResponse = SubmitQuizResponse();

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

  void _openSpeakingPractice() {
    if (!mounted) return;
    final title = widget.storyTitle.trim().isEmpty
        ? 'Story practice'
        : widget.storyTitle.trim();
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => StoryPracticeChatScreen(
          storyId: widget.storyId.trim(),
          storyTitle: title,
          quizId: widget.id,
          token: token,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    token = PreferenceManager.getStringValue(key: "token") ?? "";
    BlocProvider.of<AppCubit>(context)
        .submitQuiz(token, widget.id, widget.quizResult);
  }

  int get _correct {
    return submitQuizResponse.data?.score?.correctAnswers ?? widget.score;
  }

  int get _total {
    return submitQuizResponse.data?.score?.totalQuestions ??
        widget.totalQuestions;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goToHome();
      },
      child: Scaffold(
        backgroundColor: surfaceBg,
        body: SafeArea(
          child: Column(
            children: [
              BlocConsumer<AppCubit, AppStates>(
                listener: (context, state) {
                  if (state.status == AppStatus.submitQuizSuccess) {
                    setState(() {
                      submitQuizResponse = state.responseData?.response
                              as SubmitQuizResponse? ??
                          SubmitQuizResponse();
                    });
                  }
                },
                builder: (context, state) {
                  if (state.status == AppStatus.submitQuizLoading) {
                    return Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: appColor),
                      ),
                    );
                  }

                  final apiPct = submitQuizResponse.data?.score?.percentage;
                  final server = apiPct != null
                      ? <String, dynamic>{'percentage': apiPct}
                      : null;
                  final data = QuizFlowResultData.forPostQuiz(
                    correct: _correct,
                    total: _total,
                    server: server,
                  );

                  return Expanded(
                    child: Column(
                      children: [
                        QuizFlowResultTopBar(
                          title: data.screenTitle,
                          onBack: _goToHome,
                        ),
                        Expanded(
                          child: QuizFlowResultScrollBody(
                            data: data,
                            onReviewTap: () => Navigator.pop(context, true),
                            onPracticeTap: _openSpeakingPractice,
                            onNextStepChipTap: _openSpeakingPractice,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
