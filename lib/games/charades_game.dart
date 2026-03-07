import 'package:flutter/material.dart';
import '../screens/global_player_selection_screen.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/base_game_scaffold.dart';
import '../services/raw_data_manager.dart';
import '../services/online_data_service.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../widgets/game_intro_widget.dart';

class CharadesGame extends StatefulWidget {
  const CharadesGame({super.key});
  @override
  State<CharadesGame> createState() => _CharadesGameState();
}

class _CharadesGameState extends State<CharadesGame> {
  Map<String, List<String>> categoryWords = {};
  bool isLoadingData = true;
  bool _isGeneratingAi = false;

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent('charades', count: 10);
      Map<String, List<String>> aiCategories = {};

      for (var item in content) {
        // Handle variations in keys for categories and words
        String cat = (item['category'] ?? item['cat'] ?? 'عام').toString();
        if (!aiCategories.containsKey(cat)) aiCategories[cat] = [];

        var itemsRaw = item['items'] ?? item['words'];
        if (itemsRaw is List) {
          aiCategories[cat]!.addAll(
            List<String>.from(itemsRaw.map((e) => e.toString())),
          );
        } else {
          String? word = (item['word'] ?? item['text'])?.toString();
          if (word != null) {
            aiCategories[cat]!.add(word);
          }
        }
      }

      if (aiCategories.isNotEmpty) {
        setState(() {
          categoryWords.addAll(aiCategories);
          _selectedCategories = aiCategories.keys.toList();
          _active = false;
          _roundOver = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم توليد تصنيفات جديدة بالذكاء الاصطناعي! ✨'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل توليد محتوى AI: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGeneratingAi = false);
    }
  }

  final Map<String, List<String>> _fallbackCategoryWords = {
    '🎬 أفلام ومسلسلات': [
      'تيتانيك',
      'هاري بوتر',
      'الأسد الملك',
      'أفنجرز',
      'توباك',
      'باتمان',
      'سبايدرمان',
      'فروزن',
      'جيمس بوند',
      'ماتريكس',
      'بريكينج باد',
      'صراع العروش',
      'النمر الأسود',
      'إنترستيلار',
      'مدرسة المشاغبين',
      'إنسبشن',
      'ذا ماسك',
      'شريك',
      'كانج فو باندا',
      'لايون كينج',
      'رالف المدمر',
      'توي ستوري',
      'التنين الطيب',
      'الهوية',
      'رمضان كريم',
      'السيف والنار',
      'باب الحارة',
      'ضو القمر',
      'صح النوم',
    ],
    '🐾 حيوانات': [
      'فيل',
      'قرد',
      'تمساح',
      'طاووس',
      'بطريق',
      'كنغر',
      'أخطبوط',
      'حصان',
      'وحيد القرن',
      'ديناصور',
      'دلفين',
      'عقاب',
      'أسد',
      'دبدوب',
      'كركدن',
      'جوريلا',
      'نمر',
      'زرافة',
      'ببغاء',
      'تمساح النيل',
      'خنزير البحر',
      'قنفذ',
      'أرنب',
      'كوالا',
      'فهد',
      'حيوان القنفذ',
      'جمل',
      'خروف',
      'بطة',
      'ضفدع',
    ],
    '⚽ رياضة': [
      'كرة قدم',
      'سباحة',
      'تنس',
      'كرة سلة',
      'جمباز',
      'ملاكمة',
      'ركوب خيل',
      'غوص',
      'كاراتيه',
      'رفع أثقال',
      'جري ماراثون',
      'قفز بالزانة',
      'تنس طاولة',
      'رياضة تزلج',
      'بولينج',
      'كرة طائرة',
      'بيسبول',
      'رغبي',
      'هوكي',
      'سباق دراجات',
      'رماية',
      'مصارعة',
      'قفز بالحبل',
      'سومو',
      'تجديف',
      'قفز سباحة',
      'منافسات أولمبية',
      'ترياثلون',
      'بنتاثلون',
    ],
    '🎭 شخصيات مشهورة': [
      'ميسي',
      'رونالدو',
      'محمد صلاح',
      'أينشتاين',
      'نيوتن',
      'مايكل جاكسون',
      'محمد علي',
      'بيل غيتس',
      'إيلون ماسك',
      'كليوباترا',
      'نابليون',
      'أوباما',
      'شابلن',
      'جاكي شان',
      'ستيف جوبز',
      'مارك زوكربيرج',
      'شكسبير',
      'موتسارت',
      'ليوناردو دافنشي',
      'فريديا كالو',
      'أرسطو',
      'أرشميدس',
      'نيلسون مانديلا',
      'غاندي',
      'تيريزا',
      'إبراهيم الفقي',
      'أم كلثوم',
      'عبد الحليم حافظ',
      'فيروز',
    ],
    '🏠 أشياء يومية': [
      'مكواة ملابس',
      'تلسكوب',
      'مكنسة',
      'ماكينة قهوة',
      'ميكروويف',
      'مزهرية',
      'مظلة في ريح',
      'كاميرا',
      'منظار',
      'ساعة رملية',
      'مراوح يدوية',
      'إبريق شاي',
      'مفتاح',
      'حبل غسيل',
      'لوح تزلج',
      'شمعة في الريح',
      'منبه',
      'أرجوحة',
      'حوض استحمام',
      'فرشة أسنان',
      'ورقة عمل',
      'سبورة',
      'مقلاة',
      'خلاط',
      'شواية',
      'منفاخ',
      'دلو',
      'غلاية',
      'مجفف شعر',
    ],
    '🎭 أفعال': [
      'يرقص',
      'يبكي',
      'يغني',
      'يطير',
      'يتسلق جبل',
      'يلعب بيانو',
      'يعدو',
      'يتفاوض',
      'يصطاد السمك',
      'يرمي برمح',
      'يتصفح موبايل',
      'يجر حقيبة',
      'يلاكم',
      'يقود سيارة',
      'يطبخ',
      'يرتدي ملابس',
      'يتعثر',
      'يمشي على الحبل',
      'يخيط',
      'يلوّن',
      'يثقب الجدار',
      'يحمل طفل رضيع',
      'يصلح سيارة',
      'يتظاهر بالنوم',
      'يتظاهر بالمرض',
      'ينظف بالمكنسة',
      'يرمي الكرة',
      'يقفز',
      'يمشي عكسي',
    ],
    '🌍 أماكن': [
      'برج إيفل',
      'أهرامات الجيزة',
      'برج بيزا',
      'تمثال الحرية',
      'سور الصين العظيم',
      'كعبة مشرفة',
      'استديو هوليوود',
      'ملعب كرة قدم',
      'مطار',
      'شاطئ بحر',
      'برج خليفة',
      'تاج محل',
      'الكولوسيوم',
      'أكروبوليس',
      'البيت الأبيض',
      'مدينة ديزني',
      'قناة السويس',
      'نهر النيل',
      'أمازون',
      'جبل إيفرست',
      'الصحراء الكبرى',
      'النهر الأصفر',
      'بحيرة فيكتوريا',
      'الحواجز المرجانية الكبرى',
    ],
  };

  List<String> _selectedCategories = [];
  List<String> _shuffledWords = [];
  int _wordIndex = 0;
  int _correct = 0;
  int _skip = 0;
  bool _active = false;
  bool _roundOver = false;
  int _secondsLeft = 60;
  Timer? _timer;
  final List<String> _players = [];
  int _currentPlayer = 0;
  final _playerCtrl = TextEditingController();
  bool _showIntro = true;
  bool _started = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData('charades_game', {});

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
    _shuffledWords.shuffle(_rand);

    if (_shuffledWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد كلمات كافية في هذه الفئات')),
      );
      return;
    }

