import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:spokiai/model/aifeedback.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/socket.dart'; // Adjust path if needed
import 'package:spokiai/logic/inworld_tts/inworld_tts_cubit.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_state.dart';
import 'package:spokiai/view/screens/voice_settings.dart';
import 'package:spokiai/view/services/chat_voice_upload_service.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:translator/translator.dart';
import '../utils/colors.dart'; // Make sure appColor is defined

/// Socket / JSON fields may be null or non-String; avoids cast and null errors.
String? _coerceTrimmedString(dynamic value) {
  if (value == null) return null;
  final s = value is String ? value : value.toString();
  final t = s.trim();
  return t.isEmpty ? null : t;
}

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> partnerDetails;

  const ChatScreen({super.key, required this.partnerDetails});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _voiceRecorder = AudioRecorder();
  final AudioPlayer _chatVoicePlayer = AudioPlayer();
  late FlutterTts _flutterTts;

  bool _isRecordingVoice = false;
  bool _isVoiceUploading = false;
  String? _voiceRecordingPath;
  String? _playingVoiceMessageId;
  Duration _voicePlayPosition = Duration.zero;
  Duration _voicePlayDuration = Duration.zero;
  DateTime? _voicePlayStartedAt;
  Timer? _pronStopTimer;
  String? _activePronUrl;
  bool _isPronPlaying = false;
  // ignore: unused_field
  bool _isPronLoading = false;
  double? _pendingPronStartRatio;
  double? _pendingPronEndRatio;

  bool _isFirstAiMessageReceived = false;
  bool _isSpeaking = false;
  final TextEditingController _textController = TextEditingController();

  /// Message row showing the in-chat TTS capsule as "playing".
  String? _speakingMessageId;
  Timer? _ttsElapsedTimer;
  Duration _ttsElapsed = Duration.zero;
  int _ttsEstimatedSeconds = 4;

  /// Filled 0–1 per message: colored portion of TTS waveform (persists if stopped mid-way).
  final Map<String, double> _ttsWaveProgressByMessageId = {};

  /// When false, TTS ended via user stop — do not set waveform progress to 100% on completion.
  bool _ttsCountAsNaturalCompletion = true;

  late AnimationController _waveController;

  final GoogleTranslator _translator = GoogleTranslator();
  List<ChatMessage> _messages = [];

  late SocketService socketService;

  bool _showSuggestions = false;
  bool _isBulbActive = false;

  /// User message ids with AI feedback panel expanded below the bubble.
  final Set<String> _expandedAiFeedbackIds = {};

  /// Last opened feedback request (server responses are applied to this message id).
  String? _pendingAiFeedbackMessageId;
  final Map<String, AiFeedbackAiPayload> _aiFeedbackResultByMessageId = {};
  final Map<String, String> _aiFeedbackErrorByMessageId = {};
  final Set<String> _aiFeedbackLoadingIds = {};
  final Set<String> _pendingQuickReplyMessageIds = {};
  Future<void> _aiMessageDisplayChain = Future<void>.value();
  bool _isAiSpeechUsingRemoteAudio = false;
  int _pendingAiResponseCount = 0;
  Timer? _aiTypingDotsTimer;
  int _aiTypingDots = 1;

  InworldTtsCubit? _inworldTts;

  bool get _showAiTypingLoader => _pendingAiResponseCount > 0;

  void _startAiTypingDots() {
    _aiTypingDotsTimer?.cancel();
    _aiTypingDots = 1;
    _aiTypingDotsTimer = Timer.periodic(const Duration(milliseconds: 380), (_) {
      if (!mounted || !_showAiTypingLoader) return;
      setState(() {
        _aiTypingDots = (_aiTypingDots % 3) + 1;
      });
    });
  }

  void _stopAiTypingDotsIfIdle() {
    if (_showAiTypingLoader) return;
    _aiTypingDotsTimer?.cancel();
    _aiTypingDotsTimer = null;
    _aiTypingDots = 1;
  }

  void _markAiPendingStarted() {
    if (!mounted) return;
    setState(() {
      _pendingAiResponseCount += 1;
    });
    _startAiTypingDots();
    _scrollToBottom();
  }

  String? _ttsTextForMessageId(String id) {
    for (final m in _messages) {
      if (m.id == id) {
        final ai = m.aiTtsText?.trim();
        if (ai != null && ai.isNotEmpty) return ai;
        return m.text.trim();
      }
    }
    return null;
  }

  String _getLocaleFromPartnerLanguage(String partnerLang) {
    String lower = partnerLang.toLowerCase().trim();
    switch (lower) {
      case "chinese":
        return "zh-CN";
      case "arabic":
        return "ar-SA";
      case "french":
        return "fr-FR";
      case "german":
        return "de-DE";
      case "indonesian":
        return "id-ID";
      case "italian":
        return "it-IT";
      case "japanese":
        return "ja-JP";
      case "korean":
        return "ko-KR";
      case "russian":
        return "ru-RU";
      case "spanish":
        return "es-ES";
      case "thai":
        return "th-TH";
      case "turkish":
        return "tr-TR";
      case "vietnamese":
        return "vi-VN";
      case "persian":
        return "fa-IR";
      case "hindi":
        return "hi-IN";
      case "telugu":
        return "te-IN";
      case "tamil":
        return "ta-IN";
      case "malayalam":
        return "ml-IN";
      case "kannada":
        return "kn-IN";
      case "bengali":
        return "bn-IN";
      case "english":
      case "international":
      default:
        return "en-US";
    }
  }

  Future<bool> _waitUntilTtsReady(
    String messageId, {
    Duration maxWait = const Duration(seconds: 12),
  }) async {
    final cubit = _inworldTts ?? context.read<InworldTtsCubit>();

    bool isReady(InworldTtsState s) =>
        s.playbackId == messageId && s.status == InworldTtsStatus.playing;

    if (isReady(cubit.state)) {
      return true;
    }

    try {
      final state = await cubit.stream
          .firstWhere(
            (s) =>
                s.playbackId == messageId &&
                (s.status == InworldTtsStatus.playing ||
                    s.status == InworldTtsStatus.error),
          )
          .timeout(maxWait);
      return state.status == InworldTtsStatus.playing;
    } catch (_) {
      return false;
    }
  }

  void _appendAiMessage({
    required String messageText,
    required String messageId,
    String? suggestionText,
    String? aiTtsText,
    String? audioUrl,
  }) {
    if (!mounted) return;
    setState(() {
      if (_pendingAiResponseCount > 0) {
        _pendingAiResponseCount -= 1;
      }
      _messages.add(
        ChatMessage(
          text: messageText,
          isUser: false,
          hasAudio: true,
          suggestion: suggestionText,
          aiTtsText: aiTtsText,
          audioUrl: audioUrl,
          id: messageId,
        ),
      );
    });
    _stopAiTypingDotsIfIdle();
    _scrollToBottom();
  }

  Future<void> _playThenShowAiMessage({
    required String messageText,
    required String messageId,
    required String ttsPlaybackText,
    String? suggestionText,
    String? aiTtsText,
    String? audioUrl,
  }) async {
    if (!_isFirstAiMessageReceived) {
      _isFirstAiMessageReceived = true;
      await Future<void>.delayed(Duration.zero);
    }

    final speakStartAt = DateTime.now();
    unawaited(_speakInEnglish(ttsPlaybackText, messageId: messageId));
    final ready = await _waitUntilTtsReady(
      messageId,
      maxWait: const Duration(seconds: 12),
    );
    if (!ready) {
      _appendAiMessage(
        messageText: messageText,
        messageId: messageId,
        suggestionText: suggestionText,
        aiTtsText: aiTtsText,
        audioUrl: audioUrl,
      );
      return;
    }

    // Keep text-to-audio perceived gap tight (<1s): once playback starts,
    // append message right away (or within a tiny buffer).
    final waited = DateTime.now().difference(speakStartAt);
    if (waited < const Duration(milliseconds: 80)) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    _appendAiMessage(
      messageText: messageText,
      messageId: messageId,
      suggestionText: suggestionText,
      aiTtsText: aiTtsText,
      audioUrl: audioUrl,
    );
  }

  void _onSocketMessage(dynamic data) {
    print('Received from server: $data');

    if (data is! Map) return;
    final type = _coerceTrimmedString(data['type']);
    final messageText = _coerceTrimmedString(data['message']);

    if (messageText == null) return;
    if (!mounted) return;

    if (type == 'user' &&
        messageText.toLowerCase().contains('botname=') &&
        messageText.toLowerCase().contains('gender=')) {
      print("↳ Skipping UI for initialization message");
      return;
    }

    final suggestionText = _coerceTrimmedString(data['suggestion']);
    final audioUrl = _coerceTrimmedString(data['audioUrl']);
    final clientId = _coerceTrimmedString(data['clientMessageId']);
    final aiTtsText = _coerceTrimmedString(data['tts_text']) ??
        _coerceTrimmedString(data['ttsText']);

    if (type == 'user' &&
        clientId != null &&
        _messages.any((m) => m.id == clientId)) {
      _scrollToBottom();
      return;
    }

    final cubit = context.read<InworldTtsCubit>();
    final ttsOn = cubit.state.audioEnabled;
    setState(() {
      if (type == 'user') {
        final id = clientId ?? _newChatMessageId();
        final fromQuickReply =
            clientId != null && _pendingQuickReplyMessageIds.remove(clientId);
        _messages.add(ChatMessage(
          text: messageText,
          isUser: true,
          id: id,
          audioUrl: audioUrl,
          isQuickReply: fromQuickReply,
        ));
      } else if (type == 'ai') {
        // AI message is appended after TTS starts (or timeout fallback) below.
      }
    });

    if (type == 'ai') {
      final msgId = _newChatMessageId();
      final ttsPlaybackText = aiTtsText ?? messageText;
      if (ttsOn) {
        _aiMessageDisplayChain = _aiMessageDisplayChain.then(
          (_) => _playThenShowAiMessage(
            messageText: messageText,
            messageId: msgId,
            ttsPlaybackText: ttsPlaybackText,
            suggestionText: suggestionText,
            aiTtsText: aiTtsText,
            audioUrl: audioUrl,
          ),
        );
      } else {
        _appendAiMessage(
          messageText: messageText,
          messageId: msgId,
          suggestionText: suggestionText,
          aiTtsText: aiTtsText,
          audioUrl: audioUrl,
        );
      }
      return;
    }

    _scrollToBottom();
  }

  void _onAiFeedbackSocket(dynamic raw) {
    print('aifeedback event: $raw');
    if (!mounted) return;
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    final t = _coerceTrimmedString(data['type'])?.toLowerCase();

    if (t == 'typing') {
      final mid = _pendingAiFeedbackMessageId;
      if (mid != null) {
        setState(() => _aiFeedbackLoadingIds.add(mid));
      }
      return;
    }

    if (t == 'user') {
      // Server echo of analyzed text; optional chat mirror — skipped to avoid duplicates.
      return;
    }

    if (t == 'error') {
      final msg =
          _coerceTrimmedString(data['message']) ?? 'Feedback request failed';
      final mid = _pendingAiFeedbackMessageId;
      setState(() {
        if (mid != null) {
          _aiFeedbackLoadingIds.remove(mid);
          _aiFeedbackErrorByMessageId[mid] = msg;
          _aiFeedbackResultByMessageId.remove(mid);
        }
        _pendingAiFeedbackMessageId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    if (t == 'ai') {
      final mid = _pendingAiFeedbackMessageId;
      try {
        final payload = AiFeedbackAiPayload.fromJson(data);
        setState(() {
          if (mid != null) {
            _aiFeedbackLoadingIds.remove(mid);
            _aiFeedbackErrorByMessageId.remove(mid);
            _aiFeedbackResultByMessageId[mid] = payload;
          }
          _pendingAiFeedbackMessageId = null;
        });
      } catch (e) {
        setState(() {
          if (mid != null) {
            _aiFeedbackLoadingIds.remove(mid);
            _aiFeedbackErrorByMessageId[mid] = 'Invalid feedback data';
            _aiFeedbackResultByMessageId.remove(mid);
          }
          _pendingAiFeedbackMessageId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not parse AI feedback')),
        );
      }
      return;
    }
  }

  void _onTypingSocket(dynamic raw) {
    if (!mounted) return;
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    final scope = _coerceTrimmedString(data['type'])?.toLowerCase();
    if (scope != 'aifeedback') return;
    final mid = _pendingAiFeedbackMessageId;
    if (mid != null) {
      setState(() => _aiFeedbackLoadingIds.add(mid));
    }
  }

  @override
  void initState() {
    super.initState();

    print("partnerDetails: ${widget.partnerDetails}");

    socketService = SocketService();
    socketService.initSocket();

    _flutterTts = FlutterTts();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initializeTts();
    _chatVoicePlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _voicePlayDuration = d);
      unawaited(_tryApplyPronSegmentIfPending());
    });
    _chatVoicePlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _voicePlayPosition = p);
    });
    _chatVoicePlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _waveController.stop();
      _pronStopTimer?.cancel();
      final finishedAiMessageId = _speakingMessageId;
      final wasAiRemoteSpeech = _isAiSpeechUsingRemoteAudio;
      setState(() {
        _playingVoiceMessageId = null;
        _voicePlayPosition = Duration.zero;
        _voicePlayDuration = Duration.zero;
        _voicePlayStartedAt = null;
        _activePronUrl = null;
        _isPronPlaying = false;
        _isPronLoading = false;
        if (wasAiRemoteSpeech) {
          _isSpeaking = false;
          _speakingMessageId = null;
        }
      });
      if (wasAiRemoteSpeech && finishedAiMessageId != null) {
        _ttsWaveProgressByMessageId[finishedAiMessageId] = 1.0;
        _stopTtsElapsedTicker();
        _isAiSpeechUsingRemoteAudio = false;
      }
    });
    _textController.addListener(_onInputTextChanged);

    // New chat session (incl. new partner after leaving chat): always handshake again.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        _inworldTts = context.read<InworldTtsCubit>();
        final cubit = _inworldTts!;
        await cubit.loadPreferences();
        final g =
            widget.partnerDetails['gender']?.toString().trim() ?? 'Female';
        await cubit.setPartnerGender(g);
      }

      socketService.resetInitialFlag();

      // Already connected → send immediately
      if (socketService.isConnected) {
        socketService
            .sendInitialGreetingWithPartnerDetails(widget.partnerDetails);
        return;
      }

      // Not connected yet → wait for first connect event
      void onFirstConnect(_) {
        if (mounted) {
          socketService
              .sendInitialGreetingWithPartnerDetails(widget.partnerDetails);
        }
        socketService.socket.off('connect', onFirstConnect);
      }

      socketService.socket.onConnect(onFirstConnect);
    });

    socketService.socket.on('message', _onSocketMessage);
    socketService.socket.on('aifeedback', _onAiFeedbackSocket);
    socketService.socket.on('typing', _onTypingSocket);
  }

  void _onInputTextChanged() {
    if (mounted) setState(() {});
  }

  String _newChatMessageId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(1 << 20)}';

  String _normalizeSttText(String raw) {
    var text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return text;

    final opener = RegExp(
      r'^(yes|no|okay|ok|well)\s+',
      caseSensitive: false,
    ).firstMatch(text);
    if (opener != null) {
      final word = opener.group(1) ?? '';
      text = '$word, ${text.substring(opener.end)}';
    }

    final firstLetter = RegExp(r'[A-Za-z]').firstMatch(text);
    if (firstLetter != null) {
      final i = firstLetter.start;
      text =
          '${text.substring(0, i)}${text[i].toUpperCase()}${text.substring(i + 1)}';
    }

    if (!RegExp(r'[.!?]$').hasMatch(text)) {
      final lower = text.toLowerCase();
      final looksQuestion = RegExp(
        r'^(who|what|when|where|why|how|which|whose|whom|is|are|am|was|were|do|does|did|can|could|will|would|should|have|has|had)\b',
      ).hasMatch(lower);
      text += looksQuestion ? '?' : '.';
    }
    return text;
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setVolume(1.0);

    final languageCode = _getLocaleFromPartnerLanguage("English");

    await _flutterTts.setLanguage(languageCode);

    await _flutterTts.setSpeechRate(0.33);
    await _flutterTts.setPitch(1.0);

    final voices = await _flutterTts.getVoices;

    if (voices.isNotEmpty) {
      final genderRaw =
          widget.partnerDetails["gender"]?.toString().trim().toLowerCase();
      final genderLower = genderRaw == "female" ? "female" : "male";

      print("Trying to select friendly voice for gender: $genderLower");

      bool voiceSet = false;
      final friendlyVoicePatterns = [
        "wavenet",
        "neural",
        "premium",
        "enhanced",
        "studio",
        "high-quality",
        "male",
        "man",
        "boy",
        "david",
        "tom",
        "john",
        "tpd",
        "female",
        "woman",
        "girl",
        "karen",
        "samantha",
        "tpf",
      ];

      for (var pattern in friendlyVoicePatterns) {
        for (var voice in voices) {
          if (voice is Map && voice["locale"] != null) {
            final locale = voice["locale"].toString();
            final nameLower = (voice["name"] as String?)?.toLowerCase() ?? "";

            if (locale.startsWith(languageCode.split('-').first) &&
                nameLower.contains(pattern)) {
              if ((genderLower == "female" &&
                      (pattern.contains("female") ||
                          pattern.contains("woman") ||
                          pattern.contains("girl"))) ||
                  (genderLower == "male" &&
                      (pattern.contains("male") ||
                          pattern.contains("man") ||
                          pattern.contains("boy") ||
                          pattern.contains("wavenet") ||
                          pattern.contains("neural")))) {
                await _flutterTts.setVoice({
                  "name": (voice["name"] ?? "").toString(),
                  "locale": locale,
                });
                print(
                    "Selected friendly/natural voice: ${voice["name"]} ($locale)");
                voiceSet = true;
                break;
              }
            }
          }
        }
        if (voiceSet) break;
      }

      if (!voiceSet) {
        for (var voice in voices) {
          if (voice is Map && voice["locale"] != null) {
            final locale = voice["locale"].toString();
            if (locale.startsWith(languageCode.split('-').first)) {
              await _flutterTts.setVoice({
                "name": (voice["name"] ?? "").toString(),
                "locale": locale,
              });
              print("Fallback voice: ${voice["name"]} ($locale)");
              break;
            }
          }
        }
      }

      print("\n=== Available TTS Voices ===");
      for (var v in voices) {
        print(
            " - ${v['name']} | ${v['locale']} | gender?: ${v['gender'] ?? 'unknown'}");
      }
      print("===========================\n");
    } else {
      print("No TTS voices available on this device");
    }

    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      final id = _speakingMessageId;
      _stopTtsElapsedTicker();
      _waveController.stop();
      if (_ttsCountAsNaturalCompletion && id != null) {
        _ttsWaveProgressByMessageId[id] = 1.0;
      }
      _ttsCountAsNaturalCompletion = true;
      setState(() {
        _isSpeaking = false;
        _speakingMessageId = null;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      if (!mounted) return;
      final id = _speakingMessageId;
      _stopTtsElapsedTicker();
      _waveController.stop();
      if (id != null && _ttsEstimatedSeconds > 0) {
        final p = (_ttsElapsed.inMilliseconds / (_ttsEstimatedSeconds * 1000))
            .clamp(0.0, 1.0);
        if (p > 0) _ttsWaveProgressByMessageId[id] = p;
      }
      _ttsCountAsNaturalCompletion = true;
      setState(() {
        _isSpeaking = false;
        _speakingMessageId = null;
      });
    });
  }

  int _estimateTtsSeconds(String text) {
    final t = text.trim();
    if (t.isEmpty) return 4;
    final words = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length;
    return (words / 2.6).ceil().clamp(3, 120);
  }

  String _formatMmSs(int totalSeconds) {
    final s = totalSeconds.clamp(0, 3599);
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  void _startTtsElapsedTicker() {
    _ttsElapsedTimer?.cancel();
    _ttsElapsed = Duration.zero;
    _ttsElapsedTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || !_isSpeaking) return;
      setState(() {
        _ttsElapsed += const Duration(milliseconds: 250);
      });
    });
  }

  void _stopTtsElapsedTicker() {
    _ttsElapsedTimer?.cancel();
    _ttsElapsedTimer = null;
  }

  void _syncWaveAnimation() {
    if (_isSpeaking) {
      if (!_waveController.isAnimating) _waveController.repeat();
    } else {
      _waveController.stop();
    }
  }

  double _voiceProgressForMessage(ChatMessage message) {
    if (_playingVoiceMessageId != message.id) return 0.0;
    var playedMs = _voicePlayPosition.inMilliseconds;
    if (playedMs <= 0 && _voicePlayStartedAt != null) {
      playedMs = DateTime.now().difference(_voicePlayStartedAt!).inMilliseconds;
    }
    final totalMs = _voicePlayDuration.inMilliseconds > 0
        ? _voicePlayDuration.inMilliseconds
        : _estimateTtsSeconds(message.text) * 1000;
    if (totalMs <= 0) return 0.0;
    return (playedMs / totalMs).clamp(0.0, 1.0);
  }

  String _voiceTimeLabelForMessage(ChatMessage message) {
    if (_playingVoiceMessageId == message.id) {
      var playedMs = _voicePlayPosition.inMilliseconds;
      if (playedMs <= 0 && _voicePlayStartedAt != null) {
        playedMs =
            DateTime.now().difference(_voicePlayStartedAt!).inMilliseconds;
      }
      final sec = (playedMs / 1000).floor();
      return _formatMmSs(sec);
    }
    final sec = (_voicePlayDuration.inMilliseconds / 1000).floor();
    if (sec > 0) return _formatMmSs(sec);
    return '0:00';
  }

  Future<void> _stopVoicePlayback() async {
    _pronStopTimer?.cancel();
    _pendingPronStartRatio = null;
    _pendingPronEndRatio = null;
    await _chatVoicePlayer.stop();
    _waveController.stop();
    if (mounted) {
      setState(() {
        _playingVoiceMessageId = null;
        _voicePlayPosition = Duration.zero;
        _voicePlayDuration = Duration.zero;
        _voicePlayStartedAt = null;
        _activePronUrl = null;
        _isPronPlaying = false;
        _isPronLoading = false;
      });
    }
  }

  void _practiceAudioUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not play practice segment.')),
    );
  }

  Future<void> _tryApplyPronSegmentIfPending() async {
    final sr = _pendingPronStartRatio;
    final er = _pendingPronEndRatio;
    if (sr == null || er == null) return;
    final durationMs = _voicePlayDuration.inMilliseconds;
    if (durationMs <= 0) return;
    final start = sr.clamp(0.0, 1.0);
    final end = er.clamp(0.0, 1.0);
    if (end <= start) {
      _pendingPronStartRatio = null;
      _pendingPronEndRatio = null;
      return;
    }
    final startMs = (durationMs * start).round();
    final endMs = (durationMs * end).round();
    if (endMs <= startMs) {
      _pendingPronStartRatio = null;
      _pendingPronEndRatio = null;
      return;
    }
    await _chatVoicePlayer.seek(Duration(milliseconds: startMs));
    _pronStopTimer?.cancel();
    _pronStopTimer = Timer(Duration(milliseconds: endMs - startMs), () async {
      await _chatVoicePlayer.pause();
      if (mounted) setState(() => _isPronPlaying = false);
    });
    _pendingPronStartRatio = null;
    _pendingPronEndRatio = null;
  }

  // ignore: unused_element
  Future<void> _playPronunciationSegment(AiFeedbackPronunciation p) async {
    final url = p.playbackUrl;
    if (url == null || url.isEmpty) {
      _practiceAudioUnavailable();
      return;
    }

    if (_activePronUrl == url && _isPronPlaying) {
      await _chatVoicePlayer.pause();
      if (mounted) setState(() => _isPronPlaying = false);
      return;
    }

    if (_activePronUrl == url && !_isPronPlaying) {
      await _chatVoicePlayer.resume();
      if (mounted) setState(() => _isPronPlaying = true);
      return;
    }

    await _stopSpeaking();
    await _stopVoicePlayback();
    try {
      if (mounted) setState(() => _isPronLoading = true);
      _pronStopTimer?.cancel();
      _pendingPronStartRatio = null;
      _pendingPronEndRatio = null;
      await _chatVoicePlayer.play(UrlSource(url));
      if (mounted) {
        setState(() {
          _activePronUrl = url;
          _isPronPlaying = true;
          _isPronLoading = false;
        });
      }
      if (p.hasSegmentHint) {
        _pendingPronStartRatio = p.segmentStartRatio;
        _pendingPronEndRatio = p.segmentEndRatio;
        await _tryApplyPronSegmentIfPending();
      }
    } catch (_) {
      if (mounted) setState(() => _isPronLoading = false);
      _practiceAudioUnavailable();
    }
  }

  Future<void> _toggleVoiceMessagePlayback(ChatMessage message) async {
    final url = message.audioUrl?.trim();
    if (url == null || url.isEmpty) return;
    if (_playingVoiceMessageId == message.id) {
      await _stopVoicePlayback();
      return;
    }
    await _stopSpeaking();
    try {
      await _chatVoicePlayer.stop();
      if (mounted) {
        setState(() {
          _playingVoiceMessageId = message.id;
          _voicePlayPosition = Duration.zero;
          _voicePlayDuration = Duration.zero;
          _voicePlayStartedAt = DateTime.now();
        });
      }
      if (!_waveController.isAnimating) {
        _waveController.repeat();
      }
      await _chatVoicePlayer.play(UrlSource(url));
    } catch (e) {
      _waveController.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play voice message: $e')),
        );
      }
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isVoiceUploading) return;
    if (_isRecordingVoice) {
      await _finishVoiceRecordingAndUpload();
      return;
    }
    final ok = await _voiceRecorder.hasPermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Microphone permission is required to record.')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/chat_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _voiceRecordingPath = path;
    try {
      await _voiceRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: path,
      );
      if (mounted) setState(() => _isRecordingVoice = true);
    } catch (e) {
      _voiceRecordingPath = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _finishVoiceRecordingAndUpload() async {
    if (!_isRecordingVoice) return;
    final savedPath = _voiceRecordingPath;
    String? stoppedPath;
    try {
      stoppedPath = await _voiceRecorder.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
        _voiceRecordingPath = null;
      });
    }
    final path = (stoppedPath ?? savedPath)?.trim();
    if (path == null || path.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not read recorded audio file path.')),
        );
      }
      return;
    }
    final file = File(path);
    if (!await file.exists() || await file.length() < 32) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording too short or failed.')),
        );
      }
      try {
        await file.delete();
      } catch (_) {}
      return;
    }

    final token = PreferenceManager.getStringValue(key: 'token') ?? '';
    if (token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in — cannot upload voice.')),
        );
      }
      try {
        await file.delete();
      } catch (_) {}
      return;
    }

    if (mounted) setState(() => _isVoiceUploading = true);
    try {
      final result = await ChatVoiceUploadService.upload(
        token: token,
        filePath: path,
      );
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Voice upload failed. Check API / network.')),
        );
        return;
      }
      final tr = result.transcription.trim().isEmpty
          ? '(Voice message)'
          : _normalizeSttText(result.transcription);
      final id = _newChatMessageId();
      setState(() {
        _messages.add(ChatMessage(
          text: tr,
          isUser: true,
          id: id,
          audioUrl: result.audioUrl,
        ));
      });
      if (socketService.isConnected) {
        socketService.sendVoiceMessage(
          message: tr,
          audioUrl: result.audioUrl,
          clientMessageId: id,
        );
        _markAiPendingStarted();
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVoiceUploading = false);
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  /// Single quick reply from latest AI `suggestion` (socket payload); local default if none.
  List<String> _generateSuggestions() {
    String? latestSuggestion;
    for (final msg in _messages.reversed) {
      if (!msg.isUser &&
          msg.suggestion != null &&
          msg.suggestion!.trim().isNotEmpty) {
        latestSuggestion = msg.suggestion!.trim();
        break;
      }
    }

    if (latestSuggestion == null || latestSuggestion.isEmpty) {
      return ["Hi, let's start learning!"];
    }

    return [latestSuggestion];
  }

  void _toggleSuggestions() {
    setState(() {
      _showSuggestions = !_showSuggestions;
      _isBulbActive = _showSuggestions;
    });
  }

  Future<void> _showTranslationDialog(String englishText) async {
    if (englishText.trim().isEmpty || !mounted) return;

    final partnerLanguageName =
        _coerceTrimmedString(widget.partnerDetails["language"]) ?? "English";
    final targetCode = _getLocaleFromPartnerLanguage(partnerLanguageName);

    if (targetCode == "en-US") {
      _showSimpleTranslationDialog(partnerLanguageName, englishText);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final translation = await _translator.translate(englishText.trim(),
          to: targetCode.split('-').first);
      final rawTranslated = translation.text;
      final translatedText =
          _coerceTrimmedString(rawTranslated) ?? englishText.trim();

      if (!mounted) return;
      Navigator.pop(context);

      _showSimpleTranslationDialog(partnerLanguageName, translatedText,
          original: englishText);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Translation failed. Check internet connection.")),
      );
    }
  }

  Future<void> _showSimpleTranslationDialog(
    String languageName,
    String translatedText, {
    String? original,
  }) async {
    bool isSpeakingFromDialog = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.translate, color: appColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Translated to $languageName",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Translation:",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SelectableText(
                      translatedText,
                      style: const TextStyle(fontSize: 17, height: 1.5),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (isSpeakingFromDialog) _flutterTts.stop();
                    if (mounted) {
                      setState(() {
                        _isSpeaking = false;
                        _speakingMessageId = null;
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Close"),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (isSpeakingFromDialog) {
                      await _flutterTts.stop();
                      setDialogState(() => isSpeakingFromDialog = false);
                      if (mounted) {
                        setState(() {
                          _isSpeaking = false;
                          _speakingMessageId = null;
                        });
                      }
                    } else {
                      await _flutterTts.stop();
                      final targetCode =
                          _getLocaleFromPartnerLanguage(languageName);
                      await _flutterTts.setLanguage(targetCode);

                      if (mounted) {
                        setState(() {
                          _isSpeaking = true;
                          _speakingMessageId = null;
                        });
                      }

                      setDialogState(() => isSpeakingFromDialog = true);
                      await _flutterTts.speak(translatedText);

                      _flutterTts.setCompletionHandler(() {
                        if (mounted) {
                          setState(() {
                            _isSpeaking = false;
                            _speakingMessageId = null;
                          });
                        }
                        isSpeakingFromDialog = false;
                      });
                    }
                  },
                  icon: Icon(
                    isSpeakingFromDialog ? Icons.stop : Icons.volume_up,
                    size: 18,
                  ),
                  label: Text(isSpeakingFromDialog ? "Stop" : "Speak"),
                  style: ElevatedButton.styleFrom(backgroundColor: appColor),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (isSpeakingFromDialog) {
        _flutterTts.stop();
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _speakingMessageId = null;
          });
        }
      }
    });
  }

  Future<void> _speakInEnglish(String text, {String? messageId}) async {
    if (text.trim().isEmpty || !mounted) return;

    final cubitCheck = _inworldTts ?? context.read<InworldTtsCubit>();
    if (!cubitCheck.state.audioEnabled) return;

    await _stopVoicePlayback();
    await _flutterTts.stop();

    final trimmed = text.trim();
    if (messageId != null) {
      _ttsWaveProgressByMessageId[messageId] = 0.0;
    }
    _isAiSpeechUsingRemoteAudio = false;
    _ttsCountAsNaturalCompletion = true;
    setState(() {
      _isSpeaking = true;
      _speakingMessageId = messageId;
      _ttsEstimatedSeconds = _estimateTtsSeconds(trimmed);
    });
    _startTtsElapsedTicker();
    _syncWaveAnimation();

    if (!mounted) return;
    final cubit = _inworldTts ?? context.read<InworldTtsCubit>();
    await cubit.speak(trimmed, playbackId: messageId);
  }

  Future<bool> _startRemoteAiSpeech({
    required String audioUrl,
    required String messageId,
    required String fallbackText,
  }) async {
    if (!mounted) return false;
    final url = audioUrl.trim();
    if (url.isEmpty) return false;

    try {
      await _stopVoicePlayback();
      await _flutterTts.stop();
      final cubit = _inworldTts ?? context.read<InworldTtsCubit>();
      await cubit.stop();
    } catch (_) {}

    _ttsWaveProgressByMessageId[messageId] = 0.0;
    _ttsCountAsNaturalCompletion = true;
    _isAiSpeechUsingRemoteAudio = true;
    setState(() {
      _isSpeaking = true;
      _speakingMessageId = messageId;
      _ttsEstimatedSeconds = _estimateTtsSeconds(fallbackText.trim());
    });
    _startTtsElapsedTicker();
    _syncWaveAnimation();

    try {
      await _chatVoicePlayer.play(UrlSource(url));
      try {
        await _chatVoicePlayer.onPlayerStateChanged
            .firstWhere((state) => state == PlayerState.playing)
            .timeout(const Duration(milliseconds: 1200));
      } catch (_) {
        // Some platforms resolve play after already entering playing state.
      }
      return true;
    } catch (_) {
      _isAiSpeechUsingRemoteAudio = false;
      _stopTtsElapsedTicker();
      _waveController.stop();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingMessageId = null;
        });
      }
      return false;
    }
  }

  Future<void> _stopSpeaking() async {
    final id = _speakingMessageId;
    _ttsCountAsNaturalCompletion = false;
    if (id != null && _ttsEstimatedSeconds > 0) {
      final denom = (_ttsEstimatedSeconds * 1000).clamp(1, 999999999);
      final p = (_ttsElapsed.inMilliseconds / denom).clamp(0.0, 1.0);
      _ttsWaveProgressByMessageId[id] = p;
    }
    if (_isAiSpeechUsingRemoteAudio) {
      await _chatVoicePlayer.stop();
      _isAiSpeechUsingRemoteAudio = false;
    } else {
      final cubit = _inworldTts ?? context.read<InworldTtsCubit>();
      await cubit.stop();
    }
    if (mounted) {
      _stopTtsElapsedTicker();
      _waveController.stop();
      setState(() {
        _isSpeaking = false;
        _speakingMessageId = null;
      });
    }
  }

  void _goToDashboard() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
      (route) => false,
    );
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTextMessage({bool fromQuickReply = false}) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final clientMessageId = _newChatMessageId();
    if (fromQuickReply) {
      _pendingQuickReplyMessageIds.add(clientMessageId);
    }

    if (socketService.isConnected) {
      socketService.sendMessage(text, clientMessageId: clientMessageId);
      _markAiPendingStarted();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not connected. Please wait...')),
        );
      }
      return;
    }
    _textController.clear();
    _scrollToBottom();

    if (_showSuggestions) {
      setState(() {
        _showSuggestions = false;
        _isBulbActive = false;
      });
    }
  }

  @override
  void dispose() {
    if (_isRecordingVoice) {
      unawaited(_voiceRecorder.stop());
    }
    socketService.socket.off('message', _onSocketMessage);
    socketService.socket.off('aifeedback', _onAiFeedbackSocket);
    socketService.socket.off('typing', _onTypingSocket);
    _flutterTts.stop();
    unawaited(_inworldTts?.stop() ?? Future.value());
    _pronStopTimer?.cancel();
    unawaited(_chatVoicePlayer.stop());
    unawaited(_voiceRecorder.dispose());
    _chatVoicePlayer.dispose();
    _textController.removeListener(_onInputTextChanged);
    _stopTtsElapsedTicker();
    _aiTypingDotsTimer?.cancel();
    _waveController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _generateSuggestions();
    final partnerPhoto = widget.partnerDetails["photo"]?.toString();
    final partnerName = "${widget.partnerDetails["name"] ?? ""} AI Partner";

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _goToDashboard();
      },
      child: BlocListener<InworldTtsCubit, InworldTtsState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.playbackId != curr.playbackId ||
            prev.errorMessage != curr.errorMessage ||
            prev.audioEnabled != curr.audioEnabled,
        listener: (context, state) {
          if (!state.audioEnabled) {
            unawaited(_stopSpeaking());
          }
          if (state.status == InworldTtsStatus.error &&
              (state.errorMessage?.isNotEmpty ?? false)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }

          final pid = state.playbackId;
          final isStory = pid == 'story';

          if (state.status == InworldTtsStatus.loading ||
              state.status == InworldTtsStatus.playing) {
            if (pid != null && !isStory) {
              final t = _ttsTextForMessageId(pid) ?? '';
              setState(() {
                _isSpeaking = true;
                _speakingMessageId = pid;
                _ttsEstimatedSeconds = _estimateTtsSeconds(t);
              });
              _startTtsElapsedTicker();
              _syncWaveAnimation();
            }
            return;
          }

          if (state.status == InworldTtsStatus.idle ||
              state.status == InworldTtsStatus.error) {
            if ((!isStory || pid == null) && !_isAiSpeechUsingRemoteAudio) {
              setState(() {
                _isSpeaking = false;
                _speakingMessageId = null;
              });
              _stopTtsElapsedTicker();
              _waveController.stop();
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leadingWidth: 42,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 24),
              onPressed: _goToDashboard,
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: appColor,
                  backgroundImage: partnerPhoto != null
                      ? (partnerPhoto.startsWith("assets/")
                          ? AssetImage(partnerPhoto) as ImageProvider
                          : FileImage(File(partnerPhoto)))
                      : null,
                  child: partnerPhoto == null
                      ? Icon(
                          widget.partnerDetails["gender"]
                                      ?.toString()
                                      .toLowerCase() ==
                                  "female"
                              ? Icons.woman
                              : Icons.man,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        partnerName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFF23C552),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "ONLINE",
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Voice & TTS settings',
                icon: const Icon(Icons.record_voice_over_outlined, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VoiceSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
            elevation: 1,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[350])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "Today",
                        style: GoogleFonts.roboto(
                          fontSize: 22,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[350])),
                  ],
                ),
              ),
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Connecting to AI..."),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        itemCount:
                            _messages.length + (_showAiTypingLoader ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_showAiTypingLoader &&
                              index == _messages.length) {
                            return _buildAiTypingBubble();
                          }
                          final msg = _messages[index];
                          return KeyedSubtree(
                            key: ValueKey(msg.id),
                            child: _buildMessageBubble(msg),
                          );
                        },
                      ),
              ),
              if (_isRecordingVoice)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fiber_manual_record,
                          color: Colors.redAccent, size: 22),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Recording… Tap mic again to send',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_showSuggestions && suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber[300]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb,
                              color: Colors.amber[800], size: 20),
                          const SizedBox(width: 6),
                          Text(
                            "Say this",
                            style: TextStyle(
                              color: Colors.amber[900],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _toggleSuggestions,
                            child: Icon(Icons.close,
                                size: 18, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: suggestions.map((suggestion) {
                          return GestureDetector(
                            onTap: () {
                              _textController.text = suggestion;
                              _sendTextMessage(fromQuickReply: true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber[300]!),
                              ),
                              child: Text(
                                suggestion,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleSuggestions,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _isBulbActive
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFFFFF3CD),
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (_isBulbActive)
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: _isBulbActive
                                ? Colors.amber[900]
                                : Colors.amber[700],
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendTextMessage(),
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            border: InputBorder.none,
                            hintStyle: GoogleFonts.roboto(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (_textController.text.trim().isEmpty)
                        GestureDetector(
                          onTap:
                              _isVoiceUploading ? null : _toggleVoiceRecording,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isRecordingVoice
                                  ? Colors.redAccent
                                  : const Color(0xFF3BA4E8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecordingVoice
                                          ? Colors.redAccent
                                          : const Color(0xFF3BA4E8))
                                      .withValues(alpha: 0.35),
                                  blurRadius: _isRecordingVoice ? 26 : 12,
                                ),
                              ],
                            ),
                            child: _isVoiceUploading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isRecordingVoice
                                        ? Icons.stop
                                        : Icons.mic_none,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        )
                      else
                        IconButton(
                          icon:
                              const Icon(Icons.send, color: Color(0xFF3BA4E8)),
                          onPressed: _sendTextMessage,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAiFeedbackForMessage(ChatMessage message) {
    if (!message.isUser) return;
    setState(() {
      if (_expandedAiFeedbackIds.contains(message.id)) {
        _expandedAiFeedbackIds.remove(message.id);
        _aiFeedbackLoadingIds.remove(message.id);
        if (_pendingAiFeedbackMessageId == message.id) {
          _pendingAiFeedbackMessageId = null;
        }
      } else {
        _expandedAiFeedbackIds.add(message.id);
        _aiFeedbackResultByMessageId.remove(message.id);
        _aiFeedbackErrorByMessageId.remove(message.id);
        if (socketService.isConnected) {
          _aiFeedbackLoadingIds.add(message.id);
          _pendingAiFeedbackMessageId = message.id;
          socketService.emitAiFeedback(
            message.text,
            audioUrl: message.audioUrl,
          );
        } else {
          _aiFeedbackErrorByMessageId[message.id] =
              'Not connected. Check your network and try again.';
        }
      }
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isThisMessageSpeaking =
        _speakingMessageId == message.id && _isSpeaking;
    final partnerPhoto = widget.partnerDetails["photo"]?.toString();
    final showAiFeedbackPanel =
        isUser && _expandedAiFeedbackIds.contains(message.id);

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 72 : 0,
        right: isUser ? 0 : 72,
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            BlocBuilder<InworldTtsCubit, InworldTtsState>(
              buildWhen: (a, b) => a.audioEnabled != b.audioEnabled,
              builder: (context, tts) {
                if (!tts.audioEnabled) return const SizedBox.shrink();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: appColor,
                          backgroundImage: partnerPhoto != null
                              ? (partnerPhoto.startsWith("assets/")
                                  ? AssetImage(partnerPhoto) as ImageProvider
                                  : FileImage(File(partnerPhoto)))
                              : null,
                          child: partnerPhoto == null
                              ? Icon(
                                  widget.partnerDetails["gender"]
                                              ?.toString()
                                              .toLowerCase() ==
                                          "female"
                                      ? Icons.woman
                                      : Icons.man,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTtsCapsule(message)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                );
              },
            ),
          ] else if (message.isVoiceMessage) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(child: _buildVoiceCapsule(message)),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.person, color: Color(0xFF3BA4E8), size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.person, color: Color(0xFF3BA4E8), size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            constraints: BoxConstraints(
              minWidth: isUser ? MediaQuery.of(context).size.width * 0.55 : 0,
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [Color(0xFF4F6BED), Color(0xFF3B56D6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUser ? null : const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  textAlign: TextAlign.start,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: isUser ? Colors.white : Colors.black87,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        if (isThisMessageSpeaking) {
                          await _stopSpeaking();
                        } else {
                          await _showTranslationDialog(message.text);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.translate, size: 14, color: appColor),
                            const SizedBox(width: 4),
                            Text(
                              "Translate",
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: appColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else if (!(message.isQuickReply ?? false)) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleAiFeedbackForMessage(message),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: showAiFeedbackPanel
                                  ? appColor
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            "AI feedback",
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: appColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (showAiFeedbackPanel)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildAiFeedbackCardsStack(
                messageId: message.id,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(right: 72, bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F3F3),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: Text(
            '.' * _aiTypingDots,
            style: GoogleFonts.roboto(
              fontSize: 22,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  // --- AI feedback (Socket `aifeedback` + `typing` with type aifeedback) ---
  static const Color _fbCardBg = Color(0xFF262733);
  static const Color _fbSectionBg = Color(0xFF2E3040);
  static const Color _fbRowBg = Color(0xFF1F2130);
  static const Color _fbPurple = Color(0xFF6D3BBF);
  static const Color _fbGrammarGreen = Color(0xFF1B5E20);
  static const Color _fbGrammarGreenText = Color(0xFF69F0AE);

  Widget _buildAiFeedbackCardsStack({
    required String messageId,
  }) {
    final maxW = MediaQuery.of(context).size.width * 0.72;
    final err = _aiFeedbackErrorByMessageId[messageId];
    if (err != null && err.isNotEmpty) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _fbCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
          ),
          child: Text(
            err,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    if (_aiFeedbackLoadingIds.contains(messageId)) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: _fbCardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_fbPurple),
              ),
              const SizedBox(height: 14),
              Text(
                'Analyzing your English…',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final payload = _aiFeedbackResultByMessageId[messageId];
    if (payload == null) {
      return const SizedBox.shrink();
    }

    final showCorrectSentence = !payload.correctSentence.isEmpty;
    final showImproveSentence = !payload.improveSentence.isEmpty;
    final showMoreWays = payload.moreWaysToSay.isNotEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: _buildFeedbackCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showCorrectSentence)
              _buildCorrectSentenceCard(payload.correctSentence),
            if (showCorrectSentence && (showImproveSentence || showMoreWays))
              const SizedBox(height: 10),
            if (showImproveSentence)
              _buildImproveSentenceCard(payload.improveSentence),
            if (showImproveSentence && showMoreWays) const SizedBox(height: 10),
            if (showMoreWays) _buildMoreWaysToSayCard(payload.moreWaysToSay),
            if (!showCorrectSentence && !showImproveSentence && !showMoreWays)
              Text(
                'No structured feedback in this response.',
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.white54),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCategoryChip(
    String label, {
    required IconData icon,
    required Color bg,
    required Color border,
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor.withValues(alpha: 0.95)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCardShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: _fbCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _buildFeedbackSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: _fbSectionBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: child,
    );
  }

  Widget _buildCorrectSentenceCard(AiFeedbackCorrectSentence sentence) {
    String normSentence(String s) =>
        s.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    final inc = sentence.incorrect.trim();
    final corr = sentence.corrected.trim();
    final wrongSameAsRight = inc.isNotEmpty &&
        corr.isNotEmpty &&
        normSentence(inc) == normSentence(corr);
    final showWrongLine = inc.isNotEmpty && !wrongSameAsRight;

    return _buildFeedbackSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedbackCategoryChip(
            'Correct Sentence',
            icon: Icons.check_circle_rounded,
            bg: const Color(0xFF284A35),
            border: const Color(0xFF58C686),
            textColor: const Color(0xFFD4FFE8),
          ),
          const SizedBox(height: 10),
          if (showWrongLine)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE15B64),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 15, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: _fbRowBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      sentence.incorrect,
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        height: 1.35,
                        color: const Color(0xFFFF8E8E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (showWrongLine && sentence.corrected.isNotEmpty)
            const SizedBox(height: 8),
          if (sentence.corrected.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF50B67C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 15, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: _fbGrammarGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      sentence.corrected,
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        height: 1.35,
                        color: _fbGrammarGreenText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (sentence.tip.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1.5, right: 6),
                  child: Icon(Icons.lightbulb_rounded,
                      color: Color(0xFFF8D46B), size: 15),
                ),
                Expanded(
                  child: Text(
                    'Tip: ${sentence.tip}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.2,
                      height: 1.35,
                      color: const Color(0xFFE6E7EF),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImproveSentenceCard(AiFeedbackImproveSentence improve) {
    return _buildFeedbackSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedbackCategoryChip(
            'Improve Sentence',
            icon: Icons.auto_awesome_rounded,
            bg: const Color(0xFF2E3157),
            border: const Color(0xFF7A8EFF),
            textColor: const Color(0xFFE7ECFF),
          ),
          const SizedBox(height: 10),
          if (improve.sentence.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: _fbRowBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                improve.sentence,
                style: GoogleFonts.poppins(
                  fontSize: 12.8,
                  height: 1.35,
                  color: const Color(0xFFE6D8FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (improve.tip.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1.5, right: 6),
                  child: Icon(Icons.lightbulb_rounded,
                      color: Color(0xFFF8D46B), size: 15),
                ),
                Expanded(
                  child: Text(
                    'Tip: ${improve.tip}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.2,
                      height: 1.35,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreWaysToSayCard(List<String> phrases) {
    return _buildFeedbackSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedbackCategoryChip(
            'More Ways to Say',
            icon: Icons.chat_bubble_rounded,
            bg: const Color(0xFF56355E),
            border: const Color(0xFFE58BCE),
            textColor: const Color(0xFFFFE3F7),
          ),
          const SizedBox(height: 10),
          ...phrases.asMap().entries.map((e) {
            final isLast = e.key == phrases.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Text('•',
                        style:
                            TextStyle(color: Color(0xFFD779C3), fontSize: 13)),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.33,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static const Color _ttsCapsuleBg = Color(0xFFF0F0F2);
  static const Color _ttsPlayGradientA = Color(0xFF5B8CFF);
  static const Color _ttsPlayGradientB = Color(0xFF6D3BBF);
  static const Color _ttsWaveColor = Color(0xFF6B7FD7);
  static const Color _ttsWaveUnplayed = Color(0xFF1A1A1A);

  double _waveProgressForMessage(ChatMessage message, bool isPlaying) {
    if (isPlaying && _speakingMessageId == message.id) {
      final denom = (_ttsEstimatedSeconds * 1000).clamp(1, 999999999);
      return (_ttsElapsed.inMilliseconds / denom).clamp(0.0, 1.0);
    }
    return _ttsWaveProgressByMessageId[message.id] ?? 0.0;
  }

  Widget _buildTtsCapsule(ChatMessage message) {
    return BlocBuilder<InworldTtsCubit, InworldTtsState>(
      buildWhen: (a, b) =>
          a.status != b.status ||
          a.playbackId != b.playbackId ||
          a.audioEnabled != b.audioEnabled,
      builder: (context, tts) {
        if (!tts.audioEnabled) return const SizedBox.shrink();
        final isLoading = tts.isLoadingFor(message.id);
        final isPlayingCubit = tts.isPlayingFor(message.id);
        final isPlaying =
            isPlayingCubit || (_speakingMessageId == message.id && _isSpeaking);
        final waveActive = isPlaying || isLoading;
        final waveProgress = _waveProgressForMessage(message, isPlaying);
        final ttsText = (message.aiTtsText?.trim().isNotEmpty ?? false)
            ? message.aiTtsText!.trim()
            : message.text;
        final est = _estimateTtsSeconds(ttsText);
        final elapsedSec = (_ttsElapsed.inMilliseconds / 1000).floor();
        final timeLabel = isPlaying
            ? _formatMmSs(math.min(elapsedSec, _ttsEstimatedSeconds))
            : _formatMmSs(est);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading
                ? null
                : () {
                    if (isPlaying) {
                      _stopSpeaking();
                    } else {
                      final remoteUrl = message.audioUrl?.trim();
                      if (remoteUrl != null && remoteUrl.isNotEmpty) {
                        _startRemoteAiSpeech(
                          audioUrl: remoteUrl,
                          messageId: message.id,
                          fallbackText: ttsText,
                        );
                      } else {
                        _speakInEnglish(ttsText, messageId: message.id);
                      }
                    }
                  },
            borderRadius: BorderRadius.circular(28),
            child: Ink(
              decoration: BoxDecoration(
                color: _ttsCapsuleBg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 11, 5),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_ttsPlayGradientA, _ttsPlayGradientB],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _ttsPlayGradientB.withValues(alpha: 0.32),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 26,
                        child: _ChatTtsWaveform(
                          seed: message.id.hashCode,
                          isAnimating: waveActive,
                          listenable: _waveController,
                          playedProgress: waveProgress,
                          playedColor: _ttsWaveColor,
                          unplayedColor: _ttsWaveUnplayed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceCapsule(ChatMessage message) {
    final isPlaying = _playingVoiceMessageId == message.id;
    final waveProgress = _voiceProgressForMessage(message);
    final timeLabel = _voiceTimeLabelForMessage(message);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleVoiceMessagePlayback(message),
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: _ttsCapsuleBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 11, 5),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_ttsPlayGradientA, _ttsPlayGradientB],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _ttsPlayGradientB.withValues(alpha: 0.32),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 26,
                    child: _ChatTtsWaveform(
                      seed: message.id.hashCode,
                      isAnimating: isPlaying,
                      listenable: _waveController,
                      playedProgress: waveProgress,
                      playedColor: _ttsWaveColor,
                      unplayedColor: _ttsWaveUnplayed,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeLabel,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatTtsWaveform extends StatelessWidget {
  const _ChatTtsWaveform({
    required this.seed,
    required this.isAnimating,
    required this.listenable,
    required this.playedProgress,
    required this.playedColor,
    required this.unplayedColor,
  });

  final int seed;
  final bool isAnimating;
  final Listenable listenable;
  final double playedProgress;
  final Color playedColor;
  final Color unplayedColor;

  @override
  Widget build(BuildContext context) {
    Widget paintWithPhase(double phase) {
      return CustomPaint(
        painter: _ChatTtsWaveformPainter(
          phase: phase,
          isAnimating: isAnimating,
          playedProgress: playedProgress.clamp(0.0, 1.0),
          playedColor: playedColor,
          unplayedColor: unplayedColor,
          seed: seed,
        ),
        child: const SizedBox.expand(),
      );
    }

    if (!isAnimating) {
      return paintWithPhase(0);
    }
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, child) {
        final phase = listenable is Animation<double>
            ? (listenable as Animation<double>).value
            : 0.0;
        return paintWithPhase(phase);
      },
    );
  }
}

class _ChatTtsWaveformPainter extends CustomPainter {
  _ChatTtsWaveformPainter({
    required this.phase,
    required this.isAnimating,
    required this.playedProgress,
    required this.playedColor,
    required this.unplayedColor,
    required this.seed,
  });

  final double phase;
  final bool isAnimating;
  final double playedProgress;
  final Color playedColor;
  final Color unplayedColor;
  final int seed;

  double _pseudo01(int i) {
    var x = seed ^ (i * 0x9E3779B9);
    x = x & 0x7fffffff;
    return (x % 1001) / 1001.0;
  }

  void _drawBars(
    Canvas canvas,
    Size size,
    Color color,
  ) {
    const barCount = 26;
    const gap = 2.0;
    final totalGap = gap * (barCount - 1);
    final barW = (size.width - totalGap) / barCount;
    final midY = size.height / 2;
    final maxH = size.height;
    for (var i = 0; i < barCount; i++) {
      final x = i * (barW + gap) + barW / 2;
      final base = 0.22 + 0.58 * _pseudo01(i);
      final wobble = isAnimating
          ? 0.55 +
              0.45 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi * 2 + i * 0.48))
          : 1.0;
      final amp = (base * wobble).clamp(0.12, 1.0);
      final h = (maxH * amp).clamp(3.0, maxH);
      final paint = Paint()
        ..color = color
        ..strokeWidth = math.max(1.2, barW * 0.75)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, midY - h / 2),
        Offset(x, midY + h / 2),
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawBars(canvas, size, unplayedColor);
    final p = playedProgress.clamp(0.0, 1.0);
    if (p <= 0) return;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width * p, size.height));
    _drawBars(canvas, size, playedColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChatTtsWaveformPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.isAnimating != isAnimating ||
        oldDelegate.seed != seed ||
        oldDelegate.playedProgress != playedProgress ||
        oldDelegate.playedColor != playedColor ||
        oldDelegate.unplayedColor != unplayedColor;
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool hasAudio;
  final bool? isQuickReply;
  final String? aiTtsText;

  /// Quick-reply chip text from socket `suggestion` (not `example`).
  final String? suggestion;

  /// HTTPS URL from server after voice upload; user sees [text] only (no in-bubble player).
  final String? audioUrl;

  bool get isVoiceMessage =>
      isUser && audioUrl != null && audioUrl!.trim().isNotEmpty;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.hasAudio = false,
    this.isQuickReply = false,
    this.aiTtsText,
    this.suggestion,
    this.audioUrl,
    String? id,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}_${text.hashCode}';
}
