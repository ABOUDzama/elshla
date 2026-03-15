import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';
import '../../widgets/premium_loading_indicator.dart';

class QuizGameOnline extends StatefulWidget {
  final bool isHost;
  final String roomCode;
  final String? opponentName;
  final List<dynamic>? roomPlayers;
  final String? playerName;

  const QuizGameOnline({
    super.key,
    required this.isHost,
    required this.roomCode,
    this.opponentName,
    this.roomPlayers,
    this.playerName,
  });

  @override
  State<QuizGameOnline> createState() => _QuizGameOnlineState();
}

class _QuizGameOnlineState extends State<QuizGameOnline> {
  bool gameStarted = false;
  int currentQuestionIndex = 0;
  bool showAnswer = false;
  List<Map<String, dynamic>> gameQuestions = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    SocketService().socket.on('quiz_update', _onUpdate);
  }


  @override
  void dispose() {
    SocketService().socket.off('quiz_update', _onUpdate);
    super.dispose();
  }

  void _onUpdate(dynamic data) {
    if (!mounted) return;
    setState(() {
      gameStarted = data['gameStarted'];
      currentQuestionIndex = data['index'];
      showAnswer = data['showAnswer'];
      if (data['questions'] != null) {
        gameQuestions = List<Map<String, dynamic>>.from(data['questions']);
      }
    });
  }

  void _sync() {
    if (!widget.isHost) return;
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode,
      'moveData': {
        'type': 'quiz_sync',
        'gameStarted': gameStarted,
        'index': currentQuestionIndex,
        'showAnswer': showAnswer,
        'questions': gameQuestions,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '🎯 لعبة الأسئلة (أونلاين)',
      backgroundColor: const Color(0xFF1A1A2E),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: gameStarted ? _buildGameBody() : _buildWaitingBody(),
    );
  }

  Widget _buildWaitingBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz, size: 80, color: Colors.blueAccent).animate().scale().rotate(),
          const SizedBox(height: 20),
          Text(
            widget.isHost ? 'المضيف بيختار الأسئلة...' : 'انتظر المضيف يبدأ اللعبة...',
            style: GoogleFonts.cairo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          if (widget.isHost) ...[
            const SizedBox(height: 30),
            Text('الأسئلة أونلاين بيتم اختيارها تلقائياً للمنافسة!', style: GoogleFonts.cairo(color: Colors.white70)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () { toggleGame(true); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
              child: Text('بدء اللعبة الآن', style: GoogleFonts.cairo(fontSize: 18, color: Colors.white)),
            ),
          ]
        ],
      ),
    );
  }

  void toggleGame(bool start) {
    setState(() {
      gameStarted = start;
      if (start) {
        gameQuestions = [{'question': 'أهلاً بك في تحدي الأونلاين!', 'answer': 'استعد للأسئلة القادمة'}];
      }
    });
    _sync();
  }

  Widget _buildGameBody() {
    if (gameQuestions.isEmpty) return const Center(child: PremiumLoadingIndicator(message: 'جاري تحميل الأسئلة...'));
    final q = gameQuestions[currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('سؤال ${currentQuestionIndex + 1}', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 30),
          Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)), child: Text(q['question'], textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
          const SizedBox(height: 50),
          if (showAnswer) Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withValues(alpha: 0.5))), child: Column(children: [Text('الإجابة:', style: GoogleFonts.cairo(color: Colors.greenAccent, fontSize: 18)), Text(q['answer'], textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))])).animate().scale().fadeIn()
          else if (widget.isHost) ElevatedButton(onPressed: () { setState(() => showAnswer = true); _sync(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)), child: Text('كشف الإجابة 🔍', style: GoogleFonts.cairo(fontSize: 18, color: Colors.white))),
          const SizedBox(height: 40),
          if (showAnswer && widget.isHost) ElevatedButton(onPressed: () { setState(() { currentQuestionIndex++; showAnswer = false; }); _sync(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)), child: Text('السؤال التالي ➡️', style: GoogleFonts.cairo(fontSize: 18, color: Colors.white))),
        ],
      ),
    );
  }
}
