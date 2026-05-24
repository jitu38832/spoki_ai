import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:spokiai/view/utils/preference_manager.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;
  bool get isConnected => socket.connected;

  bool _hasSentInitialGreeting = false;
  bool _socketConfigured = false;

  void initSocket() {
    if (_socketConfigured) {
      if (!socket.connected) {
        socket.connect();
      }
      return;
    }
    _socketConfigured = true;

    socket = IO.io(
      'ws://3.109.110.211',
      // 'ws://192.168.1.6:9799',
      // 'ws://192.168.1.2:9799',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setReconnectionAttempts(9999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(10000)
          .build(),
    );

    socket.onConnect((_) {
      print('✅ SOCKET CONNECTED');
      // Do NOT send greeting here automatically anymore
      // → We will call sendInitialGreetingWithPartnerDetails() from ChatScreen
    });

    socket.onConnectError((err) => print('❌ Connect error: $err'));
    socket.onError((err) => print('❌ Socket error: $err'));
    socket.onDisconnect((_) => print('🔌 Disconnected'));
    socket.onReconnect((attempt) {
      print('🔄 Reconnected after $attempt attempts');
      _hasSentInitialGreeting = false; // allow resending after reconnect
    });

    socket.on('message', (data) {
      print('📩 Received: $data');
    });
  }

  /// Call this method **after** socket is connected and you have real partnerDetails
  void sendInitialGreetingWithPartnerDetails(Map<String, dynamic> partnerDetails) {
    if (_hasSentInitialGreeting) {
      print("→ Initial greeting already sent, skipping...");
      return;
    }

    final botName = partnerDetails['name']?.toString() ?? "jarvis";
    final genderRaw = partnerDetails['gender']?.toString().toLowerCase() ?? "male";
    final safeGender = (genderRaw == "female") ? "female" : "male";

    final greeting = "hi,botname=$botName,gender=$safeGender";

    if (socket.connected) {
      socket.emit('sendMessage', {"message": greeting});
      print('📤 Sent real initial greeting: $greeting');
      _hasSentInitialGreeting = true;
    } else {
      print('⚠️ Socket not connected yet — cannot send initial greeting');
    }
  }

  void sendMessage(String text, {String? clientMessageId}) {
    if (!isConnected) {
      print('⚠️ Not connected - cannot send');
      return;
    }
    final payload = <String, dynamic>{"message": text.trim()};
    final id = clientMessageId?.trim();
    if (id != null && id.isNotEmpty) {
      payload['clientMessageId'] = id;
    }
    socket.emit('sendMessage', payload);
    print('📤 Sent: $payload');
  }

  /// Text + uploaded voice URL (after multipart upload). Server should broadcast with same fields.
  void sendVoiceMessage({
    required String message,
    required String audioUrl,
    String? clientMessageId,
  }) {
    if (!isConnected) {
      print('⚠️ Not connected - cannot send voice message');
      return;
    }
    final payload = <String, dynamic>{
      'message': message.trim(),
      'audioUrl': audioUrl.trim(),
    };
    final id = clientMessageId?.trim();
    if (id != null && id.isNotEmpty) {
      payload['clientMessageId'] = id;
    }
    socket.emit('sendMessage', payload);
    print('📤 Sent voice message (${message.trim().length} chars, url len=${audioUrl.trim().length})');
  }

  /// Request AI feedback. Include [audioUrl] only for voice messages; server should run
  /// pronunciation analysis only when [audioUrl] is present.
  void emitAiFeedback(String learnerText, {String? audioUrl}) {
    if (!isConnected) {
      print('⚠️ Not connected - cannot send aifeedback');
      return;
    }
    final t = learnerText.trim();
    if (t.isEmpty) return;
    final payload = <String, dynamic>{
      'text': t,
      'message': t,
      'content': t,
    };
    final au = audioUrl?.trim();
    final hasAudio = au != null && au.isNotEmpty;
    payload['hasAudio'] = hasAudio;
    payload['pronunciationRequested'] = hasAudio;
    payload['pronunciationMode'] = hasAudio ? 'audio' : 'disabled_without_audio';
    if (hasAudio) {
      payload['audioUrl'] = au;
    }
    final tok = PreferenceManager.getStringValue(key: 'token')?.trim();
    if (tok != null && tok.isNotEmpty) {
      payload['token'] = tok;
      payload['accessToken'] = tok;
    }
    socket.emit('aifeedback', payload);
    print('📤 aifeedback: ${t.length} chars, hasAudio=$hasAudio');
  }

  /// Poll / refresh story quiz generation status (event `storyQuizStatus`).
  // ─── Story practice conversation (5 questions about current story) ───────
  // Socket.IO events namespaced `storyPractice:*` (contract in agent / PR notes).

  void emitStoryPracticeStart({
    required String storyId,
    required String quizId,
    required String token,
    String? storyTitle,
  }) {
    initSocket();
    if (storyId.isEmpty || quizId.isEmpty || token.isEmpty) {
      print('⚠️ storyPractice:start skipped — missing storyId, quizId, or token');
      return;
    }
    final payload = <String, dynamic>{
      'storyId': storyId,
      'quizId': quizId,
      'token': token,
      if (storyTitle != null && storyTitle.trim().isNotEmpty)
        'storyTitle': storyTitle.trim(),
      'totalQuestions': 5,
    };
    void send() {
      if (!socket.connected) return;
      socket.emit('storyPractice:start', payload);
      print('📤 storyPractice:start storyId=$storyId quizId=$quizId');
    }

    if (socket.connected) {
      send();
    } else {
      socket.once('connect', (_) => send());
    }
  }

  void emitStoryPracticeAnswer({
    required String sessionId,
    required int questionIndex,
    required String text,
    String? clientMessageId,
  }) {
    if (!isConnected) {
      print('⚠️ Not connected - cannot storyPractice:answer');
      return;
    }
    final payload = <String, dynamic>{
      'sessionId': sessionId,
      'questionIndex': questionIndex,
      'message': text.trim(),
    };
    final id = clientMessageId?.trim();
    if (id != null && id.isNotEmpty) payload['clientMessageId'] = id;
    socket.emit('storyPractice:answer', payload);
    print('📤 storyPractice:answer idx=$questionIndex');
  }

  void emitStoryPracticeEnd({required String sessionId}) {
    if (!isConnected) {
      print('⚠️ Not connected - cannot storyPractice:end');
      return;
    }
    socket.emit('storyPractice:end', {'sessionId': sessionId});
    print('📤 storyPractice:end');
  }

  void emitGetStoryQuizStatus({
    required String storyId,
    required String token,
    String? requestId,
  }) {
    if (!isConnected) {
      print('⚠️ Not connected - cannot getStoryQuizStatus');
      return;
    }
    if (storyId.isEmpty || token.isEmpty) return;
    final payload = <String, dynamic>{
      'storyId': storyId,
      'token': token,
    };
    if (requestId != null && requestId.isNotEmpty) {
      payload['requestId'] = requestId;
    }
    socket.emit('getStoryQuizStatus', payload);
    print('📤 getStoryQuizStatus: storyId=$storyId');
  }

  void resetInitialFlag() {
    _hasSentInitialGreeting = false;
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}