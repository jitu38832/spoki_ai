import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:spokiai/view/screens/socket.dart'; // Adjust path if needed
import 'package:translator/translator.dart';
import '../utils/colors.dart'; // Make sure appColor is defined

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

    // Send real partner name & gender once socket connects
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        // Clean up listener after first use
        socketService.socket.off('connect', onFirstConnect);
      }

      socketService.socket.onConnect(onFirstConnect);
    });

    // Listen for incoming messages
    socketService.socket.on('message', (data) {
      print('Received from server: $data');

      if (data is! Map) return;
      final type = data['type'] as String?;
      final messageText = (data['message'] as String?)?.trim();

      if (messageText == null || messageText.isEmpty) return;
      if (!mounted) return;

      // Skip our own initialization echo
      if (type == 'user' &&
          messageText.toLowerCase().contains('botname=') &&
          messageText.toLowerCase().contains('gender=')) {
        print("↳ Skipping UI for initialization message");
        return;
      }

      String? exampleText = (data['example'] as String?)?.trim();
      if (exampleText != null && exampleText.isEmpty) exampleText = null;

      setState(() {
        if (type == 'user') {
          _messages.add(ChatMessage(text: messageText, isUser: true));
        } else if (type == 'ai') {
          // Removed skipping of generic welcome → now shows first message
          _messages.add(ChatMessage(
            text: messageText,
            isUser: false,
            hasAudio: true,
            example: exampleText,
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

  Future<void> _initializeTts() async {
    await _flutterTts.setVolume(1.0);

    final languageCode = _getLocaleFromPartnerLanguage("English");

    await _flutterTts.setLanguage(languageCode);

    await _flutterTts.setSpeechRate(0.33);
    await _flutterTts.setPitch(1.0);

    final voices = await _flutterTts.getVoices;

    if (voices.isNotEmpty) {
      final genderLower = (widget.partnerDetails["gender"] as String?)
          ?.toLowerCase()
          .trim() ??
          "male";

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
                await _flutterTts.setVoice({"name": voice["name"], "locale": locale});
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
              await _flutterTts.setVoice({"name": voice["name"], "locale": locale});
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

  List<String> _generateSuggestions() {
    String? latestExample;
    for (final msg in _messages.reversed) {
      if (!msg.isUser && msg.example != null && msg.example!.trim().isNotEmpty) {
        latestExample = msg.example!.trim();
        break;
      }
    }

    if (latestExample == null || latestExample.isEmpty) {
      return [
        "Hi, let's start learning!",
        "Can you teach me present simple tense?",
        "Please give me an example.",
        "How do I introduce myself?"
      ];
    }

    return [latestExample];
  }

  String _shortenForReply(String example) {
    final words = example.split(' ');
    if (words.length <= 8) return example;
    return words.take(8).join(' ') + '...';
  }

  void _toggleSuggestions() {
    setState(() {
      _showSuggestions = !_showSuggestions;
      _isBulbActive = _showSuggestions;
    });
  }

  Future<void> _showTranslationDialog(String englishText) async {
    if (englishText.trim().isEmpty || !mounted) return;

    final partnerLanguageName = widget.partnerDetails["language"] ?? "English";
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
      final translatedText = translation.text;

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
        if (voice is Map && (voice["locale"] as String?)?.startsWith("en") == true) {
          await _flutterTts.setVoice({
            "name": voice["name"].toString(),
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
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _generateSuggestions();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: appColor,
              backgroundImage: widget.partnerDetails["photo"] != null
                  ? (widget.partnerDetails["photo"].toString().startsWith("assets/")
                  ? AssetImage(widget.partnerDetails["photo"]) as ImageProvider
                  : FileImage(File(widget.partnerDetails["photo"])))
                  : null,
              child: widget.partnerDetails["photo"] == null
                  ? Icon(
                widget.partnerDetails["gender"]?.toString().toLowerCase() == "female"
                    ? Icons.woman
                    : Icons.man,
                color: Colors.white,
                size: 24,
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              "${widget.partnerDetails["name"] ?? ""} AI Partner",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
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
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
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
                        "Quick Replies",
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleSuggestions,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isBulbActive ? Colors.amber : Colors.grey[300],
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
                        color: _isBulbActive ? Colors.amber[900] : Colors.grey[700],
                        size: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendTextMessage(),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(width: 8),

                  if (_textController.text.trim().isEmpty)
                    GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isListening ? Colors.redAccent : appColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? Colors.redAccent : appColor).withOpacity(0.4),
                              blurRadius: _isListening ? 30 : 15,
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
                      icon: Icon(Icons.send, color: appColor),
                      onPressed: _sendTextMessage,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isThisMessageSpeaking = _currentlySpeakingText == message.text.trim();

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 80 : 0,
        right: isUser ? 0 : 80,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: appColor,
                    backgroundImage: widget.partnerDetails["photo"] != null
                        ? (widget.partnerDetails["photo"].toString().startsWith("assets/")
                        ? AssetImage(widget.partnerDetails["photo"]) as ImageProvider
                        : FileImage(File(widget.partnerDetails["photo"])))
                        : null,
                    child: widget.partnerDetails["photo"] == null
                        ? Icon(
                      widget.partnerDetails["gender"]?.toString().toLowerCase() == "female"
                          ? Icons.woman
                          : Icons.man,
                      color: Colors.white,
                      size: 24,
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  GestureDetector(
                    onTap: () {
                      if (isThisMessageSpeaking) {
                        _stopSpeaking();
                      } else {
                        _speakInEnglish(message.text);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isThisMessageSpeaking ? Colors.red[50] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isThisMessageSpeaking ? Icons.stop : Icons.volume_up,
                            size: 18,
                            color: isThisMessageSpeaking ? Colors.red : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isThisMessageSpeaking ? "Stop" : "Listen",
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: () async {
                      if (isThisMessageSpeaking) {
                        await _stopSpeaking();
                      } else {
                        await _showTranslationDialog(message.text);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isThisMessageSpeaking ? Colors.blue[50] : appColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: appColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.translate, size: 18, color: appColor),
                          const SizedBox(width: 6),
                          Text(
                            isThisMessageSpeaking ? "Stop" : "Translate",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: appColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? appColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: isUser ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
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
  final String text;
  final bool isUser;
  final bool hasAudio;
  final String? example;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.hasAudio = false,
    this.example,
  });
}