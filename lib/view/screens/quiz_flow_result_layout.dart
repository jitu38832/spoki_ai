import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/view/utils/colors.dart';

/// Typography scale for quiz / practice-complete result screens.
double quizFlowResultFs(double px) => px * 0.86;

/// Top bar + hero block: ~15% smaller type than [quizFlowResultFs].
double quizFlowResultTopFs(double px) => quizFlowResultFs(px) * 0.85;

// --- Copy: derive messaging from quiz score (client-side; backend can override via map fields). ---

class QuizFlowResultCopy {
  QuizFlowResultCopy._();

  /// [ratio] is correct/total in 0..1.
  static String titleForQuizRatio(double ratio) {
    if (ratio >= 0.85) return 'Excellent — keep going!';
    if (ratio >= 0.6) return 'Good progress — keep going!';
    if (ratio >= 0.35) return 'Nice try — keep going!';
    return 'First attempt — keep going!';
  }

  static String subtitleForQuizRatio(double ratio, {required int wrongCount}) {
    if (ratio >= 0.85) {
      return 'Great grasp of the story. Practice speaking next to make it stick.';
    }
    if (ratio >= 0.6) {
      return 'Solid effort. Review a couple of tricky details, then try speaking practice.';
    }
    if (wrongCount > 0) {
      return "You're learning! Focus on key details like names, numbers, and events to improve quickly.";
    }
    return "You're learning! Focus on key details like names, numbers, and events to improve quickly.";
  }

  static List<String> tipsForQuizRatio(double ratio, {required int wrongCount}) {
    if (ratio >= 0.85) {
      return const [
        'Explain the ending in your own words',
        'Quiz yourself on one character’s motive',
        'Practice one line aloud with expression',
      ];
    }
    if (ratio >= 0.6) {
      return const [
        'Re-read short paragraphs for key facts',
        'Note numbers and names on first pass',
        'Summarize the plot in 2 sentences',
      ];
    }
    return const [
      'Focus on names and numbers',
      'Pay attention to key events',
      'Try reading once slowly, once normally',
    ];
  }

  static bool recommendReviewForQuizRatio(double ratio) => ratio < 0.85;
}

/// View model for [QuizResultScreen] (quiz submission result).
class QuizFlowResultData {
  const QuizFlowResultData({
    required this.screenTitle,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.percent,
    required this.resultTitle,
    required this.resultSubtitle,
    required this.metaLine,
    required this.improvementTips,
    required this.recommendReview,
    required this.completedSteps,
    required this.nextStepLabel,
    required this.speakingCompleted,
  });

  final String screenTitle;
  final int correctAnswers;
  final int totalQuestions;
  final int percent;
  final String resultTitle;
  final String resultSubtitle;
  final String? metaLine;
  final List<String> improvementTips;
  final bool recommendReview;
  final int completedSteps;
  final String nextStepLabel;
  /// True when this is the post-speaking summary (all 3 steps done).
  final bool speakingCompleted;

  int get normalizedCompletedSteps => completedSteps.clamp(0, 3);
  String get progressTitle => '$normalizedCompletedSteps of 3 completed';

  /// After quiz: steps 1–2 done, speaking next. After speaking: all 3.
  factory QuizFlowResultData.forPostQuiz({
    required int correct,
    required int total,
    Map<String, dynamic>? server,
  }) {
    final t = total.clamp(1, 99);
    final c = correct.clamp(0, t);
    final ratio = c / t;
    final int pct;
    if (server != null && server['percentage'] != null) {
      pct = _readInt(server['percentage'])!.clamp(0, 100);
    } else if (server != null && server['overallPercent'] != null) {
      pct = _readInt(server['overallPercent'])!.clamp(0, 100);
    } else {
      pct = ((ratio * 100).round()).clamp(0, 100);
    }
    final wrong = (server?['wrongCount'] as int?) ??
        _readInt(server?['incorrectCount']) ??
        (t - c);

    final title = server?['resultTitle']?.toString() ??
        server?['headline']?.toString() ??
        QuizFlowResultCopy.titleForQuizRatio(ratio);
    final subtitle = server?['resultSubtitle']?.toString() ??
        server?['subtext']?.toString() ??
        QuizFlowResultCopy.subtitleForQuizRatio(ratio, wrongCount: wrong);

    final tipsAny = server?['improvementTips'] ?? server?['tips'];
    final tips = _asStringList(tipsAny);
    final safeTips = (tips.isEmpty
            ? QuizFlowResultCopy.tipsForQuizRatio(ratio, wrongCount: wrong)
            : tips)
        .take(3)
        .toList();

    final recommend = _readBool(server?['recommendReview']) ??
        QuizFlowResultCopy.recommendReviewForQuizRatio(ratio);

    return QuizFlowResultData(
      screenTitle: server?['screenTitle']?.toString() ?? 'Quiz Result',
      correctAnswers: c,
      totalQuestions: t,
      percent: pct,
      resultTitle: title,
      resultSubtitle: subtitle,
      metaLine: server?['metaLine']?.toString() ?? '${pct}% score',
      improvementTips: safeTips,
      recommendReview: recommend,
      completedSteps: _readInt(server?['progressCompletedSteps']) ?? 2,
      nextStepLabel: server?['nextStepLabel']?.toString() ??
          'Next: Speaking practice (2 min)',
      speakingCompleted: false,
    );
  }

