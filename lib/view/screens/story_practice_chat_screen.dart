import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:spokiai/view/screens/socket.dart';
import 'package:spokiai/view/screens/story_practice_complete_screen.dart';

/// Post-quiz “Practice this story” — 5 guided questions, Socket.IO + local fallback.
const int kStoryPracticeTotalQuestions = 5;

final DateFormat _practiceTimeFmt = DateFormat('h:mm a');

const Color _kNavy = Color(0xFF1B2754);
const Color _kUserBubble = Color(0xFF6D3BBF);
const Color _kBotBubble = Color(0xFFEDEEF3);
const Color _kAvatarRing = Color(0xFFE8E0FA);
const Color _kSegmentIdle = Color(0xFFE4E6ED);
const Color _kEndRed = Color(0xFFE53935);

class _PracticeMessage {
  _PracticeMessage({
    required this.fromUser,
    required this.text,
    required this.at,
    this.showWaveform = false,
  });

  final bool fromUser;
  final String text;
  final DateTime at;
  final bool showWaveform;
}

class StoryPracticeChatScreen extends StatefulWidget {
  const StoryPracticeChatScreen({
    super.key,
    required this.storyId,
    required this.storyTitle,
    required this.quizId,
    required this.token,
  });

  final String storyId;
  final String storyTitle;
  final String quizId;
  final String token;

  @override
  State<StoryPracticeChatScreen> createState() =>
      _StoryPracticeChatScreenState();
}

class _StoryPracticeChatScreenState extends State<StoryPracticeChatScreen> {
  final SocketService _socket = SocketService();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();

  final List<_PracticeMessage> _messages = [];

  String? _sessionId;
  int _activeQuestionIndex = 0;
  bool _awaitingUser = false;
  bool _localMode = false;
  bool _serverHandshake = false;

  Timer? _fallbackTimer;
  Timer? _tickTimer;
  Duration _elapsed = Duration.zero;

  late final void Function(dynamic) _onStarted;
  late final void Function(dynamic) _onQuestion;
  late final void Function(dynamic) _onComplete;
  late final void Function(dynamic) _onError;

  List<String> get _localQuestionBank {
    final t = widget.storyTitle.trim();
    final titleBit = t.isEmpty ? 'this story' : '"$t"';
    return [
      'Who was the main character in the story?',
      'What was the central problem or conflict in $titleBit?',
      'Where (or when) does most of the story take place?',
      'What turning point or decision mattered most to the outcome?',
      'In one sentence, what do you think the story is really about?',
    ];
  }

  int get _botQuestionCount =>
      _messages.where((m) => !m.fromUser).length.clamp(0, kStoryPracticeTotalQuestions);

  int get _conversationLabel =>
      _botQuestionCount.clamp(1, kStoryPracticeTotalQuestions);

