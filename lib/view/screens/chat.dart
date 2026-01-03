import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:spokiai/view/screens/socket.dart';
import '../utils/colors.dart';

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
  bool _isSpeaking = false;

  String _currentTranscription = '';
  String? _currentlySpeakingText; // Tracks which message is being spoken

  List<ChatMessage> _messages = [];

  late SocketService socketService;

  @override
  void initState() {
    super.initState();

    print("partnerDetails");
    print(widget.partnerDetails);

    socketService = SocketService();
    socketService.initSocket();

    _flutterTts = FlutterTts();
    _initializeTts();
    _initializeSpeech();

    socketService.socket.on('message', (data) {
      print('Received from server: $data');

      if (data is! Map) return;
      String? type = data['type'];
      String? messageText = data['message'];

      if (messageText == null || messageText.trim().isEmpty) return;

      if (!mounted) return;

      setState(() {
        if (type == 'user') {
          _messages.add(ChatMessage(
            text: messageText.trim(),
            isUser: true,
          ));
        } else if (type == 'ai') {
          _messages.add(ChatMessage(
            text: messageText.trim(),
            isUser: false,
            hasAudio: true,
          ));
          // Auto-speak new AI message
          _speak(messageText.trim());
        }
      });

      _scrollToBottom();
    });
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setVolume(1.0);

    String gender = (widget.partnerDetails["gender"] ?? "Other").toString().toLowerCase();
    String age = (widget.partnerDetails["age"] ?? "Adult").toString().toLowerCase();

    print("Configuring TTS: Gender=$gender, Age=$age");

    double pitch = 1.0;
    double rate = 0.5;

    if (age == "old") {
      rate = 0.35; // Very slow for elderly
      if (gender == "male") {
        pitch = 0.6; // Very deep male
      } else if (gender == "female") {
        pitch = 0.9; // Lower but feminine
      } else {
        pitch = 0.75;
      }
    } else if (age == "young") {
      rate = 0.65;
      if (gender == "male") {
        pitch = 1.3;
      } else if (gender == "female") {
        pitch = 1.6;
      } else {
        pitch = 1.4;
      }
    } else {
      // Adult
      rate = 0.5;
      if (gender == "male") {
        pitch = 0.9;
      } else if (gender == "female") {
        pitch = 1.2;
      } else {
        pitch = 1.0;
      }
    }

    await _flutterTts.setPitch(pitch);
    await _flutterTts.setSpeechRate(rate);

    print("Applied: Pitch=$pitch, Rate=$rate");

    List<dynamic> voices = await _flutterTts.getVoices;
    print("Available voices count: ${voices.length}");

    // Try mature voices for old age
    if (age == "old") {
      List<String> oldVoices = ["en-us-x-tpd-local", "en-gb-x-fis-local"];
      for (String name in oldVoices) {
        bool found = false;
        for (var voice in voices) {
          if (voice is Map && voice["name"]?.toString() == name) {
            Map<String, String> voiceMap = {
              "name": voice["name"].toString(),
              "locale": voice["locale"]?.toString() ?? "en-US",
            };
            await _flutterTts.setVoice(voiceMap);
            print("Used mature voice: $name");
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }

    if (voices.isEmpty) {
      await _flutterTts.setLanguage("en-US");
      print("Using default voice with pitch/rate adjustments");
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
            // Partner Photo
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
            // Partner Name
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
            padding: EdgeInsets.only(
              bottom: _isListening ? 20 : 40,
              top: 10,
            ),
            child: GestureDetector(
              onTapDown: (_) => _startListening(),
              onTapUp: (_) => _stopListening(),
              onTapCancel: _stopListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.redAccent : appColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.redAccent : appColor).withOpacity(0.6),
                      blurRadius: _isListening ? 50 : 25,
                      spreadRadius: _isListening ? 12 : 6,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 30,
                ),
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
                  GestureDetector(
                    onTap: () {
                      if (isThisMessageSpeaking) {
                        _stopSpeaking();
                      } else {
                        _speak(message.text);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isThisMessageSpeaking ? Colors.red[50] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isThisMessageSpeaking ? Colors.red : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isThisMessageSpeaking ? Icons.stop : Icons.volume_up,
                            size: 20,
                            color: isThisMessageSpeaking ? Colors.red : Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isThisMessageSpeaking ? "Stop" : "Listen",
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isThisMessageSpeaking ? Colors.red : Colors.grey[700],
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