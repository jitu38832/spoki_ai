import 'package:flutter/material.dart';
import 'package:spokiai/view/screens/conversation_practice_complete_layout.dart'
    show ConversationCompleteViewModel, ConversationPracticeCompleteContent, cpcFs;
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/generatestory.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';

/// Conversation / story-practice complete — “Conversation Complete” UI (not quiz result).
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

  void _startNewStory(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardScreen(initialTabIndex: 0),
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
  }

  @override
  Widget build(BuildContext context) {
    final vm = ConversationCompleteViewModel.fromPayload(
      elapsed: elapsed,
      questionsAnswered: questionsAnswered,
      payload: serverPayload,
    );

    return Scaffold(
      backgroundColor: surfaceBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const DashboardScreen(initialTabIndex: 0),
                    ),
                    (route) => false,
                  );
                },
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: cpcFs(20), color: Colors.grey.shade800),
              ),
            ),
            Expanded(
              child: ConversationPracticeCompleteContent(
                viewModel: vm,
                onStartNewStory: () => _startNewStory(context),
                onPremiumTap: () {
                  showToast(
                    context: context,
                    message: 'Premium — coming soon',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Local fallback merged with socket `storyPractice:complete` payload (server wins on overlap).
Map<String, dynamic> deriveStoryPracticeClientSummary({
  required Duration elapsed,
  required List<String> userAnswers,
}) {
  final avgLen = userAnswers.isEmpty
      ? 0.0
      : userAnswers.map((e) => e.length).reduce((a, b) => a + b) /
          userAnswers.length;
  final pct =
      (56 + (avgLen / 100 * 36).clamp(0, 36)).round().clamp(52, 94);
  final qa = userAnswers.length;
  final m = elapsed.inMinutes;
  final s = elapsed.inSeconds.remainder(60);
  final dur = '$m:${s.toString().padLeft(2, '0')} min';

  String label() {
    if (pct >= 90) return 'Excellent';
    if (pct >= 75) return 'Good';
    if (pct >= 55) return 'Nice';
    return 'Keep practicing';
  }

  return {
    'overallPercent': pct,
    'overall_score': pct,
    'score_label': label(),
    'completion_message': pct >= 75
        ? 'Great job! You spoke clearly and understood the story well.'
        : (pct >= 55
            ? 'Nice effort! A bit more detail will make your answers even stronger.'
            : 'Good start — try longer answers and revisit tricky vocabulary.'),
    'improvement_tip': pct < 60
        ? 'Try to give slightly longer answers with more details.'
        : (pct < 80
            ? 'Add one concrete example from the story to each answer.'
            : 'Challenge yourself by summarizing the story in two different ways.'),
    'stats': {
      'questions_answered': qa,
      'speaking_duration': dur,
    },
  };
}
