import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;
  bool get isConnected => socket.connected;

  bool _hasSentInitialGreeting = false;

  void initSocket() {
    socket = IO.io(
      'ws://3.109.110.211',
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