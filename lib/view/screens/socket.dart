import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;

  bool get isConnected => socket.connected;

  void initSocket() {
    socket = IO.io(
      'ws://13.109.110.211', // Base URL (http for handshake, upgrades to ws)
      IO.OptionBuilder()
          .setTransports(['websocket']) // Force websocket only (best for Flutter)
          .enableAutoConnect()          // Auto connect on creation
          .setReconnectionAttempts(9999)// Unlimited retries
          .setReconnectionDelay(1000)   // Start with 1s delay
          .setReconnectionDelayMax(5000)// Max 5s between retries
          .setTimeout(10000)            // Connection timeout
          .build(),
    );

    // Connection events
    socket.onConnect((_) {
      print('✅ Connected to socket server');
    });

    socket.onConnectError((data) {
      print('❌ Connect error: $data');
    });

    socket.onError((data) {
      print('❌ Socket error: $data');
    });

    socket.onDisconnect((_) {
      print('🔌 Disconnected from server');
    });

    socket.onReconnect((attempt) {
      print('🔄 Reconnected after $attempt attempt(s)');
    });

    socket.onReconnectAttempt((attempt) {
      print('🔄 Reconnect attempt #$attempt');
    });

    // Listen for incoming messages from server
    socket.on('message', (data) {
      print('📩 Received message: $data');
      // You can notify listeners here (e.g., using streams or callbacks)
      // For now, we'll handle it in the ChatScreen directly
    });
  }

  /// Send user message to server
  void sendMessage(String text) {
    if (!isConnected) {
      print('⚠️ Cannot send message: Socket not connected');
      return;
    }

    final payload = {"message": text};
    socket.emit('sendMessage', payload);
    print('📤 Sent message: $payload');
  }

  /// Disconnect and clean up
  void disconnect() {
    socket.disconnect();
    socket.dispose();
    print('🔌 Socket disconnected and disposed');
  }
}