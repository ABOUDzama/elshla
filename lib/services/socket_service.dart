import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;
  bool _initialized = false;

  // Railway backend - port 443 explicit to prevent :0 bug in socket_io_client
  static const String _serverUrl =
      'https://elshla-production.up.railway.app:443';

  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket get socket {
    if (_socket == null) _init();
    return _socket!;
  }

  void initSocket() {
    if (_initialized && _socket != null) {
      if (!_socket!.connected) {
        print('🔄 Reconnecting socket...');
        _socket!.connect();
      }
      return;
    }
    _init();
  }

  void _init() {
    _initialized = true;
    print('🔌 Initializing socket to: $_serverUrl');

    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['polling'],
      'autoConnect': false,
      'timeout': 20000,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 3000,
    });

    _socket!.onConnect((_) {
      print('✅ Socket connected! ID: ${_socket!.id}');
    });

    _socket!.onConnectError((e) {
      print('❌ Connect Error: $e');
    });

    _socket!.onError((e) {
      print('❌ Socket Error: $e');
    });

    _socket!.onDisconnect((reason) {
      print('🔌 Disconnected: $reason');
    });

    print('🚀 Calling socket.connect()...');
    _socket!.connect();
  }
}
