import 'package:flutter/material.dart';
import '../../widgets/game_intro_widget.dart';
import '../../screens/global_player_selection_screen.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/offline_game_scaffold.dart';
import '../../services/raw_data_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/who_am_i_data.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';

class WhoAmIGame extends StatefulWidget {
  const WhoAmIGame({super.key});

  @override
  State<WhoAmIGame> createState() => _WhoAmIGameState();
}

class _WhoAmIGameState extends State<WhoAmIGame> {
  List<Map<String, dynamic>> characters = [];
  bool _showIntro = true;
  bool isLoadingData = true;
  bool _isGeneratingAi = false;

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent(
        'who_am_i',
        count: 12,
        history: _aiHistory,
      );
      List<Map<String, dynamic>> parsedCharacters = [];
      for (var item in content) {
        String name = (item['name'] ?? item['character'] ?? 'مجهول').toString();
        if (name != 'مجهول') {
          _aiHistory.add(name);
        }
        // Handle multiple possible keys for better resilience
        List<String> hints = [];
        var hintsRaw = item['hints'] ?? item['clues'];
        if (hintsRaw is List) {
          hints = List<String>.from(hintsRaw.map((e) => e.toString()));
        } else {
          hints = ['لا يوجد معلومات إضافية'];
        }

        parsedCharacters.add({
          'name': name,
          'hints': hints,
          'icon': item['icon']?.toString() ?? '👤',
        });
      }

      if (_aiHistory.length > 50) {
        _aiHistory.removeRange(0, _aiHistory.length - 50);
      }

