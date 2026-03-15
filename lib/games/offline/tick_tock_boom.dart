import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:vibration/vibration.dart';
import '../../widgets/offline_game_scaffold.dart';
import '../../services/raw_data_manager.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';

class TickTockBoom extends StatefulWidget {
  const TickTockBoom({super.key});

  @override
  State<TickTockBoom> createState() => _TickTockBoomState();
}

class _TickTockBoomState extends State<TickTockBoom>
    with TickerProviderStateMixin {
  bool isPlaying = false;
  String currentLetter = '';
  String currentCategory = '';
  int tickCount = 0;
  Timer? timer;
  int explosionTime = 0;
  late AnimationController _pulseController;
  late AnimationController _explosionController;
  bool hasExploded = false;
  bool isLoadingData = true;

  Map<String, List<String>> categoryLetters = {};
  Map<String, Map<String, List<String>>> allExamples = {};
  bool _isGeneratingAi = false;
  final List<String> _aiHistory = [];

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent(
        'letter_bomb',
        count: 15,
      );
      Map<String, List<String>> parsedCategories = {};
      Map<String, Map<String, List<String>>> parsedExamples = {};

      for (var item in content) {
        String cat = item['category']?.toString() ?? 'منوعات';
        String letter = item['letter']?.toString() ?? '';
        List<dynamic> examples = item['examples'] ?? [];

        if (letter.isNotEmpty) {
          if (!parsedCategories.containsKey(cat)) {
            parsedCategories[cat] = [];
            parsedExamples[cat] = {};
          }
          parsedCategories[cat]!.add(letter);
          parsedExamples[cat]![letter] = examples
              .map((e) => e.toString())
              .toList();
        }
      }

      if (_aiHistory.length > 50) {
        _aiHistory.removeRange(0, _aiHistory.length - 50);
      }

      if (parsedCategories.isNotEmpty) {
        setState(() {
          categoryLetters = parsedCategories;
          allExamples = parsedExamples;
          _shuffledCategories = categoryLetters.keys.toList()..shuffle();
          _categoryIndex = 0;
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

  // Each category mapped to letters that actually have valid answers
  final Map<String, List<String>> _fallbackCategoryLetters = {
    '🍎 فواكه': [
      'أ',
      'ب',
      'ت',
      'ج',
      'ر',
      'س',
      'ع',
      'ف',
      'ك',
      'م',
      'ن',
      'و',
      'ي',
    ],
    '🥦 خضراوات': ['ب', 'ت', 'ج', 'خ', 'ر', 'س', 'ط', 'ف', 'ك', 'م', 'ق', 'ل'],
    '🏙️ بلاد': [
      'أ',
      'ب',
      'ت',
      'ج',
      'س',
      'ع',
      'ف',
      'ق',
      'ك',
      'ل',
      'م',
      'ه',
      'ي',
    ],
    '🐘 حيوانات': [
      'أ',
      'ب',
      'ت',
      'ث',
      'ج',
      'د',
      'ذ',
      'ز',
      'س',
      'ص',
      'ض',
      'ف',
      'ق',
      'ك',
      'ن',
      'ه',
      'و',
      'ي',
    ],
    '👤 أسماء أشخاص': [
      'أ',
      'ب',
      'ت',
      'ج',
      'د',
      'ر',
      'س',
      'ع',
      'ف',
      'م',
      'ن',
      'ه',
      'ي',
      'و',
      'ل',
    ],
    '🎬 أفلام ومسلسلات': [
      'أ',
      'ب',
      'ت',
      'ج',
      'د',
      'ر',
      'س',
      'ع',
      'ف',
      'م',
      'ن',
      'ه',
      'ي',
    ],
    '⚽ رياضة': ['ب', 'ت', 'ج', 'ر', 'س', 'ش', 'ط', 'ك', 'م', 'ق', 'ل'],
    '🍔 أكلات شهيرة': ['م', 'ك', 'ف', 'ب', 'ر', 'س', 'ش', 'ط', 'ع', 'ق'],
    '🚗 ماركات سيارات': ['أ', 'ب', 'ت', 'ج', 'س', 'ف', 'م', 'ن', 'ه', 'و', 'ي'],
    '🎨 ألوان': ['أ', 'ب', 'ر', 'س', 'خ', 'ف', 'ز', 'ك'],
    '📚 أدوات مدرسية': ['ق', 'م', 'د', 'ب', 'ك', 'ح', 'أ'],
    '🧃 مشروبات': ['ع', 'ش', 'ق', 'م', 'ك', 'ي', 'ب', 'ح'],
    '🧑‍🎓 مهن': ['ط', 'م', 'س', 'ج', 'ف', 'ك', 'ن', 'ح', 'ر', 'ص'],
    '🏠 أثاث ومنزل': ['أ', 'ب', 'ت', 'ج', 'د', 'ر', 'س', 'ك', 'م', 'ن'],
    '🎤 مغنيين ومشاهير': [
      'أ',
      'ب',
      'ت',
      'ج',
      'د',
      'ر',
      'س',
      'ع',
      'ف',
      'م',
      'ن',
      'ه',
    ],
    '🦷 أعضاء الجسم': ['ر', 'ق', 'ي', 'أ', 'و', 'ك', 'ل', 'م', 'ع', 'ج'],
    '🧸 ألعاب أطفال': ['ك', 'ب', 'ت', 'س', 'ش', 'م', 'د', 'ل'],
    '🌍 دول وعواصم': [
      'أ',
      'ب',
      'ت',
      'ج',
      'س',
      'ع',
      'ف',
      'ق',
      'ك',
      'ل',
      'م',
      'ه',
    ],
    '📱 تطبيقات وتكنولوجيا': ['أ', 'ب', 'ت', 'ج', 'س', 'ف', 'م', 'ن', 'ه', 'ي'],
    '🌵 نباتات وأشجار': [
      'أ',
      'ب',
      'ت',
      'ج',
      'ر',
      'س',
      'ص',
      'ع',
      'ف',
      'ق',
      'ك',
      'م',
      'ن',
    ],
    '🌑 كواكب وفضاء': ['أ', 'ز', 'ع', 'ق', 'م', 'ن'],
    '🚢 وسائل المواصلات': [
      'أ',
      'ب',
      'ت',
      'ج',
      'د',
      'ر',
      'س',
      'ط',
      'ع',
      'ف',
      'م',
      'ق',
      'ل',
    ],
    '🎸 آلات موسيقية': [
      'أ',
      'ب',
      'ت',
      'ج',
      'د',
      'ر',
      'س',
      'ع',
      'ف',
      'ق',
      'ك',
      'م',
      'ن',
    ],
    '🍬 حلويات وحاجات حلوة': [
      'أ',
      'ب',
      'ت',
      'ج',
      'ح',
      'ر',
      'س',
      'ش',
      'ع',
      'ف',
      'ك',
      'م',
    ],
    '⌚ إكسسوارات وملابس': [
      'أ',
      'ب',
      'ت',
      'ج',
      'ح',
      'خ',
      'س',
      'ش',
      'ع',
      'ف',
      'ق',
      'م',
      'ن',
    ],
    '🎮 ألعاب فيديو': ['أ', 'ب', 'ت', 'ج', 'ف', 'ك', 'م', 'ن'],
    '🐜 حشرات وكائنات': [
      'أ',
      'ب',
      'ت',
      'ج',
      'د',
      'ذ',
      'ر',
      'س',
      'ص',
      'ع',
      'ف',
      'ق',
      'ك',
      'م',
      'ن',
    ],
  };

  List<String> _shuffledCategories = [];
  int _categoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _initFallbackExamples();
    _loadGameData();
    _shuffledCategories = categoryLetters.keys.toList()..shuffle();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _initFallbackExamples() {
    allExamples = {
      '🍎 فواكه': {
        'أ': ['أناناس', 'أفوكادو', 'إجاص'],
        'ب': ['برتقال', 'بطيخ', 'برقوق'],
        'ت': ['تفاح', 'تين', 'تمر'],
        'ج': ['جوافة', 'جوز الهند'],
        'م': ['موز', 'مانجو', 'مشمش'],
        'ع': ['عنب', 'عنب أسود'],
        'ك': ['كيوي', 'كرز', 'كمثرى'],
        'ف': ['فراولة', 'فاكهة الباشن'],
        'ر': ['رمان', 'رطب'],
        'و': ['ورد', 'وز'],
        'س': ['سفرجل', 'سبانخ فاكهة'],
        'ن': ['نارنج', 'نخلة'],
        'ي': ['يوسفي'],
      },
      '🥦 خضراوات': {
        'ب': ['بطاطس', 'بصل', 'بازلاء'],
        'ت': ['طماطم', 'ثوم'],
        'ج': ['جزر', 'جرجير'],
        'خ': ['خيار', 'خس'],
        'ر': ['رومي', 'ردش', 'رمانة'],
        'ف': ['فلفل', 'فول'],
        'ك': ['كوسة', 'كرنب'],
        'م': ['ملوخية', 'مشمش خضار'],
        'س': ['سبانخ', 'سلطة'],
        'ط': ['طماطم', 'طرخون'],
        'ق': ['قرنبيط', 'قثاء'],
        'ل': ['لفت', 'لوبيا'],
      },
      '🏙️ بلاد': {
        'أ': ['الأردن', 'أستراليا', 'ألمانيا'],
        'ب': ['بلجيكا', 'البرازيل', 'بريطانيا'],
        'ت': ['تركيا', 'تونس', 'تشاد'],
        'ج': ['الجزائر', 'جيبوتي'],
        'م': ['مصر', 'المغرب', 'موريتانيا'],
        'ف': ['فرنسا', 'فنلندا'],
        'ق': ['قطر', 'قبرص'],
        'ك': ['الكويت', 'كندا'],
        'ل': ['لبنان', 'ليبيا'],
        'ع': ['العراق', 'عمان'],
        'س': ['السعودية', 'سوريا', 'سودان'],
        'ه': ['الهند', 'هولندا'],
      },
      '🐘 حيوانات': {
        'أ': ['أسد', 'أرنب', 'أفعى'],
        'ب': ['بعير', 'بقرة', 'ببغاء'],
        'ت': ['تمساح', 'ثعلب', 'ثعبان'],
        'ج': ['جمل', 'جاموسة'],
        'ف': ['فيل', 'فهد', 'فأر'],
        'ق': ['قطة', 'قرد'],
        'ك': ['كلب', 'كنغر'],
        'ن': ['نمر', 'نسر'],
        'د': ['دولفين', 'دجاجة', 'دب'],
        'ز': ['زرافة', 'زردة'],
        'س': ['سمكة', 'سلحفاة'],
        'ه': ['هيبو', 'هدهد'],
      },
      '👤 أسماء أشخاص': {
        'أ': ['أحمد', 'آية', 'أسماء'],
        'م': ['محمد', 'مريم', 'ملك'],
        'ن': ['نور', 'نهال', 'نواف'],
        'ر': ['ريم', 'رنا', 'رامي'],
        'س': ['سارة', 'سلمى', 'سامي'],
        'ع': ['علي', 'عمر', 'عبدالله'],
        'ه': ['هيا', 'هاجر', 'هشام'],
        'ف': ['فاطمة', 'فريدة'],
        'ي': ['يارا', 'يوسف'],
      },
      '🎬 أفلام ومسلسلات': {
        'أ': ['أسود ولا أبيض', 'أفاتار'],
        'م': ['مسلسل طاش ما طاش', 'مندوب الليل'],
        'ب': ['بناتلر أونلاين', 'بيتمان'],
        'ر': ['ريا وسكينة'],
        'ف': ['فيلم جوكر'],
        'ت': ['تيتانيك'],
        'س': ['سبايدرمان'],
      },
    };
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData('tick_tock_game', {});

    if (rawData.containsKey('items') && rawData['items'] is List) {
      Map<String, List<String>> parsedCategories = {};
      Map<String, Map<String, List<String>>> parsedExamples = {};

      for (var item in rawData['items']) {
        if (item is Map) {
          String letter = item['letter']?.toString() ?? '';
          List<dynamic> examples = item['examples'] ?? [];

          if (letter.isNotEmpty && examples.isNotEmpty) {
            if (!parsedCategories.containsKey('منوعات')) {
              parsedCategories['منوعات'] = [];
              parsedExamples['منوعات'] = {};
            }
            parsedCategories['منوعات']!.add(letter);
            parsedExamples['منوعات']![letter] = examples
                .map((e) => e.toString())
                .toList();
          }
        }
      }

      if (parsedCategories.isNotEmpty) {
        if (mounted) {
          setState(() {
            categoryLetters = parsedCategories;
            allExamples = parsedExamples;
            _shuffledCategories = categoryLetters.keys.toList()..shuffle();
            isLoadingData = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        categoryLetters = _fallbackCategoryLetters;
        _shuffledCategories = categoryLetters.keys.toList()..shuffle();
        isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _pulseController.dispose();
    _explosionController.dispose();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      hasExploded = false;
      tickCount = 0;

      if (_categoryIndex >= _shuffledCategories.length) {
        _shuffledCategories.shuffle();
        _categoryIndex = 0;
      }
      currentCategory = _shuffledCategories[_categoryIndex++];

      // Pick a letter that's valid for this category and has at least one example
      List<String> validLetters =
          categoryLetters[currentCategory] ?? ['م', 'أ', 'ب', 'س', 'ك'];

      // Filter validLetters to only those that have examples
      final catExamples = allExamples[currentCategory] ?? {};
      validLetters = validLetters.where((letter) {
        final examples = catExamples[letter] ?? [];
        return examples.isNotEmpty;
      }).toList();

      if (validLetters.isEmpty) {
        // Fallback if absolutely no letters have examples (shouldn't happen with our fallback data)
        validLetters = ['م', 'أ', 'ب', 'س', 'ك'];
      }

      currentLetter = validLetters[Random().nextInt(validLetters.length)];

      explosionTime = Random().nextInt(20) + 10; // 10-30 تيك
    });

    timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      setState(() {
        tickCount++;
      });

      // Vibration intensity increases as we get closer to explosion
      final remaining = explosionTime - tickCount;
      if (remaining <= 5 && remaining > 0) {
        // Short increasing vibrations as countdown reaches end
        Vibration.hasVibrator().then((has) {
          if (has == true) {
            final duration = 50 + ((5 - remaining) * 30);
            Vibration.vibrate(
              duration: duration,
              amplitude: 80 + ((5 - remaining) * 35),
            );
          }
        });
      }

      if (tickCount >= explosionTime) {
        explode();
      }
    });
  }

  void explode() {
    timer?.cancel();
    setState(() {
      hasExploded = true;
      isPlaying = false;
    });
    _explosionController.forward(from: 0);
    // Strong explosion vibration
    Vibration.hasVibrator().then((has) {
      if (has == true) {
        Vibration.vibrate(pattern: [0, 400, 100, 400, 100, 600]);
      }
    });
  }

  void resetGame() {
    setState(() {
      isPlaying = false;
      hasExploded = false;
      tickCount = 0;
      currentLetter = '';
      currentCategory = '';
    });
    timer?.cancel();
  }


  @override
  Widget build(BuildContext context) {
    if (isLoadingData) {
      return OfflineGameScaffold(
        title: '💣 قنبلة الحروف',
        backgroundColor: const Color(0xFF1B1B1B),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return OfflineGameScaffold(
      title: '💣 قنبلة الحروف',
      backgroundColor: hasExploded ? Colors.black : const Color(0xFFC62828),
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
            onPressed: isPlaying || hasExploded || _isGeneratingAi
                ? null
                : _generateAiContent,
          ),
      ],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isPlaying && !hasExploded) ...[
                const Text('💣', style: TextStyle(fontSize: 100)),
                const SizedBox(height: 20),
                const Text(
                  'قنبلة الحروف',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  child: const Text('إيقاف اللعبة'),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFC62828),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 30),
                  label: const Text(
                    'ابدأ اللعبة',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else if (isPlaying) ...[
                const SizedBox(height: 30),
                Text(
                  'الفئة: $currentCategory',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.2),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 20 + (_pulseController.value * 15),
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            currentLetter,
                            style: const TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC62828),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 50),
                const Text(
                  'تيك توك... تيك توك...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else if (hasExploded) ...[
                ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.5,
                    end: 2.0,
                  ).animate(_explosionController),
                  child: const Text('💥', style: TextStyle(fontSize: 150)),
                ),
                const SizedBox(height: 30),
                const Text(
                  'بووووم! 💥',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'الموبايل انفجر! 😱\nاللي الموبايل في إيده هو الخسران!',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      Text(
                        '💡 أمثلة على حرف "$currentLetter" في فئة $currentCategory:',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getExamples(currentCategory, currentLetter),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.amberAccent,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: resetGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('القائمة الرئيسية'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'العب تاني 🔄',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getExamples(String category, String letter) {
    final catExamples = allExamples[category] ?? {};
    final letterExamples = catExamples[letter] ?? [];
    if (letterExamples.isEmpty) {
      return 'ابحث عن كلمات بحرف $letter في فئة $category!';
    }
    return letterExamples.take(3).map((e) => '• $e').join('\n');
  }
}