  factory QuizFlowResultData.forSpeakingComplete({
    required Duration elapsed,
    required int questionsAnswered,
    Map<String, dynamic>? server,
  }) {
    final total = (_readInt(server?['totalQuestions']) ??
            _readInt(server?['total']) ??
            5)
        .clamp(1, 20);
    final explicitCorrect = _readInt(server?['correctAnswers']) ??
        _readInt(server?['correct']) ??
        _readInt(server?['scoreValue']);
    final rawPct = _readInt(server?['overallPercent']) ??
        _readInt(server?['percentage']) ??
        (explicitCorrect != null ? ((explicitCorrect / total) * 100).round() : null) ??
        0;
    final pct = rawPct.clamp(0, 100);
    final guessedCorrect = ((pct / 100) * total).round().clamp(0, total);
    final correct = (explicitCorrect ?? guessedCorrect).clamp(0, total);
    final ratio = total > 0 ? correct / total : 0.0;
    final wrong = (total - correct).clamp(0, total);

    final defaultTitle = QuizFlowResultCopy.titleForQuizRatio(ratio);
    final defaultSubtitle =
        QuizFlowResultCopy.subtitleForQuizRatio(ratio, wrongCount: wrong);

    final tipsAny =
        server?['improvementTips'] ?? server?['tips'] ?? server?['recommendations'];
    final tips = _asStringList(tipsAny).where((e) => e.trim().isNotEmpty).toList();
    final safeTips = (tips.isEmpty
            ? QuizFlowResultCopy.tipsForQuizRatio(ratio, wrongCount: wrong)
            : tips)
        .take(3)
        .toList();

    final mm = elapsed.inMinutes;
    final ss = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final durationLine = server?['speakingDurationLabel']?.toString() ??
        (mm > 0 ? '$mm min $ss sec' : '$ss sec');

    return QuizFlowResultData(
      screenTitle: server?['screenTitle']?.toString() ?? 'Practice complete',
      correctAnswers: correct,
      totalQuestions: total,
      percent: pct,
      resultTitle: server?['resultTitle']?.toString() ??
          server?['headline']?.toString() ??
          defaultTitle,
      resultSubtitle: server?['resultSubtitle']?.toString() ??
          server?['subtext']?.toString() ??
          defaultSubtitle,
      metaLine: 'Speaking time: $durationLine',
      improvementTips: safeTips,
      recommendReview: _readBool(server?['recommendReview']) ?? (pct < 85),
      completedSteps: _readInt(server?['progressCompletedSteps']) ??
          (questionsAnswered >= 5 ? 3 : 2),
      nextStepLabel: server?['nextStepLabel']?.toString() ??
          (questionsAnswered >= 5
              ? 'Next: Start a new story practice'
              : 'Next: Speaking practice (2 min)'),
      speakingCompleted: (server?['speakingCompleted'] as bool?) ??
          (questionsAnswered >= 5),
    );
  }

  static int? _readInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v?.toString() ?? '');
  }

  static bool? _readBool(dynamic v) {
    if (v is bool) return v;
    final s = v?.toString().trim().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return null;
  }

  static List<String> _asStringList(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return <String>[];
  }
}

// --- Shared UI ---

