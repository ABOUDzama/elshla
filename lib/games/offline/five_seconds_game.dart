import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/offline_game_scaffold.dart';
import '../../services/raw_data_manager.dart';
import '../../services/score_service.dart';
import '../../data/five_seconds_data.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/game_intro_widget.dart';

class FiveSecondsGame extends StatefulWidget {
  const FiveSecondsGame({super.key});

  @override
  State<FiveSecondsGame> createState() => _FiveSecondsGameState();
}

class _FiveSecondsGameState extends State<FiveSecondsGame> {
  List<Map<String, dynamic>> questions = [];
  bool isLoadingData = true;
  bool _showIntro = true;

  final List<Map<String, dynamic>> _fallbackQuestions = fiveSecondsData;

  int currentQuestionIndex = 0;
  List<int> _shuffledIndices = [];
  int _pointer = 0;
  bool isTimerRunning = false;
  int timeLeft = 5;
  Timer? timer;
  bool showAnswer = false;
  bool isQuestionRevealed = false; // New flag for fair play
  bool _isGeneratingAi = false;
  final List<String> _aiHistory = [];

  void _generateAiQuestions() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent(
        'five_seconds',
        count: 15,
        history: _aiHistory,
      );
      List<Map<String, dynamic>> parsedQuestions = [];
      for (var item in content) {
        final question = item['question']?.toString() ?? '';
        if (question.isNotEmpty) {
          _aiHistory.add(question);
        }
        parsedQuestions.add({
          'question': item['question']?.toString() ?? 'سؤال غير معروف',
          'answers': ['...', '...', '...'],
          'icon': '⏱️',
        });
      }

