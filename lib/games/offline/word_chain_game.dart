import 'package:flutter/material.dart';
import '../../screens/global_player_selection_screen.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/premium_loading_indicator.dart';
import '../../widgets/offline_game_scaffold.dart';
import '../../widgets/game_intro_widget.dart';
import '../../services/raw_data_manager.dart';
import '../../services/settings_service.dart';
import '../../services/ai_service.dart';

class WordChainGame extends StatefulWidget {
  const WordChainGame({super.key});

  @override
  State<WordChainGame> createState() => _WordChainGameState();
}

class _WordChainGameState extends State<WordChainGame> {
  Map<String, List<String>> categoryWords = {};
  bool _showIntro = true;
  bool isLoadingData = true;
  bool _isGeneratingAi = false;
  final List<String> _aiHistory = [];

  // Category → [words]
  final Map<String, List<String>> _fallbackCategoryWords = {
    '🍎 فواكه': [
      'أناناس',
      'أفوكادو',
      'برتقال',
      'بطيخ',
      'بلح',
      'برقوق',
      'بندورة',
      'تفاح',
      'توت',
      'ثمر الغار',
      'جوافة',
      'جوز',
      'حصرم',
      'خوخ',
      'رمان',
      'زيتون',
      'سفرجل',
      'شمام',
      'عنب',
      'فواكه المناطق الاستوائية',
      'فراولة',
      'كرز',
      'كمثرى',
      'كوكو',
      'مانجو',
      'موز',
      'نبق الهند',
      'نارجيل',
      'يوسفي',
      'ورد النوار',
    ],
    '🐘 حيوانات': [
      'أسد',
      'أرنب',
      'أفعى',
      'بقرة',
      'بط',
      'بعير',
      'تمساح',
      'ثعلب',
      'جاموس',
      'جمل',
      'حصان',
      'دب',
      'ذئب',
      'ذباب',
      'رسيس',
      'زرافة',
      'سلحفاة',
      'شيمبانزي',
      'ضبع',
      'طاووس',
      'ظبي',
      'عصفور',
      'غزال',
      'فهد',
      'قط',
      'كلب',
      'كركدن',
      'مها',
      'نمر',
      'هيبو',
    ],
    '🏙️ بلاد': [
      'مصر',
      'تركيا',
      'ماليزيا',
      'أمريكا',
      'ألمانيا',
      'أستراليا',
      'إيطاليا',
      'برازيل',
      'بلجيكا',
      'باكستان',
      'تايلاند',
      'جيبوتي',
      'جزائر',
      'سوريا',
      'سودان',
      'سنغافورة',
      'صومال',
      'عُمان',
      'فرنسا',
      'فلسطين',
      'قطر',
      'كندا',
      'كويت',
      'لبنان',
      'ليبيا',
      'مغرب',
      'موريتانيا',
      'نيجيريا',
      'هند',
      'يابان',
    ],
    '👤 أسماء': [
      'أحمد',
      'أسماء',
      'أميرة',
      'إبراهيم',
      'إيمان',
      'بسمة',
      'تامر',
      'جمال',
      'حسام',
      'خالد',
      'رانيا',
      'زياد',
      'سارة',
      'سمر',
      'شادي',
      'صلاح',
      'ضياء',
      'طارق',
      'عمر',
      'فاطمة',
      'كريم',
      'لمى',
      'ليلى',
      'محمد',
      'منال',
      'نادية',
      'هاني',
      'وليد',
      'ياسمين',
      'يوسف',
    ],
    '🍔 أكلات': [
      'أرز بلبن',
      'أم علي',
      'بسطرمة',
      'بقلاوة',
      'برياني',
      'بيتزا',
      'تجين',
      'كشري',
      'كنافة',
      'كبدة',
      'فول',
      'فتة',
      'طعمية',
      'شاورما',
      'سلطة',
      'سوشي',
      'ستيك',
      'ربيان',
      'دجاج مشوي',
      'دجاج كنتاكي',
      'حمص',
      'خبز بالجبنة',
      'جبنة وفطر',
      'جريش',
      'ثريد',
      'بقلة',
      'باذنجان مقلي',
      'بامية بلحم',
      'أرز معمر',
      'أرز بالشعرية',
    ],
    '⚽ رياضة': [
      'أولمبياد',
      'ألعاب القوى',
      'إسكواش',
      'بلياردو',
      'بيسبول',
      'تنس',
      'جودو',
      'جمباز',
      'حوكي',
      'رفع أثقال',
      'ركبي',
      'روينج',
      'رياضة مائية',
      'سباحة',
      'سلة',
      'شطرنج',
      'طائرة',
      'كرة يد',
      'كرة قدم',
      'كرة طائرة',
      'كريكيت',
      'لياقة بدنية',
      'مصارعة',
      'منافسة',
      'نادي رياضي',
      'هوكي جليد',
      'يوغا',
      'يخت',
      'والتر بول',
      'وزن الريشة',
    ],
  };

