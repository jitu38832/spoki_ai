import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        _goToHome();
        return false; // prevent default pop
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goToHome,
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

}
