import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_cubit.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spokiai/model/generatestory.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/socket.dart';
import 'package:spokiai/view/screens/story_quiz_screen.dart';
import 'package:spokiai/view/screens/voice_settings.dart';
import '../utils/preference_manager.dart';
import '../../model/wordmeaning.dart';
import '../../viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/colors.dart';
import '../utils/custom_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';

/// Quiz readiness from Socket `storyQuizStatus` (`quizGenerationStatus`).
enum _StoryQuizGenPhase {
  checking,
  pending,
  processing,
  ready,
  failed,
  requestFailed,
  offline,
  noAuth,
  noStory,
}

class StorydescriptionScreen extends StatefulWidget {
  final GenerateStoryResponse generateStoryResponse;

  StorydescriptionScreen({super.key, required this.generateStoryResponse});

  @override
  State<StorydescriptionScreen> createState() => _StorydescriptionScreenState();
}

class _StorydescriptionScreenState extends State<StorydescriptionScreen> {
  static const LinearGradient _appPurpleGradient = LinearGradient(
    colors: [Color(0xFF5A35E5), Color(0xFF7E48F4)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const String _pdfDownloadChannelId = 'story_pdf_downloads';
  static const String _pdfDownloadChannelName = 'Story PDF Downloads';
  static const String _pdfDownloadChannelDescription =
      'Notifications for downloaded story PDFs';
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  late FlutterTts flutterTts;

  final SocketService _storyQuizSocket = SocketService();
  Timer? _storyQuizPollTimer;
  void Function(dynamic)? _storyQuizConnectHandler;
  bool _storyQuizListenerAttached = false;
  String? _lastEmittedRequestId;

  _StoryQuizGenPhase _storyQuizPhase = _StoryQuizGenPhase.checking;
  String? _storyQuizHint;
  Map<String, dynamic>? _preloadedQuizFromSocket;

  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.5;
  bool _isStoryTtsPreparing = false;
  bool _isSofyStorySpeaking = false;
  bool _cancelSofyStoryPlayback = false;
  InworldTtsCubit? _inworldTts;
  Map<String, String> availableLanguages = {};
  String? selectedLanguageCode;

  @override
  void initState() {
    initTts();
    unawaited(_initLocalNotifications());
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStoryQuizStatusFlow();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inworldTts ??= context.read<InworldTtsCubit>();
  }

  void _stopStoryQuizPoll() {
    _storyQuizPollTimer?.cancel();
    _storyQuizPollTimer = null;
  }

  void _ensureStoryQuizPoll() {
    _stopStoryQuizPoll();
    _storyQuizPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_storyQuizPhase != _StoryQuizGenPhase.pending &&
          _storyQuizPhase != _StoryQuizGenPhase.processing) {
        _stopStoryQuizPoll();
        return;
      }
      _emitGetStoryQuizStatus();
    });
  }

  void _emitGetStoryQuizStatus() {
    final storyId = widget.generateStoryResponse.data?.id?.toString() ?? '';
    final token = PreferenceManager.getStringValue(key: 'token') ?? '';
    if (storyId.isEmpty) return;
    if (token.isEmpty) return;

    if (!_storyQuizSocket.isConnected) {
      if (mounted) {
        setState(() {
          _storyQuizPhase = _StoryQuizGenPhase.offline;
          _storyQuizHint = 'No connection. Waiting for network…';
        });
      }
      return;
    }

    _lastEmittedRequestId = DateTime.now().microsecondsSinceEpoch.toString();
    _storyQuizSocket.emitGetStoryQuizStatus(
      storyId: storyId,
      token: token,
      requestId: _lastEmittedRequestId,
    );
  }

  void _onStoryQuizStatus(dynamic raw) {
    if (!mounted) return;
    if (raw is! Map) return;
    final m = Map<String, dynamic>.from(raw);

    final ridIn = m['requestId']?.toString();
    if (ridIn != null &&
        _lastEmittedRequestId != null &&
        ridIn != _lastEmittedRequestId) {
      return;
    }

    final success = m['success'] == true;
    if (!success) {
      setState(() {
        _storyQuizPhase = _StoryQuizGenPhase.requestFailed;
        _storyQuizHint =
            m['message']?.toString() ?? 'Could not check quiz status.';
        _preloadedQuizFromSocket = null;
      });
      _stopStoryQuizPoll();
      return;
    }

    final data = m['data'];
    if (data is! Map) {
      setState(() {
        _storyQuizPhase = _StoryQuizGenPhase.requestFailed;
        _storyQuizHint = 'Invalid quiz status response.';
      });
      _stopStoryQuizPoll();
      return;
    }

    final d = Map<String, dynamic>.from(data);
    final qStatus =
        d['quizGenerationStatus']?.toString().toLowerCase().trim() ?? '';

    switch (qStatus) {
      case 'ready':
        final quiz = d['quiz'];
        Map<String, dynamic>? quizMap;
        if (quiz is Map) {
          quizMap = Map<String, dynamic>.from(quiz);
        }
        setState(() {
          _storyQuizPhase = _StoryQuizGenPhase.ready;
          _preloadedQuizFromSocket = quizMap;
          _storyQuizHint =
              quizMap == null ? 'Quiz is ready. Open to load questions.' : null;
        });
        _stopStoryQuizPoll();
        break;
      case 'processing':
        setState(() {
          _storyQuizPhase = _StoryQuizGenPhase.processing;
          _storyQuizHint = 'Generating quiz…';
        });
        _ensureStoryQuizPoll();
        break;
      case 'failed':
        setState(() {
          _storyQuizPhase = _StoryQuizGenPhase.failed;
          _storyQuizHint = d['error']?.toString() ?? 'Quiz generation failed.';
          _preloadedQuizFromSocket = null;
        });
        _stopStoryQuizPoll();
        break;
      case 'pending':
        setState(() {
          _storyQuizPhase = _StoryQuizGenPhase.pending;
          _storyQuizHint = 'Quiz not ready yet…';
        });
        _ensureStoryQuizPoll();
        break;
      default:
        setState(() {
          _storyQuizPhase = _StoryQuizGenPhase.checking;
          _storyQuizHint = null;
        });
    }
  }

  void _startStoryQuizStatusFlow() {
    final storyId = widget.generateStoryResponse.data?.id?.toString() ?? '';
    if (storyId.isEmpty) {
      setState(() {
        _storyQuizPhase = _StoryQuizGenPhase.noStory;
        _storyQuizHint = 'Story ID missing.';
      });
      return;
    }

    final token = PreferenceManager.getStringValue(key: 'token') ?? '';
    if (token.isEmpty) {
      setState(() {
        _storyQuizPhase = _StoryQuizGenPhase.noAuth;
        _storyQuizHint = 'Log in to unlock the quiz.';
      });
      return;
    }

    _storyQuizSocket.initSocket();
    if (!_storyQuizListenerAttached) {
      _storyQuizSocket.socket.on('storyQuizStatus', _onStoryQuizStatus);
      _storyQuizListenerAttached = true;
    }

    if (_storyQuizSocket.isConnected) {
      setState(() {
        _storyQuizPhase = _StoryQuizGenPhase.checking;
        _storyQuizHint = 'Checking quiz…';
      });
      _emitGetStoryQuizStatus();
    } else {
      setState(() {
        _storyQuizPhase = _StoryQuizGenPhase.checking;
        _storyQuizHint = 'Connecting…';
      });
      _storyQuizConnectHandler = (dynamic _) {
        if (!mounted) return;
        if (_storyQuizConnectHandler != null) {
          _storyQuizSocket.socket.off('connect', _storyQuizConnectHandler!);
          _storyQuizConnectHandler = null;
        }
        setState(() {
          _storyQuizHint = 'Checking quiz…';
        });
        _emitGetStoryQuizStatus();
      };
      _storyQuizSocket.socket.on('connect', _storyQuizConnectHandler!);
    }
  }

  bool get _storyQuizYesEnabled => _storyQuizPhase == _StoryQuizGenPhase.ready;

  Widget _buildStoryActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tealSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.text_fields_rounded, size: 14, color: tealDark),
              const SizedBox(width: 6),
              textInter(
                text:
                    "${widget.generateStoryResponse.data?.metadata?.wordCount.toString() ?? "0"} words",
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: tealDark,
              ),
            ],
          ),
        ),
        Row(
          children: [
            BlocBuilder<InworldTtsCubit, InworldTtsState>(
              buildWhen: (a, b) =>
                  a.status != b.status || a.playbackId != b.playbackId,
              builder: (context, tts) {
                final inworldStoryActive = tts.playbackId == 'story' &&
                    (tts.status == InworldTtsStatus.loading ||
                        tts.status == InworldTtsStatus.playing);
                final storyTtsActive =
                    _isSofyStorySpeaking || inworldStoryActive;
                return IconButton(
                  icon: _isStoryTtsPreparing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          storyTtsActive
                              ? Icons.pause_rounded
                              : Icons.volume_up_outlined,
                        ),
                  onPressed: () async {
                    if (_isStoryTtsPreparing || storyTtsActive) {
                      await stop();
                      return;
                    }
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const VoiceSettingsScreen(fromStory: true),
                      ),
                    );
                    if (!mounted || result is! Map) return;
                    final useSofy = result['useSofy'] == true;
                    final shouldPlay = result['playStoryTts'] == true;
                    final selectedVoiceId =
                        result['selectedVoiceId']?.toString();
                    if (shouldPlay) {
                      await speak(
                        useSofy: useSofy,
                        selectedVoiceId: selectedVoiceId,
                      );
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: () {
                final String title = widget
                        .generateStoryResponse.data?.metadata?.title
                        .toString() ??
                    "";
                final String description =
                    widget.generateStoryResponse.data?.story.toString() ?? "";

                downloadPdfExternal(title, description);
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final String title = widget
                        .generateStoryResponse.data?.metadata?.title
                        .toString() ??
                    "";
                final String description =
                    widget.generateStoryResponse.data?.story.toString() ?? "";

                Share.share(
                  "$title\n\n$description",
                  subject: title,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> initTts() async {
    flutterTts = FlutterTts();

    // Android: use Google TTS engine for best quality
    if (Platform.isAndroid) {
      await flutterTts.setEngine("com.google.android.tts");
    }

    // Set initial values
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.awaitSpeakCompletion(true);

    _attachFlutterTtsHandlers();

    // Load languages safely without duplicates
    await loadLanguages();

    setState(() {});
  }

  void _attachFlutterTtsHandlers() {
    flutterTts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _isStoryTtsPreparing = false;
        _isSofyStorySpeaking = true;
      });
    });
    flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _isSofyStorySpeaking = false);
    });
    flutterTts.setCancelHandler(() {
      if (!mounted) return;
      setState(() => _isSofyStorySpeaking = false);
    });
    flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSofyStorySpeaking = false;
          _isStoryTtsPreparing = false;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $msg")));
    });
  }

  Future<void> _resetFlutterTtsEngineForSofy() async {
    try {
      await flutterTts.stop();
    } catch (_) {}
    flutterTts = FlutterTts();
    if (Platform.isAndroid) {
      await flutterTts.setEngine("com.google.android.tts");
    }
    await flutterTts.awaitSpeakCompletion(true);
    _attachFlutterTtsHandlers();
  }

  Future<void> loadLanguages() async {
    try {
      dynamic langs = await flutterTts.getLanguages;

      if (langs == null || langs.isEmpty) {
        // Fallback if getLanguages fails
        availableLanguages = {
          "en-US": "English (US)",
          "en-GB": "English (UK)",
          // "es-ES": "Spanish",
          // "fr-FR": "French",
          // "de-DE": "German",
          // "hi-IN": "Hindi",
        };
      } else {
        // Clean and deduplicate
        availableLanguages.clear();
        for (var lang in langs) {
          String code = lang.toString().trim();

          // Convert common variations to standard format
          String displayName = code;
          if (code.contains("-")) {
            displayName = "";
          }

          // Standard display names
          Map<String, String> nameMap = {
            "en-US": "English (US)",
            "en-GB": "English (UK)",
            "en-AU": "English (Australia)",
            "es-ES": "Spanish (Spain)",
            "es-MX": "Spanish (Mexico)",
            "fr-FR": "French",
            "de-DE": "German",
            "it-IT": "Italian",
            "pt-BR": "Portuguese (Brazil)",
            "hi-IN": "Hindi",
            "zh-CN": "Chinese (Simplified)",
            "ja-JP": "Japanese",
            "ko-KR": "Korean",
          };

          displayName = nameMap[code] ?? displayName;

          availableLanguages[code] = displayName;
        }
      }

      selectedLanguageCode ??= availableLanguages.keys.firstWhere(
        (k) => k.startsWith("en"),
        orElse: () => availableLanguages.keys.first,
      );

      await flutterTts.setLanguage(selectedLanguageCode!);
      setState(() {});
    } catch (e) {
      debugPrint("Error loading languages: $e");
    }
  }

  Future<void> speak({
    bool useSofy = false,
    String? selectedVoiceId,
  }) async {
    final story = widget.generateStoryResponse.data?.story.toString() ?? '';
    if (story.isEmpty || !mounted) return;
    final cubit = context.read<InworldTtsCubit>();
    if (!cubit.state.audioEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio is turned off in voice settings.')),
      );
      return;
    }
    setState(() {
      _isStoryTtsPreparing = true;
      _isSofyStorySpeaking = false;
      _cancelSofyStoryPlayback = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating voice...'),
        duration: Duration(seconds: 1),
      ),
    );
    try {
      await stop(keepPreparing: true);
      if (useSofy) {
        // Give the local TTS engine a brief moment after stop() to reset.
        await Future.delayed(const Duration(milliseconds: 120));
        await _speakStoryWithFlutterTts(story);
      } else {
        await cubit.speak(
          story,
          playbackId: 'story',
          voiceIdForPreview: selectedVoiceId,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStoryTtsPreparing = false);
      }
    }
  }

  Future<void> stop({bool keepPreparing = false}) async {
    _cancelSofyStoryPlayback = true;
    await flutterTts.stop();
    final cubit = _inworldTts;
    if (cubit != null) {
      await cubit.stop();
    }
    if (mounted) {
      setState(() {
        _isSofyStorySpeaking = false;
        if (!keepPreparing) {
          _isStoryTtsPreparing = false;
        }
      });
    }
  }

  Future<void> _exitToHome() async {
    await stop();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(initialTabIndex: 0),
      ),
      (route) => false,
    );
  }

  Future<int> _resolveFlutterTtsMaxInputLength() async {
    try {
      final dynamic maxLen = await flutterTts.getMaxSpeechInputLength;
      if (maxLen is int && maxLen > 0) return maxLen;
      if (maxLen is String) {
        final parsed = int.tryParse(maxLen);
        if (parsed != null && parsed > 0) return parsed;
      }
    } catch (_) {
      // Fallback used below.
    }
    return 2500;
  }

  List<String> _splitStoryForFlutterTts(String text, int chunkLimit) {
    final cleaned = text.replaceAll('\n', ' ').trim();
    if (cleaned.isEmpty) return const [];
    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
    final chunks = <String>[];
    var current = StringBuffer();
    for (final word in words) {
      final w = word.trim();
      final nextLen =
          current.isEmpty ? w.length : current.length + 1 + w.length;
      if (nextLen > chunkLimit && current.isNotEmpty) {
        chunks.add(current.toString());
        current = StringBuffer(w);
      } else {
        if (current.isNotEmpty) current.write(' ');
        current.write(w);
      }
    }
    if (current.isNotEmpty) chunks.add(current.toString());
    return chunks.isEmpty ? [cleaned] : chunks;
  }

  Future<void> _speakStoryWithFlutterTts(String story) async {
    _cancelSofyStoryPlayback = false;
    try {
      await _resetFlutterTtsEngineForSofy();
      await flutterTts.setLanguage(selectedLanguageCode ?? 'en-US');
      await flutterTts.setVolume(volume);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);
      if (Platform.isAndroid) {
        try {
          // Start a fresh utterance queue each time.
          await flutterTts.setQueueMode(0);
        } catch (_) {}
      }

      final cleanStory = story.replaceAll('\n', ' ').trim();
      final maxInput = await _resolveFlutterTtsMaxInputLength();
      if (mounted) {
        setState(() {
          _isStoryTtsPreparing = false;
          _isSofyStorySpeaking = true;
        });
      }

      // Prefer single utterance to avoid any chunk boundary skipping.
      if (cleanStory.length <= maxInput) {
        if (!_cancelSofyStoryPlayback) {
          await flutterTts.speak(cleanStory);
        }
      } else {
        final safeChunkLimit = maxInput > 120 ? maxInput - 20 : maxInput;
        final chunks = _splitStoryForFlutterTts(cleanStory, safeChunkLimit);
        for (final chunk in chunks) {
          if (_cancelSofyStoryPlayback || !mounted) break;
          await flutterTts.speak(chunk);
          if (_cancelSofyStoryPlayback || !mounted) break;
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSofyStorySpeaking = false;
          _isStoryTtsPreparing = false;
        });
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/app_icon');
    const settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _pdfDownloadChannelId,
        _pdfDownloadChannelName,
        description: _pdfDownloadChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    final payload = response.payload?.trim();
    if (payload == null || payload.isEmpty) return;
    await OpenFilex.open(payload);
  }

  Future<void> _showPdfDownloadedNotification(File file) async {
    const androidDetails = AndroidNotificationDetails(
      _pdfDownloadChannelId,
      _pdfDownloadChannelName,
      channelDescription: _pdfDownloadChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      id: file.path.hashCode,
      title: 'Story PDF downloaded',
      body: 'Tap to open ${file.uri.pathSegments.last}',
      notificationDetails: details,
      payload: file.path,
    );
  }

  @override
  void dispose() {
    _stopStoryQuizPoll();
    if (_storyQuizListenerAttached) {
      _storyQuizSocket.socket.off('storyQuizStatus', _onStoryQuizStatus);
      _storyQuizListenerAttached = false;
    }
    if (_storyQuizConnectHandler != null) {
      _storyQuizSocket.socket.off('connect', _storyQuizConnectHandler!);
      _storyQuizConnectHandler = null;
    }
    flutterTts.stop();
    unawaited(_inworldTts?.stop() ?? Future.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_exitToHome());
      },
      child: Scaffold(
        backgroundColor: surfaceBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => unawaited(_exitToHome()),
          ),
          title: const Text("Story Time"),
        ),
      body: Stack(
        children: [
          // Main Layout
          Column(
            children: [
              // Title Header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  gradient: _appPurpleGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: brandShadow(opacity: 0.22, blur: 16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "YOUR STORY",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    textInter(
                      text: widget.generateStoryResponse.data?.metadata?.title
                              .toString() ??
                          "",
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ),
                    // const SizedBox(height: 20),

                    // Story Image
                    // ClipRRect(
                    //   borderRadius: BorderRadius.circular(20),
                    //   child: Image.asset(
                    //     "assets/images/iv_banner.jpeg",
                    //     height: 200,
                    //     width: double.infinity,
                    //     fit: BoxFit.cover,
                    //   ),
                    // ),
                  ],
                ),
              ),

              // const SizedBox(height: 20),

              // Scrollable Story Text Only
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Story Text (Scrollable)

                        BlocConsumer<AppCubit, AppStates>(
                          listener: (context, state) {
                            // Handle Success
                            if (state.status == AppStatus.wordMeaningSuccess) {
                              // Close loading dialog if open
                              if (Navigator.canPop(context))
                                Navigator.pop(context);

                              WordMeaningResponse wordMeaningResponse = state
                                  .responseData
                                  ?.response as WordMeaningResponse;

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(
                                      "Meaning of '${wordMeaningResponse.data?.word ?? 'Word'}'",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    content: SizedBox(
                                      width: double
                                          .maxFinite, // Crucial for proper layout in dialog
                                      height: 350, // Optional: limit height
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(
                                            wordMeaningResponse
                                                    .data?.meanings?.length ??
                                                0,
                                            (index) {
                                              final meaning =
                                                  wordMeaningResponse
                                                      .data!.meanings![index];
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 16.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Part of Speech
                                                    Text(
                                                      meaning.partOfSpeech ??
                                                          "",
                                                      style: const TextStyle(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.indigo,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    // Definition
                                                    Text(
                                                      meaning.definition ?? "",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                    // Optional: Example
                                                    if (meaning.example !=
                                                            null &&
                                                        meaning.example!
                                                            .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8),
                                                        child: Text(
                                                          "Example: ${meaning.example}",
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 15,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                    const Divider(height: 24),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                              });
                            }

                            // Handle Error
                            if (state.status == AppStatus.wordMeaningError) {
                              if (Navigator.canPop(context))
                                Navigator.pop(context);

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Error"),
                                    content: Text(
                                      state.errorData?.message ??
                                          "Failed to fetch meaning.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                              });
                            }
                          },
                          builder: (context, state) {
                            if (state.status == AppStatus.wordMeaningLoading) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (ModalRoute.of(context)?.isCurrent == true) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                              });
                            }

                            return SelectableText(
                              widget.generateStoryResponse.data?.story
                                      .toString() ??
                                  "",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.start,
                              onSelectionChanged: (TextSelection selection,
                                  SelectionChangedCause? cause) {
                                if (cause == SelectionChangedCause.longPress ||
                                    cause == SelectionChangedCause.drag) {
                                  if (selection.isValid &&
                                      selection.start != selection.end) {
                                    final selectedText = widget
                                        .generateStoryResponse.data?.story
                                        .toString()
                                        .substring(
                                            selection.start, selection.end)
                                        .trim();

                                    if (selectedText.toString().isNotEmpty) {
                                      debugPrint(
                                          "Selected text: $selectedText");
                                      BlocProvider.of<AppCubit>(context)
                                          .wordMeaning(
                                              "", selectedText.toString());
                                    }
                                  }
                                }
                              },
                            );
                          },
                        ),
                        // textInter(
                        //   textAlign: TextAlign.start,
                        //   text: widget.generateStoryResponse.data?.story.toString()??"",fontSize: 15,
                        //   fontWeight: FontWeight.w400,
                        //   maxLines: 1000,
                        // ),
                        const SizedBox(height: 30),

                        _buildStoryActionsRow(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 150), // Space for bottom quiz card
            ],
          ),

          // Bottom Fixed Popup Card
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          textInter(
                            text: "Have you finished your story?",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          if (_storyQuizHint != null &&
                              _storyQuizHint!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      _storyQuizHint!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: _storyQuizYesEnabled
                                  ? _appPurpleGradient
                                  : LinearGradient(colors: [
                                      surfaceMuted,
                                      surfaceMuted
                                    ]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _storyQuizYesEnabled
                                  ? brandShadow(
                                      opacity: 0.22, blur: 14)
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _storyQuizYesEnabled
                                  ? () async {
                                      await stop();
                                      if (!mounted) return;
                                      final quizDetails = <String, dynamic>{
                                        "storyId": widget
                                            .generateStoryResponse.data?.id
                                            .toString(),
                                        "difficulty": widget
                                                .generateStoryResponse
                                                .data
                                                ?.metadata
                                                ?.learningLevel
                                                .toString() ??
                                            "",
                                        "numberOfQuestions": 5,
                                      };
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StoryQuizScreen(
                                            quizDetails: quizDetails,
                                            preloadedQuizData:
                                                _preloadedQuizFromSocket,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.quiz_rounded,
                                        color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    textInter(
                                      text: "Start Quiz",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              ),
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
      ),
    );
  }

  Future<void> downloadPdfExternal(String title, String description) async {
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      final cleanedTitle = title.trim().isEmpty ? 'story' : title.trim();
      final safeTitle = cleanedTitle
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Text(
              cleanedTitle,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              description.trim(),
              style: pw.TextStyle(
                font: ttf,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final candidateDirs = <Directory>[];

      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        candidateDirs.add(Directory('${downloadsDir.path}/Spoki AI'));
      }

      if (Platform.isAndroid) {
        candidateDirs.add(Directory('/storage/emulated/0/Download/Spoki AI'));
      }

      final appDocs = await getApplicationDocumentsDirectory();
      candidateDirs.add(Directory('${appDocs.path}/Spoki AI'));

      File? savedFile;
      for (final folder in candidateDirs) {
        try {
          if (!await folder.exists()) {
            await folder.create(recursive: true);
          }
          final file = File('${folder.path}/$safeTitle.pdf');
          await file.writeAsBytes(bytes, flush: true);
          if (await file.exists() && await file.length() > 0) {
            savedFile = file;
            break;
          }
        } catch (_) {
          // Try next writable location.
        }
      }

      if (savedFile == null) {
        if (!mounted) return;
        showToast(context: context, message: "Couldn't save PDF on this device.");
        return;
      }

      await _showPdfDownloadedNotification(savedFile);
      if (!mounted) return;
      showToast(
        context: context,
        message: "PDF saved: ${savedFile.path}",
      );
    } catch (_) {
      if (!mounted) return;
      showToast(context: context, message: "Failed to generate PDF.");
    }
  }
}
