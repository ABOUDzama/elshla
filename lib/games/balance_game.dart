import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import '../widgets/base_game_scaffold.dart';
import '../services/score_service.dart';
import '../widgets/game_intro_widget.dart';

class BalanceGame extends StatefulWidget {
  const BalanceGame({super.key});

  @override
  State<BalanceGame> createState() => _BalanceGameState();
}

class _BalanceGameState extends State<BalanceGame> {
  final List<String> motivationalMessages = [
    'ركز زي النينجا! 🥷',
    'خليك ثابت زي الجبل! 🏔️',
    'مين هيكسر الرقم القياسي؟ 🏆',
    'لو وقعت الكرة، حاول تاني! 💪',
    'أنت بطل التوازن! ⚖️',
    'حافظ على أعصابك! 😅',
    'مين أسرع واحد فيكم؟ ⏱️',
    'جرب تلعب بعين واحدة! 😉',
    'خلي صحابك يتحدوك! 🤝',
    'لو كسبت، صور الشاشة! 📸',
  ];
  String getRandomMessage() {
    return motivationalMessages[Random().nextInt(motivationalMessages.length)];
  }

  String? currentMessage;
  double ballX = 0;
  double ballY = 0;
  StreamSubscription? _accelerometerSubscription;
  bool isPlaying = false;
  int score = 0;
  Timer? _scoreTimer;
  Timer? _gameLoop;
  bool hasLost = false;
  double shrinkFactor = 1.0; // 1.0 = full size, shrinks after 30s
  List<_Obstacle> obstacles = [];
  final List<String> obstacleIcons = ['🪨', '📦', '🚧', '💥', '⚠️'];
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _scoreTimer?.cancel();
    _gameLoop?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      hasLost = false;
      ballX = 0;
      ballY = 0;
      score = 0;
      shrinkFactor = 1.0;
      obstacles = [];
      currentMessage = getRandomMessage();
    });

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!isPlaying || hasLost) return;
      setState(() {
        ballX -= event.x * 2;
        ballY += event.y * 2;

        // Full area dimensions
        final fullW = MediaQuery.of(context).size.width - 40;
        final fullH = MediaQuery.of(context).size.height - 300;

        // Current shrunken area bounds (half-width / half-height minus ball radius)
        final maxX = (fullW * shrinkFactor) / 2 - 38;
        final maxY = (fullH * shrinkFactor) / 2 - 38;

        // Clamp to full area so ball stays on screen
        ballX = ballX.clamp(-(fullW / 2 - 38), fullW / 2 - 38);
        ballY = ballY.clamp(-(fullH / 2 - 38), fullH / 2 - 38);

        // Lose if ball crosses the shrunken boundary
        if (ballX.abs() >= maxX || ballY.abs() >= maxY) {
          if (!hasLost) lose('الكرة وقعت!');
        }
      });
    });

    // Start score timer
    _scoreTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        score++;
        // After 30 seconds, start shrinking the playing area gradually
        if (score > 30) {
          shrinkFactor = (shrinkFactor - 0.008).clamp(0.3, 1.0);
        }
      });
    });

    // Start game loop for obstacles and collision detection
    _gameLoop = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!isPlaying || hasLost) return;

      setState(() {
        final fullW = MediaQuery.of(context).size.width - 40;
        final fullH = MediaQuery.of(context).size.height - 300;
        final maxY = (fullH * shrinkFactor) / 2;
        final maxX = (fullW * shrinkFactor) / 2;

        // Spawn obstacles
        // Intensity increases with score
        double spawnProbability = 0.02 + (score / 1000);
        if (Random().nextDouble() < spawnProbability.clamp(0.02, 0.15)) {
          obstacles.add(
            _Obstacle(
              x: Random().nextDouble() * (maxX * 2) - maxX,
              y: -maxY - 50,
              speed: 3.0 + (score / 20).clamp(0.0, 10.0),
              icon: obstacleIcons[Random().nextInt(obstacleIcons.length)],
            ),
          );
        }

        // Move obstacles and check collisions
        List<_Obstacle> toRemove = [];
        for (var obstacle in obstacles) {
          obstacle.y += obstacle.speed;

          // Collision detection (ball radius ~30, obstacle radius ~15)
          double dx = ballX - obstacle.x;
          double dy = ballY - obstacle.y;
          double distance = sqrt(dx * dx + dy * dy);

          if (distance < 45) {
            // 30 (ball radius) + 15 (obstacle estimated radius)
            lose('خبطت في عائق!');
            break;
          }

          // Remove off-screen obstacles
          if (obstacle.y > maxY + 50) {
            toRemove.add(obstacle);
          }
        }
        obstacles.removeWhere((o) => toRemove.contains(o));
      });
    });
  }

  void lose(String reason) {
    setState(() {
      hasLost = true;
      isPlaying = false;
      currentMessage = reason;
    });
    _accelerometerSubscription?.cancel();
    _scoreTimer?.cancel();
    _gameLoop?.cancel();

    // Award points: 1 point per 10 seconds survived
    if (score >= 10) {
      final scoreService = ScoreService();
      if (scoreService.players.isNotEmpty) {
        int points = score ~/ 10;
        scoreService.addScore(scoreService.players[0].name, points);
      }
    }
  }

  void resetGame() {
    setState(() {
      isPlaying = false;
      hasLost = false;
      ballX = 0;
      ballY = 0;
      score = 0;
      obstacles = [];
      shrinkFactor = 1.0;
    });
    _accelerometerSubscription?.cancel();
    _scoreTimer?.cancel();
    _gameLoop?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return BaseGameScaffold(
        title: '⚖️ الميزان',
        backgroundColor: Colors.teal,
        body: GameIntroWidget(
          title: 'الميزان',
          icon: '⚖️',
          description:
              'حافظ على الكرة في النص! حط الموبايل على إيدك وحاول متخليش الكرة توصل للحافة أو تخبط في العوائق!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    final fullW = MediaQuery.of(context).size.width - 40;
    final fullH = MediaQuery.of(context).size.height - 300;

    return BaseGameScaffold(
      title: '⚖️ الميزان',
      backgroundColor: Colors.teal,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isPlaying && !hasLost) ...[
                  // Original content removed because it's now in GameIntroWidget
                  const Text('⚖️', style: TextStyle(fontSize: 100)),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 30),
                    label: const Text(
                      'ابدأ اللعبة 🚀',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ] else if (hasLost) ...[
                  const Text('💥', style: TextStyle(fontSize: 100)),
                  const SizedBox(height: 20),
                  Text(
                    currentMessage ?? 'الكرة وقعت!',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '⏱️ النتيجة',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$score ثانية',
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Colors.tealAccent,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              getRandomMessage(),
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: resetGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white12,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('القائمة'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('العب تاني'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isPlaying) ...[
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_rounded,
                            color: Colors.tealAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$score ثانية',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                width: fullW * shrinkFactor,
                height: fullH * shrinkFactor,
                decoration: BoxDecoration(
                  color: score > 30
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: score > 30
                        ? Colors.orangeAccent
                        : Colors.tealAccent.withValues(alpha: 0.5),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (score > 30 ? Colors.orangeAccent : Colors.tealAccent)
                              .withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.white12, width: 2),
                        ),
                        child: const Center(
                          child: Text('🎯', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                    ),
                    Center(
                      child: Transform.translate(
                        offset: Offset(ballX, ballY),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Colors.orangeAccent, Colors.deepOrange],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                              BoxShadow(
                                color: Colors.orangeAccent.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('⚽', style: TextStyle(fontSize: 40)),
                          ),
                        ),
                      ),
                    ),
                    // Render Obstacles
                    ...obstacles.map((obstacle) {
                      return Positioned(
                        left: (fullW * shrinkFactor) / 2 + obstacle.x - 15,
                        top: (fullH * shrinkFactor) / 2 + obstacle.y - 15,
                        child: Text(
                          obstacle.icon,
                          style: const TextStyle(fontSize: 30),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Obstacle {
  double x;
  double y;
  double speed;
  String icon;

  _Obstacle({
    required this.x,
    required this.y,
    required this.speed,
    required this.icon,
  });
}
