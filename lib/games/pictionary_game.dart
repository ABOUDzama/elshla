import 'package:flutter/material.dart';
import '../screens/global_player_selection_screen.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/base_game_scaffold.dart';
import '../services/raw_data_manager.dart';
import '../services/online_data_service.dart';
import '../widgets/premium_loading_indicator.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../widgets/game_intro_widget.dart';

// ─── Drawing model ───────────────────────────────
class DrawPoint {
  final Offset? point;
  final Color color;
  final double strokeWidth;
  DrawPoint(this.point, this.color, this.strokeWidth);
}

class DrawingPainter extends CustomPainter {
  final List<DrawPoint> points;
  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].point != null && points[i + 1].point != null) {
        paint
          ..color = points[i].color
          ..strokeWidth = points[i].strokeWidth;
        canvas.drawLine(points[i].point!, points[i + 1].point!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter old) => old.points.length != points.length;
}

// ─── Game ──────────────────────────────────────────────────────────
class PictionaryGame extends StatefulWidget {
  const PictionaryGame({super.key});

  @override
  State<PictionaryGame> createState() => _PictionaryGameState();
}

class _PictionaryGameState extends State<PictionaryGame> {
  List<Map<String, String>> wordCategories = [];
  bool isLoadingData = true;
  bool _showIntro = true;
  bool _isGeneratingAi = false;

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent('pictionary', count: 20);
      List<Map<String, String>> aiWords = [];
      for (var item in content) {
        aiWords.add({
          'word': item['word']?.toString() ?? '',
          'category': item['category']?.toString() ?? 'عام',
        });
      }

