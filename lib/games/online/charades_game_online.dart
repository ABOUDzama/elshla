import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';
import 'dart:async';

class CharadesGameOnline extends StatefulWidget {
  final bool isHost;
  final String roomCode;
  final String? opponentName;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const CharadesGameOnline({
    super.key,
    required this.isHost,
    required this.roomCode,
    this.opponentName,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<CharadesGameOnline> createState() => _CharadesGameOnlineState();
}

class _CharadesGameOnlineState extends State<CharadesGameOnline> {
  bool _active = false;
  int _secondsLeft = 60;
  String _currentWord = 'انتظر...';
  int _currentPlayer = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('charades_sync', (data) {
      if (!mounted) return;
      final action = data['action'];
      setState(() {
        if (action == 'start_round') {
          _active = true; _secondsLeft = data['secondsLeft'];
          _currentWord = data['shuffledWords'][data['wordIndex']];
          _startLocalTimer();
        } else if (action == 'timeout') {
          _active = false; _timer?.cancel();
        } else if (action == 'next_player') {
          _currentPlayer = data['currentPlayer']; _active = false;
        }
      });
    });
  }

  void _startLocalTimer() {
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
    SocketService().socket.off('charades_sync');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMyTurn = (widget.roomPlayers != null && _currentPlayer < widget.roomPlayers!.length) 
        ? widget.roomPlayers![_currentPlayer]['name'] == widget.playerName : false;

    return BaseGameScaffold(
      title: '🎭 تمثيل صامت (أونلاين)',
      backgroundColor: const Color(0xFF1A237E),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: _active ? _buildActive(isMyTurn) : _buildWaiting(isMyTurn),
      ),
    );
  }

  Widget _buildActive(bool isMyTurn) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$_secondsLeft', style: TextStyle(fontSize: 40, color: Colors.redAccent)),
        const SizedBox(height: 30),
        Text(isMyTurn ? _currentWord : 'خمّن ماذا يمثّل!', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
        if (isMyTurn) ...[
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.check, color: Colors.green, size: 50), onPressed: () => _sendAnswer(true)),
              const SizedBox(width: 30),
              IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 50), onPressed: () => _sendAnswer(false)),
            ],
          )
        ]
      ],
    );
  }

  Widget _buildWaiting(bool isMyTurn) {
    String pName = (widget.roomPlayers != null && _currentPlayer < widget.roomPlayers!.length) 
        ? widget.roomPlayers![_currentPlayer]['name'] : 'اللاعب';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isMyTurn ? 'دورك تمثّل!' : 'دور $pName يمثّل', style: TextStyle(fontSize: 24, color: Colors.white)),
        const SizedBox(height: 20),
        if (widget.isHost) ElevatedButton(onPressed: _startRound, child: const Text('ابدأ الجولة'))
      ],
    );
  }

  void _startRound() {
    if (!widget.isHost) return;
    SocketService().socket.emit('charades_sync', {
      'roomCode': widget.roomCode, 'action': 'start_round', 'shuffledWords': ['كرة قدم', 'ميسي', 'تيتانيك'],
      'wordIndex': 0, 'correct': 0, 'skip': 0, 'secondsLeft': 60, 'currentPlayer': _currentPlayer
    });
  }

  void _sendAnswer(bool correct) {
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 'gameName': 'charades', 'action': 'client_answer', 'isCorrect': correct
    });
  }
}
