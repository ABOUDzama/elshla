import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/game_intro_widget.dart';
import '../widgets/base_game_scaffold.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../services/online_data_service.dart';
import '../services/raw_data_manager.dart';
import '../data/truth_or_lie_data.dart';

class TruthOrLieGame extends StatefulWidget {
  const TruthOrLieGame({super.key});

  @override
  State<TruthOrLieGame> createState() => _TruthOrLieGameState();
}

class _TruthOrLieGameState extends State<TruthOrLieGame> {
  int _currentIndex = 0;
  bool _showExplanation = false;
  bool? _isCorrect;
  String _displayedText = "";
  Timer? _timer;
  int _charIndex = 0;
  List<int> _shuffledIndices = [];
  bool _showIntro = true;
  bool _isGeneratingAi = false;
  List<Map<String, dynamic>> _currentData = [];

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent(
        'truth_or_lie',
        count: 15,
      );
      List<Map<String, dynamic>> aiFacts = [];
      for (var item in content) {
        aiFacts.add({
          'statement': item['statement']?.toString() ?? '',
          'isTrue': item['is_true'] ?? true,
          'explanation': item['explanation']?.toString() ?? '',
          'icon': item['icon']?.toString() ?? '💡',
        });
      }

      if (aiFacts.isNotEmpty) {
        setState(() {
          _currentData = aiFacts;
          _shuffledIndices = List.generate(_currentData.length, (i) => i)
            ..shuffle();
          _currentIndex = 0;
          _showExplanation = false;
          _isCorrect = null;
        });
        _startTextAnimation();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم توليد حقائق جديدة بالذكاء الاصطناعي! ✨'),
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
    final result = await OnlineDataService.syncData(force: true);
    if (mounted) {
      if (result == 'success' || result == 'already_synced') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات اللعبة! 🔄'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadLocalData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل التحديث 🌐'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadLocalData() async {
    final rawData = await RawDataManager.getGameData('truth_or_lie', {});
    if (rawData.containsKey('items') && rawData['items'] is List) {
      List<Map<String, dynamic>> parsed = [];
      for (var item in rawData['items']) {
        if (item is Map) {
          parsed.add({
            'statement': item['statement']?.toString() ?? '',
            'isTrue': item['isTrue'] ?? true,
            'explanation': item['explanation']?.toString() ?? '',
            'icon': item['icon']?.toString() ?? '💡',
          });
        }
      }
      if (parsed.isNotEmpty) {
        setState(() {
          _currentData = parsed;
          _shuffledIndices = List.generate(_currentData.length, (i) => i)
            ..shuffle();
          _currentIndex = 0;
        });
        _startTextAnimation();
        return;
      }
    }

    setState(() {
      _currentData = truthOrLieData;
      _shuffledIndices = List.generate(_currentData.length, (i) => i)
        ..shuffle();
      _currentIndex = 0;
    });
    _startTextAnimation();
  }

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTextAnimation() {
    _displayedText = "";
    _charIndex = 0;
    _timer?.cancel();

    if (_shuffledIndices.isEmpty) return;

    final actualIndex = _shuffledIndices[_currentIndex];
    final statement = _currentData[actualIndex]['statement'] as String;

    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (_charIndex < statement.length) {
        if (mounted) {
          setState(() {
            _displayedText += statement[_charIndex];
            _charIndex++;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _handleAnswer(bool userSaidTruth) {
    if (_showExplanation) return;

    _timer?.cancel();
    final actualIndex = _shuffledIndices[_currentIndex];
    final bool isActuallyTrue = _currentData[actualIndex]['isTrue'];

    setState(() {
      _displayedText = _currentData[actualIndex]['statement'];
      _showExplanation = true;
      _isCorrect = (userSaidTruth == isActuallyTrue);
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      if (_currentIndex >= _shuffledIndices.length) {
        _currentIndex = 0;
        _shuffledIndices.shuffle();
      }
      _showExplanation = false;
      _isCorrect = null;
    });
    _startTextAnimation();
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return BaseGameScaffold(
        title: '🤔 حقيقة أو هبد؟',
        backgroundColor: const Color(0xFF0F172A),
        body: GameIntroWidget(
          title: 'حقيقة أو هبد؟',
          icon: '🤔',
          description:
              'يا ترى المعلومة دي حقيقة بجد؟ ولا مجرد هبد؟ شغل دماغك وكشف الكدب من الحقيقة!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (_currentData.isEmpty || _shuffledIndices.isEmpty) {
      return BaseGameScaffold(
        title: '🤔 حقيقة أو هبد؟',
        backgroundColor: const Color(0xFF0F172A),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final actualIndex = _shuffledIndices[_currentIndex];
    final currentFact = _currentData[actualIndex];

    return BaseGameScaffold(
      title: '🤔 حقيقة أو هبد؟',
      backgroundColor: const Color(0xFF0F172A),
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
            onPressed: _isGeneratingAi ? null : _generateAiContent,
          ),
        IconButton(
          icon: const Icon(Icons.sync),
          tooltip: 'تحديث البيانات',
          onPressed: _isGeneratingAi ? null : _forceUpdateData,
        ),
      ],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Center(
                  child: Text(
                    currentFact['icon'],
                    style: const TextStyle(fontSize: 60),
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 40),

              // Statement
              Container(
                constraints: const BoxConstraints(minHeight: 120),
                child: Text(
                  _displayedText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Buttons
              if (!_showExplanation)
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'حقـيقة',
                        color: const Color(0xFF14B8A6),
                        onPressed: () => _handleAnswer(true),
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionButton(
                        label: 'هبـد',
                        color: const Color(0xFFF43F5E),
                        onPressed: () => _handleAnswer(false),
                        icon: Icons.cancel_outlined,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              // Explanation
              if (_showExplanation)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isCorrect!
                            ? Colors.teal.withAlpha(50)
                            : Colors.red.withAlpha(50),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isCorrect! ? Colors.teal : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCorrect!
                                    ? Icons.verified_rounded
                                    : Icons.cancel_rounded,
                                color: _isCorrect!
                                    ? Colors.tealAccent
                                    : Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isCorrect!
                                    ? (currentFact['isTrue']
                                          ? 'صح.. طلعت حقيقة!'
                                          : 'صح.. ده هبد فعلاً!')
                                    : (currentFact['isTrue']
                                          ? 'غلط.. دي حقيقة!'
                                          : 'غلط.. ده هبد!'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _isCorrect!
                                      ? Colors.tealAccent
                                      : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentFact['explanation'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _nextQuestion,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('اللي بعده'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final IconData icon;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(75),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
