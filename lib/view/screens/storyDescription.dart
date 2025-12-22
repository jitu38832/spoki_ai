import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spokiai/model/generatestory.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/story_quiz_screen.dart';
import '../../model/wordmeaning.dart';
import '../../viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/colors.dart';
import '../utils/custom_navigator.dart';
import '../utils/custom_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

class StorydescriptionScreen extends StatefulWidget {
  GenerateStoryResponse generateStoryResponse = GenerateStoryResponse();

  StorydescriptionScreen({super.key, required this.generateStoryResponse});

  @override
  State<StorydescriptionScreen> createState() => _StorydescriptionScreenState();
}

class _StorydescriptionScreenState extends State<StorydescriptionScreen> {
  late FlutterTts flutterTts;

  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.5;
  bool isSpeaking = false;
  Map<String, String> availableLanguages = {};
  String? selectedLanguageCode;

  @override
  void initState() {
    initTts();
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

  Future<void> speak() async {
    if (widget.generateStoryResponse.data!.story.toString().isEmpty) return;

    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.setLanguage(selectedLanguageCode ?? "en-US");

    int result = await flutterTts
        .speak(widget.generateStoryResponse.data!.story.toString());
    if (result == 1) setState(() => isSpeaking = true);
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
                          "storyId": widget.generateStoryResponse.data?.id
                              .toString(),
                          "difficulty": widget.generateStoryResponse
                              .data?.metadata?.learningLevel
                              .toString() ??
                              "",
                          "numberOfQuestions": 5
                        };
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) {
                            return StoryQuizScreen(
                                quizDetails: quizDetails);
                          },
                        ));
                      },
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
