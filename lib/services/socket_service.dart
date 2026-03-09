import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;

  // Railway backend server - stable and permanent URL
  final String serverUrl = 'https://elshla-production.up.railway.app';

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  IO.Socket get socket {
    _socket ??= _createSocket();
    return _socket!;
  }

  IO.Socket _createSocket() {
    final s = IO.io(serverUrl, <String, dynamic>{
      'transports': ['polling', 'websocket'],
      'autoConnect': false,
      'forceNew': false,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 2000,
      'timeout': 30000, // 30 ثانية
    });

    s.onConnect((_) => print('Connected to Socket.IO server 🎉'));
    s.onConnectError((err) => print('Socket.IO Connection Error ❌: $err'));
    s.onError((err) => print('Socket.IO Error ❌: $err'));
    s.onDisconnect((_) => print('Disconnected from Socket.IO server 🔌'));

    return s;
  }

  void initSocket() {
    // إذا كان متصل بالفعل لا تعمل شيء
    if (_socket != null && _socket!.connected) return;

    // إذا لم يُبنَ بعد أو قُطع الاتصال، اتصل
    _socket ??= _createSocket();
    if (!_socket!.connected) {
      _socket!.connect();
    }
  }

  /// أعد الاتصال من الصفر (استخدمه عند الضرورة فقط)
  void reconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = _createSocket();
    _socket!.connect();
  }

  bool get isConnected => _socket?.connected ?? false;
}
