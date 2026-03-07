import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/base_game_scaffold.dart';
import '../services/raw_data_manager.dart';
import '../services/online_data_service.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../widgets/game_intro_widget.dart';

class OddOneOut extends StatefulWidget {
  const OddOneOut({super.key});

  @override
  State<OddOneOut> createState() => _OddOneOutState();
}

class _OddOneOutState extends State<OddOneOut> {
  List<Map<String, dynamic>> questions = [];
  bool isLoadingData = true;
  bool _showIntro = true;
  bool _isGeneratingAi = false;

  final List<Map<String, dynamic>> _fallbackQuestions = [
    {
      'items': ['تفاح', 'موز', 'برتقال', 'مانجو', 'فراولة', 'خيار'],
      'oddOne': 'خيار',
      'reason': 'كلهم فواكه ما عدا الخيار خضار 🥕',
      'icon': '🍎',
    },
    {
      'items': ['أسد', 'نمر', 'فهد', 'قطة', 'كلب', 'تمساح'],
      'oddOne': 'تمساح',
      'reason': 'كلهم ثدييات ما عدا التمساح زواحف 🐊',
      'icon': '🦁',
    },
    {
      'items': ['مصر', 'السعودية', 'الكويت', 'الإمارات', 'الأردن', 'فرنسا'],
      'oddOne': 'فرنسا',
      'reason': 'كلهم دول عربية ما عدا فرنسا دولة أوروبية 🇫🇷',
      'icon': '🌍',
    },
  ];

  int currentIndex = 0;
  List<int> _shuffledIndices = [];
  int _pointer = 0;
  String? selectedAnswer;
  bool answered = false;
  int lives = 3;
  int timeLeft = 10;
  Timer? _timer;
  bool isGameOver = false;

  late List<String> _shuffledItems;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData('odd_one_out', {});
    List<Map<String, dynamic>> parsedQuestions = [];

