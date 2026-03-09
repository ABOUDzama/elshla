import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;

  // Railway backend server - stable and permanent URL
  final String serverUrl = 'https://elshla-production.up.railway.app';

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void initSocket() {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': [
        'polling',
        'websocket',
      ], // polling أولاً ثم ترقية لـ websocket
      'autoConnect': false,
      'forceNew': true,
    });
    socket.connect();

    socket.onConnect((_) {
      print('Connected to Socket.IO server 🎉');
    });

    socket.onConnectError((err) {
      print('Socket.IO Connection Error ❌: $err');
    });

    socket.onError((err) {
      print('Socket.IO Error ❌: $err');
    });

    socket.onDisconnect((_) {
      print('Disconnected from Socket.IO server 🔌');
    });
  }
}
