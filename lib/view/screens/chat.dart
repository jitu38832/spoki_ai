import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/socket.dart'; // Adjust path if needed
import 'package:spokiai/view/screens/voice_settings.dart';
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

class _ChatScreenState extends State<ChatScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ScrollController _scrollController = ScrollController();
  late FlutterTts _flutterTts;

  bool _isListening = false;
  bool _speechInitialized = false;
  bool _isFirstAiMessageReceived = false;
  bool _isSpeaking = false;
  final TextEditingController _textController = TextEditingController();

  String _accumulatedTranscription = '';
  final GoogleTranslator _translator = GoogleTranslator();
  String? _currentlySpeakingText;

  List<ChatMessage> _messages = [];

  late SocketService socketService;
  String _previousRecognized = '';

  bool _showSuggestions = false;
  bool _isBulbActive = false;
  String? _lastAiMessage;

  /// User message ids with AI feedback panel expanded below the bubble.
  final Set<String> _expandedAiFeedbackIds = {};

  // For 25-second continuous listening
  Timer? _countdownTimer;
  int _remainingSeconds = 25;
  Timer? _restartTimer;
  bool _shouldKeepListening = true;

  String _getLocaleFromPartnerLanguage(String partnerLang) {
    String lower = partnerLang.toLowerCase().trim();
    switch (lower) {
      case "chinese": return "zh-CN";
      case "arabic": return "ar-SA";
      case "french": return "fr-FR";
      case "german": return "de-DE";
      case "indonesian": return "id-ID";
      case "italian": return "it-IT";
      case "japanese": return "ja-JP";
      case "korean": return "ko-KR";
      case "russian": return "ru-RU";
      case "spanish": return "es-ES";
      case "thai": return "th-TH";
      case "turkish": return "tr-TR";
      case "vietnamese": return "vi-VN";
      case "persian": return "fa-IR";
      case "hindi": return "hi-IN";
      case "telugu": return "te-IN";
      case "tamil": return "ta-IN";
      case "malayalam": return "ml-IN";
      case "kannada": return "kn-IN";
      case "bengali": return "bn-IN";
      case "english":
      case "international":
      default: return "en-US";
    }
  }

  @override
  void initState() {
    super.initState();

    print("partnerDetails: ${widget.partnerDetails}");

    socketService = SocketService();
    socketService.initSocket();

    _flutterTts = FlutterTts();
    _initializeTts();
    _initializeSpeech();
    _textController.addListener(_onInputTextChanged);

    // New chat session (incl. new partner after leaving chat): always handshake again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      socketService.resetInitialFlag();

      // Already connected → send immediately
      if (socketService.isConnected) {
        socketService.sendInitialGreetingWithPartnerDetails(widget.partnerDetails);
        return;
      }

      // Not connected yet → wait for first connect event
      void onFirstConnect(_) {
        if (mounted) {
          socketService.sendInitialGreetingWithPartnerDetails(widget.partnerDetails);
        }
        socketService.socket.off('connect', onFirstConnect);
      }

      socketService.socket.onConnect(onFirstConnect);
    });

    // Listen for incoming messages
    socketService.socket.on('message', (data) {
      print('Received from server: $data');

      if (data is! Map) return;
      final type = _coerceTrimmedString(data['type']);
      final messageText = _coerceTrimmedString(data['message']);

      if (messageText == null) return;
      if (!mounted) return;

      // Skip our own initialization echo
      if (type == 'user' &&
          messageText.toLowerCase().contains('botname=') &&
          messageText.toLowerCase().contains('gender=')) {
        print("↳ Skipping UI for initialization message");
        return;
      }

      final exampleText = _coerceTrimmedString(data['example']);

      setState(() {
        if (type == 'user') {
          _messages.add(ChatMessage(
            text: messageText,
            isUser: true,
            id: _newChatMessageId(),
          ));
        } else if (type == 'ai') {
          // Removed skipping of generic welcome → now shows first message
          _messages.add(ChatMessage(
            text: messageText,
            isUser: false,
            hasAudio: true,
            example: exampleText,
            id: _newChatMessageId(),
          ));
          _lastAiMessage = messageText;

          if (!_isFirstAiMessageReceived) {
            _isFirstAiMessageReceived = true;
            Future.microtask(() {
              if (mounted) _speak(messageText);
            });
          } else {
            _speak(messageText);
          }
        }
      });

      _scrollToBottom();
    });
  }

  void _onInputTextChanged() {
    if (mounted) setState(() {});
  }

  String _newChatMessageId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(1 << 20)}';

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
                print("Selected friendly/natural voice: ${voice["name"]} ($locale)");
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
        print(" - ${v['name']} | ${v['locale']} | gender?: ${v['gender'] ?? 'unknown'}");
      }
      print("===========================\n");
    } else {
      print("No TTS voices available on this device");
    }

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingText = null;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingText = null;
        });
      }
    });
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      debugLogging: true,
      onStatus: (status) {
        print('Speech status: $status');
        if (_isListening && (status == 'notListening' || status == 'done')) {
          _tryRestartListening();
        }
      },
      onError: (error) {
        print('Speech error: ${error.errorMsg}');
        if (_isListening && !error.permanent) {
          _tryRestartListening();
        }
      },
    );
    if (mounted) setState(() => _speechInitialized = available);
  }

  void _tryRestartListening() {
    if (!_shouldKeepListening || !_isListening) return;

    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _isListening) {
        print("→ Auto-restarting speech recognition after pause");
        _startContinuousListen();
      }
    });
  }

  void _startContinuousListen() {
    _speech.listen(
      onResult: (result) {
        if (!mounted) return;

        final current = result.recognizedWords.trim();

        // Only append if there's actually new content
        if (current.isNotEmpty && current.length > _previousRecognized.length) {
          final newPart = current.substring(_previousRecognized.length).trim();

          if (newPart.isNotEmpty) {
            setState(() {
              if (_accumulatedTranscription.isNotEmpty &&
                  !_accumulatedTranscription.endsWith(' ')) {
                _accumulatedTranscription += ' ';
              }
              _accumulatedTranscription += newPart;
            });
          }
        }

        // Update previous for next partial result
        _previousRecognized = current;

        // If final result → reset for next segment
        if (result.finalResult) {
          _previousRecognized = '';
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      localeId: "en_US",
      cancelOnError: false,
    );
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListeningAndSend();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    if (!_speechInitialized) return;

    setState(() {
      _isListening = true;
      _accumulatedTranscription = '';
      _previousRecognized = '';   // ← important: reset
      _remainingSeconds = 25;
    });
    _shouldKeepListening = true;
    _startContinuousListen();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _stopListeningAndSend();
        }
      });
    });
  }

  void _stopListeningAndSend() {
    _shouldKeepListening = false;
    _restartTimer?.cancel();
    _countdownTimer?.cancel();
    _speech.stop();

    final finalText = _accumulatedTranscription.trim();
    if (finalText.isNotEmpty) {
      socketService.sendMessage(finalText);
      print("Sent accumulated message: $finalText");
    }

    setState(() {
      _isListening = false;
      _accumulatedTranscription = '';
      _remainingSeconds = 25;
    });
  }

  /// Single quick reply from latest AI `example` (backend controls length); local default if none.
  List<String> _generateSuggestions() {
    String? latestExample;
    for (final msg in _messages.reversed) {
      if (!msg.isUser && msg.example != null && msg.example!.trim().isNotEmpty) {
        latestExample = msg.example!.trim();
        break;
      }
    }

    if (latestExample == null || latestExample.isEmpty) {
      return ["Hi, let's start learning!"];
    }

    return [latestExample];
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
      final translation = await _translator.translate(englishText.trim(), to: targetCode.split('-').first);
      final rawTranslated = translation.text;
      final translatedText = _coerceTrimmedString(rawTranslated) ?? englishText.trim();

      if (!mounted) return;
      Navigator.pop(context);

      _showSimpleTranslationDialog(partnerLanguageName, translatedText, original: englishText);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Translation failed. Check internet connection.")),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.translate, color: appColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Translated to $languageName",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Translation:", style: TextStyle(fontWeight: FontWeight.w600)),
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
                        _currentlySpeakingText = null;
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
                          _currentlySpeakingText = null;
                        });
                      }
                    } else {
                      await _flutterTts.stop();
                      final targetCode = _getLocaleFromPartnerLanguage(languageName);
                      await _flutterTts.setLanguage(targetCode);

                      if (mounted) {
                        setState(() {
                          _isSpeaking = true;
                          _currentlySpeakingText = translatedText;
                        });
                      }

                      setDialogState(() => isSpeakingFromDialog = true);
                      await _flutterTts.speak(translatedText);

                      _flutterTts.setCompletionHandler(() {
                        if (mounted) {
                          setState(() {
                            _isSpeaking = false;
                            _currentlySpeakingText = null;
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
            _currentlySpeakingText = null;
          });
        }
      }
    });
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty || !mounted) return;

    // Clean the text before speaking
    final cleanText = _cleanTextForSpeech(text);

    if (cleanText.isEmpty) {
      print("No speakable text after cleaning: $text");
      return;
    }

    print("Speaking cleaned text: $cleanText");

    await _flutterTts.stop();
    setState(() {
      _isSpeaking = true;
      _currentlySpeakingText = cleanText; // show cleaned version in UI if needed
    });

    await _flutterTts.speak(cleanText);
  }
  Future<void> _speakInEnglish(String text) async {
    if (text.trim().isEmpty || !mounted) return;

    await _flutterTts.stop();

    setState(() {
      _isSpeaking = true;
      _currentlySpeakingText = text.trim();
    });

    await _flutterTts.setLanguage("en-US");

    final voices = await _flutterTts.getVoices;
    if (voices.isNotEmpty) {
      for (var voice in voices) {
        if (voice is Map &&
            voice["locale"] != null &&
            voice["locale"].toString().startsWith("en")) {
          await _flutterTts.setVoice({
            "name": (voice["name"] ?? "").toString(),
            "locale": voice["locale"].toString(),
          });
          break;
        }
      }
    }

    await _flutterTts.speak(text.trim());
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _currentlySpeakingText = null;
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

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    socketService.sendMessage(text);
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
    _restartTimer?.cancel();
    _countdownTimer?.cancel();
    socketService.socket.off('message');
    _flutterTts.stop();
    _speech.stop();
    _textController.removeListener(_onInputTextChanged);
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
                      widget.partnerDetails["gender"]?.toString().toLowerCase() ==
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
            icon: const Icon(Icons.settings_outlined, size: 28),
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
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return KeyedSubtree(
                  key: ValueKey(msg.id),
                  child: _buildMessageBubble(msg),
                );
              },
            ),
          ),

          if (_isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: appColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: appColor.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, color: appColor, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        "Listening...",
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: appColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _accumulatedTranscription.isEmpty ? "Speak now..." : _accumulatedTranscription,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Time left: $_remainingSeconds sec",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: _remainingSeconds <= 5 ? Colors.red : appColor,
                      fontWeight: FontWeight.bold,
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
                      Icon(Icons.lightbulb, color: Colors.amber[800], size: 20),
                      const SizedBox(width: 6),
                      Text(
                        "Quick reply",
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleSuggestions,
                        child: Icon(Icons.close, size: 18, color: Colors.grey[700]),
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
                          _sendTextMessage();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        color: _isBulbActive ? const Color(0xFFFFD54F) : const Color(0xFFFFF3CD),
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
                        color: _isBulbActive ? Colors.amber[900] : Colors.amber[700],
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),

                  const SizedBox(width: 6),

                  if (_textController.text.trim().isEmpty)
                    GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isListening ? Colors.redAccent : const Color(0xFF3BA4E8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? Colors.redAccent : const Color(0xFF3BA4E8)).withOpacity(0.35),
                              blurRadius: _isListening ? 26 : 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF3BA4E8)),
                      onPressed: _sendTextMessage,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _toggleAiFeedbackForMessage(String messageId) {
    setState(() {
      if (_expandedAiFeedbackIds.contains(messageId)) {
        _expandedAiFeedbackIds.remove(messageId);
      } else {
        _expandedAiFeedbackIds.add(messageId);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isThisMessageSpeaking = _currentlySpeakingText == message.text.trim();
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
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser)
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
              if (!isUser) const SizedBox(width: 8),
              _smallActionChip(
                label: isThisMessageSpeaking ? "Stop" : "Listen",
                icon: isThisMessageSpeaking ? Icons.stop : Icons.volume_up,
                onTap: () {
                  if (isThisMessageSpeaking) {
                    _stopSpeaking();
                  } else {
                    _speakInEnglish(message.text);
                  }
                },
              ),
              if (isUser) const SizedBox(width: 8),
              if (isUser)
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.person, color: Color(0xFF3BA4E8), size: 18),
                ),
            ],
          ),
          const SizedBox(height: 6),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isUser ? 10 : 14,
              vertical: isUser ? 10 : 12,
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  textAlign: isUser ? TextAlign.center : TextAlign.start,
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
                ] else ...[
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleAiFeedbackForMessage(message.id),
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
                ]
              ],
            ),
          ),
          if (showAiFeedbackPanel)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildAiFeedbackCardsStack(
                partnerPhoto: partnerPhoto,
              ),
            ),
        ],
      ),
    );
  }

  // --- AI feedback expansion (dark cards, mock content matching product mockup) ---
  static const Color _fbCardBg = Color(0xFF2C2C2E);
  static const Color _fbRowBg = Color(0xFF3A3A3C);
  static const Color _fbPurple = Color(0xFF7B61FF);
  static const Color _fbGrammarGreen = Color(0xFF1B5E20);
  static const Color _fbGrammarGreenText = Color(0xFF69F0AE);

  Widget _buildAiFeedbackCardsStack({required String? partnerPhoto}) {
    final maxW = MediaQuery.of(context).size.width * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGrammarFeedbackCard(),
          const SizedBox(height: 12),
          _buildPronunciationFeedbackCard(partnerPhoto),
          const SizedBox(height: 12),
          _buildVocabularyFeedbackCard(),
        ],
      ),
    );
  }

  Widget _buildFeedbackCategoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _fbPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGrammarFeedbackCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _fbCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedbackCategoryChip('Grammar'),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF43A047),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _fbRowBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              height: 1.45,
                              color: Colors.white,
                            ),
                            children: const [
                              TextSpan(text: 'I enjoy '),
                              TextSpan(
                                text: 'watch',
                                style: TextStyle(
                                  color: Color(0xFFEF5350),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' many '),
                              TextSpan(
                                text: 'movie',
                                style: TextStyle(
                                  color: Color(0xFFEF5350),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                  text: ' of different language and '),
                              TextSpan(
                                text: 'it culture',
                                style: TextStyle(
                                  color: Color(0xFFEF5350),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: '. It '),
                              TextSpan(
                                text: 'make',
                                style: TextStyle(
                                  color: Color(0xFFEF5350),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' me '),
                              TextSpan(
                                text: 'know world',
                                style: TextStyle(
                                  color: Color(0xFFEF5350),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' more '),
                              TextSpan(
                                text: 'better',
                                style: TextStyle(
                                  color: Color(0xFFEF5350),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: '!'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _fbGrammarGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              height: 1.45,
                              color: Colors.white,
                            ),
                            children: const [
                              TextSpan(text: 'I enjoy '),
                              TextSpan(
                                text: 'watching',
                                style: TextStyle(
                                  color: _fbGrammarGreenText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' many '),
                              TextSpan(
                                text: 'movies in',
                                style: TextStyle(
                                  color: _fbGrammarGreenText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                  text:
                                      ' different languages and '),
                              TextSpan(
                                text: 'learning about their cultures',
                                style: TextStyle(
                                  color: _fbGrammarGreenText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: '. It '),
                              TextSpan(
                                text: 'helps me understand',
                                style: TextStyle(
                                  color: _fbGrammarGreenText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' the world '),
                              TextSpan(
                                text: 'better',
                                style: TextStyle(
                                  color: _fbGrammarGreenText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: '!'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPronunciationFeedbackCard(String? partnerPhoto) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _fbCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedbackCategoryChip('Pronunciation'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'understand',
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'uhn-duh-stand',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '20%',
                      style: GoogleFonts.roboto(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF5350),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Needs practice',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF5350),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _fbRowBg,
                    backgroundImage: partnerPhoto != null
                        ? (partnerPhoto.startsWith('assets/')
                            ? AssetImage(partnerPhoto) as ImageProvider
                            : FileImage(File(partnerPhoto)))
                        : null,
                    child: partnerPhoto == null
                        ? Icon(
                            widget.partnerDetails['gender']
                                        ?.toString()
                                        .toLowerCase() ==
                                    'female'
                                ? Icons.woman
                                : Icons.man,
                            color: Colors.white54,
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: _fbRowBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.graphic_eq,
                      color: const Color(0xFF69F0AE),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Practice',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyFeedbackCard() {
    Widget row(String from, String to, {bool isLast = false}) {
      return Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _fbRowBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                from,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, color: Colors.white54, size: 18),
            ),
            Expanded(
              flex: 2,
              child: Text(
                to,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: _fbGrammarGreenText,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            Icon(Icons.bookmark_border, color: Colors.white70, size: 20),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _fbCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedbackCategoryChip('Vocabulary'),
          const SizedBox(height: 14),
          row('Watching a lot of movies', 'Exploring movies'),
          row('Multiple languages', 'Diverse languages', isLast: true),
        ],
      ),
    );
  }

  Widget _smallActionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Add this helper method in _ChatScreenState class
  String _cleanTextForSpeech(String text) {
    // 1. Remove emojis (split into multiple safe character classes)
    String cleaned = text.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]'     // Miscellaneous Symbols and Pictographs
        r'|[\u{2600}-\u{26FF}]'      // Miscellaneous Symbols
        r'|[\u{2700}-\u{27BF}]'      // Dingbats
        r'|[\u{FE00}-\u{FE0F}]'      // Variation Selectors
        r'|[\u{1F1E6}-\u{1F1FF}]',   // Regional Indicator Symbols (flags)
        unicode: true,
      ),
      '',
    );

    // 2. Remove punctuation and special characters that TTS often reads aloud
    cleaned = cleaned.replaceAll(
      RegExp(r'[!,?.:;()\[\]{}"@#$%^&*+=~`<>]'),
      '',
    );

        // 3. Collapse multiple whitespace (spaces, newlines, tabs) → single space
        cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Optional: skip very short or empty results
    if (cleaned.length < 5) return '';

    return cleaned;
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool hasAudio;
  final String? example;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.hasAudio = false,
    this.example,
    String? id,
  }) : id = id ??
            '${DateTime.now().microsecondsSinceEpoch}_${text.hashCode}';
}