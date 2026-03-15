import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/offline_game_scaffold.dart';
import '../../services/raw_data_manager.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/game_intro_widget.dart';

class SongLyricsGame extends StatefulWidget {
  const SongLyricsGame({super.key});
  @override
  State<SongLyricsGame> createState() => _SongLyricsGameState();
}

class _SongLyricsGameState extends State<SongLyricsGame> {
  List<Map<String, String>> songs = [];
  bool isLoadingData = true;
  bool _showIntro = true;
  bool _isGeneratingAi = false;
  final List<String> _aiHistory = [];

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent(
        'song_lyrics',
        count: 12,
        history: _aiHistory,
      );
      List<Map<String, String>> aiSongs = [];
      for (var item in content) {
        final prompt = item['prompt']?.toString() ?? '';
        if (prompt.isNotEmpty) {
          _aiHistory.add(prompt);
        }
        aiSongs.add({
          'prompt': item['prompt']?.toString() ?? '',
          'answer': item['answer']?.toString() ?? '',
          'artist': item['artist']?.toString() ?? '',
        });
      }

      if (_aiHistory.length > 50) {
        _aiHistory.removeRange(0, _aiHistory.length - 50);
      }

      if (aiSongs.isNotEmpty) {
        setState(() {
          songs = aiSongs;
          _shuffled = List.from(songs)..shuffle(_rand);
          _index = 0;
          _score = 0;
          _total = 0;
          _answered = false;
          _buildChoices();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم توليد أغاني جديدة بالذكاء الاصطناعي! ✨'),
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

  final List<Map<String, String>> _fallbackSongs = [
    {
      'prompt': 'يا وهيبة يا وهيبة... أكلي البيبة',
      'answer': 'أكلي البيبة وعيشيني',
      'artist': 'نجوى كرم',
    },
    {
      'prompt': 'عمري ما حبيت قبلك...',
      'answer': 'وبعدك مش حيبقى في ده وقت',
      'artist': 'أصالة',
    },
    {
      'prompt': 'بشرة الخير... بشرة الخير...',
      'answer': 'حيث ما كنت إن شاء الله',
      'artist': 'حسين الجسمي',
    },
    {
      'prompt': 'مسافر يا قلبي مسافر...',
      'answer': 'والدنيا أيام',
      'artist': 'كاظم الساهر',
    },
    {
      'prompt': 'أنا لو قلت بحبك...',
      'answer': 'لا تصدقنيش',
      'artist': 'حمزة نمرة',
    },
    {
      'prompt': 'يا ليلة العيد آنستينا...',
      'answer': 'والعيد عاد وفرّحتينا',
      'artist': 'أم كلثوم',
    },
    {
      'prompt': 'زي الهوا علّمني...',
      'answer': 'أحبك وأحبك وأحبك',
      'artist': 'ماجد المهندس',
    },
    {
      'prompt': 'ماذا أقول لك يا حبيبي...',
      'answer': 'ماذا أقول وقلبي تعذّب',
      'artist': 'فيروز',
    },
    {
      'prompt': 'أنا اللي بيغنيلك...',
      'answer': 'من زمان وبحبك من زمان',
      'artist': 'هاني شاكر',
    },
    {
      'prompt': 'روحي يا ست البنات...',
      'answer': 'روحي وعيشي حياتك',
      'artist': 'حمزة نمرة',
    },
    {
      'prompt': 'أنا زهقت من الوداع...',
      'answer': 'زهقت من جرح الفراق',
      'artist': 'ماجد المهندس',
    },
    {
      'prompt': 'كيفك انت؟ كيفك انت؟...',
      'answer': 'والحياة كيف بتعدي معاك',
      'artist': 'رامي عياش',
    },
    {
      'prompt': 'إوعى تفكر إن حبنا...',
      'answer': 'هيبقى عادي يوم ما',
      'artist': 'تامر حسني',
    },
    {
      'prompt': 'أنا وأنت حبيبي...',
      'answer': 'حبنا ما محتاجش كلام',
      'artist': 'شيرين',
    },
    {
      'prompt': 'ياما كان في ناس أحبوا...',
      'answer': 'وفي ناس ما عضّتهمش حاجة',
      'artist': 'حمزة نمرة',
    },
    {
      'prompt': 'أمي... كلمة طيّبة...',
      'answer': 'وعطرها يفوق الورد',
      'artist': 'مشاري العفاسي',
    },
    {
      'prompt': 'جايلك تاني مرة...',
      'answer': 'أسرقك من الأيام',
      'artist': 'عمرو دياب',
    },
    {
      'prompt': 'إوعى تفكر إن بحبك...',
      'answer': 'هيبقى سهل علي يوم ما ينتهي',
      'artist': 'تامر حسني',
    },
    {'prompt': 'علّمني حبك...', 'answer': 'إزاي أحبك أكتر', 'artist': 'شيرين'},
    {
      'prompt': 'لو راح مني يوم...',
      'answer': 'تلاقيني جنبك مزروع',
      'artist': 'رامي عياش',
    },
    {
      'prompt': 'هل ترى يذكر...',
      'answer': 'ذاك الحبيب الغائب',
      'artist': 'كاظم الساهر',
    },
    {
      'prompt': 'ناسيني وناسي العهود...',
      'answer': 'ناسي الحب وناسي كل شي',
      'artist': 'وائل جسار',
    },
    {
      'prompt': 'يا حبيبي يا عمري...',
      'answer': 'في دنيا بدونك ما بقدر',
      'artist': 'كاظم الساهر',
    },
    {
      'prompt': 'طل الصبح على...',
      'answer': 'بلادي وقلبي اشتاق',
      'artist': 'فيروز',
    },
    {
      'prompt': 'يا رب يامن تسمع...',
      'answer': 'كل الأصوات والأدعية',
      'artist': 'ماجد المهندس',
    },
    // 30 new songs
    {
      'prompt': 'حبيتك بالصيف وبالشتا...',
      'answer': 'وكل يوم قلبي زاد هوا',
      'artist': 'عمرو دياب',
    },
    {
      'prompt': 'الليلة هنسهر...',
      'answer': 'ونضحك ونفرح ونغني',
      'artist': 'تامر حسني',
    },
    {
      'prompt': 'يا أهلاً بالسلامة...',
      'answer': 'جيت ليه على بالي',
      'artist': 'أصالة',
    },
    {
      'prompt': 'بحبك وبكره بُعدك...',
      'answer': 'وعايش على أمل لقاك',
      'artist': 'محمد عبده',
    },
    {
      'prompt': 'ما بعدك ليش...',
      'answer': 'ما بعدك حياتي',
      'artist': 'وائل كفوري',
    },
    {'prompt': 'طيف خيالك...', 'answer': 'جاني في المنام', 'artist': 'فيروز'},
    {
      'prompt': 'أنا ما غيرتش...',
      'answer': 'أنت اللي تغيرت',
      'artist': 'شيرين',
    },
    {
      'prompt': 'يا بنت الجيران...',
      'answer': 'إنتي في عيني أحلى من القمر',
      'artist': 'محمد فؤاد',
    },
    {
      'prompt': 'حالي في الغياب...',
      'answer': 'بيقول عليك',
      'artist': 'كاظم الساهر',
    },
    {'prompt': 'اللي شافك مرة...', 'answer': 'ما ينسش', 'artist': 'رامي صبري'},
    {
      'prompt': 'حبيبي والله يهواك...',
      'answer': 'وقلبي في هواك',
      'artist': 'أم كلثوم',
    },
    {
      'prompt': 'آمي مش أنا...',
      'answer': 'آمي الغيرة في عيونك',
      'artist': 'حمزة نمرة',
    },
    {
      'prompt': 'ما تبكيش عيون...',
      'answer': 'على ما راح ما يرجع',
      'artist': 'نجوى كرم',
    },
    {'prompt': 'إنتروبي إيه...', 'answer': 'الغربة دي', 'artist': 'عمرو دياب'},
    {
      'prompt': 'أنا مش أنا...',
      'answer': 'من بعدك يا حبيبي',
      'artist': 'شيرين عبد الوهاب',
    },
    {
      'prompt': 'على أه يا ليل...',
      'answer': 'طول الليل',
      'artist': 'ماجد المهندس',
    },
    {
      'prompt': 'لو كنت بين إيدي...',
      'answer': 'ما رحتش بعيد',
      'artist': 'رامي عياش',
    },
    {
      'prompt': 'أنا آسف يا حبيبي...',
      'answer': 'غلطت وزعلتك',
      'artist': 'تامر حسني',
    },
    {
      'prompt': 'حلوة يا دنيا...',
      'answer': 'حلوة يا بلادي',
      'artist': 'أم كلثوم',
    },
    {
      'prompt': 'خدني وروحنا...',
      'answer': 'في بعض طول عمرنا',
      'artist': 'وائل جسار',
    },
    {
      'prompt': 'بعدك عيني ما شافت...',
      'answer': 'غيرك يا أغلى الناس',
      'artist': 'محمد عبده',
    },
    {
      'prompt': 'والله لو دنيا خلت منك...',
      'answer': 'إيه معنى الدنيا',
      'artist': 'وائل كفوري',
    },
    {
      'prompt': 'يا بلادي بحبك...',
      'answer': 'وفي قلبي نور اسمك',
      'artist': 'سميرة سعيد',
    },
    {
      'prompt': 'نص قلبي عندك...',
      'answer': 'والنص الثاني بعدك',
      'artist': 'ماجد المهندس',
    },
    {
      'prompt': 'خلي بالك من نفسك...',
      'answer': 'ما تزيدش وجعي',
      'artist': 'إليسا',
    },
    {
      'prompt': 'ما بين أيديك...',
      'answer': 'أغلى ما عندي',
      'artist': 'كاظم الساهر',
    },
    {
      'prompt': 'قلبي طار وغاب...',
      'answer': 'وانت السبب طيارة',
      'artist': 'عمرو دياب',
    },
    {'prompt': 'أحبك أكتر...', 'answer': 'لما ابتعدت عني', 'artist': 'شيرين'},
    {
      'prompt': 'مع الليالي...',
      'answer': 'بيغلى حبك في داخلي',
      'artist': 'محمد حماقي',
    },
    {
      'prompt': 'روح روح...',
      'answer': 'ويا ريتك تتذكرني',
      'artist': 'رامي صبري',
    },
  ];

  List<Map<String, String>> _shuffled = [];
  int _index = 0;
  bool _answered = false;
  String? _selectedAnswer;
  List<Map<String, String>> _choices = [];
  int _score = 0;
  int _total = 0;
  bool _gameStarted = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData('song_lyrics_game', {});

    if (rawData.containsKey('songs') && rawData['songs'] is List) {
      List<Map<String, String>> parsedSongs = [];
      for (var item in rawData['songs']) {
        if (item is Map) {
          parsedSongs.add({
            'prompt': item['prompt']?.toString() ?? '',
            'answer': item['answer']?.toString() ?? '',
            'artist': item['artist']?.toString() ?? '',
          });
        }
      }

      if (parsedSongs.isNotEmpty) {
        if (mounted) {
          setState(() {
            songs = parsedSongs;
            _shuffled = List.from(songs)..shuffle(_rand);
            isLoadingData = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        songs = _fallbackSongs;
        _shuffled = List.from(songs)..shuffle(_rand);
        isLoadingData = false;
      });
    }
  }

  Map<String, String> get _current => _shuffled[_index % _shuffled.length];

  void _buildChoices() {
    final correct = _current;
    final others = songs.where((s) => s['answer'] != correct['answer']).toList()
      ..shuffle(_rand);
    final wrongChoices = others.take(3).toList();
    _choices = [...wrongChoices, correct]..shuffle(_rand);
  }

  void _startGame() {
    _index = 0;
    _score = 0;
    _total = 0;
    _answered = false;
    _buildChoices();
    setState(() => _gameStarted = true);
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _total++;
      if (answer == _current['answer']) _score++;
    });
  }

  void _next() {
    setState(() {
      _index++;
      if (_index >= _shuffled.length) {
        _shuffled.shuffle(_rand);
        _index = 0;
      }
      _answered = false;
      _selectedAnswer = null;
      _buildChoices();
    });
  }


  @override
  Widget build(BuildContext context) {
    if (isLoadingData || songs.isEmpty) {
      return OfflineGameScaffold(
        title: '🎵 أكمل الأغنية',
        backgroundColor: const Color(0xFF880E4F),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_showIntro) {
      return OfflineGameScaffold(
        title: '🎵 أكمل الأغنية',
        backgroundColor: const Color(0xFF880E4F),
        body: GameIntroWidget(
          title: 'أكمل الأغنية',
          icon: '🎵',
          description:
              'بداية الأغنية بتظهر، ومطلوب منك تختار الجملة الصح اللي بتيجي بعدها!\n\nاللعبة دي محتاجة ذاكرة غنائية قوية جداً!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (!_gameStarted) {
      return OfflineGameScaffold(
        title: '🎵 أكمل الأغنية',
        backgroundColor: const Color(0xFF880E4F),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎵',
                style: const TextStyle(fontSize: 90),
              ).animate().scale(),
              const SizedBox(height: 16),
              Text(
                'أكمل الأغنية!',
                style: GoogleFonts.cairo(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 8),
              Text(
                'بداية الأغنية بتظهر\nاختار الجملة الصح اللي بتيجي بعدها! 🎶',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.music_note, size: 28),
                label: Text(
                  'ابدأ غني!',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ).animate().shimmer(duration: 2.seconds),
            ],
          ),
        ),
      );
    }

    return OfflineGameScaffold(
      title: '🎵 أكمل الأغنية',
      backgroundColor: const Color(0xFF880E4F),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Text(
              '$_score / $_total',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.home, color: Colors.white70),
          onPressed: () => setState(() => _gameStarted = false),
        ),
      ],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _total == 0 ? 0 : _score / _total,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
              ),
              const SizedBox(height: 20),
              Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade900, Colors.purple.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.shade900,
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('🎵', style: TextStyle(fontSize: 30)),
                        const SizedBox(height: 8),
                        Text(
                          _current['prompt']!,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'أكمل الأغنية... ؟',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(key: ValueKey(_index))
                  .fadeIn()
                  .scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 20),
              ..._choices.asMap().entries.map((entry) {
                final i = entry.key;
                final choice = entry.value['answer']!;
                final isCorrect = choice == _current['answer'];
                final isSelected = _selectedAnswer == choice;
                Color cardColor = Colors.white.withAlpha(15);
                Color borderColor = Colors.white24;
                IconData? icon;
                if (_answered) {
                  if (isCorrect) {
                    cardColor = Colors.green.shade800.withAlpha(200);
                    borderColor = Colors.greenAccent;
                    icon = Icons.check_circle;
                  } else if (isSelected) {
                    cardColor = Colors.red.shade800.withAlpha(200);
                    borderColor = Colors.redAccent;
                    icon = Icons.cancel;
                  }
                }
                return GestureDetector(
                  onTap: () => _selectAnswer(choice),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        if (icon != null)
                          Icon(
                            icon,
                            color: isCorrect
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            size: 22,
                          )
                        else
                          CircleAvatar(
                            backgroundColor: Colors.white24,
                            radius: 13,
                            child: Text(
                              ['أ', 'ب', 'ج', 'د'][i],
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            choice,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: _answered && isCorrect
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: (i * 80).ms).fadeIn().moveX(begin: 20),
                );
              }),
              if (_answered) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🎤', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'الفنان: ${_current['artist']}',
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    'أغنية تانية 🎵',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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


