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
import '../utils/preference_manager.dart';
import '../../model/wordmeaning.dart';
import '../../viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/colors.dart';
import '../utils/custom_navigator.dart';
import '../utils/custom_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

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
  GenerateStoryResponse generateStoryResponse = GenerateStoryResponse();

  StorydescriptionScreen({super.key, required this.generateStoryResponse});

  @override
  State<StorydescriptionScreen> createState() => _StorydescriptionScreenState();
}

class _StorydescriptionScreenState extends State<StorydescriptionScreen> {
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
  Map<String, String> availableLanguages = {};
  String? selectedLanguageCode;

  @override
  void initState() {
    initTts();
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _startStoryQuizStatusFlow());
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

    _lastEmittedRequestId =
        DateTime.now().microsecondsSinceEpoch.toString();
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
          _storyQuizHint = quizMap == null
              ? 'Quiz is ready. Open to load questions.'
              : null;
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
          _storyQuizHint =
              d['error']?.toString() ?? 'Quiz generation failed.';
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

  bool get _storyQuizYesEnabled =>
      _storyQuizPhase == _StoryQuizGenPhase.ready;
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

    // Callbacks
    flutterTts.setStartHandler(() {});
    flutterTts.setCompletionHandler(() {});
    flutterTts.setCancelHandler(() {});
    flutterTts.setErrorHandler((msg) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $msg")));
    });

    // Load languages safely without duplicates
    await loadLanguages();

    setState(() {});
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

  Future<void> speak() async {
    final story = widget.generateStoryResponse.data?.story.toString() ?? '';
    if (story.isEmpty || !mounted) return;
    final cubit = context.read<InworldTtsCubit>();
    if (!cubit.state.audioEnabled) return;
    await cubit.speak(story, playbackId: 'story');
  }

  Future<void> stop() async {
    await context.read<InworldTtsCubit>().stop();
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
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Story Time",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Main Layout
          Column(
            children: [
              // Top Blue Header (Fixed)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  // color: Color(0xFFE3F2FD),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  children: [
                    // Title
                    textInter(
                      text: widget.generateStoryResponse.data?.metadata?.title.toString()??"",
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6A1B9A),
                      textAlign: TextAlign.center,
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
                              if (Navigator.canPop(context)) Navigator.pop(context);

                              WordMeaningResponse wordMeaningResponse =
                              state.responseData?.response as WordMeaningResponse;

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(
                                      "Meaning of '${wordMeaningResponse.data?.word ?? 'Word'}'",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    content: SizedBox(
                                      width: double.maxFinite, // Crucial for proper layout in dialog
                                      height: 350, // Optional: limit height
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(
                                            wordMeaningResponse.data?.meanings?.length ?? 0,
                                                (index) {
                                              final meaning = wordMeaningResponse.data!.meanings![index];
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 16.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Part of Speech
                                                    Text(
                                                      meaning.partOfSpeech ?? "",
                                                      style: const TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.bold,
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
                                                    if (meaning.example != null && meaning.example!.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 8),
                                                        child: Text(
                                                          "Example: ${meaning.example}",
                                                          style: const TextStyle(
                                                            fontSize: 15,
                                                            fontStyle: FontStyle.italic,
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
                              if (Navigator.canPop(context)) Navigator.pop(context);

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Error"),
                                    content: Text(
                                      state.errorData?.message ?? "Failed to fetch meaning.",
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
                              widget.generateStoryResponse.data?.story.toString() ?? "",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.start,
                              onSelectionChanged: (TextSelection selection, SelectionChangedCause? cause) {
                                if (cause == SelectionChangedCause.longPress ||
                                    cause == SelectionChangedCause.drag) {
                                  if (selection.isValid && selection.start != selection.end) {
                                    final selectedText = widget.generateStoryResponse.data?.story
                                        .toString()
                                        .substring(selection.start, selection.end)
                                        .trim();

                                    if (selectedText.toString().isNotEmpty) {
                                      debugPrint("Selected text: $selectedText");
                                      BlocProvider.of<AppCubit>(context)
                                          .wordMeaning("", selectedText.toString());
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

                        // Word Count + Icons (Still visible while scrolling)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: textInter(
                                text: "Words: ${widget.generateStoryResponse.data?.metadata?.wordCount.toString()??""}",
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            Row(
                              children: [
                                BlocBuilder<InworldTtsCubit, InworldTtsState>(
                                  buildWhen: (a, b) =>
                                      a.status != b.status ||
                                      a.playbackId != b.playbackId ||
                                      a.audioEnabled != b.audioEnabled,
                                  builder: (context, tts) {
                                    if (!tts.audioEnabled) {
                                      return const SizedBox.shrink();
                                    }
                                    final storyActive = tts.playbackId == 'story' &&
                                        (tts.status == InworldTtsStatus.loading ||
                                            tts.status == InworldTtsStatus.playing);
                                    return IconButton(
                                      icon: Icon(
                                        storyActive
                                            ? Icons.stop
                                            : Icons.volume_up_outlined,
                                      ),
                                      onPressed: () {
                                        if (storyActive) {
                                          stop();
                                        } else {
                                          speak();
                                        }
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                    icon:
                                    const Icon(Icons.download_outlined),
                                    onPressed: () {
                                      final String title =
                                          widget.generateStoryResponse
                                              .data?.metadata?.title
                                              .toString() ??
                                              "";
                                      final String description =
                                          widget.generateStoryResponse
                                              .data?.story
                                              .toString() ??
                                              "";

                                      downloadPdfExternal(title, description);

                                    }),
                                IconButton(
                                    icon: const Icon(Icons.share_outlined),
                                    onPressed: () {
                                      final String title =
                                          widget.generateStoryResponse
                                              .data?.metadata?.title
                                              .toString() ??
                                              "";
                                      final String description =
                                          widget.generateStoryResponse
                                              .data?.story
                                              .toString() ??
                                              "";

                                      Share.share(
                                        "$title\n\n$description",
                                        subject: title, // optional
                                      );
                                    }),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100), // Space for bottom floating card
            ],
          ),

          // Bottom Fixed Popup Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
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
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _storyQuizYesEnabled ? appColor : Colors.grey.shade400,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _storyQuizYesEnabled ? 3 : 0,
                      ),
                      onPressed: _storyQuizYesEnabled
                          ? () {
                              final quizDetails = <String, dynamic>{
                                "storyId": widget
                                    .generateStoryResponse.data?.id
                                    .toString(),
                                "difficulty": widget.generateStoryResponse
                                        .data?.metadata?.learningLevel
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
                      child: textInter(
                        text: "Yes",
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> downloadPdfExternal(String title, String description) async {
    final fontData =
    await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final safeTitle = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .trim()
        .replaceAll(' ', '_');

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),

          // ✅ DESCRIPTION WILL NOW SHOW
          pw.Text(
            description,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

    final downloadsDir = await getExternalStorageDirectory();
    if (downloadsDir == null) return;

    final externalPath =
        downloadsDir.path.split('Android')[0] + 'Download';

    final folder = Directory('$externalPath/Spoki AI');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final file = File('${folder.path}/$safeTitle.pdf');
    await file.writeAsBytes(await pdf.save());

    print('Saved to: ${file.path}');
    showToast(context: context, message: "Pdf Saved.");
  }

}
