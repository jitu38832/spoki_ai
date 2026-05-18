import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/view/utils/colors.dart';

/// Typography and UI scale for conversation / quiz-practice complete
/// (~28% smaller than base px: prior 0.8 × further 0.9).
double cpcFs(double px) => px * 0.72;

// ═══════════════════════════════════════════════════════════════════════════
// Backend contract (`storyPractice:complete` / quiz_practice_complete):
//
// Return a JSON object the client merges over local fallbacks. Supported keys:
//
// • overall_score (int 0–100) — also: overallPercent, overall_percent
// • score_label (string) — e.g. "Good", "Excellent"
// • completion_message (string) — subtitle under title; also: completionMessage
//
// • stats (object, optional)
//   - questions_answered (int) — also: questionsAnswered
//   - speaking_duration (string) — e.g. "2:15 min"; client formats from elapsed if omitted
//
// • performance_metrics (array, optional) — also: performanceMetrics
//   Each item: { "label": "Fluency", "status_text": "Good", "rating_stars": 4,
//                "color_theme": "purple"|"green"|"orange" }
//
// • improvement_tip (string) — one actionable line; also: improvementTip
//
// • premium (object, optional) — { "title", "subtitle", "badge" } for future A/B copy
//
// Focus on conversational quality (fluency / vocabulary / grammar), not MCQ quiz copy.
// ═══════════════════════════════════════════════════════════════════════════

class ConversationPracticeMetric {
  const ConversationPracticeMetric({
    required this.label,
    required this.statusText,
    required this.stars,
    required this.theme,
  });

  final String label;
  final String statusText;
  final int stars;
  final String theme;

  Color get statusColor {
    switch (theme) {
      case 'orange':
        return const Color(0xFFE65100);
      case 'green':
        return const Color(0xFF2E7D32);
      case 'purple':
      default:
        return appColor;
    }
  }

  Color get starColor {
    switch (theme) {
      case 'orange':
        return const Color(0xFFFF9800);
      case 'green':
        return const Color(0xFF7B1FA2);
      case 'purple':
      default:
        return const Color(0xFF7B1FA2);
    }
  }
}

class ConversationCompleteViewModel {
  const ConversationCompleteViewModel({
    required this.overallPercent,
    required this.scoreLabel,
    required this.title,
    required this.subtitle,
    required this.questionsAnswered,
    required this.speakingDurationLabel,
    required this.metrics,
    required this.improvementTip,
    this.premiumTitle = 'Want to know your mistakes?',
    this.premiumSubtitle =
        'See detailed explanations and understand why your score is this.',
    this.premiumBadge = 'PREMIUM',
  });

  final int overallPercent;
  final String scoreLabel;
  final String title;
  final String subtitle;
  final int questionsAnswered;
  final String speakingDurationLabel;
  final List<ConversationPracticeMetric> metrics;
  final String improvementTip;
  final String premiumTitle;
  final String premiumSubtitle;
  final String premiumBadge;