      if (aiWords.isNotEmpty) {
        setState(() {
          wordCategories.addAll(aiWords);
        });
        if (!_started && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم توليد مفردات جديدة بالذكاء الاصطناعي! ✨'),
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

  final List<Map<String, String>> _fallbackWordCategories = [
    {'word': 'قطة', 'category': '🐾 حيوانات'},
    {'word': 'كلب', 'category': '🐾 حيوانات'},
    {'word': 'أسد', 'category': '🐾 حيوانات'},
    {'word': 'ديناصور', 'category': '🐾 حيوانات'},
    {'word': 'بطة', 'category': '🐾 حيوانات'},
    {'word': 'فيل', 'category': '🐾 حيوانات'},
    {'word': 'زرافة', 'category': '🐾 حيوانات'},
    {'word': 'خنفسة', 'category': '🐾 حيوانات'},
    {'word': 'أرنب', 'category': '🐾 حيوانات'},
    {'word': 'نمر', 'category': '🐾 حيوانات'},
    {'word': 'قرد', 'category': '🐾 حيوانات'},
    {'word': 'دلفين', 'category': '🐾 حيوانات'},
    {'word': 'خرتيت', 'category': '🐾 حيوانات'},
    {'word': 'طيطوى', 'category': '🐾 حيوانات'},
    {'word': 'سلحفاة', 'category': '🐾 حيوانات'},
    {'word': 'تمساح', 'category': '🐾 حيوانات'},
    {'word': 'بيتزا', 'category': '🍕 أكل'},
    {'word': 'كيكة', 'category': '🍕 أكل'},
    {'word': 'برغر', 'category': '🍕 أكل'},
    {'word': 'آيس كريم', 'category': '🍕 أكل'},
    {'word': 'شاورما', 'category': '🍕 أكل'},
    {'word': 'كنافة', 'category': '🍕 أكل'},
    {'word': 'سوشي', 'category': '🍕 أكل'},
    {'word': 'لازانيا', 'category': '🍕 أكل'},
    {'word': 'كشري', 'category': '🍕 أكل'},
    {'word': 'فلافل', 'category': '🍕 أكل'},
    {'word': 'قطايف', 'category': '🍕 أكل'},
    {'word': 'هوت دوج', 'category': '🍕 أكل'},
    {'word': 'موبايل', 'category': '📱 تكنولوجيا'},
    {'word': 'كمبيوتر', 'category': '📱 تكنولوجيا'},
    {'word': 'روبوت', 'category': '📱 تكنولوجيا'},
    {'word': 'كاميرا', 'category': '📱 تكنولوجيا'},
    {'word': 'تلفزيون', 'category': '📱 تكنولوجيا'},
    {'word': 'سماعة', 'category': '📱 تكنولوجيا'},
    {'word': 'طيارة', 'category': '🚗 مواصلات'},
    {'word': 'عربية', 'category': '🚗 مواصلات'},
    {'word': 'دراجة', 'category': '🚗 مواصلات'},
    {'word': 'قطر', 'category': '🚗 مواصلات'},
    {'word': 'مركب', 'category': '🚗 مواصلات'},
    {'word': 'دراجة نارية', 'category': '🚗 مواصلات'},
    {'word': 'مروحية', 'category': '🚗 مواصلات'},
    {'word': 'صاروخ', 'category': '🚗 مواصلات'},
    {'word': 'ساعة', 'category': '🏠 أشياء'},
    {'word': 'مظلة', 'category': '🏠 أشياء'},
    {'word': 'مفتاح', 'category': '🏠 أشياء'},
    {'word': 'كرسي', 'category': '🏠 أشياء'},
    {'word': 'مرآة', 'category': '🏠 أشياء'},
    {'word': 'منزل', 'category': '🏠 أشياء'},
    {'word': 'حقيبة', 'category': '🏠 أشياء'},
    {'word': 'مصباح', 'category': '🏠 أشياء'},
    {'word': 'قلم', 'category': '🏠 أشياء'},
    {'word': 'شمس', 'category': '🌍 طبيعة'},
    {'word': 'قمر', 'category': '🌍 طبيعة'},
    {'word': 'نجمة', 'category': '🌍 طبيعة'},
    {'word': 'جبل', 'category': '🌍 طبيعة'},
    {'word': 'بحر', 'category': '🌍 طبيعة'},
    {'word': 'نخلة', 'category': '🌍 طبيعة'},
    {'word': 'شجرة', 'category': '🌍 طبيعة'},
    {'word': 'مطر', 'category': '🌍 طبيعة'},
    {'word': 'برق', 'category': '🌍 طبيعة'},
    {'word': 'كرة قدم', 'category': '⚽ رياضة'},
    {'word': 'سباحة', 'category': '⚽ رياضة'},
    {'word': 'ملاكمة', 'category': '⚽ رياضة'},
    {'word': 'تنس', 'category': '⚽ رياضة'},
    {'word': 'كرة سلة', 'category': '⚽ رياضة'},
    {'word': 'غوص', 'category': '⚽ رياضة'},
    {'word': 'بتمان', 'category': '🎭 شخصيات'},
    {'word': 'سبايدرمان', 'category': '🎭 شخصيات'},
    {'word': 'سبونج بوب', 'category': '🎭 شخصيات'},
    {'word': 'ميكي ماوس', 'category': '🎭 شخصيات'},
    {'word': 'شخص يغني', 'category': '🎭 أفعال'},
    {'word': 'شخص ينام', 'category': '🎭 أفعال'},
    {'word': 'شخص يطير', 'category': '🎭 أفعال'},
    {'word': 'شخص يبكي', 'category': '🎭 أفعال'},
    {'word': 'شخص يرقص', 'category': '🎭 أفعال'},
    {'word': 'شخص يسبح', 'category': '🎭 أفعال'},
    {'word': 'شخص يأكل', 'category': '🎭 أفعال'},
    {'word': 'شخص يقفز', 'category': '🎭 أفعال'},
  ];

  List<DrawPoint> _points = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 5.0;
  Map<String, String>? _currentWord;
  bool _drawing = false;
  bool _guessing = false; // Phase where guesser types answer
  bool _showResult = false;
  String _guessText = '';
  bool? _guessCorrect;
  final List<Map<String, dynamic>> _players = [];
  int _drawerIndex = 0;
  final _rand = Random();
  final _playerCtrl = TextEditingController();
  final _guessCtrl = TextEditingController();
  bool _started = false;
  final Set<int> _usedWordIndices = {};

  final List<Color> _palette = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.yellow,
    Colors.brown,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData('pictionary_game', {});

    if (rawData.containsKey('items') && rawData['items'] is List) {
      List<Map<String, String>> parsedWords = [];
      for (var item in rawData['items']) {
        if (item is Map) {
          parsedWords.add({
            'word': item['word']?.toString() ?? '',
            'category': item['category']?.toString() ?? '',
          });
        }
      }

      if (parsedWords.isNotEmpty) {
        if (mounted) {
          setState(() {
            wordCategories = parsedWords;
            isLoadingData = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        wordCategories = _fallbackWordCategories;
        isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _playerCtrl.dispose();
    _guessCtrl.dispose();
    super.dispose();
  }

  void _pickWord() {
    if (SettingsService.isAiEnabled &&
        _started &&
        !_isGeneratingAi &&
        _usedWordIndices.length >= wordCategories.length - 2) {
      _generateAiContent(); // Auto-fetch in background
    }

    if (_usedWordIndices.length >= wordCategories.length) {
      _usedWordIndices.clear();
    }
    int idx;
    do {
      idx = _rand.nextInt(wordCategories.length);
    } while (_usedWordIndices.contains(idx));
    _usedWordIndices.add(idx);
    setState(() {
      _currentWord = wordCategories[idx];
      _points = [];
      _drawing = true;
      _guessing = false;
      _showResult = false;
      _guessText = '';
      _guessCorrect = null;
    });
    _guessCtrl.clear();
  }

  void _doneDrawing() {
    // Drawer finishes and passes phone to guesser
    setState(() {
      _drawing = false;
      _guessing = true;
    });
  }

  void _submitGuess() {
    final guess = _guessCtrl.text.trim();
    if (guess.isEmpty) return;
    // Pass phone back to drawer to decide: we just show what was guessed
    setState(() {
      _guessText = guess;
      _guessCorrect = null; // Drawer decides
      _showResult = true;
      _guessing = false;
    });
  }

  void _drawerDecide(bool correct) {
    setState(() {
      _guessCorrect = correct;
      if (correct && _players.isNotEmpty) {
        // Guesser gets 1 point
        final guessIdx = (_drawerIndex + 1) % _players.length;
        _players[guessIdx]['score'] = (_players[guessIdx]['score'] as int) + 1;
      }
    });
  }

  void _nextRound() {
    if (_players.isNotEmpty) {
      setState(() {
        _drawerIndex = (_drawerIndex + 1) % _players.length;
      });
    }
    _pickWord();
  }

  String get _drawerName => _players.isNotEmpty
      ? _players[_drawerIndex % _players.length]['name']
      : 'الرسام';

  String get _guesserName => _players.length > 1
      ? _players[(_drawerIndex + 1) % _players.length]['name']
      : 'المخمن';

  Future<void> _forceUpdateData() async {
    setState(() {
      isLoadingData = true;
    });

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
        setState(() {
          isLoadingData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return BaseGameScaffold(
        title: '🎨 ارسم وخمّن',
        backgroundColor: const Color(0xFF0D47A1),
        body: GameIntroWidget(
          title: 'ارسم وخمّن',
          icon: '🎨',
          description:
              'واحد يرسم والكل يخمّن! اللعبة اللي هتكشف مواهبك المدفونة في الرسم (أو الكارثية!)... مين هيقدر يوصّل المعلومة بالرسم؟',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (isLoadingData || wordCategories.isEmpty) {
      return BaseGameScaffold(
        title: '🎨 ارسم وخمّن',
        backgroundColor: const Color(0xFF0D47A1),
        body: const PremiumLoadingIndicator(message: 'جاري تجهيز الألوان...'),
      );
    }

    if (!_started) {
      return BaseGameScaffold(
        title: '🎨 ارسم وخمّن',
        backgroundColor: const Color(0xFF0D47A1),
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
            tooltip: 'تحديث المواضيع',
            onPressed: _isGeneratingAi ? null : _forceUpdateData,
          ),
        ],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  '🎨',
                  style: TextStyle(fontSize: 90),
                ).animate().scale(),
                const SizedBox(height: 12),
                Text(
                  'ارسم وخمّن!',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                Text(
                  'واحد يرسم والباقي يخمّن!\nمين أسرع واحد هيعرف الكلمة؟ 🎨',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 15, color: Colors.white70),
                ),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GlobalPlayerSelectionScreen(
                              gameTitle: 'ارسم وخمّن',
                              minPlayers: 2,
                              onStartGame: (ctx, selectedPlayers) {
                                Navigator.pop(ctx);
                                setState(() {
                                  _players.clear();
                                  _players.addAll(
                                    selectedPlayers.map(
                                      (name) => {'name': name, 'score': 0},
                                    ),
                                  );
                                  _drawerIndex = 0;
                                  _started = true;
                                  _pickWord();
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
                        backgroundColor: Colors.lightBlueAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        shadowColor: Colors.lightBlueAccent.withValues(
                          alpha: 0.5,
                        ),
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

    // ─── DRAWING PHASE ───────────────────────────────────────
    if (_drawing && _currentWord != null) {
      return BaseGameScaffold(
        title: '🎨 ارسم وخمّن',
        backgroundColor: const Color(0xFF0D47A1),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'تحديث المواضيع',
            onPressed: _forceUpdateData,
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white70),
            onPressed: () {
              setState(() {
                _started = false;
                _players.clear();
              });
            },
          ),
        ],
        body: SafeArea(
          child: Column(
            children: [
              // Who is drawing
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.shade700.withAlpha(50),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🎨 $_drawerName يرسم',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'الكلمة: ${_currentWord!['word']} (الرسام بس)',
                        style: GoogleFonts.cairo(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category only
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'الفئة: ${_currentWord!['category']}',
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                ),
              ),

              // Drawing canvas
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 10),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GestureDetector(
                      onPanStart: (d) => setState(
                        () => _points.add(
                          DrawPoint(
                            d.localPosition,
                            _selectedColor,
                            _strokeWidth,
                          ),
                        ),
                      ),
                      onPanUpdate: (d) => setState(
                        () => _points.add(
                          DrawPoint(
                            d.localPosition,
                            _selectedColor,
                            _strokeWidth,
                          ),
                        ),
                      ),
                      onPanEnd: (_) => setState(
                        () => _points.add(
                          DrawPoint(null, _selectedColor, _strokeWidth),
                        ),
                      ),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: DrawingPainter(_points),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Color palette
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ..._palette.map(
                      (color) => GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _selectedColor == color ? 38 : 28,
                          height: _selectedColor == color ? 38 : 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color
                                  ? Colors.white
                                  : Colors.white30,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => _points.clear()),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.line_weight,
                      color: Colors.white54,
                      size: 18,
                    ),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 2,
                        max: 25,
                        onChanged: (v) => setState(() => _strokeWidth = v),
                        activeColor: Colors.lightBlueAccent,
                      ),
                    ),
                  ],
                ),
              ),

              // Done drawing button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: _doneDrawing,
                  icon: const Icon(Icons.send_rounded, size: 22),
                  label: Text(
                    'خلصت الرسم! دي التلفون للمخمن 📱',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ─── GUESSING PHASE ──────────────────────────────────────
    if (_guessing) {
      return BaseGameScaffold(
        title: '🎨 ارسم وخمّن',
        backgroundColor: const Color(0xFF0D47A1),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD600), Color(0xFFFFA000)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    'دور المخمّن: $_guesserName',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) => RepaintBoundary(
                      child: CustomPaint(
                        painter: DrawingPainter(_points),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _guessCtrl,
                autofocus: false,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب تخمينك هنا...',
                  hintStyle: GoogleFonts.cairo(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _submitGuess(),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton.icon(
                onPressed: _submitGuess,
                icon: const Icon(Icons.check_circle, size: 24),
                label: Text(
                  'تأكيد الإجابة ✅',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_showResult) {
      final isCorrect = _guessCorrect == true;
      final drawerName = _drawerName;
      Color bgColor = _guessCorrect == null
          ? const Color(0xFF1A237E) // neutral blue while drawer decides
          : (isCorrect ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C));
      return BaseGameScaffold(
        title: '🎨 ارسم وخمّن',
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── Drawer decides ───
                  if (_guessCorrect == null) ...[
                    const Text(
                      '🎨',
                      style: TextStyle(fontSize: 80),
                    ).animate().scale(),
                    const SizedBox(height: 16),
                    Text(
                      'دي للراسم ($drawerName)',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'الفئة: ${_currentWord!['category']}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الكلمة الصحيحة:',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        color: Colors.white60,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amberAccent),
                      ),
                      child: Text(
                        _currentWord!['word']!,
                        style: GoogleFonts.cairo(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'إجابة $_guesserName:',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        color: Colors.white60,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Text(
                        _guessText,
                        style: GoogleFonts.cairo(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'هل إجابته صح؟',
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _drawerDecide(true),
                            icon: const Icon(Icons.check_circle, size: 30),
                            label: Text(
                              'صح ✅\n+1 نقطة',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _drawerDecide(false),
                            icon: const Icon(Icons.cancel, size: 30),
                            label: Text(
                              'غلط ❌\nلا نقطة',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // ─── Final result ───
                    Text(
                      isCorrect ? '🎉' : '😅',
                      style: const TextStyle(fontSize: 100),
                    ).animate().scale(),
                    const SizedBox(height: 20),
                    Text(
                      isCorrect ? 'صح! 🏆 نقطة لـ $_guesserName!' : 'مش صح 😅',
                      style: GoogleFonts.cairo(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 12),
                    Text(
                      'الكلمة: ${_currentWord!['word']}',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                    if (_players.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Wrap(
                          spacing: 20,
                          alignment: WrapAlignment.center,
                          children: _players
                              .map(
                                (p) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      p['name'],
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${p['score']} نقطة',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _nextRound,
                      icon: const Icon(Icons.refresh_rounded, size: 24),
                      label: Text(
                        'دور جديد 🎨',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return BaseGameScaffold(
      title: '🎨 ارسم وخمّن',
      backgroundColor: const Color(0xFF0D47A1),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickWord,
          child: Text('ابدأ', style: GoogleFonts.cairo()),
        ),
      ),
    );
  }
}