  List<String> _selectedCategories = [];
  List<String> _shuffledWords = [];
  int _currentWordIndex = 0;
  int _successCount = 0;
  int _skipCount = 0;
  bool _gameActive = false;
  bool _roundOver = false;
  int _secondsLeft = 60;
  Timer? _timer;
  List<String> _answeredWords = [];
  final List<Map<String, dynamic>> _players = [];
  int _currentPlayerTurn = 0;
  final TextEditingController _playerCtrl = TextEditingController();
  bool _setupDone = false;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData('word_chain_game', {});

    if (rawData.containsKey('categories') && rawData['categories'] is Map) {
      Map<String, List<String>> parsedCategories = {};
      final cats = rawData['categories'] as Map;
      cats.forEach((key, value) {
        if (value is List) {
          parsedCategories[key.toString()] = List<String>.from(
            value.map((e) => e.toString()),
          );
        }
      });

      if (parsedCategories.isNotEmpty) {
        if (mounted) {
          setState(() {
            categoryWords = parsedCategories;
            isLoadingData = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        categoryWords = _fallbackCategoryWords;
        isLoadingData = false;
      });
    }
  }

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent(
        'word_chain_game',
        count: 10,
        history: _aiHistory,
      );
      if (content.isNotEmpty) {
        for (var item in content) {
          final category = item['category']?.toString() ?? '';
          if (category.isNotEmpty) {
            _aiHistory.add(category);
          }
        }
        if (_aiHistory.length > 50) {
          _aiHistory.removeRange(0, _aiHistory.length - 50);
        }
      }
      // Expected content: list of { "category": "...", "words": ["...", "..."] }
      Map<String, List<String>> aiCategories = {};
      for (var item in content) {
        final cat = item['category']?.toString() ?? '💡 عام';
        final words = item['words'];
        if (words is List) {
          aiCategories[cat] = List<String>.from(words.map((e) => e.toString()));
        }
      }

      if (aiCategories.isNotEmpty) {
        setState(() {
          categoryWords.addAll(aiCategories);
          _selectedCategories = aiCategories.keys.toList();
          _gameActive = false;
          _setupDone = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم توليد كلمات جديدة بالذكاء الاصطناعي! ✨'),
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
  void dispose() {
    _timer?.cancel();
    _playerCtrl.dispose();
    super.dispose();
  }

  void _startRound() {
    if (_selectedCategories.isEmpty) return;

    _shuffledWords = [];
    for (String cat in _selectedCategories) {
      if (categoryWords.containsKey(cat)) {
        _shuffledWords.addAll(categoryWords[cat]!);
      }
    }
    _shuffledWords.shuffle();

    if (_shuffledWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد كلمات كافية في هذه الفئات')),
      );
      return;
    }

    setState(() {
      _currentWordIndex = 0;
      _successCount = 0;
      _skipCount = 0;
      _roundOver = false;
      _gameActive = true;
      _answeredWords = [];
      _secondsLeft = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() {
          _gameActive = false;
          _roundOver = true;
        });
        // Add score to current player
        if (_players.isNotEmpty) {
          _players[_currentPlayerTurn]['score'] =
              (_players[_currentPlayerTurn]['score'] as int) + _successCount;
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _nextWord(bool correct) {
    if (!_gameActive) return;
    setState(() {
      _answeredWords.add(
        '${correct ? '✅' : '⏭️'} ${_shuffledWords[_currentWordIndex]}',
      );
      if (correct) {
        _successCount++;
      } else {
        _skipCount++;
      }
      _currentWordIndex++;

      if (_currentWordIndex >= _shuffledWords.length) {
        _shuffledWords.shuffle();
        _currentWordIndex = 0;
      }
    });
  }

  void _nextPlayerTurn() {
    _timer?.cancel();
    setState(() {
      _currentPlayerTurn =
          (_currentPlayerTurn + 1) % _players.length.clamp(1, 99);
      _roundOver = false;
      _gameActive = false;
    });
  }

  Color _timerColor() {
    if (_secondsLeft > 30) return Colors.green;
    if (_secondsLeft > 10) return Colors.orange;
    return Colors.red;
  }


  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return OfflineGameScaffold(
        title: '⏱️ تحدي التعريف',
        backgroundColor: const Color(0xFF004D40),
        body: GameIntroWidget(
          title: 'تحدي التعريف',
          icon: '⏱️',
          description:
              'اشرح الكلمة لزميلك بدون ما تقول الكلمة نفسها!\nأكتر كلمة في الدقيقة = الفايز!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (isLoadingData || categoryWords.isEmpty) {
      return OfflineGameScaffold(
        title: '⏱️ تحدي التعريف',
        backgroundColor: const Color(0xFF004D40),
        body: const PremiumLoadingIndicator(message: 'جاري ربط الكلمات...'),
      );
    }

    if (!_setupDone) {
      return OfflineGameScaffold(
        title: '⏱️ تحدي التعريف',
        backgroundColor: const Color(0xFF004D40), // Dark Teal
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
        ],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '⏱️',
                  style: const TextStyle(fontSize: 80),
                ).animate().scale(),
                const SizedBox(height: 12),
                Text(
                  'تحدي التعريف',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اشرح الكلمة لزميلك بدون ما تقول الكلمة نفسها!\nأكتر كلمة في الدقيقة = الفايز!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 15, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                // Category Picker
                Text(
                  'اختار الفئة:',
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: categoryWords.keys.map((cat) {
                    final selected = _selectedCategories.contains(cat);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedCategories.remove(cat);
                          } else {
                            _selectedCategories.add(cat);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.tealAccent.shade700
                              : Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? Colors.tealAccent
                                : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.cairo(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                      onPressed: _selectedCategories.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GlobalPlayerSelectionScreen(
                                        gameTitle: 'تحدي التعريف',
                                        minPlayers: 2,
                                        onStartGame: (ctx, selectedPlayers) {
                                          Navigator.pop(ctx);
                                          setState(() {
                                            _players.clear();
                                            _players.addAll(
                                              selectedPlayers.map(
                                                (name) => {
                                                  'name': name,
                                                  'score': 0,
                                                },
                                              ),
                                            );
                                            _currentPlayerTurn = 0;
                                            _setupDone = true;
                                          });
                                        },
                                      ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.people_alt, size: 28),
                      label: Text(
                        'اختار شلتك وابدأ!',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: _selectedCategories.isNotEmpty ? 10 : 0,
                        shadowColor: Colors.tealAccent.withValues(alpha: 0.5),
                      ),
                    )
                    .animate(
                      target: _selectedCategories.isNotEmpty ? 1 : 0,
                      onPlay: (c) => c.repeat(reverse: true),
                    )
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

    // Game Screen
    return OfflineGameScaffold(
      title: '⏱️ تحدي التعريف',
      backgroundColor: const Color(0xFF004D40),
      actions: [
        IconButton(
          icon: const Icon(Icons.home, color: Colors.white70),
          onPressed: () {
            _timer?.cancel();
            setState(() {
              _setupDone = false;
              _roundOver = false;
              _gameActive = false;
            });
          },
        ),
      ],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Scoreboard
              if (_players.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _players.map((p) {
                    final active = _players.indexOf(p) == _currentPlayerTurn;
                    return Column(
                      children: [
                        Text(
                          p['name'],
                          style: GoogleFonts.cairo(
                            color: active ? Colors.tealAccent : Colors.white54,
                            fontWeight: active
                                ? FontWeight.w900
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          '${p['score']} نقطة',
                          style: GoogleFonts.cairo(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              if (!_gameActive && !_roundOver) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _players.isNotEmpty
                            ? 'دور: ${_players[_currentPlayerTurn]['name']}'
                            : 'اضغط ابدأ!',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'الفئات: ${_selectedCategories.join(', ')}',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.tealAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'عندك 60 ثانية تعرّف كلمات!',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: _selectedCategories.isNotEmpty
                            ? _startRound
                            : null,
                        icon: const Icon(Icons.play_arrow, size: 32),
                        label: Text(
                          'ابدأ الجولة!',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_gameActive) ...[
                // Timer
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _timerColor().withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _timerColor(), width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, color: _timerColor()),
                      const SizedBox(width: 8),
                      Text(
                        '$_secondsLeft ثانية',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _timerColor(),
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        '✅ $_successCount',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.green.shade700,
                    ),
                    const SizedBox(width: 12),
                    Chip(
                      label: Text(
                        '⏭️ $_skipCount',
                        style: GoogleFonts.cairo(color: Colors.white),
                      ),
                      backgroundColor: Colors.orange.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child:
                        Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Text(
                                _shuffledWords.isNotEmpty
                                    ? _shuffledWords[_currentWordIndex %
                                          _shuffledWords.length]
                                    : '...',
                                style: GoogleFonts.cairo(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF004D40),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                            .animate(key: ValueKey(_currentWordIndex))
                            .scale(duration: 200.ms)
                            .fadeIn(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _nextWord(false),
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '⏭️ تجاوز',
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _nextWord(true),
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '✅ صح',
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_roundOver) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '⏰ انتهى الوقت!',
                        style: GoogleFonts.cairo(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'النتيجة',
                              style: GoogleFonts.cairo(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '✅',
                                      style: const TextStyle(fontSize: 30),
                                    ),
                                    Text(
                                      '$_successCount',
                                      style: GoogleFonts.cairo(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                    Text(
                                      'عرّفها',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '⏭️',
                                      style: const TextStyle(fontSize: 30),
                                    ),
                                    Text(
                                      '$_skipCount',
                                      style: GoogleFonts.cairo(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.orangeAccent,
                                      ),
                                    ),
                                    Text(
                                      'تجاوز',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Answered words recap
                      if (_answeredWords.isNotEmpty) ...[
                        Text(
                          'الكلمات:',
                          style: GoogleFonts.cairo(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView(
                            shrinkWrap: true,
                            children: _answeredWords
                                .map(
                                  (w) => Text(
                                    w,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (_players.length > 1)
                        ElevatedButton.icon(
                          onPressed: _nextPlayerTurn,
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            'دور ${_players[(_currentPlayerTurn + 1) % _players.length]['name']}',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _startRound,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            'العب تاني',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