      if (parsedCharacters.isNotEmpty) {
        setState(() {
          characters = parsedCharacters;
          _shuffled = List.from(characters)..shuffle(_rand);
          _currentIndex = 0;
          _hintsRevealed = 0;
          _answered = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم توليد شخصيات جديدة بالذكاء الاصطناعي! ✨'),
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

  final List<Map<String, dynamic>> _fallbackCharacters = whoAmIData;

  List<Map<String, dynamic>> _shuffled = [];
  int _currentIndex = 0;
  int _hintsRevealed = 0;
  bool _answered = false;
  bool _showAllHints =
      false; // show all hints after reveal without changing _hintsRevealed
  final List<Map<String, dynamic>> _players = [];
  final TextEditingController _playerCtrl = TextEditingController();
  bool _gameStarted = false;
  int _currentPlayerTurn = 0;
  final Random _rand = Random();
  // Track last used character index to prevent repetition for next player
  int _lastUsedIndex = -1;
  final List<String> _aiHistory = [];

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData('who_am_i_game', {});

    if (rawData.containsKey('items') && rawData['items'] is List) {
      List<Map<String, dynamic>> parsedCharacters = [];
      for (var item in rawData['items']) {
        if (item is Map) {
          parsedCharacters.add({
            'name': item['name']?.toString() ?? 'مجهول',
            'hints': item['hints'] is List
                ? List<String>.from(item['hints'].map((e) => e.toString()))
                : ['لا يوجد معلومات إضافية'],
            'icon': item['icon']?.toString() ?? '👤',
          });
        }
      }

      if (parsedCharacters.isNotEmpty) {
        if (mounted) {
          setState(() {
            characters = parsedCharacters;
            _shuffled = List.from(characters)..shuffle(_rand);
            isLoadingData = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        characters = _fallbackCharacters;
        _shuffled = List.from(characters)..shuffle(_rand);
        isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _playerCtrl.dispose();
    super.dispose();
  }

  // Points = max(1, 5 - hintsRevealed): hint1→4, hint2→3, hint3→2, reveal→1
  int get _currentPoints =>
      (_hintsRevealed >= 1) ? (5 - _hintsRevealed).clamp(1, 4) : 4;

  void _nextCard({bool correct = false}) {
    setState(() {
      if (correct && _players.isNotEmpty) {
        _players[_currentPlayerTurn]['score'] =
            (_players[_currentPlayerTurn]['score'] as int) + _currentPoints;
      }
      _lastUsedIndex = _currentIndex;
      _currentPlayerTurn =
          (_currentPlayerTurn + 1) % _players.length.clamp(1, 99);
      // Move to next card, skip if same as last used
      _currentIndex = (_currentIndex + 1) % _shuffled.length;
      if (_currentIndex == _lastUsedIndex) {
        _currentIndex = (_currentIndex + 1) % _shuffled.length;
      }
      _hintsRevealed = 0;
      _answered = false;
      _showAllHints = false;
    });
  }

  void _revealHint() {
    if (_hintsRevealed < (_shuffled[_currentIndex]['hints'] as List).length) {
      setState(() => _hintsRevealed++);
    }
  }

  void _showAnswer() {
    setState(() {
      _answered = true;
      _showAllHints =
          true; // show all hints but keep _hintsRevealed for scoring
      // If no hint was revealed yet, count as 1 hint for scoring
      if (_hintsRevealed == 0) _hintsRevealed = 4; // revealed all = 1 point
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return OfflineGameScaffold(
        title: '🎭 مين أنا؟',
        backgroundColor: const Color(0xFF6A1B9A),
        body: GameIntroWidget(
          title: 'أنا مين؟',
          icon: '👤',
          description:
              'البس التاج وخلي أصحابك يوصفولك أنت مين! ممثل؟ لاعب كورة؟ ولا حيوان؟ لازم تخمن قبل ما الوقت يخلص!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (isLoadingData || characters.isEmpty) {
      return OfflineGameScaffold(
        title: '🎭 مين أنا؟',
        backgroundColor: const Color(0xFF6A1B9A),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!_gameStarted) {
      return OfflineGameScaffold(
        title: '🎭 مين أنا؟',
        backgroundColor: const Color(0xFF6A1B9A),
        actions: const [],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('🎭', style: TextStyle(fontSize: 80)).animate().scale(),
                const SizedBox(height: 16),
                Text(
                  'لعبة مين أنا؟',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                Text(
                  'الشاشة تظهر شخصية معينة\nوالمطلوب تخمينها من التلميحات!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GlobalPlayerSelectionScreen(
                              gameTitle: 'مين أنا؟',
                              minPlayers: 2,
                              onStartGame: (ctx, selectedPlayers) {
                                Navigator.pop(ctx); // Close selection screen
                                setState(() {
                                  _players.clear();
                                  _players.addAll(
                                    selectedPlayers.map(
                                      (name) => {'name': name, 'score': 0},
                                    ),
                                  );
                                  _currentPlayerTurn = 0;
                                  _gameStarted = true;
                                });
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people_alt, size: 28),
                      label: Text(
                        'اختار شلتك وابدأ!',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        shadowColor: Colors.amberAccent.withValues(alpha: 0.5),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 1.seconds,
                    ),
              ],
            ),
          ),
        ),
      );
    }

    final card = _shuffled[_currentIndex];
    final hints = card['hints'] as List<String>;

    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A),
      appBar: AppBar(
        title: const Text('🎭 مين أنا؟'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            icon: const Icon(Icons.exit_to_app, color: Colors.white70),
            onPressed: () => setState(() {
              _gameStarted = false;
              _players.clear();
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_players.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade900, Colors.purple.shade700],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _players.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    final isActive = i == _currentPlayerTurn;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.amberAccent.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isActive
                            ? Border.all(color: Colors.amberAccent, width: 2)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            p['name'],
                            style: GoogleFonts.cairo(
                              color: isActive
                                  ? Colors.amberAccent
                                  : Colors.white60,
                              fontWeight: isActive
                                  ? FontWeight.w900
                                  : FontWeight.normal,
                              fontSize: isActive ? 15 : 13,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 2),
                              Text(
                                '${p['score']}',
                                style: GoogleFonts.cairo(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: isActive ? 18 : 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (isActive)
                            Text(
                              'دوره الحين',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: Colors.amberAccent,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_players.isNotEmpty)
                        Text(
                          'دور: ${_players[_currentPlayerTurn]['name']}',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Character card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                                  card['icon'],
                                  style: const TextStyle(fontSize: 60),
                                )
                                .animate(key: ValueKey(_currentIndex))
                                .scale(duration: 300.ms),
                            const SizedBox(height: 12),
                            if (_answered)
                              Text(
                                card['name'],
                                style: GoogleFonts.cairo(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF6A1B9A),
                                ),
                              ).animate().fadeIn().scale(
                                curve: Curves.elasticOut,
                              )
                            else
                              Text(
                                '???',
                                style: GoogleFonts.cairo(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            const Divider(height: 30),
                            // Hints - use _showAllHints to show all after reveal
                            ...List.generate(
                              _showAllHints ? hints.length : _hintsRevealed,
                              (i) =>
                                  Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.lightbulb,
                                              color: i < _hintsRevealed
                                                  ? Colors.amber.shade600
                                                  : Colors.grey.shade400,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                hints[i],
                                                style: GoogleFonts.cairo(
                                                  fontSize: 18,
                                                  color: i < _hintsRevealed
                                                      ? Colors.black87
                                                      : Colors.grey.shade500,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .animate(delay: (i * 200).ms)
                                      .fadeIn()
                                      .moveX(begin: -20),
                            ),
                            if (_hintsRevealed == 0 && !_showAllHints)
                              Text(
                                'اضغط "تلميح" لتبدأ!',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            if (_hintsRevealed > 0 && !_answered)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.amber.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'تلميح $_hintsRevealed من ${hints.length} • النقاط المتاحة: $_currentPoints ⭐',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: Colors.amber.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ).animate(key: ValueKey(_currentIndex)).fadeIn().moveY(begin: 20),
                      const SizedBox(height: 24),
                      if (!_answered) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _hintsRevealed < hints.length
                                    ? _revealHint
                                    : null,
                                icon: const Icon(Icons.lightbulb_outline),
                                label: Text(
                                  'تلميح 💡',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amberAccent,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showAnswer,
                                icon: const Icon(Icons.visibility),
                                label: Text(
                                  'اكشف الجواب',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6A1B9A),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        if (_players.isNotEmpty) ...[
                          Text(
                            'هل عرف ${_players[_currentPlayerTurn]['name']}؟',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _nextCard(correct: true),
                                  icon: const Icon(Icons.check_circle),
                                  label: Text(
                                    'عرفها ✅\n+${(4 - _hintsRevealed.clamp(0, 3))} نقط',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _nextCard(correct: false),
                                  icon: const Icon(Icons.cancel),
                                  label: Text(
                                    'ما عرفش ❌',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          ElevatedButton.icon(
                            onPressed: () => _nextCard(),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(
                              'شخصية تانية 🔄',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                              foregroundColor: Colors.black87,
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