  static ConversationCompleteViewModel fromPayload({
    required Duration elapsed,
    required int questionsAnswered,
    Map<String, dynamic>? payload,
  }) {
    final p = payload ?? {};

    int pct = _readInt(p['overall_score']) ??
        _readInt(p['overallPercent']) ??
        _readInt(p['overall_percent']) ??
        72;
    pct = pct.clamp(0, 100);

    final stats = p['stats'] is Map
        ? Map<String, dynamic>.from(p['stats']! as Map)
        : <String, dynamic>{};

    final qa = _readInt(stats['questions_answered']) ??
        _readInt(stats['questionsAnswered']) ??
        questionsAnswered;

    final durStr = stats['speaking_duration']?.toString().trim();
    final speakingLabel =
        (durStr != null && durStr.isNotEmpty) ? durStr : _formatSpeakingDuration(elapsed);

    final scoreLabel = (p['score_label'] ?? p['scoreLabel'])?.toString().trim() ??
        _defaultScoreLabel(pct);

    final subtitle = (p['completion_message'] ??
            p['completionMessage'] ??
            p['resultSubtitle'])
        ?.toString()
        .trim() ??
        _defaultSubtitle(pct);

    final metrics = _parseMetrics(p['performance_metrics'] ?? p['performanceMetrics']) ??
        _defaultMetrics(pct);

    final tip = (p['improvement_tip'] ?? p['improvementTip'])?.toString().trim() ??
        _defaultImprovementTip(pct);

    final prem = p['premium'] is Map ? Map<String, dynamic>.from(p['premium']! as Map) : null;

    return ConversationCompleteViewModel(
      overallPercent: pct,
      scoreLabel: scoreLabel,
      title: (p['screen_title'] ?? p['conversationTitle'])?.toString().trim() ??
          'Conversation Complete! 🎉',
      subtitle: subtitle,
      questionsAnswered: qa.clamp(0, 99),
      speakingDurationLabel: speakingLabel,
      metrics: metrics,
      improvementTip: tip,
      premiumTitle:
          prem?['title']?.toString() ?? 'Want to know your mistakes?',
      premiumSubtitle: prem?['subtitle']?.toString() ??
          'See detailed explanations and understand why your score is this.',
      premiumBadge: prem?['badge']?.toString() ?? 'PREMIUM',
    );
  }

  static int? _readInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v?.toString() ?? '');
  }

  static String _formatSpeakingDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')} min';
  }

  static String _defaultScoreLabel(int pct) {
    if (pct >= 90) return 'Excellent';
    if (pct >= 75) return 'Good';
    if (pct >= 55) return 'Nice';
    return 'Keep practicing';
  }

  static String _defaultSubtitle(int pct) {
    if (pct >= 75) {
      return 'Great job! You spoke clearly and understood the story well.';
    }
    if (pct >= 55) {
      return 'Nice effort! A bit more detail will make your answers even stronger.';
    }
    return 'Good start — try longer answers and revisit tricky vocabulary.';
  }

  static String _defaultImprovementTip(int pct) {
    if (pct < 60) {
      return 'Try to give slightly longer answers with more details.';
    }
    if (pct < 80) {
      return 'Add one concrete example from the story to each answer.';
    }
    return 'Challenge yourself by summarizing the story in two different ways.';
  }

  static List<ConversationPracticeMetric> _defaultMetrics(int pct) {
    final grammarStars = pct >= 75 ? 4 : (pct >= 55 ? 3 : 2);
    final grammarOk = grammarStars >= 3;
    return [
      const ConversationPracticeMetric(
        label: 'Fluency',
        statusText: 'Good',
        stars: 4,
        theme: 'purple',
      ),
      const ConversationPracticeMetric(
        label: 'Vocabulary',
        statusText: 'Good',
        stars: 4,
        theme: 'green',
      ),
      ConversationPracticeMetric(
        label: 'Grammar',
        statusText: grammarOk ? 'Good' : 'Needs Work',
        stars: grammarStars,
        theme: grammarOk ? 'green' : 'orange',
      ),
    ];
  }

  static List<ConversationPracticeMetric>? _parseMetrics(dynamic raw) {
    if (raw is! List || raw.isEmpty) return null;
    final out = <ConversationPracticeMetric>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final label = m['label']?.toString() ?? '';
      if (label.isEmpty) continue;
      final stars = (_readInt(m['rating_stars'] ?? m['ratingStars']) ?? 3)
          .clamp(1, 5);
      out.add(ConversationPracticeMetric(
        label: label,
        statusText: (m['status_text'] ?? m['statusText'] ?? 'Good').toString(),
        stars: stars,
        theme: (m['color_theme'] ?? m['colorTheme'] ?? 'purple').toString(),
      ));
    }
    return out.isEmpty ? null : out.take(3).toList();
  }
}

/// Full scrollable body for conversation / story-practice complete (mock UI).
class ConversationPracticeCompleteContent extends StatelessWidget {
  const ConversationPracticeCompleteContent({
    super.key,
    required this.viewModel,
    required this.onStartNewStory,
    this.onPremiumTap,
  });

