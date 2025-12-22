import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:spokiai/view/utils/colors.dart';
import '../utils/preference_manager.dart';
import '../utils/custom_widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isListening = false;
  bool _isInitialized = false;
  String _transcribedText = '';
  List<ChatMessage> _messages = [];

  // Color scheme
  final Color purpleColor = const Color(0xFF9B59B6);
  final Color tealColor = const Color(0xFF1ABC9C);
  final Color lightGrey = const Color(0xFFF5F5F5);
  final Color darkGrey = const Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _addSampleMessages();
  }

  void _addSampleMessages() {
    _messages = [
      ChatMessage(
        text: "Hi, how are you feeling today?",
        isIncoming: true,
        hasAudio: true,
        hasTranslate: true,
        isPro: false,
      ),
      ChatMessage(
        text: "I'm feeling good",
        isIncoming: false,
        hasAudio: false,
        hasTranslate: false,
        isPro: false,
        hasAIFeedback: true,
      ),
      ChatMessage(
        text: "That's great to hear. What's making you feel good today? Maybe we can build on that positivity.",
        isIncoming: true,
        hasAudio: true,
        hasTranslate: true,
        isPro: true,
      ),
    ];
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
      },
    );
    setState(() {
      _isInitialized = available;
    });
  }

  void _startListening() async {
    if (!_isInitialized) {
      await _initializeSpeech();
    }

    if (_isInitialized && !_isListening) {
      setState(() {
        _isListening = true;
        _transcribedText = '';
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _transcribedText = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });

      if (_transcribedText.isNotEmpty) {
        _sendMessage(_transcribedText);
        _transcribedText = '';
      }
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isIncoming: false,
        hasAudio: false,
        hasTranslate: false,
        isPro: false,
        hasAIFeedback: true,
      ));
    });

    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: textRoboto(
          text: "Chat",
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkGrey,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isIncoming
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          // Profile Picture and Audio (for incoming messages)
          if (message.isIncoming) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, size: 20, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                // Audio Waveform
                if (message.hasAudio) _buildAudioWaveform(),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Message Bubble
          Row(
            mainAxisAlignment: message.isIncoming
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Refresh/Retry Icon (for outgoing messages)
              if (!message.isIncoming)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: Icon(Icons.refresh, size: 18, color: Colors.grey[600]),
                ),

              // Message Container
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isIncoming ? lightGrey : appColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: textRoboto(
                    text: message.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: message.isIncoming ? darkGrey : Colors.white,
                    maxLines: 10,
                  ),
                ),
              ),
            ],
          ),

          // AI Feedback Button (for outgoing messages)
          if (message.hasAIFeedback && !message.isIncoming) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  label: "AI feedback",
                  icon: Icons.lightbulb_outline,
                  color: Colors.grey[600]!,
                ),
              ],
            ),
          ],

          // Translate Button (for incoming messages)
          if (message.hasTranslate && message.isIncoming) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildActionButton(
                  label: message.isPro ? "Translate PRO" : "Translate",
                  icon: Icons.translate,
                  color: message.isPro ? tealColor : Colors.grey[600]!,
                  isPro: message.isPro,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioWaveform() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow, size: 16, color: darkGrey),
          const SizedBox(width: 8),
          // Simple waveform visualization
          Row(
            children: List.generate(
              5,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3,
                height: (index % 2 == 0 ? 8.0 : 12.0),
                decoration: BoxDecoration(
                  color: darkGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          textRoboto(
            text: "1x",
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    bool isPro = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPro ? appColor.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: isPro ? Border.all(color: appColor, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          textRoboto(
            text: label,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
          if (isPro) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: purpleColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: textRoboto(
                text: "PRO",
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: tealColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Instruction Text
          textRoboto(
            text: "Press the mic and start speaking",
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 12),

          // Input Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Crown and Search Icons
              Column(
                children: [
                  Icon(Icons.workspace_premium, size: 20, color: Colors.grey[600]),
                  const SizedBox(height: 4),
                  Icon(Icons.search, size: 20, color: Colors.grey[600]),
                ],
              ),

              // Microphone Button
              GestureDetector(
                onTapDown: (_) => _startListening(),
                onTapUp: (_) => _stopListening(),
                onTapCancel: () => _stopListening(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: appColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: purpleColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              // Document/Image Icon
              Icon(Icons.insert_drive_file, size: 24, color: Colors.grey[600]),
            ],
          ),

          // Text Input (optional, for typing)
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: appColor),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ),
              onSubmitted: (text) => _sendMessage(text),
            ),
          ),

          // Show transcribed text when listening
          if (_isListening && _transcribedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, color: purpleColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: textRoboto(
                      text: _transcribedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: darkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isIncoming;
  final bool hasAudio;
  final bool hasTranslate;
  final bool isPro;
  final bool hasAIFeedback;

  ChatMessage({
    required this.text,
    required this.isIncoming,
    required this.hasAudio,
    required this.hasTranslate,
    required this.isPro,
    this.hasAIFeedback = false,
  });
}
