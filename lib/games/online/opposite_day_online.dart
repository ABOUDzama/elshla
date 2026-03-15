import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';
import 'dart:async';

class OppositeDayOnline extends StatefulWidget {
  final bool isHost;
  final String? roomCode;
  final String? opponentName;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const OppositeDayOnline({
    super.key,
    required this.isHost,
    this.roomCode,
    this.opponentName,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<OppositeDayOnline> createState() => _OppositeDayOnlineState();
}

class _OppositeDayOnlineState extends State<OppositeDayOnline> {
  bool _gameActive = false;
  int _secondsLeft = 5;
  String currentQuestion = 'في انتظار المضيف...';
  int _currentPlayerTurn = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('game_move', (data) {
      if (!mounted) return;
      final move = data['moveData'];
      final type = move['type'];
      setState(() {
        if (type == 'sync_question') {
          _gameActive = true; 
          _secondsLeft = 5;
          currentQuestion = move['question'] ?? 'جهز نفسك!';
          _currentPlayerTurn = move['turn'] ?? 0;
          _startTimer();
        } else if (type == 'handle_result') {
          _gameActive = false; 
          _timer?.cancel();
        } else if (type == 'next_player') {
          _currentPlayerTurn = move['turn'];
        }
      });
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    SocketService().socket.off('game_move');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMyTurn = (widget.roomPlayers != null && _currentPlayerTurn < widget.roomPlayers!.length)
        ? widget.roomPlayers![_currentPlayerTurn]['name'] == widget.playerName : false;

    return BaseGameScaffold(
      title: '🙃 عكس العكاس (أونلاين)',
      backgroundColor: const Color(0xFF3E2723),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: _gameActive ? _buildActive(isMyTurn) : _buildWaiting(isMyTurn),
      ),
    );
  }

  Widget _buildActive(bool isMyTurn) {
    String pName = (widget.roomPlayers != null && _currentPlayerTurn < widget.roomPlayers!.length)
        ? widget.roomPlayers![_currentPlayerTurn]['name'] : 'اللاعب';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isMyTurn ? 'دورك تمثّل بالعكس! 🙃' : 'الممثل الآن: $pName',
          style: const TextStyle(fontSize: 22, color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Text('$_secondsLeft', style: const TextStyle(fontSize: 50, color: Colors.white)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
          child: Text(
            isMyTurn ? currentQuestion : 'السؤال يظهر للممثل فقط!', 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
        if (isMyTurn) ...[
          const SizedBox(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 70), onPressed: () => _sendResult(true)),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.cancel, color: Colors.red, size: 70), onPressed: () => _sendResult(false)),
          ])
        ]
      ],
    );
  }

  Widget _buildWaiting(bool isMyTurn) {
    String pName = (widget.roomPlayers != null && _currentPlayerTurn < widget.roomPlayers!.length)
        ? widget.roomPlayers![_currentPlayerTurn]['name'] : 'اللاعب';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isMyTurn ? 'دورك تبدأ!' : 'بانتظار $pName يبدأ', style: const TextStyle(fontSize: 24, color: Colors.white)),
        const SizedBox(height: 30),
        if (widget.isHost) ElevatedButton(onPressed: _emitStart, child: const Text('ابدأ الجولة'))
      ],
    );
  }

  void _emitStart() {
    String q = 'هل تحب المدرسة؟ (جاوب بالعكس)'; // Example question
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 
      'moveData': {
        'type': 'sync_question', 
        'question': q, 
        'turn': _currentPlayerTurn
      }
    });
  }

  void _sendResult(bool s) {
    int nextIdx = (_currentPlayerTurn + 1) % (widget.roomPlayers?.length ?? 1);
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 
      'moveData': {
        'type': 'handle_result', 
        'success': s,
        'nextTurn': nextIdx,
        'gameName': 'opposite_day'
      }
    });
  }
}
