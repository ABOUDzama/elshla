import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/base_game_scaffold.dart';
import '../widgets/game_intro_widget.dart';
import '../screens/global_player_selection_screen.dart';
import '../services/raw_data_manager.dart';
import '../services/online_data_service.dart';

class OppositeDay extends StatefulWidget {
  const OppositeDay({super.key});

  @override
  State<OppositeDay> createState() => _OppositeDayState();
}

class _OppositeDayState extends State<OppositeDay> {
  List<Map<String, dynamic>> questions = [];
  bool isLoadingData = true;
  bool _showIntro = true;

  final List<Map<String, dynamic>> _players = [];
  int _currentPlayerTurn = 0;
  bool _setupDone = false;
  bool _gameActive = false;
  bool _roundOver = false;
  int _secondsLeft = 5;
  Timer? _timer;

  final List<Map<String, dynamic>> _fallbackQuestions = [
    {
      'question': 'السماء لونها إيه؟',
      'forbidden': ['أزرق', 'زرقاء'],
      'icon': '🌤️',
    },
    {
      'question': '1 + 1 يساوي كام؟',
      'forbidden': ['2', 'إتنين', 'اتنين'],
      'icon': '➕',
    },
    {
      'question': 'عاصمة مصر إيه؟',
      'forbidden': ['القاهرة'],
      'icon': '🏙️',
    },
    {
      'question': 'الشمس بتطلع من فين؟',
      'forbidden': ['الشرق'],
      'icon': '🌅',
    },
    {
      'question': 'القطة بتقول إيه؟',
      'forbidden': ['مواء', 'مياو'],
      'icon': '🐱',
    },
    {
      'question': 'الثلج حرارته إيه؟',
      'forbidden': ['بارد', 'بردان'],
      'icon': '❄️',
    },
    {
      'question': 'الليمون طعمه إيه؟',
      'forbidden': ['حامض'],
      'icon': '🍋',
    },
    {
      'question': 'كم عدد أصابع اليد؟',
      'forbidden': ['5', 'خمسة', 'خمس'],
      'icon': '✋',
    },
    {
      'question': 'الموز لونه إيه؟',
      'forbidden': ['أصفره'],
      'icon': '🍌',
    },
    {
      'question': 'النار حرارتها إيه؟',
      'forbidden': ['حامي', 'حامية', 'سخن', 'سخنة'],
      'icon': '🔥',
    },
    {
      'question': 'القمر بيطلع إمتى؟',
      'forbidden': ['الليل', 'بالليل'],
      'icon': '🌙',
    },
    {
      'question': 'البحر فيه إيه؟',
      'forbidden': ['ماء', 'مياه'],
      'icon': '🌊',
    },
    {
      'question': 'الأسد ملك إيه؟',
      'forbidden': ['الغابة'],
      'icon': '🦁',
    },
    {
      'question': 'كم عدد أيام الأسبوع؟',
      'forbidden': ['7', 'سبعة', 'سبع'],
      'icon': '📅',
    },
    {
      'question': 'الفراولة لونها إيه؟',
      'forbidden': ['أحمر'],
      'icon': '🍓',
    },
    {
      'question': 'السيارة بتتحرك بإيه؟',
      'forbidden': ['بنزين', 'وقود'],
      'icon': '🚗',
    },
    {
      'question': 'الطائر بيعيش فين؟',
      'forbidden': ['عش', 'شجرة'],
      'icon': '🐦',
    },
    {
      'question': 'السمك بيعيش فين؟',
      'forbidden': ['ماء', 'بحر'],
      'icon': '🐟',
    },
    {
      'question': 'الوردة لونها إيه؟',
      'forbidden': ['أحمر', 'وردي'],
      'icon': '🌹',
    },
    {
      'question': 'الثلج بيتكون من إيه؟',
      'forbidden': ['ماء', 'مياه'],
      'icon': '❄️',
    },
    {
      'question': 'بتشرب إيه لما تعطش؟',
      'forbidden': ['ميه', 'عصير', 'ماء'],
      'icon': '🥤',
    },
    {
      'question': 'بتلبس إيه في رجلك؟',
      'forbidden': ['جزمة', 'شراب', 'حذاء'],
      'icon': '👟',
    },
    {
      'question': 'بتنام على إيه؟',
      'forbidden': ['سرير', 'مخدة'],
      'icon': '🛏️',
    },
    {
      'question': 'العربية بتمشي فين؟',
      'forbidden': ['شارع', 'طريق', 'أرض'],
      'icon': '🛣️',
    },
    {
      'question': 'السمك بيتنفس إيه؟',
      'forbidden': ['أكسجين', 'هواء', 'ميه'],
      'icon': '🫧',
    },
    {
      'question': 'بتاكل إيه بالمعلقة؟',
      'forbidden': ['رز', 'شوربة', 'أكل'],
      'icon': '🥄',
    },
    {
      'question': 'بتغسل إيدك بإيه؟',
      'forbidden': ['ميه', 'صابون'],
      'icon': '🧼',
    },
    {
      'question': 'الفيل حجمه إيه؟',
      'forbidden': ['كبير', 'ضخم'],
      'icon': '🐘',
    },
    {
      'question': 'السكر طعمه إيه؟',
      'forbidden': ['حلو', 'مسكر'],
      'icon': '🍬',
    },
    {
      'question': 'بتسرح شعرك بإيه؟',
      'forbidden': ['مشط', 'فرشة'],
      'icon': '💇',
    },
    {
      'question': 'بتكتب بإيه؟',
      'forbidden': ['قلم'],
      'icon': '✏️',
    },
    {
      'question': 'بتسمع بإيه؟',
      'forbidden': ['ودن', 'أذن'],
      'icon': '👂',
    },
    {
      'question': 'الطيارة بتمشي فين؟',
      'forbidden': ['جو', 'سماء'],
      'icon': '✈️',
    },
    {
      'question': 'الكورة شكلها إيه؟',
      'forbidden': ['مدور', 'دائرة'],
      'icon': '⚽',
    },
    {
      'question': 'النملة حجمها إيه؟',
      'forbidden': ['صغير', 'نونو'],
      'icon': '🐜',
    },
    // New Questions
    {
      'question': 'اسمك إيه؟',
      'forbidden': ['اسمي الحقيقي'],
      'icon': '🆔',
    },
    {
      'question': 'إحنا في فصل إيه دلوقتي؟',
      'forbidden': ['الشتاء', 'الصيف', 'الربيع', 'الخريف'],
      'icon': '🍂',
    },
    {
      'question': 'الغراب لونه إيه؟',
      'forbidden': ['أسود'],
      'icon': '🐦‍⬛',
    },
    {
      'question': 'الدم لونه إيه؟',
      'forbidden': ['أحمر'],
      'icon': '🩸',
    },
    {
      'question': 'الطفل الصغير بيشرب إيه؟',
      'forbidden': ['لبن', 'حليب'],
      'icon': '🍼',
    },
    {
      'question': 'الطيارة بتطير بجناح ولا برجل؟',
      'forbidden': ['جناح', 'أجنحة'],
      'icon': '🛫',
    },
    {
      'question': 'الفلفل الحراق طعمه إيه؟',
      'forbidden': ['حراق', 'مشطشط'],
      'icon': '🌶️',
    },
    {
      'question': 'الخشب بيغرق ولا بيعوم؟',
      'forbidden': ['بيعوم', 'يطفو'],
      'icon': '🪵',
    },
    {
      'question': 'الحديد خفيف ولا تقيل؟',
      'forbidden': ['تقيل', 'ثقيل'],
      'icon': '🏗️',
    },
    {
      'question': 'العنب لونه إيه؟',
      'forbidden': ['أخضر', 'أحمر', 'بنفسجي'],
      'icon': '🍇',
    },
    {
      'question': 'الديك بيبيض ولا بيأذن؟',
      'forbidden': ['بيأذن', 'يصيح'],
      'icon': '🐓',
    },
    {
      'question': 'إنت دلوقتي صاحي ولا نايم؟',
      'forbidden': ['صاحي', 'مفتح'],
      'icon': '👁️',
    },
    {
      'question': 'الكهرباء خطر ولا أمان؟',
      'forbidden': ['خطر'],
      'icon': '⚡',
    },
    {
      'question': 'الأسد بياكل لحمة ولا خضار؟',
      'forbidden': ['لحمة', 'لحم'],
      'icon': '🥩',
    },
    {
      'question': 'الأرنب بيحب ياكل إيه؟',
      'forbidden': ['جزر'],
      'icon': '🥕',
    },
    {
      'question': 'البيتزا شكلها إيه؟',
      'forbidden': ['مدورة', 'دائرة'],
      'icon': '🍕',
    },
    {
      'question': 'الكمبيوتر بيشتغل بـ إيه؟',
      'forbidden': ['كهرباء'],
      'icon': '💻',
    },
    {
      'question': 'السحاب لونه إيه؟',
      'forbidden': ['أبيض'],
      'icon': '☁️',
    },
    {
      'question': 'الشجر لونه إيه؟',
      'forbidden': ['أخضر'],
      'icon': '🌳',
    },
    {
      'question': 'الليل ضلمة ولا نور؟',
      'forbidden': ['ضلمة', 'ظلام'],
      'icon': '🌑',
    },
    {
      'question': 'إنت إنسان ولا حيوان؟',
      'forbidden': ['إنسان'],
      'icon': '👤',
    },
    {
      'question': 'الميه بتغلي عند درجة كام؟',
      'forbidden': ['100', 'مية'],
      'icon': '🌡️',
    },
    {
      'question': 'الزرافة رقبتها إيه؟',
      'forbidden': ['طويلة'],
      'icon': '🦒',
    },
    {
      'question': 'السلحفاة حركتها إيه؟',
      'forbidden': ['بطيئة'],
      'icon': '🐢',
    },
    {
      'question': 'الصاروخ سرعته إيه؟',
      'forbidden': ['سريع'],
      'icon': '🚀',
    },
    {
      'question': 'المنبه بيعمل إيه؟',
      'forbidden': ['بيرن', 'بيصحيني'],
      'icon': '⏰',
    },
  ];