    setState(() {
      _wordIndex = 0;
      _correct = 0;
      _skip = 0;
      _roundOver = false;
      _active = true;
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
          _active = false;
          _roundOver = true;
        });
        if (_players.isNotEmpty) {
          _players[_currentPlayer] =
              '${_players[_currentPlayer].split('|').first}|$_correct';
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _answer(bool correct) {
    if (!_active) return;
    setState(() {
      if (correct) {
        _correct++;
      } else {
        _skip++;
      }
      _wordIndex = (_wordIndex + 1) % _shuffledWords.length;
    });
  }

  void _nextPlayer() {
    _timer?.cancel();
    setState(() {
      _currentPlayer = (_currentPlayer + 1) % _players.length.clamp(1, 99);
      _roundOver = false;
      _active = false;
    });
  }

  String _playerName(String p) => p.split('|').first;
  int _playerScore(String p) {
    final parts = p.split('|');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }

  Color _timerColor() {
    if (_secondsLeft > 30) return Colors.green;
    if (_secondsLeft > 10) return Colors.orange;
    return Colors.red;
  }

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
    if (isLoadingData || categoryWords.isEmpty) {
      return BaseGameScaffold(
        title: '🎭 تمثيل صامت',
        backgroundColor: const Color(0xFF1A237E),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_showIntro) {
      return BaseGameScaffold(
        title: '🎭 تمثيل صامت',
        backgroundColor: const Color(0xFF1A237E),
        body: GameIntroWidget(
          title: 'تمثيل صامت',
          icon: '🎭',
          description:
              'مثّل الكلمة من غير ما تتكلم!\n\nفريقك لازم يخمّن الكلمة في 60 ثانية بس. ممنوع الكلام أو الإشارات الصوتية!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (!_started) {
      return BaseGameScaffold(
        title: '🎭 تمثيل صامت',
        backgroundColor: const Color(0xFF1A237E),
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
            tooltip: 'تحديث الكلمات',
            onPressed: _isGeneratingAi ? null : _forceUpdateData,
          ),
        ],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  '🎭',
                  style: TextStyle(fontSize: 90),
                ).animate().scale(),
                const SizedBox(height: 12),
                Text(
                  'تمثيل صامت!',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                Text(
                  'مثّل الكلمة من غير ما تتكلم!\nفريقك يخمّن في 60 ثانية 🤫',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 15, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                // Category
                Text(
                  'اختار الفئة:',
                  style: GoogleFonts.cairo(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.indigoAccent
                              : Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? Colors.indigoAccent
                                : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                      onPressed: _selectedCategories.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GlobalPlayerSelectionScreen(
                                        gameTitle: 'تمثيل صامت',
                                        minPlayers: 2,
                                        onStartGame: (ctx, selectedPlayers) {
                                          Navigator.pop(ctx);
                                          setState(() {
                                            _players.clear();
                                            _players.addAll(
                                              selectedPlayers.map(
                                                (name) => '$name|0',
                                              ),
                                            );
                                            _currentPlayer = 0;
                                            _started = true;
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
                        backgroundColor: Colors.indigoAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: _selectedCategories.isNotEmpty ? 10 : 0,
                        shadowColor: Colors.indigoAccent.withValues(alpha: 0.5),
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

    return BaseGameScaffold(
      title: '🎭 تمثيل صامت',
      backgroundColor: const Color(0xFF1A237E),
      actions: [
        IconButton(
          icon: const Icon(Icons.home, color: Colors.white70),
          onPressed: () {
            _timer?.cancel();
            setState(() {
              _started = false;
              _active = false;
              _players.clear();
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
                  children: _players.asMap().entries.map((e) {
                    final active = e.key == _currentPlayer;
                    return Column(
                      children: [
                        Text(
                          _playerName(e.value),
                          style: GoogleFonts.cairo(
                            color: active
                                ? Colors.indigoAccent
                                : Colors.white54,
                            fontWeight: active
                                ? FontWeight.w900
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          '${_playerScore(e.value)} ✅',
                          style: GoogleFonts.cairo(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),

              if (!_active && !_roundOver) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_players.isNotEmpty)
                        Text(
                          'دور: ${_playerName(_players[_currentPlayer])}',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'الفئات: ${_selectedCategories.join(', ')}',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: Colors.indigoAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'الممثل يرى الكلمة — الفريق يخمّن!\nعندك 60 ثانية 🤫',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: _selectedCategories.isNotEmpty
                            ? _startRound
                            : null,
                        icon: const Icon(Icons.play_arrow, size: 30),
                        label: Text(
                          'ابدأ الجولة!',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_active) ...[
                // Timer
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _timerColor().withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _timerColor(),
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        '✅ $_correct',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.green.shade700,
                    ),
                    const SizedBox(width: 10),
                    Chip(
                      label: Text(
                        '⏭️ $_skip',
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
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  const BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Text(
                                _shuffledWords.isNotEmpty
                                    ? _shuffledWords[_wordIndex %
                                          _shuffledWords.length]
                                    : '',
                                style: GoogleFonts.cairo(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1A237E),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                            .animate(key: ValueKey(_wordIndex))
                            .scale(duration: 200.ms)
                            .fadeIn(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _answer(false),
                        child: Container(
                          height: 65,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '⏭️ تجاوز',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _answer(true),
                        child: Container(
                          height: 65,
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '✅ خمّنها!',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
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
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text('✅', style: const TextStyle(fontSize: 36)),
                                Text(
                                  '$_correct',
                                  style: GoogleFonts.cairo(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                                Text(
                                  'خمّن صح',
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
                                  style: const TextStyle(fontSize: 36),
                                ),
                                Text(
                                  '$_skip',
                                  style: GoogleFonts.cairo(
                                    fontSize: 40,
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
                      ),
                      const SizedBox(height: 24),
                      if (_players.length > 1)
                        ElevatedButton.icon(
                          onPressed: _nextPlayer,
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            'دور ${_playerName(_players[(_currentPlayer + 1) % _players.length])}',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
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
                            backgroundColor: Colors.indigoAccent,
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
