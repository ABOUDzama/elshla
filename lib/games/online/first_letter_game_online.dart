import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';
import 'dart:async';

class FirstLetterGameOnline extends StatefulWidget {
  final bool isHost;
  final String roomCode;
  final String? opponentName;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const FirstLetterGameOnline({
    super.key,
    required this.isHost,
    required this.roomCode,
    this.opponentName,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<FirstLetterGameOnline> createState() => _FirstLetterGameOnlineState();
}

class _FirstLetterGameOnlineState extends State<FirstLetterGameOnline> {
  bool _gameActive = false;
  int _secondsLeft = 5;
  String? _category;
  String? _letter;
  int _currentPlayer = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('first_letter_sync', (data) {
      if (!mounted) return;
      final action = data['action'];
      setState(() {
        if (action == 'start_round') {
          _gameActive = true; _secondsLeft = data['secondsLeft'];
          _category = data['currentCategory']; _letter = data['currentLetter'];
          _startTimer();
        } else if (action == 'timeout' || action == 'result') {
          _gameActive = false; _timer?.cancel();
        } else if (action == 'next_player') {
          _currentPlayer = data['currentPlayerTurn']; _gameActive = false;
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
    SocketService().socket.off('first_letter_sync');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMyTurn = (widget.roomPlayers != null && _currentPlayer < widget.roomPlayers!.length)
        ? widget.roomPlayers![_currentPlayer]['name'] == widget.playerName : false;

    return BaseGameScaffold(
      title: '🍎 أول حرف (أونلاين)',
      backgroundColor: const Color(0xFF2E7D32),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: _gameActive ? _buildActive(isMyTurn) : _buildWaiting(isMyTurn),
      ),
    );
  }

  Widget _buildActive(bool isMyTurn) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$_secondsLeft', style: TextStyle(fontSize: 50, color: Colors.redAccent)),
        const SizedBox(height: 20),
        Text(_category ?? '', style: TextStyle(fontSize: 24, color: Colors.white70)),
        Text(_letter ?? '', style: TextStyle(fontSize: 100, color: Colors.white, fontWeight: FontWeight.bold)),
        if (isMyTurn) ...[
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Icon(Icons.check_circle, color: Colors.green, size: 60), onPressed: () => _sendResult(true)),
              SizedBox(width: 40),
              IconButton(icon: Icon(Icons.cancel, color: Colors.red, size: 60), onPressed: () => _sendResult(false)),
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
        Text(isMyTurn ? 'دورك!' : 'دور $pName', style: TextStyle(fontSize: 24, color: Colors.white)),
        const SizedBox(height: 20),
        if (widget.isHost) ElevatedButton(onPressed: _startRound, child: const Text('ابدأ الجولة'))
      ],
    );
  }

  void _startRound() {
    if (!widget.isHost) return;
    SocketService().socket.emit('first_letter_sync', {
      'roomCode': widget.roomCode, 'action': 'start_round', 'currentCategory': '🍎 فواكه', 'currentLetter': 'أ',
      'secondsLeft': 5, 'currentPlayerTurn': _currentPlayer
    });
  }

  void _sendResult(bool success) {
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 'gameName': 'first_letter', 'action': 'client_result', 'success': success
    });
  }
}
