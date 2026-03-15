import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';
import 'dart:async';

class FiveSecondsGameOnline extends StatefulWidget {
  final bool isHost;
  final String? roomCode;
  final String? opponentName;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const FiveSecondsGameOnline({
    super.key,
    required this.isHost,
    this.roomCode,
    this.opponentName,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<FiveSecondsGameOnline> createState() => _FiveSecondsGameOnlineState();
}

class _FiveSecondsGameOnlineState extends State<FiveSecondsGameOnline> {
  bool isTimerRunning = false;
  int timeLeft = 5;
  String currentQuestion = 'في انتظار المضيف...';
  bool showAnswer = false;
  bool isQuestionRevealed = false;
  int _currentPlayerTurn = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('game_move', (data) {
      if (!mounted) return;
      final type = data['type'];
      setState(() {
        if (type == 'sync_questions') {
          currentQuestion = data['questions'][data['currentIndex']]['question'];
        } else if (type == 'start_timer') {
          _startTimer();
        } else if (type == 'next_question') {
          _currentPlayerTurn = data['currentPlayerTurn']; showAnswer = false; isQuestionRevealed = false; timeLeft = 5; isTimerRunning = false;
        }
      });
    });
  }

  void _startTimer() {
    setState(() { isTimerRunning = true; isQuestionRevealed = true; timeLeft = 5; });
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft <= 0) {
        t.cancel();
        setState(() {
          isTimerRunning = false;
          showAnswer = true;
        });
      } else {
        setState(() => timeLeft--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    SocketService().socket.off('game_move');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '⏱️ خمس ثواني (أونلاين)',
      backgroundColor: const Color(0xFFAD1457),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$timeLeft', style: TextStyle(fontSize: 60, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [
              if (!isQuestionRevealed) Text('استعد...', style: TextStyle(fontSize: 24, color: Colors.pink))
              else ...[
                Text(currentQuestion, style: TextStyle(fontSize: 22, color: Color(0xFF880E4F), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ]
            ])),
            const SizedBox(height: 30),
            if (widget.isHost && !isTimerRunning && !showAnswer) ElevatedButton(onPressed: _emitStart, child: const Text('ابدأ التحدي 🔥'))
            else if (widget.isHost && showAnswer) ElevatedButton(onPressed: _emitNext, child: const Text('التالي ➡️')),
          ],
        ),
      ),
    );
  }

  void _emitStart() {
    SocketService().socket.emit('game_move', {'roomCode': widget.roomCode, 'moveData': {'type': 'start_timer'}});
  }

  void _emitNext() {
    SocketService().socket.emit('game_move', {'roomCode': widget.roomCode, 'moveData': {'type': 'next_question', 'currentIndex': 0, 'currentPlayerTurn': (_currentPlayerTurn + 1) % 2}});
  }
}