class QuizFlowResultTopBar extends StatelessWidget {
  const QuizFlowResultTopBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final fs = quizFlowResultTopFs;
    return Padding(
      padding: EdgeInsets.fromLTRB(fs(8), fs(4), fs(8), fs(6)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: fs(19),
                color: const Color(0xFF1D1B4A),
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: fs(22),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF171539),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizFlowResultScrollBody extends StatelessWidget {
  const QuizFlowResultScrollBody({
    super.key,
    required this.data,
    required this.onReviewTap,
    required this.onPracticeTap,
    this.onNextStepChipTap,
  });

  final QuizFlowResultData data;
  final VoidCallback onReviewTap;
  final VoidCallback onPracticeTap;
  final VoidCallback? onNextStepChipTap;

  @override
  Widget build(BuildContext context) {
    final fs = quizFlowResultFs;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(fs(16), fs(6), fs(16), fs(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultHeroCard(data: data),
          SizedBox(height: fs(14)),
          _NextStepSection(
            data: data,
            onReviewTap: onReviewTap,
            onPracticeTap: onPracticeTap,
          ),
          SizedBox(height: fs(14)),
          _ProgressCard(data: data, onNextStepTap: onNextStepChipTap),
        ],
      ),
    );
  }
}

class _ResultHeroCard extends StatelessWidget {
  const _ResultHeroCard({required this.data});

  final QuizFlowResultData data;

  @override
  Widget build(BuildContext context) {
    final fs = quizFlowResultFs;
    final topFs = quizFlowResultTopFs;
    final vm = data;
    return Container(
      padding: EdgeInsets.fromLTRB(fs(14), fs(14), fs(14), fs(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fs(20)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC778), Color(0xFFFFDFA8)],
        ),
        border: Border.all(color: const Color(0xFFFFE5BC)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: fs(118),
                height: fs(118),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFE5C9), width: 4),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: fs(10)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${vm.correctAnswers}',
                          style: GoogleFonts.inter(
                            fontSize: topFs(42),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF39A1E),
                            height: 0.88,
                          ),
                        ),
                        SizedBox(height: fs(2)),
                        Text(
                          '/ ${vm.totalQuestions}',
                          style: GoogleFonts.inter(
                            fontSize: topFs(20),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3E3B6C),
                          ),
                        ),
                        SizedBox(height: fs(3)),
                        Text(
                          '${vm.percent}%',
                          style: GoogleFonts.inter(
                            fontSize: topFs(22),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF5C5790),
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: fs(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.resultTitle,
                      style: GoogleFonts.inter(
                        fontSize: topFs(20),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF171539),
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: fs(8)),
                    Text(
                      vm.resultSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: topFs(14),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2A2752),
                        height: 1.35,
                      ),
                    ),
                    if (vm.metaLine != null && vm.metaLine!.isNotEmpty) ...[
                      SizedBox(height: fs(10)),
                      Text(
                        vm.metaLine!,
                        style: GoogleFonts.inter(
                          fontSize: topFs(12),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3C3965),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: fs(8)),
              _TrophyBooks(size: fs(98)),
            ],
          ),
          SizedBox(height: fs(12)),
          _HowToImproveCard(tips: vm.improvementTips),
        ],
      ),
    );
  }
}

