import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/submitquiz.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/story_practice_chat_screen.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/preference_manager.dart';

/// Quiz completion hero — matches product mockup (deep purple + warm orange).
const Color _quizDeepPurple = Color(0xFF3B2697);
const Color _quizOrangeTop = Color(0xFFFFB75E);
const Color _quizOrangeDeep = Color(0xFFF09819);

/// Whole-screen typography scale (−20%).
double _qfs(double px) => px * 0.8;

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
              _QuizAppBar(onBack: _goToHome),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(_qfs(20), _qfs(8), _qfs(20), _qfs(20)),
                  child: BlocConsumer<AppCubit, AppStates>(
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
                        return Center(
                          child: CircularProgressIndicator(color: appColor),
                        );
                      }
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeroCard(context),
                            SizedBox(height: _qfs(20)),
                            _buildReadyToSpeakCard(),
                            SizedBox(height: _qfs(18)),
                            _buildPracticeButton(),
                            SizedBox(height: _qfs(12)),
                            _buildReviewButton(),
                            SizedBox(height: _qfs(22)),
                            _buildProgressCard(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get _correct {
    return submitQuizResponse.data?.score?.correctAnswers ?? widget.score;
  }

  int get _total {
    return submitQuizResponse.data?.score?.totalQuestions ??
        widget.totalQuestions;
  }

  double get _percent {
    final apiPct = submitQuizResponse.data?.score?.percentage;
    if (apiPct != null && _total > 0) {
      return (apiPct / 100).clamp(0.0, 1.0);
    }
    if (_total <= 0) return 0;
    return (_correct / _total).clamp(0.0, 1.0);
  }

  String get _headline {
    final p = _percent;
    if (p >= 0.8) return "Outstanding — you nailed it! ⭐";
    if (p >= 0.5) return "Nice work — keep it up! ⭐";
    return "Keep going— you're learning. ⭐";
  }

  String get _subtext {
    final p = _percent;
    if (p >= 0.8) {
      return "Turn this story into a real conversation and keep the momentum.";
    }
    if (p >= 0.5) {
      return "Review anything tricky, then practice speaking to go further.";
    }
    return "Review the story and try again, or practice speaking to improve faster.";
  }

  String get _emoji {
    final p = _percent;
    if (p >= 0.8) return "🎉";
    if (p >= 0.5) return "😊";
    return "😟";
  }

  String get _improvementBody {
    final wrong = submitQuizResponse.data?.userAnswers
            ?.where((a) => a.isCorrect == false)
            .length ??
        0;
    if (wrong > 0) {
      return "You missed questions about details in the story.";
    }
    return "Solid grasp of the story — polish speaking to make it stick.";
  }

  Widget _buildHeroCard(BuildContext context) {
    final pctLabel = "${(_percent * 100).round()}%";

    return ClipRRect(
      borderRadius: BorderRadius.circular(_qfs(20)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _quizOrangeTop,
                    _quizOrangeDeep.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: _qfs(28),
            top: _qfs(20),
            child: Icon(Icons.star_rounded,
                size: _qfs(14),
                color: Colors.white.withValues(alpha: 0.45)),
          ),
          Positioned(
            left: _qfs(36),
            top: _qfs(48),
            child: Icon(Icons.star_rounded,
                size: _qfs(10),
                color: Colors.white.withValues(alpha: 0.35)),
          ),
          Positioned(
            left: -20,
            bottom: -12,
            child: Container(
              width: 100,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          Positioned(
            right: -16,
            bottom: 8,
            child: Container(
              width: 72,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_qfs(18), _qfs(22), _qfs(18), _qfs(18)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      SizedBox(
                        width: _qfs(118),
                        height: _qfs(118),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: _total <= 0
                                    ? null
                                    : _percent.clamp(0.0, 1.0),
                                strokeWidth: _qfs(9),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.28),
                                valueColor: const AlwaysStoppedAnimation(
                                    Colors.white),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "$_correct",
                                  style: GoogleFonts.inter(
                                    fontSize: _qfs(36),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: _qfs(2)),
                                Text(
                                  "out of $_total",
                                  style: GoogleFonts.inter(
                                    fontSize: _qfs(11),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white
                                        .withValues(alpha: 0.92),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _qfs(12)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: _qfs(18), vertical: _qfs(7)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          pctLabel,
                          style: GoogleFonts.inter(
                            fontSize: _qfs(15),
                            fontWeight: FontWeight.w800,
                            color: _quizOrangeDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.only(left: _qfs(4), top: _qfs(4)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: _qfs(40),
                          height: _qfs(40),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _emoji,
                            style: TextStyle(fontSize: _qfs(22)),
                          ),
                        ),
                        SizedBox(height: _qfs(10)),
                        Text(
                          _headline,
                          style: GoogleFonts.inter(
                            fontSize: _qfs(15) * 1.1,
                            fontWeight: FontWeight.w800,
                            color: _quizDeepPurple,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: _qfs(6)),
                        Text(
                          _subtext,
                          style: GoogleFonts.inter(
                            fontSize: _qfs(12),
                            fontWeight: FontWeight.w500,
                            color: _quizDeepPurple.withValues(alpha: 0.88),
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: _qfs(10)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 260),
                                child: Container(
                                  padding: EdgeInsets.fromLTRB(
                                      _qfs(12),
                                      _qfs(12),
                                      _qfs(12),
                                      _qfs(12)),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(_qfs(16)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.lightbulb_rounded,
                                          color: _quizOrangeDeep
                                              .withValues(alpha: 0.9),
                                          size: _qfs(26)),
                                      SizedBox(width: _qfs(10)),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "What to improve?",
                                              textAlign: TextAlign.left,
                                              style: GoogleFonts.inter(
                                                fontSize: _qfs(14) * 0.95,
                                                fontWeight: FontWeight.w800,
                                                color: _quizDeepPurple,
                                              ),
                                            ),
                                            SizedBox(height: _qfs(4)),
                                            Text(
                                              _improvementBody,
                                              textAlign: TextAlign.left,
                                              style: GoogleFonts.inter(
                                                fontSize: _qfs(12.5) * 0.95,
                                                fontWeight: FontWeight.w500,
                                                color: _quizDeepPurple
                                                    .withValues(alpha: 0.85),
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToSpeakCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(_qfs(16), _qfs(16), _qfs(16), _qfs(20)),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(_qfs(18)),
        border: Border.all(color: textFieldBorderColor),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _qfs(48),
                height: _qfs(48),
                decoration: BoxDecoration(
                  color: surfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mic_rounded,
                    color: _quizDeepPurple, size: _qfs(26)),
              ),
              SizedBox(width: _qfs(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ready to speak?",
                      style: GoogleFonts.inter(
                        fontSize: _qfs(15),
                        fontWeight: FontWeight.w800,
                        color: _quizDeepPurple,
                      ),
                    ),
                    SizedBox(height: _qfs(6)),
                    Text(
                      "Turn this story into a real conversation and build your speaking confidence.",
                      style: GoogleFonts.inter(
                        fontSize: _qfs(12.5),
                        fontWeight: FontWeight.w500,
                        color: _quizDeepPurple.withValues(alpha: 0.82),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: _qfs(8),
            bottom: -_qfs(4),
            child: CustomPaint(
              size: Size(_qfs(36), _qfs(28)),
              painter: _CurlyArrowPainter(color: _quizOrangeDeep),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openSpeakingPractice,
        borderRadius: BorderRadius.circular(_qfs(18)),
        child: Ink(
          padding: EdgeInsets.symmetric(
              horizontal: _qfs(16), vertical: _qfs(16)),
          decoration: BoxDecoration(
            color: _quizDeepPurple,
            borderRadius: BorderRadius.circular(_qfs(18)),
            boxShadow: [
              BoxShadow(
                color: _quizDeepPurple.withValues(alpha: 0.28),
                blurRadius: _qfs(16),
                offset: Offset(0, _qfs(8)),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: _qfs(44),
                height: _qfs(44),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mic_rounded,
                    color: Colors.white, size: _qfs(22)),
              ),
              SizedBox(width: _qfs(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "Practice This Story",
                            style: GoogleFonts.inter(
                              fontSize: _qfs(15),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: _qfs(8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: _qfs(8), vertical: _qfs(3)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "2–3 min",
                            style: GoogleFonts.inter(
                              fontSize: _qfs(10),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _qfs(4)),
                    Text(
                      "Turn this story into a real conversation",
                      style: GoogleFonts.inter(
                        fontSize: _qfs(11.5),
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: _qfs(36),
                height: _qfs(36),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded,
                    color: _quizDeepPurple, size: _qfs(22)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, true),
        borderRadius: BorderRadius.circular(_qfs(18)),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: _qfs(16), vertical: _qfs(14)),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(_qfs(18)),
            border: Border.all(color: _quizDeepPurple, width: _qfs(1.5)),
          ),
          child: Row(
            children: [
              Container(
                width: _qfs(44),
                height: _qfs(44),
                decoration: BoxDecoration(
                  color: surfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.visibility_rounded,
                    color: _quizDeepPurple, size: _qfs(22)),
              ),
              SizedBox(width: _qfs(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Review Answers",
                      style: GoogleFonts.inter(
                        fontSize: _qfs(15),
                        fontWeight: FontWeight.w800,
                        color: _quizDeepPurple,
                      ),
                    ),
                    SizedBox(height: _qfs(3)),
                    Text(
                      "See correct answers and explanations",
                      style: GoogleFonts.inter(
                        fontSize: _qfs(11.5),
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: _quizDeepPurple, size: _qfs(24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(_qfs(16), _qfs(16), _qfs(16), _qfs(20)),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(_qfs(18)),
        border: Border.all(color: textFieldBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your Progress 🎉",
                style: GoogleFonts.inter(
                  fontSize: _qfs(14),
                  fontWeight: FontWeight.w800,
                  color: _quizDeepPurple,
                ),
              ),
              Text(
                "2 of 3 completed",
                style: GoogleFonts.inter(
                  fontSize: _qfs(12),
                  fontWeight: FontWeight.w600,
                  color: _quizDeepPurple.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          SizedBox(height: _qfs(20)),
          _ProgressTimeline(),
        ],
      ),
    );
  }
}

class _QuizAppBar extends StatelessWidget {
  const _QuizAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_qfs(8), _qfs(4), _qfs(8), _qfs(8)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: _qfs(18)),
              color: _quizDeepPurple,
            ),
          ),
          Text(
            "Quiz Result",
            style: GoogleFonts.inter(
              fontSize: _qfs(17),
              fontWeight: FontWeight.w800,
              color: _quizDeepPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimelineNode(
            icon: Icons.menu_book_rounded,
            filled: true,
            label: "Story",
            subLabel: "Completed",
            subColor: const Color(0xFF2E9E6B),
            showCheck: true,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: _qfs(18)),
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: textFieldBorderColor.withValues(alpha: 0.9),
                strokeWidth: _qfs(1.2),
              ),
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          ),
        ),
        Expanded(
          child: _TimelineNode(
            icon: Icons.fact_check_rounded,
            filled: true,
            label: "Quiz",
            subLabel: "Completed",
            subColor: const Color(0xFF2E9E6B),
            showCheck: true,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: _qfs(18)),
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: textFieldBorderColor.withValues(alpha: 0.9),
                strokeWidth: _qfs(1.2),
              ),
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          ),
        ),
        Expanded(
          child: _TimelineNode(
            icon: Icons.mic_rounded,
            filled: false,
            label: "Speaking",
            subLabel: "Next up",
            subColor: _quizDeepPurple,
            showCheck: false,
          ),
        ),
      ],
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.icon,
    required this.filled,
    required this.label,
    required this.subLabel,
    required this.subColor,
    required this.showCheck,
  });

  final IconData icon;
  final bool filled;
  final String label;
  final String subLabel;
  final Color subColor;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _qfs(46),
              height: _qfs(46),
              decoration: BoxDecoration(
                color: filled ? _quizDeepPurple : surfaceSoft,
                shape: BoxShape.circle,
                border: filled
                    ? null
                    : Border.all(
                        color: _quizDeepPurple.withValues(alpha: 0.25),
                      ),
              ),
              child: Icon(
                icon,
                color: filled ? Colors.white : _quizDeepPurple,
                size: _qfs(22),
              ),
            ),
            if (showCheck)
              Positioned(
                right: -_qfs(2),
                top: -_qfs(2),
                child: Container(
                  width: _qfs(18),
                  height: _qfs(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E9E6B),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      size: _qfs(12), color: Colors.white),
                ),
              ),
          ],
        ),
        SizedBox(height: _qfs(10)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: _qfs(11),
            fontWeight: FontWeight.w700,
            color: _quizDeepPurple,
          ),
        ),
        SizedBox(height: _qfs(2)),
        Text(
          subLabel,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: _qfs(10),
            fontWeight: FontWeight.w600,
            color: subColor,
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final dash = _qfs(4.0);
    final gap = _qfs(3.0);
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CurlyArrowPainter extends CustomPainter {
  _CurlyArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _qfs(2.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(4, 2)
      ..quadraticBezierTo(size.width * 0.9, 4, size.width * 0.55, 14)
      ..quadraticBezierTo(size.width * 0.25, 22, size.width * 0.35, 26);

    canvas.drawPath(path, paint);
    final tip = Offset(size.width * 0.42, 26);
    canvas.drawLine(tip, tip + const Offset(-4, -3), paint);
    canvas.drawLine(tip, tip + const Offset(2, -4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