      if (parsedQuestions.isNotEmpty) {
        setState(() {
          questions = parsedQuestions;
          _setupInitialGame();
          _pointer = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم توليد أسئلة جديدة بالذكاء الاصطناعي! ✨'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل توليد محتوى AI: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingAi = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData('five_seconds_game', {});

    if (rawData.containsKey('items') && rawData['items'] is List) {
      List<Map<String, dynamic>> parsedQuestions = [];
      for (var item in rawData['items']) {
        if (item is String) {
          parsedQuestions.add({
            'question': item,
            'answers': ['...', '...', '...'],
            'icon': '⏱️',
          });
        } else if (item is Map) {
          parsedQuestions.add({
            'question': item['question']?.toString() ?? 'سؤال غير معروف',
            'answers': item['answers'] is List
                ? List<String>.from(item['answers'])
                : ['...', '...', '...'],
            'icon': item['icon']?.toString() ?? '⏱️',
          });
        }
      }

      if (parsedQuestions.isNotEmpty) {
        if (mounted) {
          setState(() {
            questions = parsedQuestions;
            _setupInitialGame();
            isLoadingData = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        questions = _fallbackQuestions;
        _setupInitialGame();
        isLoadingData = false;
      });
    }
  }

  void _setupInitialGame() {
    _shuffledIndices = List.generate(questions.length, (i) => i)..shuffle();
    if (_shuffledIndices.isNotEmpty) {
      currentQuestionIndex = _shuffledIndices[0];
    }
  }

  void startTimer() {
    if (isTimerRunning) return;
    setState(() {
      isTimerRunning = true;
      isQuestionRevealed = true; // REVEAL ON START
      timeLeft = 5;
      showAnswer = false;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeLeft--;
      });
      if (timeLeft <= 0) {
        timer.cancel();
        setState(() {
          isTimerRunning = false;
          showAnswer = true;
        });
      }
    });
  }

  void nextQuestion() {
    setState(() {
      _pointer++;
      if (_pointer >= _shuffledIndices.length) {
        _shuffledIndices.shuffle();
        _pointer = 0;
      }
      currentQuestionIndex = _shuffledIndices[_pointer];
      showAnswer = false;
      isQuestionRevealed = false; // HIDE FOR NEXT
      timeLeft = 5;
      isTimerRunning = false;
    });
    timer?.cancel();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (isLoadingData || questions.isEmpty) {
      return OfflineGameScaffold(
        title: '⏱️ خمس ثواني',
        backgroundColor: const Color(0xFFAD1457), // Deeper Pink
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_showIntro) {
      return OfflineGameScaffold(
        title: '⏱️ خمس ثواني',
        backgroundColor: const Color(0xFFAD1457),
        body: GameIntroWidget(
          title: 'لعبة الـ 5 ثواني',
          icon: '⏱️',
          description:
              'قدامك 5 ثواني بس عشان تجاوب على السؤال! تفتكر هتلحق؟\n\nاللعبة دي محتاجة تركيز وسرعة رهيبة!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    return OfflineGameScaffold(
      title: '⏱️ خمس ثواني',
      backgroundColor: const Color(0xFFAD1457),
      actions: [
        if (SettingsService.isAiEnabled)
          IconButton(
            icon: _isGeneratingAi
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            tooltip: 'توليد بالذكاء الاصطناعي',
            onPressed: isTimerRunning || _isGeneratingAi
                ? null
                : _generateAiQuestions,
          ),
      ],
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFAD1457), Color(0xFF880E4F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Timer Circle
                        _buildTimerUI(),

                        const SizedBox(height: 30),

                        // Question Card
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: _buildQuestionCard(currentQuestion),
                        ),

                        const SizedBox(height: 30),

                        // Action Buttons
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerUI() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: isTimerRunning ? timeLeft / 5 : 1.0,
            strokeWidth: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              isTimerRunning && timeLeft <= 2
                  ? Colors.orangeAccent
                  : Colors.white,
            ),
          ),
        ),
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$timeLeft',
              style: GoogleFonts.cairo(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ).animate(target: isTimerRunning ? 1 : 0).shimmer(duration: 2.seconds);
  }

  Widget _buildQuestionCard(Map<String, dynamic> currentQuestion) {
    return Container(
      key: ValueKey(isQuestionRevealed ? currentQuestionIndex : -1),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isQuestionRevealed) ...[
            const Icon(
              Icons.help_outline_rounded,
              size: 80,
              color: Color(0xFFAD1457),
            ),
            const SizedBox(height: 20),
            Text(
              'استعد...',
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'اضغط ابدأ لإظهار السؤال',
              style: GoogleFonts.cairo(color: Colors.grey[600]),
            ),
          ] else ...[
            Text(currentQuestion['icon'], style: const TextStyle(fontSize: 70)),
            const SizedBox(height: 20),
            Text(
              currentQuestion['question'],
              style: GoogleFonts.cairo(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF880E4F),
              ),
              textAlign: TextAlign.center,
            ),
            if (showAnswer) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(thickness: 2),
              ),
              Text(
                'إجابات مقترحة:',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 12),
              _buildAnswersGrid(currentQuestion['answers']),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAnswersGrid(List<dynamic> answers) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: answers
          .map(
            (a) => Container(
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.pink.withValues(alpha: 0.1)),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(4),
              child: Text(
                a,
                style: GoogleFonts.cairo(
                  color: Colors.pink[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionButtons() {
    if (!isTimerRunning && !showAnswer) {
      return ElevatedButton(
        onPressed: startTimer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.pink,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
        ),
        child: Text(
          'ابدأ التحدي 🔥',
          style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds);
    }

    if (isTimerRunning) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final scoreService = ScoreService();
              if (scoreService.players.isNotEmpty) {
                scoreService.addScore(scoreService.players[0].name, 1);
              }
              timer?.cancel();
              setState(() {
                isTimerRunning = false;
                showAnswer = true;
              });
            },
            icon: const Icon(Icons.check_circle_outline, size: 32),
            label: Text(
              'جاوبت صح! ✅',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 15,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: nextQuestion,
              icon: const Icon(Icons.bolt_rounded, size: 30),
              label: Text(
                'التحدي التالي ➡️',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.pink[800],
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