  final ConversationCompleteViewModel viewModel;
  final VoidCallback onStartNewStory;
  final VoidCallback? onPremiumTap;

  static const Color _titleColor = Color(0xFF1B2754);
  static const Color _muted = Color(0xFF5C5F7A);

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = cpcFs(18);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, cpcFs(8), hPad, cpcFs(28)),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ConversationIllustration(height: cpcFs(168)),
                SizedBox(height: cpcFs(2)),
                Text(
                  vm.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: cpcFs(22),
                    fontWeight: FontWeight.w800,
                    color: _titleColor,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: cpcFs(10)),
                Text(
                  vm.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: cpcFs(14),
                    fontWeight: FontWeight.w500,
                    color: _muted,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: cpcFs(22)),
                _YourScoreCard(
                  percent: vm.overallPercent,
                  scoreLabel: vm.scoreLabel,
                  questionsAnswered: vm.questionsAnswered,
                  speakingDuration: vm.speakingDurationLabel,
                ),
                SizedBox(height: cpcFs(22)),
                Text(
                  'Your Performance',
                  style: GoogleFonts.inter(
                    fontSize: cpcFs(16),
                    fontWeight: FontWeight.w800,
                    color: _titleColor,
                  ),
                ),
                SizedBox(height: cpcFs(12)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < vm.metrics.length; i++) ...[
                      if (i > 0) SizedBox(width: cpcFs(8)),
                      Expanded(child: _MetricTile(metric: vm.metrics[i])),
                    ],
                  ],
                ),
                SizedBox(height: cpcFs(18)),
                _ImprovementTipCard(text: vm.improvementTip),
                SizedBox(height: cpcFs(14)),
                _PremiumUpsellCard(
                  title: vm.premiumTitle,
                  subtitle: vm.premiumSubtitle,
                  badge: vm.premiumBadge,
                  onTap: onPremiumTap,
                ),
                SizedBox(height: cpcFs(22)),
                OutlinedButton.icon(
                  onPressed: onStartNewStory,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: appColor,
                    side: BorderSide(color: appColor.withOpacity(0.85), width: cpcFs(1.8)),
                    padding: EdgeInsets.symmetric(vertical: cpcFs(14)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cpcFs(14)),
                    ),
                  ),
                  icon: Icon(Icons.menu_book_rounded, color: appColor, size: cpcFs(20)),
                  label: Text(
                    'Start New Story',
                    style: GoogleFonts.inter(
                      fontSize: cpcFs(15),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConversationIllustration extends StatelessWidget {
  const _ConversationIllustration({required this.height});

  final double height;

  static const String _logoAsset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: cpcFs(24),
            top: cpcFs(12),
            child: _swirl(const Color(0xFFE8DFFF), cpcFs(36)),
          ),
          Positioned(
            right: cpcFs(20),
            bottom: cpcFs(20),
            child: _swirl(const Color(0xFFD5F5EE), cpcFs(42)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              _logoAsset,
              height: height * 0.76,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.auto_awesome_rounded,
                size: cpcFs(44),
                color: appColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _swirl(Color c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withOpacity(0.65),
      ),
    );
  }
}

class _YourScoreCard extends StatelessWidget {
  const _YourScoreCard({
    required this.percent,
    required this.scoreLabel,
    required this.questionsAnswered,
    required this.speakingDuration,
  });

  final int percent;
  final String scoreLabel;
  final int questionsAnswered;
  final String speakingDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(cpcFs(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cpcFs(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: cpcFs(20),
            offset: Offset(0, cpcFs(8)),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _GradientScoreRing(percent: percent, label: scoreLabel),
          SizedBox(width: cpcFs(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Score',
                  style: GoogleFonts.inter(
                    fontSize: cpcFs(15),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B2754),
                  ),
                ),
                SizedBox(height: cpcFs(12)),
                _statRow(Icons.chat_bubble_outline_rounded,
                    'You answered $questionsAnswered questions'),
                SizedBox(height: cpcFs(8)),
                _statRow(Icons.schedule_rounded, 'You spoke for $speakingDuration'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: cpcFs(18), color: appColor.withOpacity(0.9)),
        SizedBox(width: cpcFs(8)),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: cpcFs(13),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3E4266),
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientScoreRing extends StatelessWidget {
  const _GradientScoreRing({required this.percent, required this.label});

  final int percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = (percent / 100).clamp(0.0, 1.0);
    final size = cpcFs(108);
    final stroke = cpcFs(9).clamp(4.0, 14.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: p, strokeWidth: stroke),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: GoogleFonts.inter(
                  fontSize: cpcFs(22),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B2754),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: cpcFs(12),
                  fontWeight: FontWeight.w700,
                  color: appColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final stroke = strokeWidth;

    final bgPaint = Paint()
      ..color = const Color(0xFFEDEEF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(c, r - stroke / 2, bgPaint);

    final rect = Rect.fromCircle(center: c, radius: r - stroke / 2);
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [Color(0xFF6D3BBF), Color(0xFF5B8DEF), Color(0xFF6D3BBF)],
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final ConversationPracticeMetric metric;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconBg;
    switch (metric.label.toLowerCase()) {
      case 'vocabulary':
        icon = Icons.menu_book_rounded;
        iconBg = const Color(0xFFE8F5E9);
        break;
      case 'grammar':
        icon = Icons.edit_rounded;
        iconBg = const Color(0xFFFFF3E0);
        break;
      default:
        icon = Icons.chat_bubble_rounded;
        iconBg = const Color(0xFFEDE7F6);
    }

    return Container(
      padding: EdgeInsets.fromLTRB(cpcFs(8), cpcFs(12), cpcFs(8), cpcFs(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cpcFs(16)),
        border: Border.all(color: const Color(0xFFE8EAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: cpcFs(10),
            offset: Offset(0, cpcFs(4)),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: cpcFs(40),
            height: cpcFs(40),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: cpcFs(22), color: appColor),
          ),
          SizedBox(height: cpcFs(8)),
          Text(
            metric.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: cpcFs(11),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B2754),
            ),
          ),
          SizedBox(height: cpcFs(4)),
          Text(
            metric.statusText,
            style: GoogleFonts.inter(
              fontSize: cpcFs(10.5),
              fontWeight: FontWeight.w700,
              color: metric.statusColor,
            ),
          ),
          SizedBox(height: cpcFs(6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < metric.stars;
              return Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                size: cpcFs(15),
                color: filled ? metric.starColor : const Color(0xFFD7DAE8),
              );
            }),
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
      padding: EdgeInsets.all(cpcFs(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF2),
        borderRadius: BorderRadius.circular(cpcFs(16)),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: cpcFs(40),
            height: cpcFs(40),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_rounded,
                color: const Color(0xFF43A047), size: cpcFs(22)),
          ),
          SizedBox(width: cpcFs(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Improvement Tip',
                  style: GoogleFonts.inter(
                    fontSize: cpcFs(13.5),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: cpcFs(6)),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: cpcFs(13),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF37474F),
                    height: 1.35,
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
  const _PremiumUpsellCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3EDFF),
      borderRadius: BorderRadius.circular(cpcFs(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cpcFs(16)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cpcFs(14), vertical: cpcFs(14)),
          child: Row(
            children: [
              Container(
                width: cpcFs(44),
                height: cpcFs(44),
                decoration: BoxDecoration(
                  color: appColor.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium_rounded,
                    color: const Color(0xFFD4AF37), size: cpcFs(26)),
              ),
              SizedBox(width: cpcFs(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: cpcFs(8), vertical: cpcFs(2)),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(cpcFs(8)),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: cpcFs(9.5),
                          fontWeight: FontWeight.w800,
                          color: appColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    SizedBox(height: cpcFs(6)),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: cpcFs(13.5),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B2754),
                      ),
                    ),
                    SizedBox(height: cpcFs(4)),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: cpcFs(11.5),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5C5F7A),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: cpcFs(24), color: appColor.withOpacity(0.65)),
            ],
          ),
        ),
      ),
    );
  }
}