    if (rawData.containsKey('questions') && rawData['questions'] is List) {
      for (var item in rawData['questions']) {
        if (item is Map && item['items'] is List) {
          parsedQuestions.add({
            'items': List<String>.from(item['items'].map((e) => e.toString())),
            'oddOne': item['oddOne']?.toString() ?? '',
            'reason': item['reason']?.toString() ?? '',
            'icon': item['icon']?.toString() ?? '❓',
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        questions = parsedQuestions.isNotEmpty
            ? parsedQuestions
            : List.from(_fallbackQuestions);
        _shuffledIndices = List.generate(questions.length, (i) => i)..shuffle();
        _pointer = 0;
        currentIndex = _shuffledIndices[0];
        _prepareQuestion();
        isLoadingData = false;
      });
    }
  }

  void _prepareQuestion() {
    final q = questions[currentIndex];
    List<String> items = List<String>.from(q['items']);

    // Only add decoys if we don't already have 6 items (related items)
    if (items.length < 6) {
      List<String> decoys = [];
      // Try to find decoys from other questions, but this is still "unrelated"
      // The AI will provide 6 related items, which is the preferred solution.
      for (var otherQ in questions) {
        if (otherQ == q) continue;
        for (var item in otherQ['items']) {
          if (!items.contains(item) && !decoys.contains(item)) {
            decoys.add(item);
          }
          if (decoys.length + items.length >= 6) break;
        }
        if (decoys.length + items.length >= 6) break;
      }
      items.addAll(decoys);
    }

    _shuffledItems = items..shuffle();
    timeLeft = 10;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (answered || isGameOver) return;
    setState(() {
      answered = true;
      lives--;
      if (lives <= 0) isGameOver = true;
    });
  }

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent(
        'odd_one_out',
        count: 10,
      );
      List<Map<String, dynamic>> aiQuestions = [];

      for (var item in content) {
        if (item['items'] is List && item['oddOne'] != null) {
          aiQuestions.add({
            'items': List<String>.from(item['items'].map((e) => e.toString())),
            'oddOne': item['oddOne'].toString(),
            'reason': item['reason']?.toString() ?? 'لا يوجد سبب محدد',
            'icon': item['icon']?.toString() ?? '✨',
          });
        }
      }

      if (aiQuestions.isNotEmpty) {
        setState(() {
          questions = aiQuestions;
          _shuffledIndices = List.generate(questions.length, (i) => i)
            ..shuffle();
          _pointer = 0;
          currentIndex = _shuffledIndices[0];
          selectedAnswer = null;
          answered = false;
          lives = 3;
          isGameOver = false;
          _prepareQuestion();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم توليد أسئلة ذكية وجديدة! 🎯'),
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

  Future<void> _forceUpdateData() async {
    setState(() => isLoadingData = true);
    final result = await OnlineDataService.syncData(force: true);

    if (mounted) {
      if (result == 'success' || result == 'already_synced') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث أسئلة اللعبة بنجاح! 🔄'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadGameData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل التحديث، تأكد من اتصالك بالإنترنت 🌐'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoadingData = false);
      }
    }
  }

  void _pickAnswer(String answer) {
    if (answered || isGameOver) return;
    _timer?.cancel();
    setState(() {
      selectedAnswer = answer;
      answered = true;
      if (answer != questions[currentIndex]['oddOne']) {
        lives--;
        if (lives <= 0) isGameOver = true;
      }
    });
  }

  void nextQuestion() {
    if (isGameOver) {
      _restartGame();
      return;
    }
    setState(() {
      _pointer++;
      if (_pointer >= _shuffledIndices.length) {
        _shuffledIndices.shuffle();
        _pointer = 0;
      }
      currentIndex = _shuffledIndices[_pointer];
      selectedAnswer = null;
      answered = false;
      _prepareQuestion();
    });
  }

  void _restartGame() {
    setState(() {
      lives = 3;
      isGameOver = false;
      _pointer = 0;
      _shuffledIndices.shuffle();
      currentIndex = _shuffledIndices[0];
      selectedAnswer = null;
      answered = false;
      _prepareQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return BaseGameScaffold(
        title: '🎯 طلع الغريب',
        backgroundColor: Colors.amber.shade900,
        body: GameIntroWidget(
          title: 'طلع الغريب',
          icon: '🔎',
          description:
              'هيظهرلك مجموعة حاجات، فيهم واحدة بس مختلفة ومكانها مش معاهم! تقدر تكتشفها في أقل من 10 ثواني؟\n\nاللعبة اللي بتمتحن ذكاءك وسرعة بديهتك!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (isLoadingData || questions.isEmpty) {
      return BaseGameScaffold(
        title: '🎯 الاختيار الثالث',
        backgroundColor: Colors.amber.shade900,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final q = questions[currentIndex];
    final String oddOne = q['oddOne'] as String;

    return BaseGameScaffold(
      title: '🎯 الاختيار الثالث',
      backgroundColor: Colors.amber.shade900,
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
            onPressed: _isGeneratingAi ? null : _generateAiContent,
          ),
        IconButton(
          icon: const Icon(Icons.sync),
          tooltip: 'تحديث الأسئلة',
          onPressed: _forceUpdateData,
        ),
      ],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Lives and Timer Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(3, (index) {
                          return Icon(
                            index < lives
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.redAccent,
                            size: 28,
                          );
                        }),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '00:${timeLeft.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: timeLeft <= 3
                                ? Colors.redAccent
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Timer Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: timeLeft / 10,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        timeLeft <= 3 ? Colors.redAccent : Colors.tealAccent,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'أي واحد مش زي الباقيين؟',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black38, blurRadius: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 2x3 Grid of choices
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 2.2,
                            children: _shuffledItems.map((item) {
                              Color cardColor = Colors.white;
                              Color textColor = Colors.amber.shade900;
                              IconData? icon;

                              if (answered || isGameOver) {
                                if (item == oddOne) {
                                  cardColor = Colors.green.shade400;
                                  textColor = Colors.white;
                                  icon = Icons.check_circle;
                                } else if (item == selectedAnswer) {
                                  cardColor = Colors.red.shade400;
                                  textColor = Colors.white;
                                  icon = Icons.cancel;
                                } else {
                                  cardColor = Colors.white.withValues(
                                    alpha: 0.5,
                                  );
                                  textColor = Colors.white70;
                                }
                              }

                              return GestureDetector(
                                    onTap: () => _pickAnswer(item),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if ((answered || isGameOver) &&
                                                icon != null)
                                              Icon(
                                                icon,
                                                color: textColor,
                                                size: 18,
                                              ),
                                            if ((answered || isGameOver) &&
                                                icon != null)
                                              const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                item,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate(
                                    delay:
                                        (_shuffledItems.indexOf(item) * 80).ms,
                                  )
                                  .fadeIn()
                                  .scale(
                                    begin: const Offset(0.85, 0.85),
                                    end: const Offset(1, 1),
                                  );
                            }).toList(),
                          ),
                          if (answered && !isGameOver) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(18),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: selectedAnswer == oddOne
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    selectedAnswer == oddOne
                                        ? '🎉 صح! الإجابة هي: $oddOne'
                                        : (selectedAnswer == null
                                              ? '⏰ خلص الوقت! الإجابة هي: $oddOne'
                                              : '❌ غلط! الإجابة الصح هي: $oddOne'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    q['reason'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().moveY(begin: 20, end: 0),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: nextQuestion,
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text(
                                'سؤال جديد',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.amber.shade900,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ).animate().fadeIn(),
                          ] else if (!isGameOver) ...[
                            const SizedBox(height: 20),
                            Text(
                              'اختار الإجابة الغريبة بسرعة! 👆',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Game Over Overlay
            if (isGameOver)
              Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💔', style: TextStyle(fontSize: 80)),
                      const SizedBox(height: 20),
                      const Text(
                        'خسرت كل المحاولات!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: _restartGame,
                        icon: const Icon(Icons.refresh),
                        label: const Text('حاول تاني'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }
}
