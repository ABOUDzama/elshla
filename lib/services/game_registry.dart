import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../games/quiz_game.dart';
import '../games/tick_tock_boom.dart';
import '../games/multi_touch_screen.dart';
import '../games/balance_game.dart';
import '../games/five_seconds_game.dart';

import '../games/reverse_quiz.dart';
import '../games/odd_one_out.dart';
import '../games/first_letter_game.dart';
import '../games/opposite_day.dart';
import '../games/xo_game.dart';
import '../games/seega_game.dart';
import '../games/who_am_i_game.dart';
import '../games/word_chain_game.dart';
import '../games/truth_or_dare_game.dart';

import '../games/pictionary_game.dart';
import '../games/song_lyrics_game.dart';
import '../games/charades_game.dart';
import '../games/gobblet_game.dart';
import '../games/truth_or_lie_game.dart';

class GameRegistry {
  static const List<GameModel> games = [
    GameModel(
      title: '🎯 إكس أو',
      description: 'لعبة إكس أو الكلاسيكية',
      icon: Icons.close,
      color: Colors.blueAccent,
      screen: TicTacToeGame(),
    ),
    GameModel(
      title: '🎮 سيجا',
      description: 'لعبة السيجا الشعبية 3x3',
      icon: Icons.grid_3x3,
      color: Colors.brown,
      screen: SeegaGame(),
    ),
    GameModel(
      title: '👾 الكبير ياكل الصغير',
      description: 'تيك تاك تو بس الأحجام بتفرق! الكبير ياكل الصغير',
      icon: Icons.smart_toy,
      color: Colors.deepOrange,
      screen: GobbletGame(),
    ),
    GameModel(
      title: '🎯 لعبة الأسئلة',
      description: 'أسئلة في مختلف المجالات مع تسجيل النقاط',
      icon: Icons.quiz,
      color: Colors.blue,
      screen: QuizGame(),
    ),
    GameModel(
      title: '💣 قنبلة الحروف',
      description: 'قول كلمة قبل ما الموبايل ينفجر!',
      icon: Icons.timer,
      color: Colors.red,
      screen: TickTockBoom(),
    ),
    GameModel(
      title: '👆 اختيار عشوائي',
      description: 'كل واحد يحط صباعه والتطبيق يختار واحد',
      icon: Icons.touch_app,
      color: Colors.green,
      screen: MultiTouchScreen(),
    ),
    GameModel(
      title: '⚖️ الميزان',
      description: 'حافظ على الكرة في النص!',
      icon: Icons.balance,
      color: Colors.teal,
      screen: BalanceGame(),
    ),
    GameModel(
      title: '⏱️ خمس ثواني',
      description: 'أجب على السؤال في 5 ثواني بس!',
      icon: Icons.speed,
      color: Colors.pink,
      screen: FiveSecondsGame(),
    ),

    GameModel(
      title: '🔄 الأسئلة المعكوسة',
      description: 'الإجابة موجودة، خمن السؤال!',
      icon: Icons.swap_horiz,
      color: Colors.cyan,
      screen: ReverseQuiz(),
    ),
    GameModel(
      title: '🎯 الخيار الثالث',
      description: 'مين الدخيل من الأربعة؟',
      icon: Icons.filter_3,
      color: Colors.amber,
      screen: OddOneOut(),
    ),
    GameModel(
      title: '🔤 أول حرف',
      description: 'قول كلمة بتبدأ بالحرف ده!',
      icon: Icons.font_download,
      color: Colors.deepOrange,
      screen: FirstLetterGame(),
    ),
    GameModel(
      title: '🙃 عكس العكاس',
      description: 'أجب بإجابة غلط بسرعة!',
      icon: Icons.flip,
      color: Colors.brown,
      screen: OppositeDay(),
    ),
    GameModel(
      title: '🎭 مين أنا؟',
      description: 'خمّن الشخصية من التلميحات!',
      icon: Icons.person_search,
      color: Color(0xFF6A1B9A),
      screen: WhoAmIGame(),
    ),
    GameModel(
      title: '⏱️ تحدي التعريف',
      description: 'عرّف الكلمة بدون ما تقولها في 60 ثانية!',
      icon: Icons.record_voice_over,
      color: Color(0xFF004D40),
      screen: WordChainGame(),
    ),
    GameModel(
      title: '🎲 حقيقة أم جرأة',
      description: 'جاوب بصدق أو نفّذ الجرأة!',
      icon: Icons.casino,
      color: Color(0xFFB71C1C),
      screen: TruthOrDareGame(),
    ),

    GameModel(
      title: '🎨 ارسم وخمّن',
      description: 'ارسم بصباعك والثاني يخمّن!',
      icon: Icons.brush,
      color: Color(0xFF0D47A1),
      screen: PictionaryGame(),
    ),
    GameModel(
      title: '🎵 أكمل الأغنية',
      description: 'اختار الجملة الصح من الأغنية!',
      icon: Icons.music_note,
      color: Color(0xFF880E4F),
      screen: SongLyricsGame(),
    ),
    GameModel(
      title: '🎭 تمثيل صامت',
      description: 'مثّل الكلمة بدون ما تتكلم!',
      icon: Icons.theater_comedy,
      color: Color(0xFF1A237E),
      screen: CharadesGame(),
    ),
    GameModel(
      title: '🤔 حقيقة أو هبد',
      description: 'حقائق مدهشة بتظهر شوية شوية.. حقيقة ولا هبد؟',
      icon: Icons.lightbulb_outline,
      color: Color(0xFF14B8A6),
      screen: TruthOrLieGame(),
    ),
  ];
}
