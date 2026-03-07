import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../widgets/base_game_scaffold.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/global_player_selection_screen.dart';
import '../services/settings_service.dart';
import '../services/ai_service.dart';
import '../services/raw_data_manager.dart';
import '../services/online_data_service.dart';
import '../widgets/game_intro_widget.dart';

class FirstLetterGame extends StatefulWidget {
  const FirstLetterGame({super.key});

  @override
  State<FirstLetterGame> createState() => _FirstLetterGameState();
}

class _FirstLetterGameState extends State<FirstLetterGame> {
  Map<String, List<String>> categories = {};
  Map<String, List<Map<String, String>>> examples = {};
  bool _showIntro = true;
  bool isLoadingData = true;
  bool _isGeneratingAi = false;

  final List<Map<String, dynamic>> _players = [];
  int _currentPlayerTurn = 0;
  bool _setupDone = false;
  bool _gameActive = false;
  bool _roundOver = false;
  int _secondsLeft = 5;
  Timer? _timer;

  String? currentCategory;
  String? currentLetter;
  bool showExamples = false;

  List<String> _shuffledCategories = [];
  int _catIndex = 0;
  final _rand = Random();

  final Map<String, List<String>> _fallbackCategories = {
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
      'د',
      'ح',
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
      'ظ',
      'ف',
      'ق',
      'ك',
      'ن',
      'ه',
      'و',
      'ي',
    ],
    '👤 أسماء': [
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
    '⚽ رياضة': ['ب', 'ت', 'ج', 'ر', 'س', 'ش', 'ط', 'ك', 'م', 'ق', 'ل'],
    '🚗 سيارات': ['أ', 'ب', 'ت', 'ج', 'س', 'ف', 'م', 'ن', 'ه', 'و', 'ي', 'د'],
    '🎬 أفلام': [
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
    '🦋 أشياء': [
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
    // New Categories
    '🧑‍🎓 مهن': ['ط', 'م', 'س', 'ج', 'ف', 'ك', 'ن', 'ح', 'ر'],
    '🍲 أكلات': ['م', 'ك', 'ف', 'ب', 'ر', 'س', 'ش', 'ط'],
    '🥤 مشروبات': ['ع', 'ش', 'ق', 'م', 'ك', 'ي', 'ب'],
    '🎨 ألوان': ['أ', 'ب', 'ر', 'س', 'ب', 'خ', 'ف'],
    '🦷 أعضاء الجسم': ['ر', 'ق', 'ي', 'أ', 'و', 'ك', 'ل', 'م'],
    '📚 أدوات مكتبية': ['ق', 'م', 'د', 'ب', 'ك', 'ح'],
    '🏠 أثاث منزلي': ['س', 'ك', 'د', 'ت', 'م', 'ب'],
    '🌍 دول عربية': ['م', 'س', 'ع', 'ل', 'ت', 'ج', 'ق', 'ك', 'ب', 'أ', 'ف'],
    '🦸 أبطال خارقين': ['س', 'ب', 'ف', 'أ', 'ك', 'د', 'ه', 'ن', 'ر'],
    '⭐ مشاهير ورياضيين': ['م', 'ر', 'ك', 'ن', 'ل', 'أ', 'ج', 'س', 'ع', 'ف'],
  };

  final Map<String, List<Map<String, String>>> _fallbackExamples = {
    '🍎 فواكه': [
      {'letter': 'ت', 'examples': 'تفاح، توت، تين'},
      {'letter': 'م', 'examples': 'موز، مانجو، مشمش'},
      {'letter': 'ب', 'examples': 'برتقال، بطيخ، بلح'},
      {'letter': 'ع', 'examples': 'عنب، عنب أحمر، عنب أبيض'},
      {'letter': 'ك', 'examples': 'كيوي، كمثرى'},
      {'letter': 'ف', 'examples': 'فراولة، فستق'},
      {'letter': 'أ', 'examples': 'أناناس، أنار'},
      {'letter': 'ج', 'examples': 'جوافة، جريب فروت'},
      {'letter': 'ر', 'examples': 'رمان'},
      {'letter': 'س', 'examples': 'سفرجل'},
      {'letter': 'ن', 'examples': 'نبق، نارجيل'},
      {'letter': 'و', 'examples': 'وشنة'},
      {'letter': 'ي', 'examples': 'يوسفي'},
    ],
    '🥦 خضراوات': [
      {'letter': 'ب', 'examples': 'بطاطس، باذنجان، بصل'},
      {'letter': 'ط', 'examples': 'طماطم، طرخون'},
      {'letter': 'خ', 'examples': 'خيار، خس'},
      {'letter': 'ج', 'examples': 'جزر، جرجير'},
      {'letter': 'ف', 'examples': 'فلفل، فول'},
      {'letter': 'ت', 'examples': 'ترمس'},
      {'letter': 'ر', 'examples': 'رشاد'},
      {'letter': 'س', 'examples': 'سبانخ، سلق'},
      {'letter': 'ك', 'examples': 'كرنب، كوسة'},
      {'letter': 'م', 'examples': 'ملوخية، مخروطة'},
      {'letter': 'ق', 'examples': 'قلقاس، قرنبيط'},
      {'letter': 'ل', 'examples': 'فت، ليمون خضرة'},
    ],
    '🏙️ بلاد': [
      {'letter': 'م', 'examples': 'مصر، مغرب، ماليزيا'},
      {'letter': 'س', 'examples': 'سوريا، سعودية، سودان'},
      {'letter': 'ع', 'examples': 'عراق، عمان، عُمان'},
      {'letter': 'ب', 'examples': 'برازيل، بريطانيا، بلجيكا'},
      {'letter': 'ك', 'examples': 'كندا، كينيا، كوبا'},
      {'letter': 'أ', 'examples': 'ألمانيا، أمريكا، أستراليا'},
      {'letter': 'ت', 'examples': 'تونس، تركيا، تشاد'},
      {'letter': 'ج', 'examples': 'جزائر، جيبوتي، جامايكا'},
      {'letter': 'ف', 'examples': 'فرنسا، فلسطين، فنلندا'},
      {'letter': 'ق', 'examples': 'قطر، قبرص'},
      {'letter': 'ل', 'examples': 'لبنان، ليبيا'},
      {'letter': 'ه', 'examples': 'هند، هولندا'},
      {'letter': 'ي', 'examples': 'يمن، يونان'},
      {'letter': 'د', 'examples': 'دنمارك، دومينيكا'},
      {'letter': 'ح', 'examples': 'حبشة (إثيوبيا)'},
    ],
    '🐘 حيوانات': [
      {'letter': 'ف', 'examples': 'فيل، فأر، فهد'},
      {'letter': 'أ', 'examples': 'أسد، أرنب، أفعى'},
      {'letter': 'ق', 'examples': 'قط، قرد، قنفذ'},
      {'letter': 'ب', 'examples': 'بطة، بقرة، بغل'},
      {'letter': 'ك', 'examples': 'كلب، كنغر، كوالا'},
      {'letter': 'ت', 'examples': 'تمساح، تيس'},
      {'letter': 'ث', 'examples': 'ثعلب، ثعبان'},
      {'letter': 'ج', 'examples': 'جمل، جدي'},
      {'letter': 'د', 'examples': 'دب، ديك'},
      {'letter': 'ذ', 'examples': 'ذئب، ذبابة'},
      {'letter': 'ز', 'examples': 'زرافة'},
      {'letter': 'س', 'examples': 'سمكة، سلحفاة'},
      {'letter': 'ص', 'examples': 'صقر'},
      {'letter': 'ض', 'examples': 'ضفدع، ضبع'},
      {'letter': 'ظ', 'examples': 'ظبي'},
      {'letter': 'ن', 'examples': 'نمر، نسر'},
      {'letter': 'ه', 'examples': 'هدهد، قطة هيمالايا'},
      {'letter': 'و', 'examples': 'وشق، وحيد القرن'},
      {'letter': 'ي', 'examples': 'يمامة'},
    ],
    '👤 أسماء': [
      {'letter': 'م', 'examples': 'محمد، مريم، مصطفى، منى'},
      {'letter': 'أ', 'examples': 'أحمد، علي، عمر، أمل'},
      {'letter': 'ف', 'examples': 'فاطمة، فريد، فؤاد'},
      {'letter': 'س', 'examples': 'سارة، سامي، سعيد'},
      {'letter': 'ن', 'examples': 'ندى، نادر، نجلاء'},
      {'letter': 'ب', 'examples': 'باسم، بسمة'},
      {'letter': 'ت', 'examples': 'تامر، تهاني'},
      {'letter': 'ج', 'examples': 'جمال، جميلة'},
      {'letter': 'د', 'examples': 'داليا، دينا'},
      {'letter': 'ر', 'examples': 'رامي، رانيا'},
      {'letter': 'ع', 'examples': 'علاء، عبير'},
      {'letter': 'ه', 'examples': 'هادي، هناء'},
      {'letter': 'ي', 'examples': 'ياسين، ياسمين'},
      {'letter': 'و', 'examples': 'وليد، وفاء'},
      {'letter': 'ل', 'examples': 'ليلى، لؤي'},
    ],
    '⚽ رياضة': [
      {'letter': 'ك', 'examples': 'كرة القدم، كرة السلة، كرة اليد'},
      {'letter': 'ت', 'examples': 'تنس، تزلج'},
      {'letter': 'س', 'examples': 'سباحة، سباق، سكواش'},
      {'letter': 'ب', 'examples': 'بلياردو، بادمنتون'},
      {'letter': 'ج', 'examples': 'جودو، جمباز'},
      {'letter': 'ر', 'examples': 'رماية، ركض'},
      {'letter': 'ش', 'examples': 'شطرنج (رياضة ذهنية)'},
      {'letter': 'ط', 'examples': 'طائرة (كرة)'},
      {'letter': 'م', 'examples': 'ملاكمة، مصارعة'},
      {'letter': 'ق', 'examples': 'قفز طويل'},
      {'letter': 'ل', 'examples': 'لاسيه'},
    ],
    '🚗 سيارات': [
      {'letter': 'ت', 'examples': 'تويوتا، تيسلا'},
      {'letter': 'م', 'examples': 'مرسيدس، ميتسوبيشي، مازدا'},
      {'letter': 'ف', 'examples': 'فورد، فيات، فيراري'},
      {'letter': 'ك', 'examples': 'كيا، كاديلاك'},
      {'letter': 'أ', 'examples': 'أودي، أستون مارتن'},
      {'letter': 'ب', 'examples': 'بي إم دبليو، بنتلي'},
      {'letter': 'ج', 'examples': 'جيب، جاكوار'},
      {'letter': 'س', 'examples': 'سوزوكي، سيات'},
      {'letter': 'ن', 'examples': 'نيسان'},
      {'letter': 'ه', 'examples': 'هوندا، هيونداي'},
      {'letter': 'و', 'examples': 'فولفو (و بالعامية)'},
      {'letter': 'ي', 'examples': 'ياماها'},
      {'letter': 'د', 'examples': 'دودج، دايو'},
    ],
    '🎬 أفلام': [
      {'letter': 'ف', 'examples': 'فيلم الفيل الأزرق، فيلم الفرح'},
      {'letter': 'م', 'examples': 'مهمة مستحيلة، مافيا'},
      {'letter': 'س', 'examples': 'سلام يا صاحبي، سهر الليالي'},
      {'letter': 'أ', 'examples': 'آسف على الإزعاج، إبراهيم الأبيض'},
      {'letter': 'ب', 'examples': 'بوحة، بلبل حيران'},
      {'letter': 'ت', 'examples': 'تيتو، تيمور وشفيقة'},
      {'letter': 'ج', 'examples': 'جعفر العمدة (مسلسل/فيلم)'},
      {'letter': 'د', 'examples': 'دكان شحاتة'},
      {'letter': 'ر', 'examples': 'رسائل البحر'},
      {'letter': 'ع', 'examples': 'عسل أسود، عمارة يعقوبيان'},
      {'letter': 'ن', 'examples': 'ناظر (مدرسة الناظر)'},
      {'letter': 'ه', 'examples': 'همام في أمستردام'},
      {'letter': 'ي', 'examples': 'يا أنا يا خالتي'},
      {'letter': 'و', 'examples': 'واحد من الناس'},
      {'letter': 'ل', 'examples': 'لعبة الحب'},
    ],
    '🦋 أشياء': [
      {'letter': 'ق', 'examples': 'قلم، قميص، قفل'},
      {'letter': 'م', 'examples': 'مفتاح، مقص، مرآة'},
      {'letter': 'س', 'examples': 'ساعة، سكين، سماعة'},
      {'letter': 'أ', 'examples': 'أريكة، إبريق'},
      {'letter': 'ب', 'examples': 'باب، برواز'},
      {'letter': 'ت', 'examples': 'تلفزيون، تليفون'},
      {'letter': 'ج', 'examples': 'جرس، جورب'},
      {'letter': 'د', 'examples': 'دولاب، دباسة'},
      {'letter': 'ر', 'examples': 'راديو، ريشة'},
      {'letter': 'ع', 'examples': 'عربة، عقد'},
      {'letter': 'ف', 'examples': 'فستان، فانوس'},
      {'letter': 'ن', 'examples': 'نظارة، نافذة'},
      {'letter': 'ه', 'examples': 'هاتف'},
      {'letter': 'ي', 'examples': 'ياقة'},
      {'letter': 'و', 'examples': 'وسادة، ورقة'},
      {'letter': 'ل', 'examples': 'لوحة، لمبة'},
    ],
    '🧑‍🎓 مهن': [
      {'letter': 'ط', 'examples': 'طبيب، طيار'},
      {'letter': 'م', 'examples': 'مهندس، مدرس، محامي'},
      {'letter': 'س', 'examples': 'سباك، سائق'},
      {'letter': 'ج', 'examples': 'جندي، جزار'},
      {'letter': 'ف', 'examples': 'فنان، فلاح'},
      {'letter': 'ك', 'examples': 'كاتب، كهربائي'},
      {'letter': 'ن', 'examples': 'نجار، نقاش'},
      {'letter': 'ح', 'examples': 'حداد، حلاق'},
      {'letter': 'ر', 'examples': 'رسام، راقص'},
    ],
    '🍲 أكلات': [
      {'letter': 'م', 'examples': 'محشي، ملوخية، مسقعة'},
      {'letter': 'ك', 'examples': 'كشري، كبسة، كفتة'},
      {'letter': 'ف', 'examples': 'فول، فلافل، فتة'},
      {'letter': 'ب', 'examples': 'بامية، بيتزا، برجر'},
      {'letter': 'ر', 'examples': 'رز بلبن، رقاق'},
      {'letter': 'س', 'examples': 'سمك، سمان'},
      {'letter': 'ش', 'examples': 'شوربة، شاورما'},
      {'letter': 'ط', 'examples': 'طعمية، طحينة'},
    ],
    '🥤 مشروبات': [
      {'letter': 'ع', 'examples': 'عصير، عناب'},
      {'letter': 'ش', 'examples': 'شاي، شعير'},
      {'letter': 'ق', 'examples': 'قهوة، قرفة'},
      {'letter': 'م', 'examples': 'مياه، مخفوق الحليب'},
      {'letter': 'ك', 'examples': 'كاكاو، كركديه'},
      {'letter': 'ي', 'examples': 'يانسون'},
      {'letter': 'ب', 'examples': 'بيبسي، بريل'},
    ],
    '🎨 ألوان': [
      {'letter': 'أ', 'examples': 'أحمر، أزرق، أبيض، أخضر، أسود، أصفر'},
      {'letter': 'ب', 'examples': 'بنفسجي، برتقالي، بني'},
      {'letter': 'ر', 'examples': 'رمادي، رماني'},
      {'letter': 'س', 'examples': 'سماوي'},
      {'letter': 'خ', 'examples': 'خوخي'},
      {'letter': 'ف', 'examples': 'فوشيا، فضي'},
    ],
    '🦷 أعضاء الجسم': [
      {'letter': 'ر', 'examples': 'رأس، رجل، رقبة، رئة'},
      {'letter': 'ق', 'examples': 'قلب، قدم'},
      {'letter': 'ي', 'examples': 'يد'},
      {'letter': 'أ', 'examples': 'أذن، أنف، أمعاء'},
      {'letter': 'و', 'examples': 'وجه'},
      {'letter': 'ك', 'examples': 'كبد، كتف، كاحل'},
      {'letter': 'ل', 'examples': 'لسان، لثة'},
      {'letter': 'م', 'examples': 'مخ، معدة'},
    ],
    '📚 أدوات مكتبية': [
      {'letter': 'ق', 'examples': 'قلم، قاموس'},
      {'letter': 'م', 'examples': 'مسطرة، ممحاة، مقص، ميكرفون'},
      {'letter': 'د', 'examples': 'دفتر، دباسة'},
      {'letter': 'ب', 'examples': 'براية، برجل'},
      {'letter': 'ك', 'examples': 'كتاب، كراسة'},
      {'letter': 'ح', 'examples': 'حبر، حاسبة'},
    ],
    '🏠 أثاث منزلي': [
      {'letter': 'س', 'examples': 'سرير، سجادة، ستارة'},
      {'letter': 'ك', 'examples': 'كرسي، كنبة'},
      {'letter': 'د', 'examples': 'دولاب، درج'},
      {'letter': 'ت', 'examples': 'تلفزيون، تابلوه'},
      {'letter': 'م', 'examples': 'مكتب، مرآة، منضدة'},
      {'letter': 'ب', 'examples': 'بوفيه، بانيو'},
    ],
    '🌍 دول عربية': [
      {'letter': 'م', 'examples': 'مصر، مغرب، موريتانيا'},
      {'letter': 'س', 'examples': 'سوريا، سعودية، سودان، سلطنة عمان'},
      {'letter': 'ع', 'examples': 'عراق، الإمارات'},
      {'letter': 'ل', 'examples': 'لبنان، ليبيا'},
      {'letter': 'ت', 'examples': 'تونس'},
      {'letter': 'ج', 'examples': 'جزائر، جيبوتي'},
      {'letter': 'ق', 'examples': 'قطر'},
      {'letter': 'ك', 'examples': 'الكويت، كومورس'},
      {'letter': 'ب', 'examples': 'البحرين'},
      {'letter': 'أ', 'examples': 'الأردن'},
      {'letter': 'ف', 'examples': 'فلسطين'},
    ],
    '🦸 أبطال خارقين': [
      {'letter': 'س', 'examples': 'سبايدرمان، سوبرمان'},
      {'letter': 'ب', 'examples': 'باتمان'},
      {'letter': 'ف', 'examples': 'فلاش'},
      {'letter': 'أ', 'examples': 'أكوامان'},
      {'letter': 'ك', 'examples': 'كابتن أمريكا'},
      {'letter': 'د', 'examples': 'ديدبول'},
      {'letter': 'ه', 'examples': 'هولك'},
      {'letter': 'ن', 'examples': 'نور (شخصيات عربية)'},
      {'letter': 'ر', 'examples': 'رجل النمل'},
    ],
    '⭐ مشاهير ورياضيين': [
      {'letter': 'م', 'examples': 'محمد صلاح، ميسي، مارادونا'},
      {'letter': 'ر', 'examples': 'رونالدو'},
      {'letter': 'ك', 'examples': 'كريستيانو رونالدو، كيليان مبابي'},
      {'letter': 'ن', 'examples': 'نيمار'},
      {'letter': 'ل', 'examples': 'لوكا مودريتش'},
      {'letter': 'أ', 'examples': 'أنتوان غريزمان'},
      {'letter': 'ج', 'examples': 'جاك ويلشير'},
      {'letter': 'س', 'examples': 'سيرينا ويليامز'},
      {'letter': 'ع', 'examples': 'عمرو ذياب، عادل إمام'},
      {'letter': 'ف', 'examples': 'فيرجيل فان دايك'},
    ],
  };

  void generateNew() {
    if (_shuffledCategories.isEmpty ||
        _catIndex >= _shuffledCategories.length) {
      _shuffledCategories = categories.keys.toList()..shuffle();
      _catIndex = 0;
    }

    final selectedCategory = _shuffledCategories[_catIndex++];
    final letters = categories[selectedCategory]!;

    String selectedLetter;
    do {
      selectedLetter = letters[_rand.nextInt(letters.length)];
    } while (selectedLetter == currentLetter && letters.length > 1);

    setState(() {
      currentCategory = selectedCategory;
      currentLetter = selectedLetter;
      showExamples = false;
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

  void toggleExamples() {
    setState(() {
      showExamples = !showExamples;
    });
  }

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent(
        'letter_bomb',
        count: 10,
      );
      Map<String, List<String>> aiCategories = {};
      Map<String, List<Map<String, String>>> aiExamples = {};

      for (var item in content) {
        final cat = item['category']?.toString() ?? '💡 منوعات';
        final letter = item['letter']?.toString() ?? '';
        final examplesList = item['examples'];

        if (aiCategories[cat] == null) aiCategories[cat] = [];
        if (letter.isNotEmpty) aiCategories[cat]!.add(letter);

        if (aiExamples[cat] == null) aiExamples[cat] = [];
        if (letter.isNotEmpty && examplesList is List) {
          aiExamples[cat]!.add({
            'letter': letter,
            'examples': examplesList.join('، '),
          });
        }
      }

      if (aiCategories.isNotEmpty) {
        setState(() {
          categories = aiCategories;
          examples = aiExamples;
          _shuffledCategories = categories.keys.toList()..shuffle();
          _catIndex = 0;
          _setupDone = false;
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
    final rawData = await RawDataManager.getGameData('first_letter_game', {});

    if (rawData.containsKey('categories') &&
        rawData['categories'] is Map &&
        rawData.containsKey('examples') &&
        rawData['examples'] is Map) {
      Map<String, List<String>> parsedCategories = {};
      final cats = rawData['categories'] as Map;
      cats.forEach((key, value) {
        if (value is List) {
          parsedCategories[key.toString()] = List<String>.from(
            value.map((e) => e.toString()),
          );
        }
      });

      Map<String, List<Map<String, String>>> parsedExamples = {};
      final ex = rawData['examples'] as Map;
      ex.forEach((key, value) {
        if (value is List) {
          List<Map<String, String>> categoryExamples = [];
          for (var item in value) {
            if (item is Map) {
              categoryExamples.add({
                'letter': item['letter']?.toString() ?? '',
                'examples': item['examples']?.toString() ?? '',
              });
            }
          }
          parsedExamples[key.toString()] = categoryExamples;
        }
      });

      if (parsedCategories.isNotEmpty && parsedExamples.isNotEmpty) {
        if (mounted) {
          setState(() {
            categories = parsedCategories;
            examples = parsedExamples;
            isLoadingData = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        categories = _fallbackCategories;
        examples = _fallbackExamples;
        isLoadingData = false;
      });
    }
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
        title: '🔤 أول حرف',
        backgroundColor: const Color(0xFFE64A19),
        body: GameIntroWidget(
          title: 'لعبة أول حرف',
          icon: '🅰️',
          description:
              'سرعة البديهة هي الحل! أول ما الحرف يظهر، قول بسرعة الحاجة المطلوبة.\n\nركز مع التايمر عشان ميفوتكش الوقت!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (!_setupDone) {
      return BaseGameScaffold(
        title: '🔤 أول حرف',
        backgroundColor: const Color(0xFFE64A19),
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
            tooltip: 'تحديث الحروف والمواضيع',
            onPressed: _forceUpdateData,
          ),
        ],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  '🔤',
                  style: TextStyle(fontSize: 80),
                ).animate().scale(),
                const SizedBox(height: 12),
                Text(
                  'أول حرف',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'المطلوب تقول كلمة بتبدأ بالحرف اللي هيظهر في 5 ثواني!\nالسرعة هي كل حاجة ⚡',
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
                              gameTitle: 'أول حرف',
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
                        foregroundColor: const Color(0xFFE64A19),
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

    return BaseGameScaffold(
      title: '🔤 أول حرف',
      backgroundColor: const Color(0xFFE64A19),
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
                                ? const Color(0xFFE64A19)
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
                                ? const Color(0xFFE64A19).withValues(alpha: 0.7)
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
                                  foregroundColor: const Color(0xFFE64A19),
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
                          // Category Label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              currentCategory ?? '',
                              style: GoogleFonts.cairo(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ).animate().fadeIn().moveY(begin: -20),

                          const SizedBox(height: 40),

                          // Large Letter with Timer Ring
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 240,
                                height: 240,
                                child: CircularProgressIndicator(
                                  value: _secondsLeft / 5,
                                  strokeWidth: 15,
                                  color: _secondsLeft <= 1
                                      ? Colors.yellow
                                      : Colors.white,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                              Container(
                                    width: 190,
                                    height: 190,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        currentLetter ?? '',
                                        style: GoogleFonts.cairo(
                                          fontSize: 110,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFFE64A19),
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate(key: ValueKey(currentLetter))
                                  .scale(
                                    duration: 400.ms,
                                    curve: Curves.elasticOut,
                                  ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          Text(
                            'قول كلمة بسرعة! ⏳',
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 30),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _handleResult(true),
                                icon: const Icon(Icons.check_circle, size: 28),
                                label: Text(
                                  'قولتها ✅',
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
                                  'خسرت ❌',
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
                            'ممكن كنت تقول:',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Text(
                              examples[currentCategory]?.firstWhere(
                                    (e) => e['letter'] == currentLetter,
                                    orElse: () => {},
                                  )['examples'] ??
                                  'مفيش أمثلة دلوقتي 😅',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.yellowAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          ElevatedButton(
                            onPressed: _nextPlayer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFE64A19),
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
