import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;
  bool get isConnected => socket.connected;

  // Flag to prevent multiple initial messages
  bool _hasSentInitialGreeting = false;

  // ── Private helper method ── (declared BEFORE it's used)
  void _sendInitialGreeting({
    required String botName,
    required String gender,
  }) {
    final safeGender = gender.toLowerCase() == "female" ? "female" : "male";
    final greeting = "hi,botname=$botName,gender=$safeGender";

    socket.emit('sendMessage', {"message": greeting});
    print('📤 Auto-sent initial greeting: $greeting');
  }

  // Public method to be called from ChatScreen with real partner data
  void sendInitialGreetingWithPartnerDetails(Map<String, dynamic> partnerDetails) {
    final botName = "jarvis"; // you can make this dynamic later if needed
    final gender = (partnerDetails["gender"] ?? "male").toString().toLowerCase();

    _sendInitialGreeting(
      botName: botName,
      gender: gender,
    );
  }

  void initSocket() {
    socket = IO.io(
      'ws://3.109.110.211',
      // 'ws://13.127.143.122:9799',
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

      Future.delayed(const Duration(milliseconds: 400), () {
        if (socket.connected && !_hasSentInitialGreeting) {
          // Default fallback greeting (in case partnerDetails not available yet)
          _sendInitialGreeting(
            botName: "jarvis",
            gender: "male", // ← safe default
          );
          _hasSentInitialGreeting = true;
        }
      });
    });

    // Important: This is where you should call the real gender version
    // → But only AFTER connection (see ChatScreen below)

    socket.onConnectError((err) => print('❌ Connect error: $err'));
    socket.onError((err) => print('❌ Socket error: $err'));
    socket.onDisconnect((_) => print('🔌 Disconnected'));
    socket.onReconnect((attempt) {
      print('🔄 Reconnected after $attempt attempts');
      _hasSentInitialGreeting = false; // reset flag on reconnect
    });

    socket.on('message', (data) {
      print('📩 Received (global): $data');
    });
  }

  void sendMessage(String text) {
    if (!isConnected) {
      print('⚠️ Not connected - cannot send');
      return;
    }
    final payload = {"message": text.trim()};
    socket.emit('sendMessage', payload);
    print('📤 Sent: $payload');
  }

  void resetInitialFlag() {
    _hasSentInitialGreeting = false;
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}