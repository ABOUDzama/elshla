import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';
import 'dart:async';

class WordChainGameOnline extends StatefulWidget {
  final bool isHost;
  final String roomCode;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const WordChainGameOnline({
    super.key,
    required this.isHost,
    required this.roomCode,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<WordChainGameOnline> createState() => _WordChainGameOnlineState();
}

class _WordChainGameOnlineState extends State<WordChainGameOnline> {
  bool _gameActive = false;
  int _secondsLeft = 60;
  String currentWord = 'في انتظار المضيف...';
  int _currentPlayerTurn = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('word_chain_sync', (data) {
      if (!mounted) return;
      final action = data['action'];
      setState(() {
        if (action == 'start_round') {
          _gameActive = true; 
          _secondsLeft = data['secondsLeft'] ?? 60;
          _currentPlayerTurn = data['currentPlayerTurn'] ?? 0;
          currentWord = data['shuffledWords'][data['currentWordIndex']];
          _startTimer();
        } else if (action == 'next_word') {
          currentWord = data['shuffledWords'][data['currentWordIndex']];
          _currentPlayerTurn = data['currentPlayerTurn'] ?? _currentPlayerTurn;
        } else if (action == 'next_player') {
          _currentPlayerTurn = data['currentPlayerTurn'];
          _gameActive = false;
          _timer?.cancel();
        } else if (action == 'timeout') {
          _gameActive = false; 
          _timer?.cancel();
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
    SocketService().socket.off('word_chain_sync');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMyTurn = (widget.roomPlayers != null && _currentPlayerTurn < widget.roomPlayers!.length)
        ? widget.roomPlayers![_currentPlayerTurn]['name'] == widget.playerName : false;

    return BaseGameScaffold(
      title: '⏱️ تحدي التعريف (أونلاين)',
      backgroundColor: const Color(0xFF004D40),
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
        Text(
          'دور: ${widget.roomPlayers?[_currentPlayerTurn]['name'] ?? '...'}',
          style: const TextStyle(fontSize: 20, color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('$_secondsLeft', style: const TextStyle(fontSize: 50, color: Colors.white)),
        const SizedBox(height: 50),
        Text(currentWord, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        if (isMyTurn) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(
            onPressed: () => _answer(true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('صح'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () => _answer(false), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('تخطي'),
          ),
        ]) else const Text('بانتظار حركة اللاعب...', style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildWaiting(bool isMyTurn) {
    String pName = (widget.roomPlayers != null && _currentPlayerTurn < widget.roomPlayers!.length)
        ? widget.roomPlayers![_currentPlayerTurn]['name'] : 'اللاعب';
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(isMyTurn ? 'دورك تبدأ!' : 'بانتظار $pName يبدأ', style: const TextStyle(fontSize: 24, color: Colors.white)),
      const SizedBox(height: 30),
      if (widget.isHost) ElevatedButton(onPressed: _start, child: const Text('ابدأ اللعبة'))
    ]);
  }

  void _start() {
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 
      'action': 'start_round', 
      'shuffledWords': ['تجربة', 'برمجة', 'فلاتر'], 
      'currentWordIndex': 0, 
      'secondsLeft': 60,
      'currentPlayerTurn': _currentPlayerTurn,
    });
  }

  void _answer(bool c) {
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 
      'action': 'client_answer', 
      'isCorrect': c,
      'gameName': 'word_chain'
    });
  }
}
