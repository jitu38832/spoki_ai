import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spokiai/model/historydescription.dart';
import 'package:spokiai/model/wordmeaning.dart';
import 'package:spokiai/view/screens/story_quiz_history.dart';
import 'package:spokiai/view/screens/story_quiz_screen.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';

import '../../viewmodel/cubit/appcubit.dart';
import '../utils/colors.dart';
import '../utils/custom_widgets.dart';
import '../utils/preference_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

class HistoryDescription extends StatefulWidget {
  String id = "";

  HistoryDescription({super.key, required this.id});

  @override
  State<HistoryDescription> createState() => _HistoryDescriptionState();
}

class _HistoryDescriptionState extends State<HistoryDescription> {
  String token = "";
  HistoryDescriptionResponse historyDescriptionResponse =
      HistoryDescriptionResponse();
  late FlutterTts flutterTts;
  WordMeaningResponse wordMeaningResponse= WordMeaningResponse();

  double volume = 1.0;
  double pitch = 0.96;
  double rate = 0.29;
  bool isSpeaking = false;
  Map<String, String> availableLanguages = {};
  String? selectedLanguageCode;

  @override
  void initState() {
    token = PreferenceManager.getStringValue(key: "token") ?? "";

    BlocProvider.of<AppCubit>(context).historyDescription(token, widget.id);

    initTts().then((_) {
      _trySetBestVoice();   // ← add this
    });
    super.initState();
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

    // Callbacks
    flutterTts.setStartHandler(() => setState(() => isSpeaking = true));
    flutterTts.setCompletionHandler(() => setState(() => isSpeaking = false));
    flutterTts.setCancelHandler(() => setState(() => isSpeaking = false));
    flutterTts.setErrorHandler((msg) {
      setState(() => isSpeaking = false);
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
  Future<void> _trySetBestVoice() async {
    try {
      final voices = await flutterTts.getVoices;

      // Debug: see what voices you actually have
      print("Available voices: $voices");

      // Try to find a nice modern English voice
      // Some good candidates (names vary by device/Android version/region/language pack):
      // "en-us-x-tpd-network", "en-us-x-sfg#male_1-local", etc.
      // "en-gb-x-gbb-network" (British is often perceived as more premium)

      for (var voice in voices) {
        final name = voice["name"]?.toString().toLowerCase() ?? "";
        final locale = voice["locale"]?.toString() ?? "";

        // Prefer network/high quality voices
        if (locale.startsWith("en") &&
            (name.contains("network") || name.contains("wavenet") || name.contains("neural"))) {
          await flutterTts.setVoice({"name": voice["name"], "locale": locale});
          print("Selected better voice: $name ($locale)");
          return;
        }
      }

      // Fallback: at least try to set any en-US / en-GB voice explicitly
      await flutterTts.setVoice({"name": "en-us-x-tpd-local", "locale": "en-US"});
      // or British variant (many people find British voices more "AI-like"):
      // await flutterTts.setVoice({"name": "en-gb-x-gbb-network", "locale": "en-GB"});

    } catch (e) {
      print("Couldn't set custom voice: $e");
    }
  }

  Future<void> speak() async {
    if (historyDescriptionResponse.data!.story.toString().isEmpty) return;

    // Apply settings every time before speaking (safe & recommended)
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);   // ← most important for your request
    await flutterTts.setPitch(pitch);
    await flutterTts.setLanguage(selectedLanguageCode ?? "en-US");

    // Optional but sometimes helps stability on Android
    // await flutterTts.awaitSpeakCompletion(true); // waits until speaking is done

    int result = await flutterTts.speak(historyDescriptionResponse.data!.story.toString());

    if (result == 1) {
      setState(() => isSpeaking = true);
    }
  }

  Future<void> stop() async {
    int result = await flutterTts.stop();
    if (result == 1) setState(() => isSpeaking = false);
  }

  @override
  void dispose() {
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
          "Story Description",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<AppCubit, AppStates>(
        listener: (context, state) {
          if (state.status == AppStatus.historyDescriptionSuccess) {
            historyDescriptionResponse =
                state.responseData?.response as HistoryDescriptionResponse;
          }

          if (state.status == AppStatus.historyDescriptionError) {
            showToast(
                context: context,
                message: state.errorData?.message.toString() ?? "");
          }
        },
        builder: (context, state) {
          if (state.status == AppStatus.historyDescriptionLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: appColor,
              ),
            );
          }
          return Stack(
            children: [
              Column(
                children: [
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
                          text: historyDescriptionResponse.data?.metadata?.title
                                  .toString() ??
                              "",
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: appColor,
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
                                  historyDescriptionResponse.data?.story.toString() ?? "",
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
                                        final selectedText = historyDescriptionResponse.data?.story
                                            .toString()
                                            .substring(selection.start, selection.end)
                                            .trim();

                                        if (selectedText.toString().isNotEmpty) {
                                          debugPrint("Selected text: $selectedText");
                                          BlocProvider.of<AppCubit>(context)
                                              .wordMeaning(token, selectedText.toString());
                                        }
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                            // textInter(
                            //   text: historyDescriptionResponse.data?.story
                            //           .toString() ??
                            //       "",
                            //   fontSize: 15,
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
                                    text:
                                        "Words: ${historyDescriptionResponse.data?.metadata?.wordCount.toString() ?? ""}",
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(!isSpeaking
                                          ? Icons.volume_up_outlined
                                          : Icons.stop),
                                      onPressed: () {
                                        if (isSpeaking) {
                                          stop(); // call stop
                                        } else {
                                          speak(); // call speak
                                        }
                                      },
                                    ),
                                    IconButton(
                                        icon:
                                            const Icon(Icons.download_outlined),
                                        onPressed: () {
                                          final String title =
                                              historyDescriptionResponse
                                                      .data?.metadata?.title
                                                      .toString() ??
                                                  "";
                                          final String description =
                                              historyDescriptionResponse
                                                      .data?.story
                                                      .toString() ??
                                                  "";

                                          downloadPdfExternal(
                                              title, description);
                                        }),
                                    IconButton(
                                        icon: const Icon(Icons.share_outlined),
                                        onPressed: () {
                                          final String title =
                                              historyDescriptionResponse
                                                      .data?.metadata?.title
                                                      .toString() ??
                                                  "";
                                          final String description =
                                              historyDescriptionResponse
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          onPressed: () {
                            Map<String, dynamic> quizDetails = {
                              "storyId": historyDescriptionResponse.data?.id
                                  .toString(),
                              "difficulty": historyDescriptionResponse
                                      .data?.metadata?.learningLevel
                                      .toString() ??
                                  "",
                              "numberOfQuestions": 5
                            };
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return QuizHistoryScreen(
                                    id: historyDescriptionResponse.data?.id.toString()??"");
                              },
                            ));
                          },
                          child: textInter(
                            text: "Review your answers",
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
          );
        },
      ),
    );
  }

  Future<void> downloadPdfExternal(String title, String description) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
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

    final externalPath = downloadsDir.path.split('Android')[0] + 'Download';

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
