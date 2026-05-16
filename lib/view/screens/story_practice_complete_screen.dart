import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/generatestory.dart';
import 'package:spokiai/view/utils/colors.dart';

/// Conversation complete screen typography (−30%).
double _completeScreenFs(double px) => px * 0.7;

/// Vertical gap between major sections / cards (−10% vs prior baseline).
double _sectionGap(double px) => px * 0.9 * 0.85 * 0.6;

/// Summary after story practice conversation — matches “Conversation Complete” mock.
class StoryPracticeCompleteScreen extends StatelessWidget {
  const StoryPracticeCompleteScreen({
    super.key,
    required this.elapsed,
    required this.questionsAnswered,
    this.serverPayload,
  });

  final Duration elapsed;
  final int questionsAnswered;
  final Map<String, dynamic>? serverPayload;

  @override
  Widget build(BuildContext context) {
    final s = _SummaryViewModel.from(
      elapsed: elapsed,
      questionsAnswered: questionsAnswered,
      server: serverPayload,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  _sectionGap(12),
                  20,
                  _sectionGap(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: _sectionGap(4)),
                    const _HeroIllustration(),
                    SizedBox(height: _sectionGap(6)),
                    Text(
                      'Conversation Complete! 🎉',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: _completeScreenFs(22),
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: _sectionGap(10)),
                    Text(
                      s.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: _completeScreenFs(14),
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    SizedBox(height: _sectionGap(24)),
                    _ScoreCard(summary: s),
                    SizedBox(height: _sectionGap(26)),
                    Text(
                      'Your Performance',
                      style: GoogleFonts.inter(
                        fontSize: _completeScreenFs(17),
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: _sectionGap(12)),
                    _PerformanceRow(summary: s),
                    SizedBox(height: _sectionGap(20)),
                    _ImprovementTipCard(text: s.improvementTip),
                    SizedBox(height: _sectionGap(14)),
                    _PremiumUpsellCard(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Premium breakdown coming soon.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, _sectionGap(12)),
              child: _StartNewStoryButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const DashboardScreen(initialTabIndex: 0),
                    ),
                    (route) => false,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    nav.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GenerateStoryScreen(),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> deriveStoryPracticeClientSummary({
  required Duration elapsed,
  required List<String> userAnswers,
}) {
  final avgLen = userAnswers.isEmpty
      ? 0.0
      : userAnswers.map((e) => e.length).reduce((a, b) => a + b) /
          userAnswers.length;
  final pct = (58 + (avgLen / 100 * 34).clamp(0, 34)).round().clamp(55, 94);
  return {
    'overallPercent': pct,
    'fluencyStars': avgLen >= 45 ? 4 : 3,
    'vocabularyStars': avgLen >= 40 ? 4 : 3,
    'grammarStars': avgLen >= 55 ? 4 : 2,
    'grammarStatus': avgLen >= 55 ? 'Good' : 'Needs Work',
  };
}

class _SummaryViewModel {
  _SummaryViewModel({
    required this.overallPercent,
    required this.scoreLabel,
    required this.subtitle,
    required this.fluencyLabel,
    required this.fluencyStars,
    required this.vocabularyLabel,
    required this.vocabularyStars,
    required this.grammarLabel,
    required this.grammarStars,
    required this.grammarStatusOrange,
    required this.improvementTip,
    required this.spokenLine,
    required this.questionsAnswered,
  });

  final int overallPercent;
  final String scoreLabel;
  final String subtitle;
  final String fluencyLabel;
  final int fluencyStars;
  final String vocabularyLabel;
  final int vocabularyStars;
  final String grammarLabel;
  final int grammarStars;
  final bool grammarStatusOrange;
  final String improvementTip;
  final String spokenLine;
  final int questionsAnswered;

  factory _SummaryViewModel.from({
    required Duration elapsed,
    required int questionsAnswered,
    Map<String, dynamic>? server,
  }) {
    final pct = _readInt(server?['overallPercent']) ??
        _readInt(server?['score']) ??
        72;
    final clampedPct = pct.clamp(0, 100);
    final label = _scoreLabelFor(clampedPct);

    final fluStars = _readInt(server?['fluencyStars']) ?? 4;
    final vocStars = _readInt(server?['vocabularyStars']) ?? 4;
    final gramStars = _readInt(server?['grammarStars']) ?? 2;
    final gramStatus = server?['grammarStatus']?.toString() ?? 'Needs Work';
    final grammarOrange = gramStatus.toLowerCase().contains('need');

    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds.remainder(60);
    final spokenLine =
        'You spoke for $m:${s.toString().padLeft(2, '0')} min';

    return _SummaryViewModel(
      overallPercent: clampedPct,
      scoreLabel: label,
      subtitle: server?['subtitle']?.toString() ??
          'Great job! You spoke clearly and understood the story well.',
      fluencyLabel: server?['fluencyLabel']?.toString() ?? 'Good',
      fluencyStars: fluStars.clamp(0, 5),
      vocabularyLabel: server?['vocabularyLabel']?.toString() ?? 'Good',
      vocabularyStars: vocStars.clamp(0, 5),
      grammarLabel: gramStatus,
      grammarStars: gramStars.clamp(0, 5),
      grammarStatusOrange: grammarOrange,
      improvementTip: server?['improvementTip']?.toString() ??
          'Try to give slightly longer answers with more details.',
      spokenLine: spokenLine,
      questionsAnswered: questionsAnswered,
    );
  }

  static int? _readInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v?.toString() ?? '');
  }

  static String _scoreLabelFor(int p) {
    if (p >= 85) return 'Excellent';
    if (p >= 70) return 'Good';
    if (p >= 55) return 'Fair';
    return 'Keep practicing';
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.summary});

  final _SummaryViewModel summary;

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFFF0EBFA);
    const deepP = Color(0xFF4A2F9E);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            height: 108,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CustomPaint(
                    painter: _DonutScorePainter(
                      progress: summary.overallPercent / 100,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${summary.overallPercent}%',
                      style: GoogleFonts.inter(
                        fontSize: _completeScreenFs(26),
                        fontWeight: FontWeight.w900,
                        color: deepP,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.scoreLabel,
                      style: GoogleFonts.inter(
                        fontSize: _completeScreenFs(12),
                        fontWeight: FontWeight.w700,
                        color: deepP.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Score',
                  style: GoogleFonts.inter(
                    fontSize: _completeScreenFs(16),
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _StatLine(
                  icon: Icons.forum_outlined,
                  text:
                      'You answered ${summary.questionsAnswered} questions',
                ),
                const SizedBox(height: 8),
                _StatLine(
                  icon: Icons.schedule_outlined,
                  text: summary.spokenLine,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: _completeScreenFs(13),
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: textPrimary.withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutScorePainter extends CustomPainter {
  _DonutScorePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const stroke = 10.0;

    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(c, r - stroke / 2, bg);

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    final fg = Paint()
      ..color = const Color(0xFF6D3BBF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - stroke / 2),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutScorePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.summary});

  final _SummaryViewModel summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PerfMiniCard(
            iconBg: appColor.withValues(alpha: 0.2),
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Fluency',
            status: summary.fluencyLabel,
            stars: summary.fluencyStars,
            goodGreen: true,
          ),
        ),
        SizedBox(width: _sectionGap(10)),
        Expanded(
          child: _PerfMiniCard(
            iconBg: successColor.withValues(alpha: 0.22),
            icon: Icons.menu_book_rounded,
            label: 'Vocabulary',
            status: summary.vocabularyLabel,
            stars: summary.vocabularyStars,
            goodGreen: true,
          ),
        ),
        SizedBox(width: _sectionGap(10)),
        Expanded(
          child: _PerfMiniCard(
            iconBg: warningColor.withValues(alpha: 0.28),
            icon: Icons.edit_rounded,
            label: 'Grammar',
            status: summary.grammarLabel,
            stars: summary.grammarStars,
            goodGreen: !summary.grammarStatusOrange,
            starOrange: summary.grammarStatusOrange,
          ),
        ),
      ],
    );
  }
}

class _PerfMiniCard extends StatelessWidget {
  const _PerfMiniCard({
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.status,
    required this.stars,
    required this.goodGreen,
    this.starOrange = false,
  });

