import 'package:flutter/material.dart';
import '../../screens/global_player_selection_screen.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/offline_game_scaffold.dart';
import '../../services/raw_data_manager.dart';
import '../../services/settings_service.dart';
import '../../services/ai_service.dart';
import '../../services/score_service.dart';
import '../../widgets/premium_loading_indicator.dart';
import '../../widgets/game_intro_widget.dart';

class QuizGame extends StatefulWidget {
  const QuizGame({super.key});

  @override
  State<QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<QuizGame> {
  Set<String> selectedCategories = {};
  bool _showIntro = true;
  bool gameStarted = false;
  int currentQuestionIndex = 0;
  bool showAnswer = false;
  List<Map<String, dynamic>> gameQuestions = [];
  bool isLoadingData = true;
  bool isGeneratingAi = false;
  final scoreService = ScoreService();
  final List<String> _aiHistory = [];

  Future<void> _generateAiQuestions() async {
    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار فئة واحدة على الأقل')),
      );
      return;
    }

    setState(() => isGeneratingAi = true);

    try {
      final category = selectedCategories.join(' و ');
      int totalQuestions = min(
        30,
        10 * selectedCategories.length,
      ); // Avoid huge requests that timeout out
      final newQuestions = await AIService.fetchAiQuestions(
        category,
        count: totalQuestions,
        history: _aiHistory,
      );

      if (newQuestions.isNotEmpty) {
        for (var q in newQuestions) {
          final questionText = q['question']?.toString() ?? '';
          if (questionText.isNotEmpty) {
            _aiHistory.add(questionText);
          }
        }
        if (_aiHistory.length > 50) {
          _aiHistory.removeRange(0, _aiHistory.length - 50);
        }
      }

      if (newQuestions.isEmpty) {
        throw Exception('الذكاء الاصطناعي لم يرجع أي أسئلة، حاول مرة أخرى');
      }

        gameQuestions = [...gameQuestions, ...newQuestions];
        gameStarted = true;
        currentQuestionIndex = (gameQuestions.length - newQuestions.length).toInt();
        showAnswer = false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل توليد الأسئلة: $e')));
      }
    } finally {
      setState(() => isGeneratingAi = false);
    }
  }

  // These will be the default fallback questions
  Map<String, List<Map<String, String>>> questions = {};

  final Map<String, List<Map<String, String>>> _fallbackQuestions = {
    'ثقافة عامة': [
      {
        'question': 'ما هو الطائر الذي يضع أكبر بيضة في العالم؟',
        'answer': 'النعامة',
      },
      {
        'question': 'ما هو أصل كلمة "أطلس" التي تطلق على كتاب الخرائط؟',
        'answer': 'يوناني',
      },
      {
        'question': 'من هو أول من اكتشف الدورة الدموية الكبرى؟',
        'answer': 'ويليام هارفي',
      },
      {'question': 'ما هي أقوى عضلة في جسم الإنسان؟', 'answer': 'عضلة الفك'},
      {'question': 'ما هو لون دم الكركند (الاستاكوزا)؟', 'answer': 'أزرق'},
      {'question': 'كم عدد أضلاع جسم الإنسان؟', 'answer': '24 ضلعاً'},
      {
        'question': 'ما هو العضو الذي يستهلك 40% من أكسجين الدم؟',
        'answer': 'المخ',
      },
      {
        'question': 'ما هي الدولة التي تمتلك أكبر عدد من الأهرامات في العالم؟',
        'answer': 'السودان',
      },
      {'question': 'ما هو الحيوان الذي قلبه في رأسه؟', 'answer': 'الجمبري'},
      {
        'question': 'كم عدد لترات الدم في جسم الإنسان البالغ؟',
        'answer': 'من 5 إلى 6 لترات',
      },
      {'question': 'ما هو أقدم خط في اللغة العربية؟', 'answer': 'الخط الكوفي'},
      {
        'question': 'ما هي المادة التي يتكون منها قرن الخرتيت؟',
        'answer': 'شعر مضغوط (كيراتين)',
      },
      {'question': 'ما هو الحيوان الذي لا ينام أبداً؟', 'answer': 'القرش'},
      {
        'question': 'ما هو الشيء الذي له عين واحدة ولكنه لا يرى؟',
        'answer': 'الإبرة',
      },
      {
        'question': 'ما هو الكوكب الذي يطلق عليه "توأم الأرض"؟',
        'answer': 'كوكب الزهرة',
      },
      {'question': 'ما هي عاصمة اليابان؟', 'answer': 'طوكيو'},
      {'question': 'كم عدد ألوان قوس قزح؟', 'answer': '7 ألوان'},
      {'question': 'ما هو المعدن السائل الوحيد؟', 'answer': 'الزئبق'},
      {'question': 'من هو مكتشف الجاذبية؟', 'answer': 'إسحاق نيوتن'},
      {'question': 'ما هو أثقل الحيوانات وزناً؟', 'answer': 'الحوت الأزرق'},
      {'question': 'ما هي أكبر قارة في العالم؟', 'answer': 'آسيا'},
      {'question': 'كم عدد القلوب لدى الأخطبوط؟', 'answer': '3 قلوب'},
      {
        'question': 'ما هو الحيوان الذي يلقب بسفينة الصحراء؟',
        'answer': 'الجمل',
      },
      {
        'question': 'ما هو الغاز الذي يستخدمه النبات في عملية البناء الضوئي؟',
        'answer': 'ثاني أكسيد الكربون',
      },
      {'question': 'ما هي عاصمة فرنسا؟', 'answer': 'باريس'},
      // New Questions
      {'question': 'ما هو أطول نهر في العالم؟', 'answer': 'نهر النيل'},
      {'question': 'ما هي أصغر دولة في العالم؟', 'answer': 'الفاتيكان'},
      {'question': 'من هو مخترع المصباح الكهربائي؟', 'answer': 'توماس إديسون'},
      {
        'question': 'ما هو العنصر الكيميائي الذي يمثله الرمز Au؟',
        'answer': 'الذهب',
      },
      {'question': 'كم عدد القارات في العالم؟', 'answer': '7 قارات'},
    ],
    'رياضة': [
      {
        'question': 'كم عدد لاعبي فريق كرة القدم في الملعب؟',
        'answer': '11 لاعب',
        'icon': '⚽',
      },
      {
        'question': 'من هو اللاعب الذي فاز بأكبر عدد من كرات ذهبية؟',
        'answer': 'ليونيل ميسي',
        'icon': '🏆',
      },
      {
        'question': 'في أي عام أقيمت أول بطولة كأس عالم لكرة القدم؟',
        'answer': '1930',
        'icon': '🌎',
      },
      {
        'question': 'ما هي الدولة التي فازت بكأس العالم 2022؟',
        'answer': 'الأرجنتين',
        'icon': '🇦🇷',
      },
      {
        'question': 'كم مدة الشوط الواحد في مباراة كرة القدم؟',
        'answer': '45 دقيقة',
        'icon': '⏱️',
      },
      {
        'question': 'ما هي الرياضة التي تسمى "رياضة الملوك"؟',
        'answer': 'الفروسية',
        'icon': '🏇',
      },
      {
        'question': 'ما هو طول ماراثون الجري؟',
        'answer': '42.195 كيلومتر',
        'icon': '🏃',
      },
      {
        'question': 'كم عدد لاعبي فريق كرة السلة؟',
        'answer': '5 لاعبين',
        'icon': '🏀',
      },
      {
        'question': 'في أي مدينة أقيمت أول ألعاب أولمبية حديثة؟',
        'answer': 'أثينا',
        'icon': '🇬🇷',
      },
      {
        'question': 'من هو الملاكم الملقب بـ "الرجل الحديدي"؟',
        'answer': 'مايك تايسون',
        'icon': '🥊',
      },
      {
        'question': 'ما هو النادي الذي يلقب بـ "القلعة الحمراء" في مصر؟',
        'answer': 'النادي الأهلي',
        'icon': '🦅',
      },
      {
        'question': 'كم عدد حلقات العلم الأولمبي؟',
        'answer': '5 حلقات',
        'icon': '🏅',
      },
      {
        'question': 'من هو الهداف التاريخي لكأس العالم لكرة القدم؟',
        'answer': 'ميروسلاف كلوزه',
        'icon': '⚽',
      },
      {
        'question': 'ما هي الرياضة التي تستخدم فيها الريشة بدلاً من الكرة؟',
        'answer': 'الريشة الطائرة',
        'icon': '🏸',
      },
      {
        'question': 'كم عدد لاعبي فريق الكرة الطائرة؟',
        'answer': '6 لاعبين',
        'icon': '🏐',
      },
      {
        'question': 'ما هو لقب المنتخب المصري لكرة القدم؟',
        'answer': 'الفراعنة',
        'icon': '🇪🇬',
      },
      {
        'question': 'في أي رياضة يشتهر اسم "مايكل جوردن"؟',
        'answer': 'كرة السلة',
        'icon': '🏀',
      },
      {
        'question': 'ما هو أكبر ملعب كرة قدم في العالم من حيث السعة؟',
        'answer': 'ملعب رونغرادو مايو',
        'icon': '🏟️',
      },
      {
        'question': 'كم مرة فازت البرازيل بكأس العالم؟',
        'answer': '5 مرات',
        'icon': '🇧🇷',
      },
      {
        'question': 'ما هي الدولة المستضيفة لأولمبياد 2024؟',
        'answer': 'فرنسا (باريس)',
        'icon': '🇫🇷',
      },
      {
        'question': 'من هو أسرع رجل في العالم؟',
        'answer': 'يوسين بولت',
        'icon': '🏃‍♂️',
      },
      {
        'question': 'كم وقت الراحة في مباراة كرة القدم؟',
        'answer': '15 دقيقة',
        'icon': '⏳',
      },
      {
        'question': 'ما هي الرياضة التي تُلعب على الجليد بقرص صغير؟',
        'answer': 'هوكي الجليد',
        'icon': '🏒',
      },
      {
        'question': 'ما هو اللون الذي يرتديه متصدر سباق طواف فرنسا للدراجات؟',
        'answer': 'القميص الأصفر',
        'icon': '🚴',
      },
      {
        'question': 'من بطل دوري أبطال أوروبا 2024؟',
        'answer': 'ريال مدريد',
        'icon': '👑',
      },
      // New Questions
      {
        'question': 'في أي رياضة نستخدم كلمة "ماتش بوينت"؟',
        'answer': 'التنس',
        'icon': '🎾',
      },
      {
        'question': 'كم عدد لاعبي فريق كرة اليد؟',
        'answer': '7 لاعبين',
        'icon': '🤾',
      },
      {
        'question': 'ما هو لقب الدوري الإنجليزي الممتاز؟',
        'answer': 'البريميرليج',
        'icon': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      },
      {
        'question': 'من هو صاحب الرقم القياسي في عدد الأهداف بقميص ريال مدريد؟',
        'answer': 'كريستيانو رونالدو',
        'icon': '⚽',
      },
      {
        'question': 'ما هي المسافة التي يقطعها السباح في سباق 400 متر متنوع؟',
        'answer': '400 متر',
        'icon': '🏊',
      },
    ],
    'علوم': [
      {'question': 'ما هو الرمز الكيميائي للماء؟', 'answer': 'H2O'},
      {'question': 'ما هو أكبر كوكب في المجموعة الشمسية؟', 'answer': 'المشتري'},
      {
        'question': 'ما هو الغاز الذي يشكل أغلب الغلاف الجوي للأرض؟',
        'answer': 'النيتروجين',
      },
      {'question': 'كم عدد عظام جسم الإنسان البالغ؟', 'answer': '206 عظمة'},
      {
        'question': 'ما هو الفيتامين الذي يتم الحصول عليه من أشعة الشمس؟',
        'answer': 'فيتامين د',
      },
      {'question': 'ما هو أقرب كوكب إلى الشمس؟', 'answer': 'عطارد'},
      {'question': 'ما هي المادة التي تصنع منها الماسات؟', 'answer': 'الكربون'},
      {
        'question': 'ما هو العضو المسؤول عن تصفية الدم في الجسم؟',
        'answer': 'الكلى',
      },
      {
        'question': 'ما هو العلم الذي يدرس النجوم والكواكب؟',
        'answer': 'علم الفلك',
      },
      {'question': 'ما هي الوحدة المستخدمة لقياس القوة؟', 'answer': 'النيوتن'},
      {'question': 'ما هو الكوكب الأحمر؟', 'answer': 'المريخ'},
      {
        'question': 'ما هو الغاز الذي نتنفسه ونحتاجه للبقاء؟',
        'answer': 'الأكسجين',
      },
      {
        'question': 'ما هو الجزء في الخلية الذي يحتوي على المادة الوراثية؟',
        'answer': 'النواة',
      },
      {
        'question': 'من هو العالم الذي وضع نظرية النسبية؟',
        'answer': 'ألبرت أينشتاين',
      },
      {'question': 'ما هو أسرع شيء في الكون؟', 'answer': 'الضوء'},
      {'question': 'ما هي درجة غليان الماء؟', 'answer': '100 درجة مئوية'},
      {
        'question': 'ما هو المعدن السائل في درجات الحرارة العادية؟',
        'answer': 'الزئبق',
      },
      {
        'question': 'ما هو العصب الذي يربط العين بالمخ؟',
        'answer': 'العصب البصري',
      },
      {'question': 'كم قلب لدى دودة الأرض؟', 'answer': '5 قلوب'},
      {
        'question': 'ما هي الطبقة التي تحمي الأرض من الأشعة فوق البنفسجية؟',
        'answer': 'طبقة الأوزون',
      },
      {
        'question': 'ما هو الحيوان الذي لديه أطول فترة حمل؟',
        'answer': 'الفيل (22 شهر)',
      },
      {
        'question': 'ما هو الغاز المسبب لظاهرة الاحتباس الحراري؟',
        'answer': 'ثاني أكسيد الكربون',
      },
      {'question': 'من هو مخترع المصباح الكهربائي؟', 'answer': 'توماس إديسون'},
      {'question': 'ما هي أصغر وحدة بنائية للمادة؟', 'answer': 'الذرة'},
      {
        'question': 'ما هو الكوكب الذي يمتلك حلقات واضحة حوله؟',
        'answer': 'زحل',
      },
      // New Questions
      {'question': 'ما هو العضو الأكبر في جسم الإنسان؟', 'answer': 'الجلد'},
      {'question': 'ما هو الرمز الكيميائي للحديد؟', 'answer': 'Fe'},
      {
        'question': 'ما هو الوقود الذي تستخدمه النجوم لتوليد الطاقة؟',
        'answer': 'الهيدروجين',
      },
      {
        'question': 'كم عدد لترات الدم في جسم الإنسان تقريباً؟',
        'answer': '5 لتر',
      },
      {
        'question': 'ما هو الغاز الذي يساعد على الاشتعال؟',
        'answer': 'الأكسجين',
      },
    ],
    'تاريخ': [
      {'question': 'من هو أول إنسان صعد إلى الفضاء؟', 'answer': 'يوري جاجارين'},
      {'question': 'في أي عام بدأت الحرب العالمية الأولى؟', 'answer': '1914'},
      {
        'question': 'من هو القائد الذي فتح مصر في عهد عمر بن الخطاب؟',
        'answer': 'عمرو بن العاص',
      },
      {
        'question': 'ما هي الحضارة التي قامت ببناء الأهرامات؟',
        'answer': 'الحضارة المصرية القديمة',
      },
      {'question': 'من هو مخترع الطباعة؟', 'answer': 'يوهان غوتنبرغ'},
      {'question': 'في أي عام سقطت الدولة العباسية؟', 'answer': '1258 م'},
      {
        'question': 'من هو مؤسس الدولة الأموية؟',
        'answer': 'معاوية بن أبي سفيان',
      },
      {'question': 'في أي عام وقعت الثورة الفرنسية؟', 'answer': '1789'},
      {
        'question': 'من هو القائد الذي هزم الصليبيين في معركة حطين؟',
        'answer': 'صلاح الدين الأيوبي',
      },
      {'question': 'في أي عام تم اكتشاف أمريكا؟', 'answer': '1492 م'},
      {
        'question': 'ما هو اسم المعركة التي أنهت حكم المماليك لمصر؟',
        'answer': 'معركة الريدانية',
      },
      {
        'question': 'من هو أول رئيس للولايات المتحدة الأمريكية؟',
        'answer': 'جورج واشنطن',
      },
      {'question': 'في أي عام انتهت الحرب العالمية الثانية؟', 'answer': '1945'},
      {
        'question': 'ما هو الاسم القديم لمدينة إسطنبول؟',
        'answer': 'القسطنطينية',
      },
      {
        'question': 'من هي المرأة التي لقبت بـ "شجرة الدر"؟',
        'answer': 'عصمة الدين أم خليل',
      },
      {
        'question': 'في أي عام تم افتتاح قناة السويس للمرة الأولى؟',
        'answer': '1869',
      },
      {'question': 'من هو القائد الذي فتح الأندلس؟', 'answer': 'طارق بن زياد'},
      {'question': 'ما هو أقدم هرم في التاريخ؟', 'answer': 'هرم زوسر المدرج'},
      {'question': 'في أي عام وقع زلزال مصر الشهير؟', 'answer': '1992'},
      {
        'question': 'من هو الرسام الذي رسم لوحة العشاء الأخير؟',
        'answer': 'ليوناردو دافنشي',
      },
      {
        'question': 'ما هي العملة التي كانت تستخدم في عهد الدولة العثمانية؟',
        'answer': 'الليرة',
      },
      {
        'question': 'من هو القائد الذي لقب بـ "الأسكندر الأكبر"؟',
        'answer': 'الأسكندر المقدوني',
      },
      {
        'question': 'في أي عام تم توحيد المملكة العربية السعودية؟',
        'answer': '1932 م',
      },
      {
        'question': 'ما هو اسم الحضارة التي ظهرت في العراق قديماً؟',
        'answer': 'حضارة وادي الرافدين',
      },
      {
        'question': 'من هو الملك الذي تم اكتشاف مقبرته عام 1922؟',
        'answer': 'توت عنخ آمون',
      },
      // New Questions
      {'question': 'في أي عام وقعت ثورة يوليو في مصر؟', 'answer': '1952'},
      {'question': 'من هو صاحب لقب "أبو الهند الحديثة"؟', 'answer': 'غاندي'},
      {'question': 'في أي مدينة قتل جون كينيدي؟', 'answer': 'دالاس'},
      {
        'question': 'ما هو الاسم التاريخي لمدينة المدينة المنورة؟',
        'answer': 'يثرب',
      },
      {'question': 'من هو الملك الذي بنى هرم خوفو؟', 'answer': 'خوفو'},
    ],
    'أفلام وفن': [
      {
        'question': 'من هو مؤلف رواية هاري بوتر؟',
        'answer': 'جي كي رولينج',
        'icon': '📚',
      },
      {
        'question': 'ما هو أطول فيلم رسوم متحركة من ديزني؟',
        'answer': 'فانتازيا',
        'icon': '🎬',
      },
      {
        'question': 'من رسم لوحة الموناليزا؟',
        'answer': 'ليوناردو دافنشي',
        'icon': '🖼️',
      },
      {
        'question': 'من هو الممثل الذي لعب دور توني ستارك في أفلام مارفل؟',
        'answer': 'روبرت داوني جونيور',
        'icon': '🦸',
      },
      {
        'question': 'ما هو الفيلم الذي يحكي قصة سفينة تيتانيك؟',
        'answer': 'تيتانيك',
        'icon': '🚢',
      },
      {
        'question': 'من هو المخرج الذي صنع فيلم Inception؟',
        'answer': 'كريستوفر نولان',
        'icon': '🎥',
      },
      {
        'question': 'ما هو فيلم الرسوم المتحركة الذي فيه شخصية سيمبا؟',
        'answer': 'الأسد الملك',
        'icon': '🦁',
      },
      {
        'question': 'من هو الفنان الذي رسم لوحة النجوم الليلية (Starry Night)؟',
        'answer': 'فينسنت فان غوخ',
        'icon': '🌟',
      },
      {
        'question': 'ما هو الفيلم المصري الذي فيه أحمد زكي في دور موسيقار؟',
        'answer': 'الفيل الأزرق / ناصر أوبير',
        'icon': '🎵',
      },
      {
        'question': 'ما هي الآلة الموسيقية التي عزف عليها موزارت؟',
        'answer': 'البيانو',
        'icon': '🎹',
      },
      {
        'question': 'ما هو الفيلم الأكثر ربحاً في التاريخ؟',
        'answer': 'أفاتار',
        'icon': '💰',
      },
      {
        'question': 'من هو مؤلف رواية ألف ليلة وليلة؟',
        'answer': 'مجهول (من التراث الشعبي)',
        'icon': '📖',
      },
      {
        'question': 'في أي عام صدر فيلم تيتانيك؟',
        'answer': '1997',
        'icon': '🚢',
      },
      {
        'question': 'من هو مغني أغنية "شيل المعدة"؟',
        'answer': 'أحمد شيبة',
        'icon': '🎶',
      },
      {
        'question': 'ما هو أشهر فيلم لمخرج ستيفن سبيلبيرج؟',
        'answer': 'فكي (Jaws)',
        'icon': '🦈',
      },
      {
        'question': 'من هو الفنان الأكثر مبيعاً في التاريخ؟',
        'answer': 'مايكل جاكسون',
        'icon': '🌟',
      },
      {
        'question': 'ما هو أطول مسلسل عربي رمضاني؟',
        'answer': 'نور (120 حلقة تقريباً)',
        'icon': '📺',
      },
      {
        'question': 'ما هو لون غلاف رواية هاري بوتر والحجر الفلسفي؟',
        'answer': 'أخضر وبرتقالي (حسب الإصدار)',
        'icon': '📗',
      },
      {
        'question': 'من هو الفنان الذي رسم لوحة الصرخة (The Scream)؟',
        'answer': 'إدفارد مونش',
        'icon': '🖼️',
      },
    ],
    'تكنولوجيا': [
      {
        'question': 'من هو مؤسس شركة Apple؟',
        'answer': 'ستيف جوبز',
        'icon': '🍎',
      },
      {
        'question': 'ما هو اسم محرك البحث الأشهر في العالم؟',
        'answer': 'جوجل',
        'icon': '🔍',
      },
      {'question': 'في أي سنة صدر أول آيفون؟', 'answer': '2007', 'icon': '📱'},
      {
        'question': 'ما هي اللغة البرمجية التي تستخدمها Flutter?',
        'answer': 'Dart',
        'icon': '💻',
      },
      {
        'question': 'من هو مؤسس Facebook؟',
        'answer': 'مارك زوكربيرغ',
        'icon': '📘',
      },
      {
        'question': 'ما هو معنى اختصار CPU؟',
        'answer': 'وحدة المعالجة المركزية',
        'icon': '⚙️',
      },
      {
        'question': 'ما هي الشركة التي طورت نظام أندرويد؟',
        'answer': 'جوجل',
        'icon': '🤖',
      },
      {
        'question': 'ما هو اختصار WiFi؟',
        'answer': 'Wireless Fidelity',
        'icon': '📶',
      },
      {
        'question': 'من هو مؤسس Tesla وSpaceX؟',
        'answer': 'إيلون ماسك',
        'icon': '🚀',
      },
      {
        'question': 'ما هو أشهر نظام تشغيل للحواسب؟',
        'answer': 'Windows',
        'icon': '🖥️',
      },
      {
        'question': 'ما هو أسرع معالج للحواسب في 2024؟',
        'answer': 'Apple M3 Ultra',
        'icon': '⚡',
      },
      {
        'question': 'من هو مؤسس ويكيبيديا؟',
        'answer': 'جيمي ويلز',
        'icon': '📚',
      },
      {
        'question': 'ما هو اختصار HTML؟',
        'answer': 'HyperText Markup Language',
        'icon': '🌐',
      },
      {
        'question': 'في أي عام تأسست شركة أمازون؟',
        'answer': '1994',
        'icon': '📦',
      },
      {
        'question': 'ما هو اسم أول قمر صناعي أطلقته البشرية؟',
        'answer': 'سبوتنيك',
        'icon': '🛰️',
      },
      {
        'question': 'ما هو أكثر نظام تشغيل للموبايل استخداماً؟',
        'answer': 'أندرويد',
        'icon': '📱',
      },
      {
        'question': 'من هو مخترع البرق والصاعقة الحامية؟',
        'answer': 'بنجامين فرانكلين',
        'icon': '⚡',
      },
      {
        'question': 'ما هو معنى AI؟',
        'answer': 'Artificial Intelligence - ذكاء اصطناعي',
        'icon': '🤖',
      },
      {
        'question': 'ما هي أول لغة برمجة في التاريخ؟',
        'answer': 'Fortran',
        'icon': '💻',
      },
    ],
    '🔥 أسئلة صعبة': [
      {
        'question': 'ما هو العنصر الكيميائي ذو العدد الذري 79؟',
        'answer': 'الذهب (Au)',
        'icon': '🥇',
      },
      {
        'question': 'كم عدد عظام الرسغ في يد الإنسان؟',
        'answer': '8 عظام',
        'icon': '🦴',
      },
      {
        'question': 'ما هي أبرد نقطة في الكون؟',
        'answer': 'سديم الحرازة (-272°C)',
        'icon': '❄️',
      },
      {
        'question': 'ما هو الاسم العلمي لغاز الضحك؟',
        'answer': 'أكسيد النيتروز (N2O)',
        'icon': '😂',
      },
      {
        'question': 'في أي دولة يقع جبل فوجي؟',
        'answer': 'اليابان',
        'icon': '🗻',
      },
      {
        'question': 'كم عدد دقات قلب الإنسان في اليوم تقريباً؟',
        'answer': '100,000 دقة',
        'icon': '❤️',
      },
      {
        'question':
            'ما هو الحيوان الوحيد الذي لا يستطيع القفز رغم قدرته على القفز نظرياً؟',
        'answer': 'الفيل',
        'icon': '🐘',
      },
      {
        'question': 'ما هو أصغر عظمة في جسم الإنسان؟',
        'answer': 'عظمة الركابة في الأذن',
        'icon': '👂',
      },
      {
        'question': 'كم كيلومتراً يبعد القمر عن الأرض تقريباً؟',
        'answer': '384,400 كم',
        'icon': '🌙',
      },
      {
        'question': 'ما هو الجزء الذي يُنتج اللعاب في فم الإنسان؟',
        'answer': 'الغدد اللعابية',
        'icon': '🫦',
      },
      {
        'question': 'ما اسم الغاز المسؤول عن رائحة البيضة الفاسدة؟',
        'answer': 'كبريتيد الهيدروجين (H2S)',
        'icon': '🥚',
      },
      {
        'question': 'في أي سنة انهار جدار برلين؟',
        'answer': '1989',
        'icon': '🧱',
      },
      {
        'question': 'ما هو أكثر عنصر موجود في الكون؟',
        'answer': 'الهيدروجين',
        'icon': '🌌',
      },
      {
        'question': 'ما هي أكبر غدة في جسم الإنسان؟',
        'answer': 'الكبد',
        'icon': '🫀',
      },
      {
        'question': 'ما هو الدم الذي يحمل الأكسجين من الرئتين للجسم؟',
        'answer': 'الدم الشرياني',
        'icon': '🫁',
      },
      {
        'question': 'ما هي سرعة الضوء بالكيلومتر في الثانية تقريباً؟',
        'answer': '300,000 كم/ث',
        'icon': '💡',
      },
      {
        'question': 'كم عدد أصابع اليد لدى البشر إجمالاً (اليدين معاً)؟',
        'answer': '10 أصابع',
        'icon': '✋',
      },
      {
        'question': 'ما هو العضو الذي يستمر في النمو طوال حياة الإنسان؟',
        'answer': 'الأذن والأنف',
        'icon': '👃',
      },
      {
        'question': 'في أي دولة اخترع الإنترنت؟',
        'answer': 'الولايات المتحدة الأمريكية',
        'icon': '🌐',
      },
      {
        'question': 'ما هي معادلة أينشتاين الشهيرة للطاقة؟',
        'answer': 'E = mc²',
        'icon': '⚛️',
      },
      {
        'question': 'كم تبلغ مساحة المحيط الهادي بالكيلومتر المربع تقريباً؟',
        'answer': '165 مليون كم²',
        'icon': '🌊',
      },
      {
        'question': 'ما هو أول عنصر في الجدول الدوري؟',
        'answer': 'الهيدروجين',
        'icon': '⚗️',
      },
      {
        'question': 'كم كوكب في مجموعتنا الشمسية ليس له قمر؟',
        'answer': '2 (عطارد والزهرة)',
        'icon': '🪐',
      },
      {
        'question': 'ما اسم العالم الذي اكتشف البنسلين؟',
        'answer': 'ألكسندر فلمنج',
        'icon': '💊',
      },
      {
        'question': 'كم عدد الكروموسومات في الخلية البشرية السليمة؟',
        'answer': '46 كروموسوم',
        'icon': '🧬',
      },
      {
        'question': 'ما هو أثقل عنصر في الطبيعة؟',
        'answer': 'الأوزميوم (Osmium)',
        'icon': '⚖️',
      },
      {
        'question': 'في أي مدينة بنى نابليون بونابرت قوسه الشهير؟',
        'answer': 'باريس',
        'icon': '🗼',
      },
      {
        'question': 'ما هو أطول خندق في العالم؟',
        'answer': 'خندق ماريانا',
        'icon': '🌊',
      },
      {
        'question': 'ما هي مكونات الهواء الجاف بنسبة؟',
        'answer': '78% نيتروجين، 21% أكسجين',
        'icon': '💨',
      },
      {
        'question': 'كم طول الحبل الشوكي في جسم الإنسان تقريباً؟',
        'answer': '45 سم',
        'icon': '🦷',
      },
    ],
    '🧠 عبقري': [
      {
        'question': 'ما الذي له أسنان لكن لا يأكل؟',
        'answer': 'المشط',
        'icon': '🔠',
      },
      {
        'question': 'ما الذي يكبر كلما أخذت منه؟',
        'answer': 'الحفرة',
        'icon': '🕳️',
      },
      {
        'question': 'ما هو الشيء الذي كلما أضفت إليه قل؟',
        'answer': 'الحفرة',
        'icon': '🧩',
      },
      {
        'question': 'مريم لديها 7 بنات، ولكل بنت أخ واحد. كم عدد أولاد مريم؟',
        'answer': '8 (7 بنات + 1 ولد مشترك)',
        'icon': '👨‍👩‍👧',
      },
      {
        'question': 'ما هو أكبر رقم ممكن كتابته بثلاثة أرقام؟',
        'answer': '9^9^9 أو 9^(9^9)',
        'icon': '🔢',
      },
      {
        'question': 'لو عندك 3 تفاحات وأخذت منهم 2، كم تبقى معاك؟',
        'answer': '2 تفاحات (اللي أخدتهم)',
        'icon': '🍎',
      },
      {
        'question':
            'ما الذي يحدث مرة في الدقيقة، مرتين في اللحظة، ولا يحدث في ألف سنة؟',
        'answer': 'حرف م',
        'icon': '🔤',
      },
      {
        'question': 'أي شهر له 28 يوم؟',
        'answer': 'كل الشهور (كلها عندها على الأقل 28)',
        'icon': '📅',
      },
      {
        'question': 'لو طيرت طيارتك على الحدود، أين تدفن الناجين؟',
        'answer': 'لا تدفنهم، هم ناجين!',
        'icon': '✈️',
      },
      {
        'question': 'ما الذي يسافر حول العالم ويبقى في ركنه؟',
        'answer': 'الطابع البريدي',
        'icon': '📮',
      },
      {
        'question': 'كم عدد الشهور التي بها 30 يوم؟',
        'answer':
            '11 شهر (إبريل، يونيو، سبتمبر، نوفمبر = 4، والباقي 31 أو 28/29)',
        'icon': '🗓️',
      },
      {
        'question': 'لو أمك لها أخت، وأخت أمك لها ابن، ما علاقة هذا الابن منك؟',
        'answer': 'ابن خالتك',
        'icon': '👨‍👩‍👦',
      },
      {
        'question': 'ما هو الشيء الذي كلما نظفته، اتسخ؟',
        'answer': 'الماء (الماء نفسه)',
        'icon': '💧',
      },
      {
        'question': 'طبيب أعطى مريضه 3 حبوب كل نصف ساعة. كم ساعة ستخلص الحبوب؟',
        'answer':
            'ساعة واحدة (تاخد الأولى فوراً، الثانية بعد 30 دقيقة، الثالثة بعد 60)',
        'icon': '💊',
      },
      {
        'question': 'في السباق تجاوزت اللاعب الثاني. أنت الآن رقم كام؟',
        'answer': 'الثاني',
        'icon': '🏃',
      },
      {
        'question': 'ما الذي عنده يد لكن لا يستطيع التصفيق؟',
        'answer': 'الساعة',
        'icon': '⌚',
      },
      {
        'question': 'ما الذي يكون لك ولكنه يُستخدم أكثر من قِبل الآخرين؟',
        'answer': 'اسمك',
        'icon': '📛',
      },
      {
        'question': 'ماذا يحدث لو رميت حجراً في البحر الأبيض؟',
        'answer': 'يبتل (ويغوص)',
        'icon': '🪨',
      },
      {
        'question': 'ما هو رقم يصبح أكبر عند عكسه؟',
        'answer': '6 يُعكس يصبح 9',
        'icon': '🔄',
      },
      {
        'question': 'لديك كورة ورميتها وعادت إليك بدون أن تصطدم بأي شيء. كيف؟',
        'answer': 'رميتها للأعلى',
        'icon': '⚽',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData(
      'quiz_game',
      _fallbackQuestions,
    );

    // Parse the data (ensure it matches the required format)
    Map<String, List<Map<String, String>>> parsedQuestions = {};
    rawData.forEach((key, value) {
      if (value is List) {
        parsedQuestions[key] = value
            .map((item) {
              if (item is Map) {
                return {
                  'question': item['question']?.toString() ?? '',
                  'answer': item['answer']?.toString() ?? '',
                  'icon': item['icon']?.toString() ?? '',
                };
              }
              return <String, String>{};
            })
            .where((m) => m.isNotEmpty)
            .toList();
      }
    });

    if (mounted) {
      setState(() {
        questions = parsedQuestions.isNotEmpty
            ? parsedQuestions
            : _fallbackQuestions;
        isLoadingData = false;
      });
    }
  }

  List<Map<String, String>> getShuffledQuestions() {
    if (selectedCategories.isEmpty) return [];
    List<Map<String, String>> allQuestions = [];
    for (var category in selectedCategories) {
      if (questions.containsKey(category)) {
        allQuestions.addAll(questions[category]!);
      }
    }
    allQuestions.shuffle(Random());
    return allQuestions;
  }

  void toggleCategory(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
    });
  }

  // Removed _showAddPlayerDialog and _addPlayer as we use GlobalPlayerSelectionScreen

  void updateScore(int playerIndex, int points) {
    if (scoreService.players.isNotEmpty &&
        playerIndex < scoreService.players.length) {
      scoreService.addScore(scoreService.players[playerIndex].name, points);
      setState(() {}); // Refresh UI
    }
  }

  void nextQuestion() {
    if (SettingsService.isAiEnabled &&
        currentQuestionIndex + 1 >= gameQuestions.length) {
      _generateAiQuestions();
      return;
    }

    setState(() {
      currentQuestionIndex++;
      if (currentQuestionIndex >= gameQuestions.length) {
        gameQuestions.shuffle();
        currentQuestionIndex = 0;
      }
      showAnswer = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return OfflineGameScaffold(
        title: '💡 مسابقة المعلومات',
        backgroundColor: const Color(0xFF1A237E),
        body: GameIntroWidget(
          title: 'مسابقة المعلومات',
          icon: '💡',
          description:
              'اختبر معلوماتك في فئات كتير! ثقافة عامة، رياضة، تاريخ، تكنولوجيا وأكتر!\n\nتقدر تجاوب صح على كل الأسئلة؟',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (isLoadingData) {
      return OfflineGameScaffold(
        title: '🎯 تحدي المعرفة',
        backgroundColor: const Color(0xFF0D47A1),
        body: const PremiumLoadingIndicator(message: 'جاري تحميل الأسئلة...'),
      );
    }

    if (!gameStarted) {
      return OfflineGameScaffold(
        title: '🎯 تحدي المعرفة',
        backgroundColor: const Color(0xFF0D47A1),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              children: [
                Text(
                  'تحدي الأسئلة الكبرى',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ).animate().fadeIn().moveY(begin: -20, end: 0),
                const SizedBox(height: 30),

                const SizedBox(height: 40),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: questions.keys.map((category) {
                    final isSelected = selectedCategories.contains(category);
                    return GestureDetector(
                          onTap: () => toggleCategory(category),
                          child: AnimatedContainer(
                            duration: 300.ms,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orangeAccent
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orangeAccent
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                        );
                  }).toList(),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 50),
                if (selectedCategories.isNotEmpty)
                  isGeneratingAi
                      ? Column(
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'جاري توليد الأسئلة بالذكاء الاصطناعي...',
                              style: GoogleFonts.cairo(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GlobalPlayerSelectionScreen(
                                          gameTitle: 'تحدي المعرفة',
                                          minPlayers: 1,
                                          onStartGame: (ctx, selectedPlayers) {
                                            Navigator.pop(ctx);
                                            scoreService.setPlayers(selectedPlayers);
                                            if (SettingsService.isAiEnabled) {
                                              _generateAiQuestions();
                                            } else {
                                              setState(() {
                                                final questions =
                                                    getShuffledQuestions();
                                                if (questions.isNotEmpty) {
                                                  gameQuestions = questions;
                                                  gameQuestions.shuffle();
                                                  gameStarted = true;
                                                  currentQuestionIndex = 0;
                                                  showAnswer = false;
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'لا توجد أسئلة كافية في هذه الفئات',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              });
                                            }
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
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 10,
                                shadowColor: Colors.orangeAccent.withValues(
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

    if (isGeneratingAi && gameStarted) {
      return OfflineGameScaffold(
        title: '🎯 تحدي المعلومات',
        backgroundColor: const Color(0xFF0D47A1),
        body: const PremiumLoadingIndicator(
          message: 'الذكاء الاصطناعي يجهز دفعة أسئلة جديدة...',
        ),
      );
    }

    final currentQuestion =
        gameQuestions[currentQuestionIndex % gameQuestions.length];

    return OfflineGameScaffold(
      title: '🎯 تحدي المعلومات',
      backgroundColor: const Color(0xFF0D47A1),
      actions: [
        IconButton(
          icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white70),
          onPressed: () => setState(() => gameStarted = false),
        ),
      ],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              // Progress Section
              Text(
                'سؤال ${currentQuestionIndex + 1} من ${gameQuestions.length}',
                style: GoogleFonts.cairo(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (currentQuestionIndex + 1) / gameQuestions.length,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.orangeAccent,
                ),
                borderRadius: BorderRadius.circular(10),
                minHeight: 6,
              ),
              const SizedBox(height: 30),

              // Question Card
              GestureDetector(
                    onTap: () {
                      if (!showAnswer) setState(() => showAnswer = true);
                    },
                    child: AnimatedContainer(
                      duration: 500.ms,
                      padding: const EdgeInsets.all(30),
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 280),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentQuestion['question']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(height: 30),
                          if (showAnswer)
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'الإجابة الصحيحة:',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    currentQuestion['answer']!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().scale(curve: Curves.elasticOut)
                          else
                            Text(
                                  'انقر لرؤية الإجابة 💡',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    color: Colors.blueAccent,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(duration: 2.seconds),
                        ],
                      ),
                    ),
                  )
                  .animate(key: ValueKey(currentQuestionIndex))
                  .fadeIn()
                  .moveX(begin: 30, end: 0),

              const SizedBox(height: 20),
              if (scoreService.players.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'لوحة النقاط',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${scoreService.players.length} لاعبين',
                            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: scoreService.players.asMap().entries.map((e) {
                          return Container(
                            width: double.infinity, // Full width for better alignment
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Colors.transparent, // Transparent background
                              border: Border(bottom: BorderSide(color: Colors.white10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Name at the start
                                Text(
                                  e.value.name,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Score and Buttons at the end
                                Row(
                                  children: [
                                    Text(
                                      '${e.value.score}',
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () => updateScore(e.key, 1),
                                      child: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 36),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => updateScore(e.key, -1),
                                      child: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 36),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn().scale(),

              // Score Tracking during game

              const SizedBox(height: 30),
              if (showAnswer)
                ElevatedButton.icon(
                  onPressed: nextQuestion,
                  icon: const Icon(Icons.navigate_next_rounded, size: 28),
                  label: Text(
                    'السؤال التالي',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ).animate().fadeIn().scale(),
            ],
          ),
        ),
      ),
    );
  }
}


