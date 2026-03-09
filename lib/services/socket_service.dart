import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;

  // Railway backend server
  final String serverUrl = 'https://elshla-production.up.railway.app';

  factory SocketService() => _instance;

  SocketService._internal();

  bool _initialized = false;

  void initSocket() {
    if (_initialized) {
      // إذا انقطع الاتصال، أعد الاتصال
      if (!socket.connected) socket.connect();
      return;
    }

    _initialized = true;
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['polling', 'websocket'],
      'autoConnect': true, // تلقائي
      'forceNew': false,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
      'timeout': 20000,
    });

    socket.onConnect((_) => print('✅ Connected!'));
    socket.onConnectError((e) => print('❌ Connect Error: $e'));
    socket.onError((e) => print('❌ Error: $e'));
    socket.onDisconnect((_) => print('🔌 Disconnected'));
  }
}
