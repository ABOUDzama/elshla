import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/base_game_scaffold.dart';
import '../widgets/game_intro_widget.dart';
import '../screens/global_player_selection_screen.dart';
import '../services/online_data_service.dart';
import '../services/raw_data_manager.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';

class ReverseQuiz extends StatefulWidget {
  const ReverseQuiz({super.key});

  @override
  State<ReverseQuiz> createState() => _ReverseQuizState();
}

class _ReverseQuizState extends State<ReverseQuiz> {
  bool isLoadingData = true;
  bool _showIntro = true;
  List<Map<String, String>> questions = [];
  bool _isGeneratingAi = false;

  final List<Map<String, dynamic>> _players = [];
  int _currentPlayerTurn = 0;
  bool _setupDone = false;
  bool _gameActive = false;
  bool _roundOver = false;

  bool _isFlipped = false;
  bool _hintUsed = false;
  int _secondsLeft = 15;
  Timer? _timer;

  final List<Map<String, String>> _fallbackQuestions = [
    {
      'answer': 'أرجنتيني وبيعلب في إنتر ميامي',
      'question': 'مين هو ليونيل ميسي؟',
      'icon': '⚽',
    },
    {
      'answer': 'عاصمة مصر وأكبر مدنها',
      'question': 'إيه هي القاهرة؟',
      'icon': '🏙️',
    },
    {
      'answer': 'كوكب أحمر ورابع كوكب من الشمس',
      'question': 'إيه هو المريخ؟',
      'icon': '🔴',
    },
    {
      'answer': 'فاكهة صفراء طويلة بتحبها القرود',
      'question': 'إيه هي الموزة؟',
      'icon': '🍌',
    },
    {
      'answer': 'لعبة بـ 11 لاعب وفيها مرمى',
      'question': 'إيه هي كرة القدم؟',
      'icon': '⚽',
    },
    {
      'answer': 'شركة تفاحة مقضومة شعارها',
      'question': 'إيه هي شركة أبل؟',
      'icon': '🍏',
    },
    {
      'answer': 'أكبر حيوان في العالم بيعيش في البحر',
      'question': 'إيه هو الحوت الأزرق؟',
      'icon': '🐋',
    },
    {
      'answer': 'عملة مصر الرسمية',
      'question': 'إيه هو الجنيه المصري؟',
      'icon': '💵',
    },
    {
      'answer': 'أعلى جبل في العالم',
      'question': 'إيه هو جبل إيفرست؟',
      'icon': '🏔️',
    },
    {
      'answer': 'لون السماء في النهار',
      'question': 'إيه هو الأزرق؟',
      'icon': '🌤️',
    },
    {'answer': 'أشهر هرم في مصر', 'question': 'إيه هو هرم خوفو؟', 'icon': '🗿'},
    {
      'answer': 'أشهر نهر في أفريقيا',
      'question': 'إيه هو نهر النيل؟',
      'icon': '🌊',
    },
    {
      'answer': 'أشهر لاعب كرة سلة أمريكي',
      'question': 'إيه هو مايكل جوردان؟',
      'icon': '🏀',
    },
    {
      'answer': 'أشهر برج في فرنسا',
      'question': 'إيه هو برج إيفل؟',
      'icon': '🗼',
    },
    {
      'answer': 'أشهر مدينة في إيطاليا',
      'question': 'إيه هي روما؟',
      'icon': '🏛️',
    },
    {
      'answer': 'أشهر عالم فيزياء ألماني',
      'question': 'إيه هو أينشتاين؟',
      'icon': '🧑‍🔬',
    },
    {
      'answer': 'أشهر كوكب في المجموعة الشمسية',
      'question': 'إيه هو زحل؟',
      'icon': '🪐',
    },
    {
      'answer': 'أشهر فاكهة صيفية حمراء',
      'question': 'إيه هي البطيخ؟',
      'icon': '🍉',
    },
    {'answer': 'أشهر قارة في العالم', 'question': 'إيه هي آسيا؟', 'icon': '🌏'},
    {
      'answer': 'أشهر رياضة في العالم',
      'question': 'إيه هي كرة القدم؟',
      'icon': '⚽',
    },
    {
      'answer': 'أكبر محيط في العالم',
      'question': 'إيه هو المحيط الهادئ؟',
      'icon': '🌊',
    },
    {'answer': 'أسرع حيوان بري', 'question': 'إيه هو الفهد؟', 'icon': '🐆'},
    {
      'answer': 'معدن سائل في درجة حرارة الغرفة',
      'question': 'إيه هو الزئبق؟',
      'icon': '🌡️',
    },
    {
      'answer': 'أطول نهر في العالم',
      'question': 'إيه هو نهر النيل؟',
      'icon': '🌊',
    },
    {
      'answer': 'أول إنسان مشي على القمر',
      'question': 'مين هو نيل أرمسترونج؟',
      'icon': '👨‍🚀',
    },
    {
      'answer': 'الغاز اللي بنتنفسه عشان نعيش',
      'question': 'إيه هو الأكسجين؟',
      'icon': '💨',
    },
    {
      'answer': 'أكبر دولة في العالم من حيث المساحة',
      'question': 'إيه هي روسيا؟',
      'icon': '🇷🇺',
    },
    {
      'answer': 'الحيوان اللي بيسمى سفينة الصحراء',
      'question': 'إيه هو الجمل؟',
      'icon': '🐪',
    },
    {
      'answer': 'الشيء اللي كل ما زاد نقص',
      'question': 'إيه هو العمر؟',
      'icon': '⏳',
    },
    {
      'answer': 'عاصمة المملكة العربية السعودية',
      'question': 'إيه هي الرياض؟',
      'icon': '🇸🇦',
    },
    {
      'answer': 'مخترع المصباح الكهربائي',
      'question': 'مين هو توماس إديسون؟',
      'icon': '💡',
    },
    {
      'answer': 'أكبر طائر في العالم',
      'question': 'إيه هي النعامة؟',
      'icon': '🐦',
    },
    {
      'answer': 'اللون اللي بينتج من خلط الأحمر والأصفر',
      'question': 'إيه هو البرتقالي؟',
      'icon': '🟠',
    },
    {
      'answer': 'عدد قارات العالم',
      'question': 'كام هما 7 قارات؟',
      'icon': '🌍',
    },
    {'answer': 'أقرب كوكب للشمس', 'question': 'إيه هو عطارد؟', 'icon': '☀️'},
    {
      'answer': 'العملة المستخدمة في الاتحاد الأوروبي',
      'question': 'إيه هو اليورو؟',
      'icon': '💶',
    },
    {
      'answer': 'بطل كأس العالم 2022',
      'question': 'مين هو منتخب الأرجنتين؟',
      'icon': '🏆',
    },
    {'answer': 'صوت الحصان', 'question': 'إيه هو الصهيل؟', 'icon': '🐎'},
    {
      'answer': 'عدد أيام السنة الكبيسة',
      'question': 'كام هما 366 يوم؟',
      'icon': '📅',
    },
    {
      'answer': 'الشيء اللي له أسنان بس مش بيعض',
      'question': 'إيه هو المشط؟',
      'icon': '🪮',
    },
    {'answer': 'أذكى حيوان بحري', 'question': 'إيه هو الدولفين؟', 'icon': '🐬'},
    {
      'answer': 'البلد اللي فيها تاج محل',
      'question': 'إيه هي الهند؟',
      'icon': '🇮🇳',
    },
    {
      'answer': 'الغاز المستخدم في البالونات عشان تطير',
      'question': 'إيه هو الهيليوم؟',
      'icon': '🎈',
    },
    {
      'answer': 'أطول عظمة في جسم الإنسان',
      'question': 'إيه هي عظمة الفخذ؟',
      'icon': '🦴',
    },
    {
      'answer': 'الشيء اللي بيشوف كل حاجة بس ملوش عيون',
      'question': 'إيه هي المراية؟',
      'icon': '🪞',
    },
    {'answer': 'عاصمة فرنسا', 'question': 'إيه هي باريس؟', 'icon': '🇫🇷'},
    {
      'answer': 'الحيوان اللي بيغير لونه',
      'question': 'إيه هي الحرباء؟',
      'icon': '🦎',
    },
    {
      'answer': 'أول حرف في الحروف الهجائية',
      'question': 'إيه هو الألف؟',
      'icon': '🅰️',
    },
    {
      'answer': 'الشيء اللي بيكتب بس مبيعرفش يقرأ',
      'question': 'إيه هو القلم؟',
      'icon': '✏️',
    },
    {
      'answer': 'أكبر عضو داخل جسم الإنسان',
      'question': 'إيه هو الكبد؟',
      'icon': '🩺',
    },
    // New Questions
    {'answer': 'صوت الكلب', 'question': 'إيه هو النباح؟', 'icon': '🐕'},
    {
      'answer': 'البلد اللي فيها الأهرامات',
      'question': 'إيه هي مصر؟',
      'icon': '🇪🇬',
    },
    {
      'answer': 'الشيء اللي بتلبسه في إيدك عشان تعرف الوقت',
      'question': 'إيه هي الساعة؟',
      'icon': '⌚',
    },
    {
      'answer': 'الحشرة اللي بتصنع العسل',
      'question': 'إيه هي النحلة؟',
      'icon': '🐝',
    },
    {
      'answer': 'الصلصة اللي بتتحط على المكرونة ولونها أحمر',
      'question': 'إيه هي الصلصة / الطماطم؟',
      'icon': '🍅',
    },
    {
      'answer': 'اللاعب المصري الملقب بـ الفرعون المصري',
      'question': 'مين هو محمد صلاح؟',
      'icon': '🇪🇬',
    },
    {
      'answer': 'أكبر كوكب في المجموعة الشمسية',
      'question': 'إيه هو المشتري؟',
      'icon': '🪐',
    },
    {
      'answer': 'الشيء اللي بيخلي الطيارة تطير',
      'question': 'إيه هي المحركات / الأجنحة؟',
      'icon': '✈️',
    },
    {
      'answer': 'البلد اللي اخترعت البيتزا',
      'question': 'إيه هي إيطاليا؟',
      'icon': '🇮🇹',
    },
    {
      'answer': 'الشيء اللي بنستخدمه عشان نبرد الأكل',
      'question': 'إيه هي الثلاجة؟',
      'icon': '🧊',
    },
    {
      'answer': 'أشهر ممثلة إغراء قديمة في مارلين مورنو العرب',
      'question': 'مين هي هند رستم؟',
      'icon': '🎞️',
    },
    {
      'answer': 'العملة الرسمية للولايات المتحدة',
      'question': 'إيه هو الدولار؟',
      'icon': '💵',
    },
    {
      'answer': 'أشهر سور في الصين',
      'question': 'إيه هو سور الصين العظيم؟',
      'icon': '🇨🇳',
    },
    {
      'answer': 'الحيوان اللي بيسموه ملك الغابة',
      'question': 'إيه هو الأسد؟',
      'icon': '🦁',
    },
    {
      'answer': 'أشهر مشروب غازي لونه أسود وبطعم الكولا',
      'question': 'إيه هي كوكاكولا / بيبسي؟',
      'icon': '🥤',
    },
    {
      'answer': 'الآلة الموسيقية اللي فيها أوتار وبتتحط تحت الدقن',
      'question': 'إيه هو الكمان؟',
      'icon': '🎻',
    },
    {
      'answer': 'البرنامج اللي بنستخدمه عشان نفتح المواقع',
      'question': 'إيه هو المتصفح / براوزر؟',
      'icon': '🌐',
    },
    {
      'answer': 'الشيء اللي بنستخدمه عشان نصور بيه',
      'question': 'إيه هي الكاميرا؟',
      'icon': '📷',
    },
    {
      'answer': 'البلد اللي فيها الكعبة المشرفة',
      'question': 'إيه هي السعودية؟',
      'icon': '🕋',
    },
    {
      'answer': 'الشيء اللي بنفتحه عشان يحمينا من المطر',
      'question': 'إيه هي الشمسية؟',
      'icon': '☔',
    },
    {
      'answer': 'أشهر محرك بحث في العالم',
      'question': 'إيه هو جوجل؟',
      'icon': '🔍',
    },
    {
      'answer': 'الشيء اللي بنلبسه في عينينا عشان نشوف أحسن',
      'question': 'إيه هي النظارة؟',
      'icon': '👓',
    },
    {
      'answer': 'الغاز اللي النبات بياخده عشان يعمل بناء ضوئي',
      'question': 'إيه هو ثاني أكسيد الكربون؟',
      'icon': '🌿',
    },
    {
      'answer': 'أصغر قارة في العالم',
      'question': 'إيه هي أستراليا؟',
      'icon': '🌏',
    },
    {
      'answer': 'الشيء اللي بنغليه ونشربه ولونه بني ويسهر',
      'question': 'إيه هي القهوة؟',
      'icon': '☕',
    },
    {
      'answer': 'البلد اللي فيها تمثال الحرية',
      'question': 'إيه هي أمريكا؟',
      'icon': '🇺🇸',
    },
    {
      'answer': 'أسرع سيارة في العالم حالياً',
      'question': 'إيه هي بوغاتي؟',
      'icon': '🏎️',
    },
    {
      'answer': 'الشيء اللي بنحط عليه الأكل عشان ناكل',
      'question': 'إيه هي الترابيزة / الطاولة؟',
      'icon': '🍱',
    },
    {
      'answer': 'اللاعب الملقب بـ الدون',
      'question': 'مين هو كريستيانو رونالدو؟',
      'icon': '🇵🇹',
    },
    {
      'answer': 'أكبر دولة عربية مساحة',
      'question': 'إيه هي الجزائر؟',
      'icon': '🇩🇿',
    },
  ];