  final Color iconBg;
  final IconData icon;
  final String label;
  final String status;
  final int stars;
  final bool goodGreen;
  final bool starOrange;

  @override
  Widget build(BuildContext context) {
    final statusColor = goodGreen
        ? const Color(0xFF2E9E6B)
        : warningColor;

    final starColor =
        starOrange ? warningColor : appColor;
    final emptyStar = starOrange
        ? warningColor.withValues(alpha: 0.25)
        : surfaceMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(7, 10, 7, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textFieldBorderColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: _completeScreenFs(12),
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: _completeScreenFs(11.5),
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final on = i < stars;
                  return Padding(
                    padding: EdgeInsets.only(right: i < 4 ? 1.5 : 0),
                    child: Icon(
                      on ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 15,
                      color: on ? starColor : emptyStar,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImprovementTipCard extends StatelessWidget {
  const _ImprovementTipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF43A047),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Improvement Tip',
                  style: GoogleFonts.inter(
                    fontSize: _completeScreenFs(14),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: _completeScreenFs(13),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumUpsellCard extends StatelessWidget {
  const _PremiumUpsellCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: appColor.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: appColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFFC9A227), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: appColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PREMIUM',
                        style: GoogleFonts.inter(
                          fontSize: _completeScreenFs(9),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Want to know your mistakes?',
                      style: GoogleFonts.inter(
                        fontSize: _completeScreenFs(14),
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'See detailed explanations and understand why your score is this.',
                      style: GoogleFonts.inter(
                        fontSize: _completeScreenFs(12),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: appColor, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartNewStoryButton extends StatelessWidget {
  const _StartNewStoryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: appColor,
        side: BorderSide(color: appColor.withValues(alpha: 0.45)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories_rounded, color: appColor, size: 22),
          Expanded(
            child: Text(
              'Start New Story',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: _completeScreenFs(16),
                fontWeight: FontWeight.w800,
                color: appColor,
              ),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }
}

/// App main logo (same asset as splash).
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  static const String _logoAsset = 'assets/images/app_icon.jpeg';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Center(
        child: Semantics(
          label: 'Spoki AI',
          child: Image.asset(
            _logoAsset,
            height: 108,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Icon(
              Icons.auto_awesome_rounded,
              size: 88,
              color: appColor,
            ),
          ),
        ),
      ),
    );
  }
}
