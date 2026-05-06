import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:spokiai/view/screens/socket.dart';
import 'package:translator/translator.dart';
import '../utils/colors.dart';

class ChatWithVoiceChangeScreen extends StatefulWidget {
  final Map<String, dynamic> partnerDetails;

  const ChatWithVoiceChangeScreen({super.key, required this.partnerDetails});

  @override
  State<ChatWithVoiceChangeScreen> createState() => _ChatWithVoiceChangeScreenState();
}

class _ChatWithVoiceChangeScreenState extends State<ChatWithVoiceChangeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ScrollController _scrollController = ScrollController();
  late FlutterTts _flutterTts;

  bool _isListening = false;
  bool _speechInitialized = false;
  bool _isFirstAiMessageReceived = false;
  bool _isSpeaking = false;
  final TextEditingController _textController = TextEditingController();
  final String _initMessage = "hi,botname=jarvis,gender=male";

  String _currentTranscription = '';
  final GoogleTranslator _translator = GoogleTranslator();
  String? _currentlySpeakingText;

  List<ChatMessage> _messages = [];

  late SocketService socketService;


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

  @override
  void initState() {
    super.initState();

    print("partnerDetails: ${widget.partnerDetails}");

    socketService = SocketService();
    socketService.initSocket(); // ← now automatically handles connection + greeting

    _flutterTts = FlutterTts();
    _initializeTts();
    _initializeSpeech();

    // Only keep the message listener + skip logic
    socketService.socket.on('message', (data) {
      print('Received from server: $data');

      if (data is! Map) return;
      String? type = data['type'];
      String? messageText = data['message']?.toString().trim();

      if (messageText == null || messageText.isEmpty) return;
      if (!mounted) return;

      // Skip showing our own initial message if echoed back
      if (type == 'user' &&
          !_isFirstAiMessageReceived &&
          messageText.toLowerCase().contains('botname=jarvis') &&
          messageText.toLowerCase().contains('gender=male')) {
        print("↳ Skipping UI for initialization message");
        _isFirstAiMessageReceived = true;
        return;
      }

      setState(() {
        if (type == 'user') {
          _messages.add(ChatMessage(text: messageText, isUser: true));
        } else if (type == 'ai') {
          _messages.add(ChatMessage(
            text: messageText,
            isUser: false,
            hasAudio: true,
          ));
          _speak(messageText);
        }
      });

      _scrollToBottom();
    });
  }

  Future<void> _showTranslationDialog(String englishText) async {
    if (englishText.trim().isEmpty || !mounted) return;

    String partnerLanguageName = widget.partnerDetails["language"] ?? "English";
    String targetCode = _getLocaleFromPartnerLanguage(partnerLanguageName);

    // If it's already English, just show original
    if (targetCode == "en-US") {
      _showSimpleTranslationDialog(partnerLanguageName, englishText);
      return;
    }

    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final translation = await _translator.translate(englishText.trim(), to: targetCode.split('-').first);
      String translatedText = translation.text;

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      _showSimpleTranslationDialog(partnerLanguageName, translatedText, original: englishText);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
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
    // Track if we're speaking from this dialog
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
                    const Text(
                      "Translation:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                    // Stop speaking if playing from dialog
                    if (isSpeakingFromDialog) {
                      _flutterTts.stop();
                      // Restore global speaking state
                      if (mounted) {
                        setState(() {
                          _isSpeaking = false;
                          _currentlySpeakingText = null;
                        });
                      }
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Close"),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (isSpeakingFromDialog) {
                      // Stop speaking
                      await _flutterTts.stop();
                      setDialogState(() {
                        isSpeakingFromDialog = false;
                      });
                      if (mounted) {
                        setState(() {
                          _isSpeaking = false;
                          _currentlySpeakingText = null;
                        });
                      }
                    } else {
                      // Start speaking
                      await _flutterTts.stop(); // Stop any previous speech
                      String targetCode = _getLocaleFromPartnerLanguage(languageName);

                      await _flutterTts.setLanguage(targetCode);

                      // Update global state so other "Stop" buttons reflect correctly
                      if (mounted) {
                        setState(() {
                          _isSpeaking = true;
                          _currentlySpeakingText = translatedText; // Important!
                        });
                      }

                      setDialogState(() {
                        isSpeakingFromDialog = true;
                      });

                      await _flutterTts.speak(translatedText);

                      // When speech ends naturally
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
      // This runs when dialog is dismissed (by Close or back button)
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
  Future<void> _initializeTts() async {
    await _flutterTts.setVolume(1.0);

    String partnerLanguage = "English";
    String languageCode = _getLocaleFromPartnerLanguage(partnerLanguage);

    await _flutterTts.setLanguage(languageCode);
    print("TTS Language set to: $languageCode ($partnerLanguage)");

    // Pitch & Rate based on gender/age (keep your existing logic)
    double pitch = 1.0;
    double rate = 0.5;
    await _flutterTts.setPitch(pitch);
    await _flutterTts.setSpeechRate(rate);

    // Try to select best voice for partner's language
    List<dynamic> voices = await _flutterTts.getVoices;
    if (voices.isNotEmpty) {
      for (var voice in voices) {
        if (voice is Map && voice["locale"] != null) {
          String locale = voice["locale"].toString();
          if (locale.startsWith(languageCode.split('-').first)) {
            await _flutterTts.setVoice({
              "name": voice["name"].toString(),
              "locale": locale,
            });
            print("Selected voice: ${voice["name"]}");
            break;
          }
        }
      }
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

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty || !mounted) return;
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = true;
      _currentlySpeakingText = text.trim();
    });
    await _flutterTts.speak(text);
  }

  Future<void> _speakInEnglish(String text) async {
    if (text.trim().isEmpty || !mounted) return;

    await _flutterTts.stop();

    // String partnerCode = _getLocaleFromPartnerLanguage(widget.partnerDetails["language"] ?? "English");
    String partnerCode = "english";

    setState(() {
      _isSpeaking = true;
      _currentlySpeakingText = text.trim();
    });

    await _flutterTts.setLanguage("en-US");

    // Optional: pick best English voice
    List<dynamic> voices = await _flutterTts.getVoices;
    if (voices.isNotEmpty) {
      for (var voice in voices) {
        if (voice is Map && voice["locale"]?.toString().startsWith("en") == true) {
          await _flutterTts.setVoice({
            "name": voice["name"].toString(),
            "locale": voice["locale"].toString(),
          });
          break;
        }
      }
    }

    await _flutterTts.speak(text.trim());

    // Restore partner's language
    await _flutterTts.setLanguage(partnerCode);
  }


  Future<void> _translateToPartnerLanguageAndSpeak(String englishText) async {
    if (englishText.trim().isEmpty || !mounted) return;

    setState(() {
      _isSpeaking = true;
      _currentlySpeakingText = englishText.trim();
    });

    await _flutterTts.stop();

    String partnerLanguageName = widget.partnerDetails["language"] ?? "English";
    String targetCode = _getLocaleFromPartnerLanguage(partnerLanguageName);

    // If partner language is English, just speak in English
    if (targetCode == "en-US") {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.speak(englishText.trim());
      return;
    }

    try {
      // Translate English → Partner's language
      var translation = await _translator.translate(englishText.trim(), to: targetCode.split('-').first);

      String translatedText = translation.text;

      // Set TTS to partner's language
      await _flutterTts.setLanguage(targetCode);

      // Optional: Select best voice for target language
      List<dynamic> voices = await _flutterTts.getVoices;
      if (voices.isNotEmpty) {
        for (var voice in voices) {
          if (voice is Map && voice["locale"] != null) {
            String locale = voice["locale"].toString();
            if (locale.startsWith(targetCode.split('-').first)) {
              await _flutterTts.setVoice({
                "name": voice["name"].toString(),
                "locale": locale,
              });
              break;
            }
          }
        }
      }

      // Speak the translated text
      await _flutterTts.speak(translatedText);
    } catch (e) {
      print("Translation failed: $e");
      // Fallback: speak original in partner's voice (pronunciation only)
      await _flutterTts.setLanguage(targetCode);
      await _flutterTts.speak(englishText.trim());
    }

    // Restore original TTS settings if needed (optional)
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

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      debugLogging: true,
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: ${error.errorMsg}'),
    );
    if (mounted) setState(() => _speechInitialized = available);
  }

  void _startListening() async {
    if (!_speechInitialized) await _initializeSpeech();
    if (!_speechInitialized || _isListening) return;

    setState(() {
      _isListening = true;
      _currentTranscription = '';
    });

    _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _currentTranscription = result.recognizedWords;
          });
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 10),
      partialResults: true,
    );
  }

  void _stopListening() {
    if (!_isListening) return;
    _speech.stop();

    final String userText = _currentTranscription.trim();
    if (userText.isNotEmpty) {
      SocketService().sendMessage(userText);
    }

    if (mounted) {
      setState(() {
        _isListening = false;
        _currentTranscription = '';
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
    final String text = _textController.text.trim();
    if (text.isEmpty) return;

    SocketService().sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    socketService.socket.off('message');
    _flutterTts.stop();
    _speech.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
                    _currentTranscription.isEmpty ? "Speak now..." : _currentTranscription,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
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
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _sendTextMessage(),
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
                      onTapDown: (_) => _startListening(),
                      onTapUp: (_) => _stopListening(),
                      onTapCancel: _stopListening,
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
                    ),
                  if (_textController.text.trim().isNotEmpty)
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
    bool isUser = message.isUser;
    bool isThisMessageSpeaking = _currentlySpeakingText == message.text.trim();

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

                  // Listen in English
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

                  // Translate & Speak (opens dialog)
                  // GestureDetector(
                  //   onTap: () async {
                  //     if (isThisMessageSpeaking) {
                  //       await _stopSpeaking();
                  //     } else {
                  //       await _translateToPartnerLanguageAndSpeak(message.text);
                  //     }
                  //   },
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  //     decoration: BoxDecoration(
                  //       color: isThisMessageSpeaking ? Colors.blue[50] : appColor.withOpacity(0.2),
                  //       borderRadius: BorderRadius.circular(20),
                  //       border: Border.all(color: appColor.withOpacity(0.4)),
                  //     ),
                  //     child: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Icon(Icons.translate, size: 18, color: appColor),
                  //         const SizedBox(width: 6),
                  //         Text(
                  //           // isThisMessageSpeaking ? "Stop" : "Translate in ${widget.partnerDetails["language"] ?? "Language"}",
                  //           isThisMessageSpeaking ? "Translate" : "Translate",
                  //           style: TextStyle(
                  //             fontSize: 13,
                  //             fontWeight: FontWeight.w600,
                  //             color: appColor,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  GestureDetector(
                    onTap: () async {
                      if (isThisMessageSpeaking) {
                        await _stopSpeaking();
                      } else {
                        // Open dialog showing translation in partner's language
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
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool hasAudio;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.hasAudio = false,
  });
}