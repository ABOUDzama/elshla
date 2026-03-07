import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class AIService {
  /// Generates questions for a specific category using GitHub Models AI.
  static Future<List<Map<String, dynamic>>> fetchAiQuestions(
    String category, {
    int count = 10,
  }) async {
    final prompt =
        '''
ولد $count أسئلة **صعبة جداً ومخصصة للمحترفين** في فئة "$category" باللغة العربية. 
تأكد من أن الأسئلة تتطلب تفكيراً عميقاً ومعلومات عامة واسعة (مستوى التحدي: عالٍ جداً).
يجب أن يكون الرد بتنسيق JSON فقط كقائمة من الكائنات.
كل كائن يحتوي على المفاتيح التالية: "question" و "answer".
تأكد من أن الأسئلة ممتعة وغير مكررة.
مثال للتنسيق:
[
  {"question": "سؤال تحدي صعبة", "answer": "إجابة دقيقة"}
]
''';
    return _fetchContent(prompt);
  }

  static Future<List<Map<String, dynamic>>> fetchGameContent(
    String gameType, {
    int count = 10,
  }) async {
    String specificPrompt = '';

    switch (gameType) {
      case 'jokes':
        specificPrompt =
            'ولد $count نكت مصرية وعربية مضحكة جداً جداً وتموت من الضحك، مستوحاة من أسلوب السوشيال ميديا المودرن وموقع "التكية". ممنوع تماماً النكت البايخة، القديمة، أو الفصيلة. ركز على النكت الذكية، القلش العالي، والمواقف اللي بتعصب من كتر ما هي بتضحك. التنسيق: [{"joke": "...", "icon": "😂"}]';
        break;
      case 'letter_bomb':
        specificPrompt =
            'ولد $count تصنيفات لألعاب القنبلة الموقوتة (فئة وحرف وأمثلة). يجب أن تكون الحروف المختارة لها أمثلة كثيرة وشائعة جداً في تلك الفئة. التنسيق: [{"category": "...", "letter": "...", "examples": ["...", "..."]}]';
        break;
      case 'five_seconds':
        specificPrompt =
            'ولد $count أسئلة صعبة للعبة الـ 5 ثواني (تطلب ذكر 3 أشياء). التنسيق: [{"question": "..."}]';
        break;
      case 'reverse_quiz':
        specificPrompt =
            'ولد $count أسئلة معكوسة (بعطيك الإجابة والمستخدم يحذر السؤال). التنسيق: [{"answer": "...", "question": "..."}]';
        break;
      case 'who_am_i':
        specificPrompt =
            'ولد بالضبط $count شخصية مشهورة متنوعة (ممثلين، لاعبين، علماء، شخصيات تاريخية). لكل شخصية قدم 3 تلميحات تدريجية في الصعوبة. التنسيق: [{"name": "اسم الشخصية", "hints": ["تلميح 1", "تلميح 2", "تلميح 3"], "icon": "إيموجي مناسب"}]';
        break;
      case 'truth_or_dare':
        specificPrompt =
            'ولد $count طلبات حقيقة وجرأة (منوعة وجريئة). التنسيق: [{"type": "truth|dare", "prompt": "..."}]';
        break;

      case 'pictionary':
        specificPrompt =
            'ولد بالضبط $count كلمات صعبة وممتعة للرسم والتخمين. التنسيق: [{"word": "الكلمة", "category": "اسم الفئة"}]';
        break;
      case 'charades':
        specificPrompt =
            'ولد $count فئات (categories) متنوعة للتمثيل الصامت (أفلام، أفعال، مهن، أشياء). وفي كل فئة، قم بتوليد 15 كلمة صعبة وممتعة للتمثيل. التنسيق: [{"category": "اسم الفئة", "words": ["كلمة 1", "كلمة 2", ...]}]';
        break;
      case 'song_lyrics':
        specificPrompt =
            'ولد $count مقاطع من أغاني عربية مشهورة مع جملة ناقصة. التنسيق: [{"prompt": "بداية الأغنية...", "answer": "التكملة الصح", "artist": "اسم الفنان"}]';
        break;
      case 'truth_or_lie':
        specificPrompt =
            'ولد $count حقائق مدهشة (منها حقيقي ومنها هبد) مع تعليل. التنسيق: [{"statement": "...", "is_true": true|false, "explanation": "..."}]';
        break;
      case 'definition':
        specificPrompt =
            'ولد $count كلمات صعبة مع تعريفات دقيقة لها للعبة تحدي التعريف. التنسيق: [{"word": "...", "definition": "..."}]';
        break;
      case 'odd_one_out':
        specificPrompt =
            'ولد $count أسئلة للعبة "الاختيار الثالث". كل سؤال يحتوي على 6 عناصر، 5 منهم مرتبطين جداً ببعض منطقياً، وعنصر واحد مختلف تماماً (الـ odd one). التنسيق: [{"items": ["...", "...", "...", "...", "...", "..."], "oddOne": "...", "reason": "سبب الاختلاف بالعامية المصرية", "icon": "emoji"}]';
        break;
      case 'word_chain_game':
        specificPrompt =
            'ولد $count فئات (categories) للعبة "تحدي التعريف". كل فئة تحتوي على $count كلمات صعبة ومختلفة للتمثيل بالشرح (بدون نطق الكلمة). التنسيق: [{"category": "اسم الفئة", "words": ["كلمة 1", "كلمة 2", ...]}]';
        break;
      default:
        specificPrompt =
            'ولد $count محتوى لهذه اللعبة: $gameType باللغة العربية. التنسيق: [{"text": "..."}]';
    }

    final prompt =
        '''
$specificPrompt
يجب أن يكون الرد بتنسيق JSON فقط كقائمة من الكائنات.
اللغة: العربية.
تأكد من أن المحتوى ممتع، جديد، وغير مكرر.
''';

    return _fetchContent(prompt);
  }

  static Future<List<Map<String, dynamic>>> _fetchContent(String prompt) async {
    final token = SettingsService.githubToken;
    if (token.isEmpty) {
      throw Exception('GitHub Token is missing. Please set it in Settings.');
    }

    try {
      final response = await http.post(
        Uri.parse('https://models.inference.ai.azure.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a professional game content creator in Arabic.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'model': 'gpt-4o',
          'temperature': 0.8,
          'max_tokens': 4000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;

        // Extract JSON using regex (in case there's markdown)
        final jsonRegex = RegExp(r'\[[\s\S]*\]');
        final match = jsonRegex.firstMatch(content);

        if (match != null) {
          final jsonStr = match.group(0)!;
          final List<dynamic> list = jsonDecode(jsonStr);
          return list.map((e) => Map<String, dynamic>.from(e)).toList();
        }

        throw Exception('Failed to find JSON in response: $content');
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('AI Service Error: $e');
      rethrow;
    }
  }
}
