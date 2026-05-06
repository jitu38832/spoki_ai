import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/submitquiz.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/custom_widgets.dart';
import '../utils/preference_manager.dart';

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String quizResult;
  final String id;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.quizResult,
    required this.id,
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

  @override
  void initState() {
    super.initState();
    token = PreferenceManager.getStringValue(key: "token") ?? "";
    BlocProvider.of<AppCubit>(context)
        .submitQuiz(token, widget.id, widget.quizResult);
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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: _goToHome,
          ),
          title: const Text("Quiz Result"),
          backgroundColor: surfaceBg,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: BlocConsumer<AppCubit, AppStates>(
              listener: (context, state) {
                if (state.status == AppStatus.submitQuizSuccess) {
                  submitQuizResponse =
                      state.responseData?.response as SubmitQuizResponse;
                }
              },
              builder: (context, state) {
                if (state.status == AppStatus.submitQuizLoading) {
                  return Center(
                      child:
                          CircularProgressIndicator(color: appColor));
                }
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildScoreCard(),
                      const SizedBox(height: 26),
                      _buildActionButtons(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final correct = submitQuizResponse.data?.score?.correctAnswers ??
        widget.score;
    final total =
        submitQuizResponse.data?.score?.totalQuestions ?? widget.totalQuestions;
    final percent = total > 0 ? (correct / total) : 0.0;
    final message =
        submitQuizResponse.data?.score?.message?.toString() ??
            "Great effort!";

    final accent = percent >= 0.75
        ? successColor
        : percent >= 0.5
            ? appColor
            : warningColor;

    return GradientCard(
      gradient: LinearGradient(
        colors: [
          accent,
          accent.withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    "$correct",
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "out of $total",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "${(percent * 100).round()}%",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        button(
          context: context,
          width: double.infinity,
          title: "Review Your Answers",
          fontSize: 15,
          fontWeight: FontWeight.w700,
          icon: Icons.visibility_rounded,
          isLoading: false,
          onPressed: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 14),
        outlineButton(
          context: context,
          width: double.infinity,
          title: "Create a New Story",
          icon: Icons.auto_stories_rounded,
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              ),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}
