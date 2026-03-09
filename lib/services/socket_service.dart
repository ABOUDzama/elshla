import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;
  bool _initialized = false;

  // Railway backend server
  final String serverUrl = 'https://elshla-production.up.railway.app';

  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket get socket {
    if (_socket == null) _init();
    return _socket!;
  }

  void initSocket() {
    if (_initialized && _socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }
    _init();
  }

  void _init() {
    _initialized = true;
    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports([
            'polling',
          ]) // polling فقط - أكثر استقراراً على الموبايل
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setTimeout(30000)
          .build(),
    );

    _socket!.onConnect((_) => print('✅ Connected!'));
    _socket!.onConnectError((e) => print('❌ Connect Error: $e'));
    _socket!.onError((e) => print('❌ Error: $e'));
    _socket!.onDisconnect((_) => print('🔌 Disconnected'));

    _socket!.connect();
  }
}