  int currentIndex = 0;
  List<int> _shuffledIndices = [];
  int _pointer = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData('opposite_game', {});

    if (rawData.containsKey('items') && rawData['items'] is List) {
      List<Map<String, dynamic>> parsedQuestions = [];
      for (var item in rawData['items']) {
        if (item is Map) {
          parsedQuestions.add({
            'question': item['question']?.toString() ?? 'سؤال بلا نص',
            'forbidden': item['forbidden'] is List
                ? List<String>.from(item['forbidden'].map((e) => e.toString()))
                : ['لا يوجد'],
            'icon': item['icon']?.toString() ?? '🎲',
          });
        }
      }

      if (parsedQuestions.isNotEmpty) {
        if (mounted) {
          setState(() {
            questions = parsedQuestions;
            isLoadingData = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        questions = _fallbackQuestions;
        isLoadingData = false;
      });
    }
  }

  void generateNew() {
    if (_shuffledIndices.isEmpty || _pointer >= _shuffledIndices.length) {
      _shuffledIndices = List.generate(questions.length, (i) => i)..shuffle();
      _pointer = 0;
    }

    setState(() {
      currentIndex = _shuffledIndices[_pointer++];
      _secondsLeft = 5;
      _gameActive = true;
      _roundOver = false;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 0) {
        t.cancel();
        _handleResult(false);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _handleResult(bool success) {
    _timer?.cancel();
    setState(() {
      if (success && _players.isNotEmpty) {
        _players[_currentPlayerTurn]['score'] =
            (_players[_currentPlayerTurn]['score'] as int) + 1;
      }
      _gameActive = false;
      _roundOver = true;
    });
  }

  void _nextPlayer() {
    setState(() {
      _currentPlayerTurn = (_currentPlayerTurn + 1) % _players.length;
      _roundOver = false;
    });
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
    if (_showIntro) {
      return BaseGameScaffold(
        title: '🙃 عكس العكاس',
        backgroundColor: const Color(0xFF3E2723),
        body: GameIntroWidget(
          title: 'عكس العكاس',
          icon: '🙃',
          description:
              'اللعبة اللي بتشقلب الدماغ! هيظهرلك سؤال بسيط، ومطلوب منك تجاوب إجابة غلط تماماً وبسرعة في 5 ثواني!\n\nركز مع التايمر عشان ميفوتكش الوقت!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (isLoadingData || questions.isEmpty) {
      return BaseGameScaffold(
        title: '🙃 عكس العكاس',
        backgroundColor: const Color(0xFF3E2723), // Darker Brown
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!_setupDone) {
      return BaseGameScaffold(
        title: '🙃 عكس العكاس',
        backgroundColor: const Color(0xFF3E2723),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'تحديث الأسئلة',
            onPressed: _forceUpdateData,
          ),
        ],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  '🙃',
                  style: TextStyle(fontSize: 80),
                ).animate().scale(),
                const SizedBox(height: 12),
                Text(
                  'عكس العكاس',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'المطلوب تجاوب إجابة غلط تماماً وبسرعة في 5 ثواني!\nالسرعة هي كل حاجة ⚡',
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
                              gameTitle: 'عكس العكاس',
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
                                  _currentPlayerTurn = 0;
                                  _setupDone = true;
                                  _gameActive = false;
                                  _roundOver = false;
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
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3E2723),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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

    final currentQuestion = questions[currentIndex];

    return BaseGameScaffold(
      title: '🙃 عكس العكاس',
      backgroundColor: const Color(0xFF3E2723),
      actions: [
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => setState(() {
            _timer?.cancel();
            _setupDone = false;
          }),
        ),
      ],
      body: SafeArea(
        child: Column(
          children: [
            // Scoreboard (Premium)
            Container(
              height: 85,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final p = _players[index];
                  final isActive = index == _currentPlayerTurn;
                  return AnimatedContainer(
                    duration: 400.ms,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white10,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 15,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          p['name'],
                          style: GoogleFonts.cairo(
                            color: isActive
                                ? const Color(0xFF3E2723)
                                : Colors.white70,
                            fontWeight: isActive
                                ? FontWeight.w900
                                : FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${p['score']} ن',
                          style: GoogleFonts.cairo(
                            color: isActive
                                ? const Color(0xFF3E2723).withValues(alpha: 0.7)
                                : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!_gameActive && !_roundOver) ...[
                          Text(
                            'دور: ${_players[_currentPlayerTurn]['name']}',
                            style: GoogleFonts.cairo(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.yellowAccent,
                            ),
                          ).animate().fadeIn().scale(),
                          const SizedBox(height: 30),
                          ElevatedButton(
                                onPressed: generateNew,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF3E2723),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 50,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 10,
                                ),
                                child: Text(
                                  'يلا جاهز؟ 🏁',
                                  style: GoogleFonts.cairo(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.05, 1.05),
                              ),
                        ] else if (_gameActive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  currentQuestion['icon'] ?? '🙃',
                                  style: const TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  currentQuestion['question'] ?? '',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    fontSize: 24,
                                    color: const Color(0xFF3E2723),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().moveY(begin: -20),

                          const SizedBox(height: 40),

                          // Large Timer Ring
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: CircularProgressIndicator(
                                  value: _secondsLeft / 5,
                                  strokeWidth: 10,
                                  color: _secondsLeft <= 1
                                      ? Colors.redAccent
                                      : Colors.yellow,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                              Container(
                                    width: 110,
                                    height: 110,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$_secondsLeft',
                                        style: GoogleFonts.cairo(
                                          fontSize: 50,
                                          fontWeight: FontWeight.w900,
                                          color: _secondsLeft <= 1
                                              ? Colors.red
                                              : const Color(0xFF3E2723),
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate(key: ValueKey(_secondsLeft))
                                  .scale(
                                    duration: 200.ms,
                                    curve: Curves.easeOut,
                                  ),
                            ],
                          ),

                          const SizedBox(height: 40),
                          Text(
                            'أجب العكس! 🤯',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _handleResult(true),
                                icon: const Icon(Icons.check_circle, size: 28),
                                label: Text(
                                  'صح✅',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton.icon(
                                onPressed: () => _handleResult(false),
                                icon: const Icon(Icons.cancel, size: 28),
                                label: Text(
                                  'غلط❌',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black26,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (_roundOver) ...[
                          const Text(
                            'انتهى الوقت! ⏰',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 60),
                          ).animate().shake(),
                          const SizedBox(height: 20),
                          Text(
                            'الممنوع كان:',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                (currentQuestion['forbidden'] as List<dynamic>)
                                    .map(
                                      (word) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        child: Text(
                                          word.toString(),
                                          style: GoogleFonts.cairo(
                                            fontSize: 20,
                                            color: Colors.yellowAccent,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ).animate().fadeIn(),
                          const SizedBox(height: 50),
                          ElevatedButton(
                            onPressed: _nextPlayer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF3E2723),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'الدور اللي بعده 🔜',
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
