import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokiai/model/submitquiz.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/custom_widgets.dart';
import '../utils/preference_manager.dart';
import 'home.dart';
import 'story_quiz_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  String quizResult = "";
  String id = "";

  QuizResultScreen({
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

  bool _isCurrentScore(int scoreValue) {
    // Normalize to 5-point scale for display
    final normalizedScore = (widget.score * 5 / widget.totalQuestions).round();
    return normalizedScore == scoreValue;
  }

  @override
  void initState() {
    super.initState();

    print("Selected otpions");
    print(widget.quizResult);
    token = PreferenceManager.getStringValue(key: "token") ?? "";
    BlocProvider.of<AppCubit>(context).submitQuiz(
        token, widget.id, widget.quizResult);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // SAME as AppBar back
        return false; // prevent default pop
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
          title: Row(
            children: [
              textInter(
                text: "Quiz Result",
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
          // Centers the title
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
            child: BlocConsumer<AppCubit, AppStates>(
              listener: (context, state) {
                  if(state.status==AppStatus.submitQuizSuccess){
                    submitQuizResponse= state.responseData?.response as SubmitQuizResponse;


                  }
              },
              builder: (context, state) {

                if(state.status==AppStatus.submitQuizLoading){
                  return SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: appColor,
                      ),
                    ),
                  );
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildScoreSection(),
                    const SizedBox(height: 40),

                    // Action Buttons
                    _buildActionButtons(),
                    const SizedBox(height: 40),

                    // Scoring Legend/Feedback Section
                    // _buildScoringLegend(),
                    // const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSection() {
    return Column(
      children: [
        // "Great job!" with emojis
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const Text(
            //   '🎉',
            //   style: TextStyle(fontSize: 32),
            // ),
            const SizedBox(width: 12),
            SizedBox(
              width: MediaQuery.of(context).size.width*0.8,
              child: textInter(
                text: submitQuizResponse.data?.score?.message.toString()??"",
                fontSize: 20,
                maxLines: 5,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            // const Text(
            //   '🎉',
            //   style: TextStyle(fontSize: 32),
            // ),
          ],
        ),
        const SizedBox(height: 16),
        // Score text
        textInter(
          text: "You scored ${submitQuizResponse.data?.score?.correctAnswers.toString()} out of ${submitQuizResponse.data?.score?.totalQuestions.toString()}",
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ],
    );
  }


  Widget _buildActionButtons() {
    return Column(
      children: [
        // Play Again Button
        Card(
          elevation: 6,
          shadowColor: appColor.withOpacity(0.8),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: appColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context, true);
                },
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: textInter(
                    text: "Review Your Answer",
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Create a New Story Button
        Card(
          elevation: 6,
          shadowColor: appColor.withOpacity(0.8),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: appColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                        (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: textInter(
                    text: "Creat a New Story",
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoringLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildScoreItem(
            "0/5", "Time To Review! Great Attempt.", _isCurrentScore(0)),
        const SizedBox(height: 12),
        _buildScoreItem("1/5", "Promising Start!", _isCurrentScore(1)),
        const SizedBox(height: 12),
        _buildScoreItem("2/5", "Solid Effort!", _isCurrentScore(2)),
        const SizedBox(height: 12),
        _buildScoreItem("3/5", "Great Job!", _isCurrentScore(3)),
        const SizedBox(height: 12),
        _buildScoreItem("4/5", "Excellent!", _isCurrentScore(4)),
        const SizedBox(height: 12),
        _buildScoreItem("5/5", "You Crushed it!", _isCurrentScore(5)),
      ],
    );
  }

  Widget _buildScoreItem(String score, String message, bool isCurrent) {
    return textInter(
      text: "$score= $message",
      fontSize: 14,
      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
      color: isCurrent ? Colors.black : Colors.grey[600],
    );
  }
}