class _TrophyBooks extends StatelessWidget {
  const _TrophyBooks({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: size * 0.04,
            child: Container(
              width: size * 0.78,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F2A),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.18,
            child: Container(
              width: size * 0.84,
              height: size * 0.14,
              decoration: BoxDecoration(
                color: const Color(0xFF3522A2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            top: size * 0.02,
            child: Icon(
              Icons.emoji_events_rounded,
              color: const Color(0xFFE3A600),
              size: size * 0.58,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToImproveCard extends StatelessWidget {
  const _HowToImproveCard({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    final fs = quizFlowResultFs;
    final topFs = quizFlowResultTopFs;
    return Container(
      padding: EdgeInsets.fromLTRB(fs(12), fs(12), fs(12), fs(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(fs(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: fs(34),
                height: fs(34),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4D9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: const Color(0xFFF39A1E),
                  size: topFs(20),
                ),
              ),
              SizedBox(width: fs(8)),
              Text(
                'How to improve',
                style: GoogleFonts.inter(
                  fontSize: topFs(16),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171539),
                ),
              ),
            ],
          ),
          SizedBox(height: fs(12)),
          Row(
            children: List.generate(tips.length, (index) {
              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: const Color(0xFFF39A1E),
                      size: topFs(16),
                    ),
                    SizedBox(width: fs(6)),
                    Expanded(
                      child: Text(
                        tips[index],
                        style: GoogleFonts.inter(
                          fontSize: topFs(12),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF27254A),
                          height: 1.28,
                        ),
                      ),
                    ),
                    if (index != tips.length - 1)
                      Container(
                        width: 1,
                        height: fs(38),
                        margin: EdgeInsets.symmetric(horizontal: fs(8)),
                        color: const Color(0xFFEDEAF8),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _NextStepSection extends StatelessWidget {
  const _NextStepSection({
    required this.data,
    required this.onReviewTap,
    required this.onPracticeTap,
  });

  final QuizFlowResultData data;
  final VoidCallback onReviewTap;
  final VoidCallback onPracticeTap;

  @override
  Widget build(BuildContext context) {
    final fs = quizFlowResultFs;
    final vm = data;
    return Container(
      padding: EdgeInsets.fromLTRB(fs(12), fs(12), fs(12), fs(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(fs(18)),
        border: Border.all(color: const Color(0xFFF0EEFA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: fs(22),
                decoration: BoxDecoration(
                  color: appColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(width: fs(8)),
              Text(
                'What to do next',
                style: GoogleFonts.inter(
                  fontSize: fs(16),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171539),
                ),
              ),
            ],
          ),
          SizedBox(height: fs(10)),
          _ActionCard(
            bgColor: const Color(0xFF3E22B8),
            icon: Icons.mic_rounded,
            title: vm.speakingCompleted ? 'Start next story' : 'Practice Speaking',
            subtitle: vm.speakingCompleted
                ? 'Keep improving with a fresh story conversation.'
                : 'Build confidence by turning this story into a real conversation.',
            titleColor: Colors.white,
            subtitleColor: Colors.white.withValues(alpha: 0.88),
            durationChip: vm.speakingCompleted ? null : '2–3 min',
            trailingBadge: vm.speakingCompleted ? null : 'Recommended',
            onTap: onPracticeTap,
          ),
          SizedBox(height: fs(8)),
          _ActionCard(
            bgColor: Colors.white,
            icon: Icons.visibility_rounded,
            title: 'Review & Learn',
            subtitle: 'See correct answers and learn from your mistakes.',
            titleColor: const Color(0xFF171539),
            subtitleColor: const Color(0xFF5C5A7C),
            borderColor: const Color(0xFFEDEAF8),
            onTap: onReviewTap,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.bgColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
    this.trailingBadge,
    this.durationChip,
    this.borderColor,
  });

  final Color bgColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;
  final String? trailingBadge;
  final String? durationChip;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final fs = quizFlowResultFs;
    final bool isDarkCard = bgColor.computeLuminance() < 0.3;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(fs(14)),
        child: Ink(
          padding: EdgeInsets.fromLTRB(fs(12), fs(12), fs(12), fs(12)),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(fs(14)),
            border: borderColor == null ? null : Border.all(color: borderColor!),
          ),
          child: Row(
            children: [
              Container(
                width: fs(44),
                height: fs(44),
                decoration: BoxDecoration(
                  color: isDarkCard
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF4F1FF),
                  borderRadius: BorderRadius.circular(fs(10)),
                ),
                child: Icon(
                  icon,
                  color: isDarkCard ? Colors.white : appColor,
                  size: fs(24),
                ),
              ),
              SizedBox(width: fs(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: fs(14),
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        height: 1.22,
                      ),
                    ),
                    if (durationChip != null || trailingBadge != null) ...[
                      SizedBox(height: fs(6)),
                      Wrap(
                        spacing: fs(8),
                        runSpacing: fs(6),
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (durationChip != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: fs(8),
                                vertical: fs(3),
                              ),
                              decoration: BoxDecoration(
                                color: isDarkCard
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : const Color(0xFFF1EDFF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                durationChip!,
                                style: GoogleFonts.inter(
                                  fontSize: fs(10.5),
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDarkCard ? Colors.white : appColor,
                                ),
                              ),
                            ),
                          if (trailingBadge != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: fs(10),
                                vertical: fs(4),
                              ),
                              decoration: BoxDecoration(
                                color: isDarkCard
                                    ? Colors.white
                                    : const Color(0xFFF1EDFF),
                                borderRadius: BorderRadius.circular(999),
                                border: isDarkCard
                                    ? null
                                    : Border.all(
                                        color: appColor.withValues(alpha: 0.25),
                                      ),
                              ),
                              child: Text(
                                trailingBadge!,
                                style: GoogleFonts.inter(
                                  fontSize: fs(11),
                                  fontWeight: FontWeight.w700,
                                  color: appColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    SizedBox(height: fs(4)),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: fs(12),
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: fs(8)),
              Container(
                width: fs(34),
                height: fs(34),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkCard
                        ? Colors.transparent
                        : appColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: appColor,
                  size: fs(24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.data,
    this.onNextStepTap,
  });

  final QuizFlowResultData data;
  final VoidCallback? onNextStepTap;

  @override
  Widget build(BuildContext context) {
    final fs = quizFlowResultFs;
    final vm = data;
    final doneColor = const Color(0xFF2E9E6B);
    final speakingDone = vm.normalizedCompletedSteps >= 3;

    final content = Container(
      padding: EdgeInsets.fromLTRB(fs(12), fs(12), fs(12), fs(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(fs(18)),
        border: Border.all(color: const Color(0xFFF0EEFA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress 🎉',
                style: GoogleFonts.inter(
                  fontSize: fs(16),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF171539),
                ),
              ),
              Text(
                vm.progressTitle,
                style: GoogleFonts.inter(
                  fontSize: fs(12),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3F3C6D),
                ),
              ),
            ],
          ),
          SizedBox(height: fs(14)),
          Row(
            children: [
              _ProgressNode(
                icon: Icons.menu_book_rounded,
                title: 'Story',
                subtitle: 'Completed',
                completed: true,
              ),
              _ProgressDash(completed: vm.normalizedCompletedSteps > 1),
              _ProgressNode(
                icon: Icons.fact_check_rounded,
                title: 'Quiz',
                subtitle: 'Completed',
                completed: vm.normalizedCompletedSteps > 1,
              ),
              _ProgressDash(completed: vm.normalizedCompletedSteps > 2),
              _ProgressNode(
                icon: Icons.mic_rounded,
                title: 'Speaking',
                subtitle: speakingDone ? 'Completed' : 'Next up',
                completed: speakingDone,
                subtitleColor: speakingDone ? doneColor : appColor,
              ),
            ],
          ),
          SizedBox(height: fs(12)),
          Material(
            color: const Color(0xFFF5F1FF),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onNextStepTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: fs(12), vertical: fs(8)),
                child: Row(
                  children: [
                    Container(
                      width: fs(20),
                      height: fs(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5DCFF),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(Icons.mic_rounded, color: appColor, size: fs(14)),
                    ),
                    SizedBox(width: fs(8)),
                    Expanded(
                      child: Text(
                        vm.nextStepLabel,
                        style: GoogleFonts.inter(
                          fontSize: fs(13),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2A2752),
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: appColor, size: fs(20)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return content;
  }
}

class _ProgressNode extends StatelessWidget {
  const _ProgressNode({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.completed,
    this.subtitleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool completed;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final fs = quizFlowResultFs;
    return Expanded(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: fs(40),
                height: fs(40),
                decoration: BoxDecoration(
                  color: completed ? appColor : const Color(0xFFF2EEFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: completed ? Colors.white : appColor,
                  size: fs(20),
                ),
              ),
              if (completed)
                Positioned(
                  right: -fs(1),
                  top: -fs(1),
                  child: Container(
                    width: fs(16),
                    height: fs(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E9E6B),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: fs(11),
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: fs(8)),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: fs(11.5),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF171539),
            ),
          ),
          SizedBox(height: fs(2)),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: fs(10.5),
              fontWeight: FontWeight.w700,
              color: subtitleColor ?? const Color(0xFF2E9E6B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDash extends StatelessWidget {
  const _ProgressDash({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final fs = quizFlowResultFs;
    return SizedBox(
      width: fs(26),
      child: Divider(
        height: 1,
        thickness: 1.2,
        color: completed
            ? appColor.withValues(alpha: 0.45)
            : const Color(0xFFD9D7E9),
      ),
    );
  }
}
