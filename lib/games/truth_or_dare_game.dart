import 'package:flutter/material.dart';
import '../screens/global_player_selection_screen.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/base_game_scaffold.dart';
import '../services/raw_data_manager.dart';
import '../services/online_data_service.dart';
import '../services/ai_service.dart';
import '../widgets/premium_loading_indicator.dart';
import '../services/settings_service.dart';
import '../widgets/game_intro_widget.dart';

class TruthOrDareGame extends StatefulWidget {
  const TruthOrDareGame({super.key});

  @override
  State<TruthOrDareGame> createState() => _TruthOrDareGameState();
}

class _TruthOrDareGameState extends State<TruthOrDareGame> {
  List<String> truths = [];
  List<String> dares = [];
  bool isLoadingData = true;
  bool _showIntro = true;
  bool _isGeneratingAi = false;

  void _generateAiContent() async {
    if (!SettingsService.isAiEnabled) return;

    setState(() => _isGeneratingAi = true);
    try {
      final content = await AIService.fetchGameContent(
        'truth_or_dare',
        count: 20,
      );
      List<String> newTruths = [];
      List<String> newDares = [];

      for (var item in content) {
        if (item['type'] == 'truth') {
          newTruths.add(item['prompt']?.toString() ?? '');
        } else {
          newDares.add(item['prompt']?.toString() ?? '');
        }
      }

      if (newTruths.isNotEmpty || newDares.isNotEmpty) {
        setState(() {
          if (newTruths.isNotEmpty) truths = newTruths;
          if (newDares.isNotEmpty) dares = newDares;
          _shuffledTruths = [];
          _shuffledDares = [];
          _truthIndex = 0;
          _dareIndex = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم توليد مواضيع جديدة بالذكاء الاصطناعي! ✨'),
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

  final List<String> _fallbackTruths = [
    'ما هو أكبر كذبة قلتها في حياتك؟',
    'مين في الأوضة ده تحبه أكتر من غيره؟',
    'ما هو أحرج موقف مر عليك؟',
    'هل سرقت حاجة من قبل وإيه؟',
    'من هو أحسن إنسان قابلته في حياتك؟',
    'ما هو أكبر خوف عندك؟',
    'هل حبيت حد من الأوضة دي من غير ما تقوله؟',
    'ما هو أسوأ هدية استلمتها؟',
    'هل عملت حاجة وقلت على غيرك؟',
    'ما هو أكبر سر عندك لحد دلوقتي؟',
    'هل بكيت على فيلم عربي؟ أيه؟',
    'مين في الأوضة بيعمل أكتر حاجة بتغيظك؟',
    'ما هو آخر حلم حلمته؟',
    'هل حبيت حد صدقك وأنت ما كنتش بتحبه؟',
    'ما هي الوظيفة اللي كنت عاوز تشتغلها وأنت صغير؟',
    'ما هو أغلى شيء كسرته في حياتك؟',
    'هل قلت كلمة "بحبك" وأنت بتقصدها فعلاً؟',
    'ما هو أحرج شيء اكتشف عنك عيلتك؟',
    'هل نمت في الفصل أو الشغل؟',
    'مين فيكم بتنام أكتر من 10 ساعات في اليوم؟',
    'ما هو أغرب أكلة أكلتها في حياتك؟',
    'إيه آخر حاجة بكيت عليها؟',
    'هل تفتح محادثة وتعمل إنك ما شوفتهاش؟',
    'مين اللي بتعتقد إنه بيحب نفسه أكتر الناس في الأوضة دي؟',
    'هل حكيت كذبة في السنة الماضية وانكشفت؟',
    'ما هو أكبر حلم عندك في الحياة؟',
    'هل عندك عادة بتتحرج منها؟',
    'لو كنت تقدر ترجع لقرار واحد في حياتك، إيه هو؟',
    'هل عندك شخصية خيالية بتتمنى تكون زيها؟',
    'ما هو أكتر إيموجي بتبعته في اليوم؟',
    'ما هو أحسن شيء في شخصيتك؟',
    'ما هو أسوأ شيء في شخصيتك؟',
    'مين اللي أثّر فيك أكتر في حياتك؟',
    'هل عملت حاجة وبعدين ندمت عليها فوراً؟',
    'ما هو أحرج بوست نشرته على السوشيال ميديا؟',
    'هل قلبك اتكسر قبل كده؟',
    'إيه أكتر حاجة بتخاف تعترف بيها؟',
    'مين أذكى واحد في الأوضة دي برأيك؟',
    'ما هو الشيء اللي تتمنى تتعلمه لكن مفعلتش؟',
    'هل كنت بتغش في الامتحانات؟',
    'لو قدرت تقرأ أفكار شخص في الأوضة دي، مين هيكون؟',
    'ما هو أكتر شيء بتحسدوا عليه غيرك؟',
    'هل قلت على حد كذبة وما اعترفتش بيها لحد دلوقتي؟',
    'إيه أكتر حاجة بتتمنى تتغير في نفسك؟',
    'هل نمت وصحيت وأنت في مكان مش بيتك؟ إيه القصة؟',
    'ما هو أكتر شيء بتفعله لما تكون لوحدك في الأوضة؟',
    'لو قدرت تتبادل حياتك مع حد في الأوضة، مين هيكون ولييه؟',
    'هل عندك عدو حقيقي في حياتك؟',
    'ما هو أصعب قرار اتخذته في حياتك؟',
    'مين فيكم الأكثر عناداً؟',
    'هل تمنيت يوماً تكون شخص تاني؟',
    'إيه أكتر مكان بتحبه في الدنيا؟',
    'مين أول شخص بتكلمه لما بتيجيك مشكلة؟',
    'هل عندك هواية خفية ما حدش يعرف عنها؟',
    'ما هو أكبر درس اتعلمته في حياتك؟',
    'لو عرفت إن الدنيا ستنتهي بكره، هتعمل إيه النهارده؟',
    'هل حصل إنك اتجاهلت حد واحتجته بعدين؟',
    'ما هي الكلمة اللي أحرجتك وقلتها غلط في ناس؟',
    'هل عندك صاحب بتقول عنه صديق بس في الحقيقة ميقدرش؟',
    'مين فيكم بيتقل على نفسه قبل أي قرار كبير؟',
    'ما هو أغرب شيء كنت بتخاف منه وأنت صغير؟',
    'هل سبق لك أن تظاهرت بالمرض للهروب من موعد؟',
    'ما هو الشيء الذي تفعله سراً وتظن أنه غريب؟',
    'هل قرأت رسائل شخص آخر دون علمه؟',
    'ما هي أكثر صفة تكرهها في أعز أصدقائك؟',
    'هل سبق لك أن أكلت شيئاً من الأرض؟',
    'ما هو الشيء الذي لا يعرفه أهلك عنك حتى الآن؟',
    'هل سبق لك أن أعجبت بشخص هو صديق لأحد إخوتك؟',
    'ما هي أطول مدة قضيتها دون استحمام؟',
    'هل سبق لك أن كذبت بشأن عمرك؟',
    'ما هو الشيء الذي يجعلك تشعر بالغيرة بسرعة؟',
    'هل سبق لك أن أجريت عملية تجميل أو تمنيت ذلك؟',
    'ما هو أغرب حلم حلمته عن شخص في هذه الغرفة؟',
    'هل سبق لك أن وقعت في حب شخصين في نفس الوقت؟',
    'ما هو الشيء الذي يجعلك تفقد أعصابك فوراً؟',
    'هل سبق لك أن سرقت قلماً أو شيئاً بسيطاً من مكان عملك؟',
    'ما هو أكثر شيء تندم على شرائه؟',
    'هل سبق لك أن تظاهرت بأنك لا تعرف شخصاً في الشارع؟',
    'ما هو الشيء الذي يجعلك تشعر بالخجل من نفسك؟',
    'هل سبق لك أن كذبت على والديك بشأن مكان تواجدك؟',
    'ما هي أكثر ذكرى تريد مسحها من ذاكرتك؟',
    'هل سبق لك أن أعجبت بأستاذك في المدرسة؟',
    'ما هو الشيء الذي يجعلك تشعر بالضعف؟',
    'هل سبق لك أن خنت ثقة شخص وضعها فيك؟',
    'ما هي الكذبة التي تكررها دائماً؟',
    'هل سبق لك أن ندمت على رسالة أرسلتها لشخص ما؟',
    'ما هو الشيء الذي تفتخر به سراً؟',
    'هل سبق لك أن بكيت بسبب تعليق على السوشيال ميديا؟',
    'ما هو أكثر شيء يقلقك بشأن المستقبل؟',
    'هل سبق لك أن سهرت طوال الليل تفكر في شخص؟',
    'ما هي الصفة التي تتمنى لو كانت موجودة في شريك حياتك القادم؟',
    'هل سبق لك أن شعرت أنك وحيد رغم وجود الناس حولك؟',
    'ما هو الشيء الذي يجعلك تشعر بالسعادة الحقيقية؟',
    'هل سبق لك أن اختلقت قصة لتبدو مثيراً للاهتمام؟',
    'ما هو أكثر شيء تخشاه في العلاقات؟',
    'هل سبق لك أن تمنيت العيش في زمن آخر؟',
    'ما هو الشيء الذي يجعلك تبتسم رغماً عنك؟',
    'هل سبق لك أن شعرت بالظلم ولم تدافع عن نفسك؟',
    'ما هي أكبر تضحية قدمتها من أجل شخص آخر؟',
    'هل سبق لك أن كتمت مشاعرك تجاه شخص خوفاً من الرفض؟',
    'ما هو الشيء الذي يجعلك تشعر بالأمل؟',
    'هل سبق لك أن شعرت بالندم لأنك لم تقل "شكراً" لشخص ما؟',
    'ما هي العادة التي تريد التخلص منها بشدة؟',
    'هل سبق لك أن شعرت بالخوف من النجاح؟',
    'ما هو الشيء الذي يجعلك تشعر بالانتماء؟',
    'هل سبق لك أن شعرت بأنك غير مفهوم من الآخرين؟',
    'ما هي الكلمة التي تصف حياتك الآن؟',
    'هل سبق لك أن شعرت بالامتنان لشيء بسيط جداً؟',
    'ما هو الشيء الذي يجعلك تشعر بالحنين؟',
    'هل سبق لك أن ندمت على فرصة ضاعت منك؟',
    'ما هي الصفة التي تحبها في نفسك أكثر من غيرها؟',
    'هل سبق لك أن شعرت بأنك مراقب من شخص ما؟',
    'ما هو الشيء الذي يجعلك تشعر بالهدوء؟',
    'هل سبق لك أن شعرت بالرغبة في الهروب من كل شيء؟',
    'ما هي الرسالة التي تريد إيصالها لشخص لم يعد في حياتك؟',
    'هل سبق لك أن شعرت بالفخر لشخص غريب؟',
    'ما هو الشيء الذي يجعلك تشعر بالقوة؟',
    'هل سبق لك أن ندمت على كلمة جارحة قلتها لشخص تحبه؟',
    'ما هي الحكمة التي تؤمن بها في حياتك؟',
    'هل سبق لك أن شعرت بأنك محظوظ جداً؟',
    'ما هو الشيء الذي يجعلك تشعر بالدهشة؟',
    'هل سبق لك أن تمنيت لو كان بإمكانك تغيير اسمك؟',
    'ما هي الذكرى التي تجعلك تضحك كلما تذكرتها؟',
    'هل سبق لك أن شعرت بالتفاؤل في وقت صعب؟',
    'ما هو الشيء الذي يجعلك تشعر بالراحة النفسية؟',
    'هل سبق لك أن ندمت على قرار اتخذته بعاطفتك؟',
    'ما هي المهارة التي تمنيت لو تعلمتها في طفولتك؟',
    'هل سبق لك أن شعرت بأنك في المكان الخطأ؟',
    'ما هو الشيء الذي يجعلك تشعر بالرضا عن حياتك؟',
    'هل سبق لك أن شعرت بأنك تفتقد شخصاً لا تعرفه؟',
    'ما هي الكلمة التي تريد سماعها الآن؟',
    'هل سبق لك أن شعرت بالفرح لنجاح منافس لك؟',
    'ما هو الشيء الذي يجعلك تشعر بالخصوصية؟',
    'هل سبق لك أن شعرت بالرغبة في تغيير مسار حياتك بالكامل؟',
    'ما هي أغلى ذكرى تملكها؟',
    'هل سبق لك أن شعرت بأنك أثرت في حياة شخص آخر إيجابياً؟',
    'ما هو الشيء الذي يجعلك تشعر بالإلهام؟',
    'هل سبق لك أن شعرت بالسكينة في الطبيعة؟',
    'ما هي الكلمة التي تصف علاقتك بأهلك؟',
    'هل سبق لك أن ندمت على عدم الاعتراف بمشاعرك؟',
    'ما هو الشيء الذي يجعلك تشعر بالثقة في المستقبل؟',
    'هل سبق لك أن شعرت بأنك قمت بعمل بطولي؟',
    'ما هي الصفة التي تجذبك في الناس فوراً؟',
    'هل سبق لك أن شعرت بالامتنان لصعوبة مررت بها؟',
    'ما هو الشيء الذي يجعلك تشعر بأنك على قيد الحياة حقاً؟',
  ];

  final List<String> _fallbackDares = [
    'ابقى وصف نفسك بثلاث كلمات فقط!',
    'اعمل صوت حيوان من اختيار المجموعة لمدة 10 ثواني!',
    'قلّد شخص من الأوضة دي من غير ما تقول اسمه!',
    'ابقى شيل الموبايل فوق دماغك لمدة دقيقة!',
    'اكتب اسم حبيبك/حبيبتك على الهواء بلسانك!',
    'احكي نكتة، لو ما ضحكناش تتعاقب!',
    'اتصل بشخص عشوائي من كونتاكتاتك وقوله "بحبك يا حلو"!',
    'ابعت ستيكر محرج لآخر شخص كلمته!',
    'ارقص لمدة 30 ثانية من غير موسيقى!',
    'قلّد صوت شخص مشهور وأحنا نخمن!',
    'اعمل بوست على انستجرام أو واتساب مع الجملة "أنا شخصية رائعة"!',
    'قف على رجل واحدة لمدة 30 ثانية!',
    'اقرأ آخر رسالة واتساب عندك بصوت عالي!',
    'ابقى اعمل وجه حزين وكمل كده لحد ما نقولك وقف!',
    'غنّي أي أغنية بأعلى صوتك لمدة 20 ثانية!',
    'اتخيل إنك بتتكلم مع فنان مشهور وحكي المحادثة!',
    'ابقى امشي زي بطه في الأوضة ثلاث مرات!',
    'افتح التطبيقات على موبايلك واقرأ لنا محتوى أول أبليكيشن هايجيك!',
    'اعمل تعبير وجه غضبان لمدة دقيقة كاملة!',
    'ابقى قول "شكراً" لأول 3 أشياء هتشوفها!',
    'اعمل سيلفي وجهك زعلان وابعته لأهلك!',
    'حاول تحكي قصة بالأيدي بس من غير كلام!',
    'قول مين من الأوضة دي الأكتر مزاجي!',
    'اعمل تقليد لمذيع أخبار وقدم خبر عشوائي!',
    'اكتب تغريدة عشوائية ممتعة وابعتها',
    'حكي ذكرى محرجة من طفولتك في دقيقة!',
    'اعمل وش بكاء من غير ما تبكي فعلاً!',
    'قلّد 3 أشخاص في الأوضة بالترتيب!',
    'ابعت إيموجي عشوائي لأول 5 أشخاص في واتساب!',
    'اتصرف كأنك في مقابلة عمل وإجب على أسئلتنا!',
    'اتنطط على رجليك 20 مرة وأنت بتغني أغنية!',
    'ابقى كل جملة تقولها تبدأ بـ "في رأيي المتواضع"!',
    'اعمل وش محايد وكمل كده لمدة دقيقتين!',
    'سمّي 5 دول في ثانيتين!',
    'اكتب اسمك بإيدك التانية!',
    'خد سيلفي وجهك بالكاميرا الأمامية مكبّرة 100%!',
    'قول "مساء الخير يا كبير" لأول شخص بالغرفة!',
    'ابقى قول جملة حلوة لكل شخص في الأوضة!',
    'اعمل تصرف كأنك حيوان من اختيارنا لدقيقة!',
    'ابقى تتكلم بالإنجليزي بس لمدة 3 دقايق!',
    'اعمل حركة يوغا واحدة وفضل فيها 30 ثانية!',
    'صمم إعلان في دقيقة لأي منتج عشوائي بتختاره المجموعة!',
    'اعمل مقابلة بالعربي بأسلوب محقق مع شخص من الأوضة!',
    'ارسم بورتريه لشخص في الأوضة خلال دقيقة واحدة!',
    'غنّ الحروف الأبجدية بأسرع ما تقدر!',
    'اعمل رد فعل مبالغ فيه على أغنية أطفال!',
    'أقنع المجموعة إن الموز أفضل فاكهة في 60 ثانية!',
    'اتصرف كأنك ممثل في مسلسل درامي وحكي موقف عادي بشكل درامي!',
    'قول 10 مواصفات تحبيبتك المثالية!',
    'اعمل تعبير وجه لكل فرد في الأوضة زي ما بتحس بيه تجاههم!',
    'حاول لمس أنفك بلسانك!',
    'اشرب كوب ماء كامل في نفس واحد!',
    'تظاهر بأنك نادل وخذ طلبات الجميع!',
    'قم بعمل 15 تمرين ضغط فوراً!',
    'اتصل بصديق وأقنعه بأنك فزت باليانصيب!',
    'البس جواربك في يديك لمدة جولة كاملة!',
    'ارسم شارباً على وجهك باستخدام قلم كحل (أو تخيل ذلك)!',
    'تحدث بلهجة مختلفة تماماً لمدة 5 دقائق!',
    'قم بعمل "دبكة" سريعة لوحدك!',
    'حاول موازنة ملعقة على أنفك لمدة 20 ثانية!',
    'تظاهر بأنك مخرج سينمائي ووجه المجموعة لمشهد أكشن!',
    'قم بتبديل مكان جلوسك مع الشخص المقابل لك فوراً!',
    'ارقص رقصة "الفلوس" لمدة 15 ثانية!',
    'تظاهر بأنك قطة جائعة وتودد لأحد اللاعبين!',
    'قل جملة سريعة وصعبة (مثل: خشبة الحبس حبست خمس خشبات) 5 مرات!',
    'حاول الضحك بصوت عالٍ دون سبب لمدة 30 ثانية!',
    'قم بعمل وضعية "الرجل الحديدي" لمدة 20 ثانية!',
    'تظاهر بأنك بطل خارق يكتشف قوته لأول مرة!',
    'قل شعراً ارتجالياً عن أحد الموجودين في القاعة!',
    'اجلس تحت الطاولة لمدة جولة واحدة!',
    'تظاهر بأنك فنان يرسم بريشة خيالية على الهواء!',
    'حاول الغناء وفمك مليء بالماء!',
    'قم بعمل حركة بهلوانية بسيطة (مثل الدوران حول نفسك 5 مرات والوقوف بثبات)!',
    'تظاهر بأنك معلق رياضي يعلق على حركة بسيطة يقوم بها شخص ما!',
    'البس قميصك بالمقلوب وأكمل جولة واحدة!',
    'قم بعمل تمثيل صامت لفيلم مشهور وعلى الجميع تخمينه!',
    'تظاهر بأنك بائع في سوق شعبي يحاول بيع شيء تافه للمجموعة!',
    'تحدث وكأنك في بطء شديد لمدة دقيقتين!',
    'حاول التقاط صورة سيلفي مضحكة جداً مع الشخص الذي بجانبك!',
    'قم بعمل مشية "الرجل الآلي" (Robot) من زاوية الغرفة إلى الأخرى!',
    'تظاهر بأنك في رحلة فضائية وتحدث مع "الأرض"!',
    'حاول التحدث دون تحريك شفتيك لمدة دقيقة!',
    'قم بعمل حركة رقص "بري كدانس" (أو حاول ذلك)!',
    'تظاهر بأنك ساحر يقدم عرضاً فاشلاً!',
    'قل كلمة "أنا بطل" بأعلى صوتك من النافذة (أو بصوت عالٍ في الغرفة)!',
    'حاول الوقوف على يديك (بمساعدة الحائط إذا لزم الأمر)!',
    'تظاهر بأنك تمشي على حبل مشدود في السيرك!',
    'قم بتقليد ضحكة شخص شرير في الأفلام!',
    'حاول القيام بـ 20 قفزة "Jumping Jacks"!',
    'تحدث كأنك طفل صغير يطلب حلوى لمدة دقيقة!',
    'تظاهر بأنك عارض أزياء يمشى على المنصة!',
    'حاول التوازن على قدم واحدة وعيناك مغمضتان لمدة 15 ثانية!',
    'تظاهر بأنك مصور فوتوغرافي محترف يصور المجموعة!',
    'قم بعمل وجه "البطة" (Duck Face) في كل صورة تؤخذ لك هذه الجولة!',
    'تحدث بصوت خفيض جداً (همس) لمدة جولتين!',
    'تظاهر بأنك تحارب عدواً خفياً بالسيف!',
    'قم بعمل حركة "الزومبي" وامشِ ببطء نحو المجموعة!',
    'حاول لمس أصابع قدميك دون ثني ركبتيك لمدة 10 ثوانٍ!',
    'تظاهر بأنك تستعد لسباق جري عالمي!',
    'قم بتقليد صوت سيارة سباق تمر بسرعة!',
    'تظاهر بأنك تمشي في طين لزج جداً!',
    'حاول القيام بـ 10 تمارين "Squats" وأنت تبتسم!',
    'تظاهر بأنك قائد أوركسترا يقود موسيقى حماسية!',
    'قم بتقليد حركة حيوان الكنغر لمدة 30 ثانية!',
    'تظاهر بأنك في سفينة تتمايل وسط أمواج عاتية!',
    'حاول قول الأبجدية بالعكس!',
    'تظاهر بأنك تمسك بشيء ثقيل جداً وتحاول نقله!',
    'قم بعمل حركة "النينجا" والاختباء خلف أي شيء!',
    'تظاهر بأنك تجري مقابلة مع نفسك في المرآة!',
    'حاول البقاء صامتاً تماماً وتعبيرات وجهك جادة لمدة دقيقة مهما حدث!',
    'تظاهر بأنك تطير فوق مدينة كبيرة!',
    'قم بعمل حركة "الفلامنكو" الراقصة!',
    'تظاهر بأنك جندي في مهمة سرية وتحرك بحذر!',
    'حاول القيام بحركة "الجسر" بالظهر (إذا كنت تستطيع)!',
    'تظاهر بأنك تعزف على غيتار خيالي (Air Guitar) بحماس!',
    'قم بتقليد صوت انفجار كبير!',
    'تظاهر بأنك تسبح في حمام سباحة خيالي وسط الغرفة!',
    'حاول التحدث بكلمات مقفاة (سجع) لمدة دقيقة!',
    'تظاهر بأنك رجل إطفاء ينقذ قطة!',
    'قم بعمل مشية "تشارلي تشابلن"!',
    'تظاهر بأنك تقود طائرة جامبو وسط عاصفة!',
    'حاول القيام بحركة "البلانك" (Plank) لمدة 30 ثانية!',
    'تظاهر بأنك شيف عالمي يشرح طريقة عمل البيض المقلي!',
    'قم بتقليد حركة القرد لمدة 15 ثانية!',
    'تظاهر بأنك تمشي على سطح القمر (جاذبية منخفضة)!',
    'حاول الغناء بأسلوب "الأوبرا"!',
    'تظاهر بأنك تمثال حي لا يتحرك أبداً لدقيقة!',
    'قم بعمل حركة "اليوغا" (شجرة) والبقاء ثابتاً!',
    'تظاهر بأنك تتحدث في الهاتف مع كائن فضائي!',
    'حاول القيام بـ 5 تمارين "Burpees"!',
    'تظاهر بأنك في سباق دراجات هوائية سريع!',
    'قم بتقليد صوت الرياح القوية!',
    'تظاهر بأنك تفتح علبة هدايا كبيرة جداً ومتحمس!',
    'حاول الكلام بصوت "روبوت" معدني!',
    'تظاهر بأنك تتسلق جبل إفرست!',
    'قم بعمل حركة رقص "ديسكو" سريعة!',
    'تظاهر بأنك تمشي وسط عاصفة رملية!',
    'حاول قول "أحب البرتقال" 10 مرات بسرعة دون خطأ!',
    'تظاهر بأنك تخيط ملابس بخيط وإبرة خيالية!',
    'قم بعمل مشية العسكري (Marching)!',
    'تظاهر بأنك تمسك بمظلة في ريح شديدة!',
    'حاول الوقوف على أصابع قدميك لأطول فترة ممكنة!',
    'تظاهر بأنك تلعب كره سلة وتسجل هدفاً حاسماً!',
    'قم بعمل حركة "الجمباز" البسيطة (مثل الوقوف على قدم واحدة)!',
    'تظاهر بأنك تغرق في رمال متحركة!',
    'حاول الابتسام لأقصى حد ممكن والبقاء هكذا لدقيقة!',
  ];

  bool _typeChosen = false;
  bool _isTruth = false;
  String? _currentCard;
  final _rand = Random();
  final List<String> _players = [];
  int _currentPlayer = 0;
  final _playerCtrl = TextEditingController();
  bool _started = false;

  // Anti-repeat tracking
  List<String> _shuffledTruths = [];
  List<String> _shuffledDares = [];
  int _truthIndex = 0;
  int _dareIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final rawData = await RawDataManager.getGameData('truth_or_dare_game', {});

    if (rawData.containsKey('truth') &&
        rawData['truth'] is List &&
        rawData.containsKey('dare') &&
        rawData['dare'] is List) {
      List<String> parsedTruths = List<String>.from(
        rawData['truth'].map((e) => e.toString()),
      );
      List<String> parsedDares = List<String>.from(
        rawData['dare'].map((e) => e.toString()),
      );

      if (parsedTruths.isNotEmpty && parsedDares.isNotEmpty) {
        if (mounted) {
          setState(() {
            truths = parsedTruths;
            dares = parsedDares;
            isLoadingData = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        truths = _fallbackTruths;
        dares = _fallbackDares;
        isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _playerCtrl.dispose();
    super.dispose();
  }

  void _pick(bool truth) {
    if (_shuffledTruths.isEmpty && truths.isNotEmpty) {
      _shuffledTruths = List.from(truths)..shuffle(_rand);
      _truthIndex = 0;
    }
    if (_shuffledDares.isEmpty && dares.isNotEmpty) {
      _shuffledDares = List.from(dares)..shuffle(_rand);
      _dareIndex = 0;
    }
    setState(() {
      _isTruth = truth;
      _typeChosen = true;
      if (truth) {
        if (_truthIndex >= _shuffledTruths.length) {
          _shuffledTruths.shuffle(_rand);
          _truthIndex = 0;
        }
        _currentCard = _shuffledTruths[_truthIndex++];
      } else {
        if (_dareIndex >= _shuffledDares.length) {
          _shuffledDares.shuffle(_rand);
          _dareIndex = 0;
        }
        _currentCard = _shuffledDares[_dareIndex++];
      }
    });
  }

  void _next() {
    setState(() {
      _typeChosen = false;
      _currentCard = null;
      _currentPlayer = (_currentPlayer + 1) % _players.length.clamp(1, 99);
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
    if (isLoadingData || truths.isEmpty || dares.isEmpty) {
      return BaseGameScaffold(
        title: '🎲 حقيقة أم جرأة',
        backgroundColor: const Color(0xFFB71C1C),
        body: const PremiumLoadingIndicator(message: 'جاري تحضير التحديات...'),
      );
    }

    if (_showIntro) {
      return BaseGameScaffold(
        title: '🎲 حقيقة أم جرأة',
        backgroundColor: const Color(0xFFB71C1C),
        body: GameIntroWidget(
          title: 'حقيقة أم جرأة',
          icon: '😈',
          description:
              'اللعبة الأشهر في العالم! اختار حقيقة عشان نكشف أسرارك، أو جرأة عشان تنفذ تحديات مجنونة.\n\nمستعد تواجه الحقيقة؟',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    if (!_started) {
      return BaseGameScaffold(
        title: '🎲 حقيقة أم جرأة',
        backgroundColor: const Color(0xFFB71C1C),
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
                  '🎲',
                  style: TextStyle(fontSize: 90),
                ).animate().scale(),
                const SizedBox(height: 12),
                Text(
                  'حقيقة أم جرأة!',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                Text(
                  'اختار حقيقة لو عايز تجاوب بصراحة،\nأو جرأة لو قلبك جامد! 🔥',
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
                              gameTitle: 'حقيقة أم جرأة',
                              minPlayers: 2,
                              onStartGame: (ctx, selectedPlayers) {
                                Navigator.pop(ctx);
                                setState(() {
                                  _players.clear();
                                  _players.addAll(selectedPlayers);
                                  _currentPlayer = 0;
                                  _started = true;
                                });
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people_alt, size: 30),
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

    return BaseGameScaffold(
      title: '🎲 حقيقة أم جرأة',
      backgroundColor: const Color(0xFFB71C1C),
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
          icon: const Icon(Icons.home, color: Colors.white70),
          onPressed: () => setState(() {
            _started = false;
            _typeChosen = false;
            _currentCard = null;
            _players.clear();
          }),
        ),
      ],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_players.isNotEmpty)
                  Text(
                    'دور: ${_players[_currentPlayer % _players.length]}',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fadeIn(),
                const SizedBox(height: 20),
                if (!_typeChosen) ...[
                  Text(
                    'اختار:',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pick(true),
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.shade700,
                                  Colors.blue.shade900,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade900,
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '💬',
                                  style: TextStyle(fontSize: 50),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'حقيقة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().scale(delay: 100.ms),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pick(false),
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.orange.shade700,
                                  Colors.red.shade800,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.shade900,
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 50),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'جرأة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().scale(delay: 200.ms),
                      ),
                    ],
                  ),
                ] else ...[
                  // Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isTruth
                            ? [Colors.blue.shade700, Colors.blue.shade900]
                            : [Colors.orange.shade700, Colors.red.shade800],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: (_isTruth ? Colors.blue : Colors.orange)
                              .withAlpha(100),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isTruth ? '💬 حقيقة' : '🔥 جرأة',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _currentCard ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(_isTruth),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                            'غيّر',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _next,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 24,
                          ),
                          label: Text(
                            'الدور الجاي',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFB71C1C),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