  int currentIndex = 0;
  List<int> _shuffledIndices = [];
  int _pointer = 0;

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
    setState(() => isLoadingData = true);
    final rawData = await RawDataManager.getGameData('reverse_quiz', {});

    List<Map<String, String>> parsedQuestions = [];
    if (rawData.containsKey('items') && rawData['items'] is List) {
      for (var item in rawData['items']) {
        if (item is Map) {
          parsedQuestions.add({
            'answer': item['answer']?.toString() ?? '',
            'question': item['question']?.toString() ?? '',
            'icon': item['icon']?.toString() ?? '🔄',
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        questions = parsedQuestions.isNotEmpty
            ? parsedQuestions
            : _fallbackQuestions;
        _shuffledIndices = List.generate(questions.length, (i) => i)..shuffle();
        currentIndex = _shuffledIndices[0];
        _pointer = 0;
        isLoadingData = false;
      });
    }
  }

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent(
        'reverse_quiz',
        count: 12,
      );
      List<Map<String, String>> aiQuestions = [];
      for (var item in content) {
        aiQuestions.add({
          'answer': item['answer']?.toString() ?? '',
          'question': item['question']?.toString() ?? '',
          'icon': item['icon']?.toString() ?? '🔄',
        });
      }

      if (aiQuestions.isNotEmpty) {
        setState(() {
          questions = aiQuestions;
          _shuffledIndices = List.generate(questions.length, (i) => i)
            ..shuffle();
          currentIndex = _shuffledIndices[0];
          _pointer = 0;
          _isFlipped = false;
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

  void generateNew() {
    if (_shuffledIndices.isEmpty || _pointer >= _shuffledIndices.length) {
      _shuffledIndices = List.generate(questions.length, (i) => i)..shuffle();
      _pointer = 0;
    }

    setState(() {
      currentIndex = _shuffledIndices[_pointer++];
      _secondsLeft = 15;
      _isFlipped = false;
      _hintUsed = false;
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
        if (!_isFlipped) {
          _flipCard(timeout: true);
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _flipCard({bool timeout = false}) {
    _timer?.cancel();
    setState(() {
      _isFlipped = true;
      if (timeout) {
        _roundOver = true;
      }
    });
  }

  void _useHint() {
    if (!_hintUsed && !_isFlipped && _secondsLeft > 0) {
      setState(() {
        _hintUsed = true;
      });
    }
  }

  void _handleResult(bool success) {
    setState(() {
      if (success && _players.isNotEmpty) {
        int points = _hintUsed ? 1 : 2;
        _players[_currentPlayerTurn]['score'] =
            (_players[_currentPlayerTurn]['score'] as int) + points;
      }
      _gameActive = false;
      _roundOver = true;
    });
  }

  void _nextPlayer() {
    setState(() {
      _currentPlayerTurn = (_currentPlayerTurn + 1) % _players.length;
      _roundOver = false;
      _gameActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return BaseGameScaffold(
        title: '🔄 الأسئلة المعكوسة',
        backgroundColor: const Color(0xFF00838F),
        body: GameIntroWidget(
          title: 'الأسئلة المعكوسة',
          icon: '🔄',
          description:
              'اللعبة هنا بالعكس! إحنا هنديك الإجابة، وأنت تقولنا كان إيه السؤال.. التايمر بيجري فكر بسرعة وخمن السؤال أو استسلم واقلب الكارت!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (isLoadingData || questions.isEmpty) {
      return BaseGameScaffold(
        title: '🔄 الأسئلة المعكوسة',
        backgroundColor: const Color(0xFF00838F),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!_setupDone) {
      return BaseGameScaffold(
        title: '🔄 الأسئلة المعكوسة',
        backgroundColor: const Color(0xFF00838F),
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
                  '🔄',
                  style: TextStyle(fontSize: 80),
                ).animate().scale(),
                const SizedBox(height: 12),
                Text(
                  'الأسئلة المعكوسة',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اللعبة محتاجة تركيز وسرعة بديهة!\nالتايمر 15 ثانية! خمن السؤال أو خد تلميح ⏳',
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
                              gameTitle: 'الأسئلة المعكوسة',
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
                        'اختار اللعيبة وابدأ!',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00838F),
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

    // Hint logic: split prompt to show first word
    String hintText = "التلميح: ";
    if (_hintUsed && currentQuestion['question'] != null) {
      List<String> words = currentQuestion['question']!.split(' ');
      if (words.length > 2) {
        hintText += "${words[0]} ${words[1]}...";
      } else {
        hintText += words[0];
      }
    } else {
      hintText += "الكلمات الأولى";
    }

    return BaseGameScaffold(
      title: '🔄 الأسئلة المعكوسة',
      backgroundColor: const Color(0xFF00838F),
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
            // Scoreboard
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
                                ? const Color(0xFF00838F)
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
                                ? const Color(0xFF00838F).withValues(alpha: 0.7)
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
                                  foregroundColor: const Color(0xFF00838F),
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
                        ] else if (_gameActive ||
                            (_roundOver && _isFlipped)) ...[
                          // Timer Ring
                          if (!_isFlipped)
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CircularProgressIndicator(
                                    value: _secondsLeft / 15,
                                    strokeWidth: 8,
                                    color: _secondsLeft <= 5
                                        ? Colors.redAccent
                                        : Colors.yellowAccent,
                                    backgroundColor: Colors.white12,
                                  ),
                                ),
                                Text(
                                      '$_secondsLeft',
                                      style: GoogleFonts.cairo(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        color: _secondsLeft <= 5
                                            ? Colors.redAccent
                                            : Colors.white,
                                      ),
                                    )
                                    .animate(key: ValueKey(_secondsLeft))
                                    .scale(duration: 200.ms),
                              ],
                            ),
                          const SizedBox(height: 20),

                          // Card Area
                          SizedBox(
                            height: 250,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: _isFlipped
                                  ? _buildBackCard(currentQuestion)
                                  : _buildFrontCard(currentQuestion),
                            ),
                          ),

                          const SizedBox(height: 30),

                          if (!_isFlipped) ...[
                            // Hint Button
                            OutlinedButton.icon(
                              onPressed: _useHint,
                              icon: const Icon(Icons.lightbulb),
                              label: Text(
                                _hintUsed
                                    ? hintText
                                    : 'تلميح (أول كلمتين من السؤال)',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.yellowAccent,
                                side: const BorderSide(
                                  color: Colors.yellowAccent,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ).animate().fadeIn(),
                            const SizedBox(height: 15),
                            ElevatedButton.icon(
                              onPressed: _flipCard,
                              icon: const Icon(Icons.flip_camera_android),
                              label: Text(
                                'قلب الكارت (إظهار السؤال)',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.teal.shade900,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ).animate().fadeIn(),
                          ] else if (!_roundOver) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _handleResult(true),
                                  icon: const Icon(
                                    Icons.check_circle,
                                    size: 28,
                                  ),
                                  label: Text(
                                    'صح (+${_hintUsed ? 1 : 2})',
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.green.shade700,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
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
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn().slideY(begin: 0.5),
                          ],

                          if (_roundOver) ...[
                            const SizedBox(height: 20),
                            if (_secondsLeft <= 0)
                              const Text(
                                'انتهى الوقت! ⏰',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  color: Colors.yellowAccent,
                                ),
                              ).animate().shake(),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _nextPlayer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF00838F),
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

  Widget _buildFrontCard(Map<String, String> question) {
    return Container(
      key: const ValueKey(false),
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(
                'الإجابة هي:',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            question['answer'] ?? '',
            style: GoogleFonts.cairo(
              fontSize: 26,
              color: Colors.black87,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(Map<String, String> question) {
    return Container(
      key: const ValueKey(true),
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.cyan.shade900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.5),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.help_outline, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'السؤال كان:',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            question['question'] ?? '',
            style: GoogleFonts.cairo(
              fontSize: 26,
              color: Colors.yellowAccent,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
