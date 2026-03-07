import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;

  // Using local IP address for physical device and web testing on the same network
  final String serverUrl = 'http://192.168.1.7:3000';

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void initSocket() {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'], // السماح بالبولينج أولاً للترقية
      'autoConnect': false,
      'forceNew': true, // إجبار اتصال جديد في كل مرة
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