  @override
  void initState() {
    super.initState();
    _onStarted = (dynamic raw) {
      final m = _asMap(raw);
      if (m == null) return;
      _serverHandshake = true;
      _fallbackTimer?.cancel();
      final sid = m['sessionId']?.toString().trim();
      if (sid != null && sid.isNotEmpty) {
        setState(() => _sessionId = sid);
      }
    };

    _onQuestion = (dynamic raw) {
      final m = _asMap(raw);
      if (m == null) return;
      _serverHandshake = true;
      _fallbackTimer?.cancel();
      final sid = m['sessionId']?.toString().trim();
      final text = _pickQuestionText(m);
      if (text.isEmpty) return;
      final idx = _readInt(m['questionIndex']) ?? _readInt(m['index']) ?? 0;
      setState(() {
        if (sid != null && sid.isNotEmpty) _sessionId ??= sid;
        _activeQuestionIndex = idx.clamp(0, kStoryPracticeTotalQuestions - 1);
        _messages.add(_PracticeMessage(
          fromUser: false,
          text: text,
          at: DateTime.now(),
        ));
        _awaitingUser = true;
      });
      _scrollToEnd();
    };

    _onComplete = (dynamic raw) {
      _fallbackTimer?.cancel();
      if (!mounted) return;
      _openCompleteSummary(serverPayload: _asMap(raw));
    };

    _onError = (dynamic raw) {
      final m = _asMap(raw);
      final msg = m?['message']?.toString() ?? 'Session error';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    };

    _socket.initSocket();
    _socket.socket.on('storyPractice:started', _onStarted);
    _socket.socket.on('storyPractice:question', _onQuestion);
    _socket.socket.on('storyPractice:complete', _onComplete);
    _socket.socket.on('storyPractice:error', _onError);

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });

    _fallbackTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted || _serverHandshake) return;
      setState(() {
        _localMode = true;
        if (_messages.where((e) => !e.fromUser).isEmpty) {
          _appendLocalQuestion(0);
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socket.emitStoryPracticeStart(
        storyId: widget.storyId,
        quizId: widget.quizId,
        token: widget.token,
        storyTitle: widget.storyTitle,
      );
    });
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  int? _readInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v?.toString() ?? '');
  }

  String _pickQuestionText(Map<String, dynamic> m) {
    for (final k in ['text', 'question', 'message', 'content']) {
      final s = m[k]?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return '';
  }

  void _appendLocalQuestion(int index) {
    if (index < 0 || index >= kStoryPracticeTotalQuestions) return;
    final bank = _localQuestionBank;
    final q = bank[index.clamp(0, bank.length - 1)];
    _messages.add(_PracticeMessage(fromUser: false, text: q, at: DateTime.now()));
    _activeQuestionIndex = index;
    _awaitingUser = true;
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _openCompleteSummary({Map<String, dynamic>? serverPayload}) {
    if (!mounted) return;
    _tickTimer?.cancel();
    final texts =
        _messages.where((m) => m.fromUser).map((m) => m.text).toList();
    final derived = deriveStoryPracticeClientSummary(
      elapsed: _elapsed,
      userAnswers: texts,
    );
    final merged = <String, dynamic>{...derived, ...?serverPayload};
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => StoryPracticeCompleteScreen(
          elapsed: _elapsed,
          questionsAnswered: texts.length,
          serverPayload: merged,
        ),
      ),
    );
  }

  Future<void> _sendUserMessage() async {
    final text = _input.text.trim();
    if (text.isEmpty || !_awaitingUser) return;

    final qIdx = _activeQuestionIndex;
    final clientId =
        '${DateTime.now().microsecondsSinceEpoch}_${text.hashCode}';

    setState(() {
      _messages.add(_PracticeMessage(
        fromUser: true,
        text: text,
        at: DateTime.now(),
        showWaveform: true,
      ));
      _input.clear();
      _awaitingUser = false;
    });
    _scrollToEnd();

    if (_localMode || _sessionId == null) {
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      if (qIdx >= kStoryPracticeTotalQuestions - 1) {
        _openCompleteSummary();
        return;
      }
      setState(() => _appendLocalQuestion(qIdx + 1));
      return;
    }

    _socket.emitStoryPracticeAnswer(
      sessionId: _sessionId!,
      questionIndex: qIdx,
      text: text,
      clientMessageId: clientId,
    );
  }

  Future<void> _confirmEnd() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End conversation?'),
        content: const Text(
          'You can resume later from the story if your coach saves progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'End',
              style: TextStyle(color: _kEndRed),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final sid = _sessionId;
    if (sid != null && sid.isNotEmpty) {
      _socket.emitStoryPracticeEnd(sessionId: sid);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _tickTimer?.cancel();
    _socket.socket.off('storyPractice:started', _onStarted);
    _socket.socket.off('storyPractice:question', _onQuestion);
    _socket.socket.off('storyPractice:complete', _onComplete);
    _socket.socket.off('storyPractice:error', _onError);
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  String _formatElapsed() {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = _elapsed.inHours;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8EE)),
            Expanded(child: _buildMessageList()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: _kNavy.withValues(alpha: 0.85)),
              ),
              Expanded(
                child: Text(
                  widget.storyTitle.trim().isEmpty
                      ? 'Story practice'
                      : widget.storyTitle.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kNavy,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _confirmEnd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kEndRed,
                  side: const BorderSide(color: Color(0xFFE0E0E6)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(Icons.flag_outlined, size: 16, color: _kEndRed),
                label: Text(
                  'End',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kEndRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Conversation $_conversationLabel of $kStoryPracticeTotalQuestions',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _kNavy.withValues(alpha: 0.72),
                ),
              ),
              const Spacer(),
              Icon(Icons.schedule_rounded, size: 18, color: _kUserBubble),
              const SizedBox(width: 4),
              Text(
                _formatElapsed(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kUserBubble,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SegmentedProgress(
            total: kStoryPracticeTotalQuestions,
            filled: _botQuestionCount,
            activeColor: _kUserBubble,
            idleColor: _kSegmentIdle,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final m = _messages[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: m.fromUser ? _UserRow(message: m) : _BotRow(message: m),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          10 + MediaQuery.paddingOf(context).bottom * 0.2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: _kNavy,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your answer…',
                  hintStyle: GoogleFonts.inter(
                    color: _kNavy.withValues(alpha: 0.35),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6F6F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendUserMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: _kUserBubble,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kSegmentIdle,
              ),
              onPressed: !_awaitingUser ? null : _sendUserMessage,
              icon: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({
    required this.total,
    required this.filled,
    required this.activeColor,
    required this.idleColor,
  });

  final int total;
  final int filled;
  final Color activeColor;
  final Color idleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i < filled;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < total - 1 ? 5 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 7,
              decoration: BoxDecoration(
                color: done ? activeColor : idleColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BotRow extends StatelessWidget {
  const _BotRow({required this.message});

  final _PracticeMessage message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Avatar(child: Icon(Icons.smart_toy_rounded, color: _kUserBubble, size: 22)),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _kBotBubble,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: _kNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _practiceTimeFmt.format(message.at),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _kNavy.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.message});

  final _PracticeMessage message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 36),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: _kUserBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.text,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _practiceTimeFmt.format(message.at),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          if (message.showWaveform) ...[
                            const SizedBox(width: 8),
                            const _MiniWaveform(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _Avatar(
          child: Icon(Icons.person_rounded, color: _kUserBubble, size: 22),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: _kAvatarRing,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _MiniWaveform extends StatelessWidget {
  const _MiniWaveform();

  @override
  Widget build(BuildContext context) {
    const heights = <double>[4, 9, 6, 11, 5, 8];
    return SizedBox(
      width: 34,
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: heights
            .map(
              (h) => Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
