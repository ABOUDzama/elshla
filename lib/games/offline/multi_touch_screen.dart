import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/offline_game_scaffold.dart';
import '../../widgets/game_intro_widget.dart';

class MultiTouchScreen extends StatefulWidget {
  const MultiTouchScreen({super.key});

  @override
  State<MultiTouchScreen> createState() => _MultiTouchScreenState();
}

class _MultiTouchScreenState extends State<MultiTouchScreen>
    with TickerProviderStateMixin {
  Map<int, Offset> touches = {};
  int? selectedPointer;
  bool isSelecting = false;
  bool showResult = false;
  final Random random = Random();
  Timer? _selectionTimer;
  bool _showIntro = true;

  // Countdown for auto-selection
  int _countdown = 0;
  Timer? _countdownTimer;

  final List<Color> _circlePalette = [
    const Color(0xFFE53935),
    const Color(0xFF1E88E5),
    const Color(0xFF43A047),
    const Color(0xFFFF8F00),
    const Color(0xFF8E24AA),
    const Color(0xFF00ACC1),
    const Color(0xFFF4511E),
    const Color(0xFF00897B),
    const Color(0xFF6D4C41),
    const Color(0xFF3949AB),
  ];

  void _startAutoSelection() {
    if (touches.length < 2) return;
    setState(() {
      isSelecting = true;
      showResult = false;
      _countdown = 3;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        _doSelect();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _doSelect() {
    final keys = touches.keys.toList();
    final picked = keys[random.nextInt(keys.length)];
    setState(() {
      selectedPointer = picked;
      isSelecting = false;
      showResult = true;
    });
  }

  void reset() {
    _countdownTimer?.cancel();
    _selectionTimer?.cancel();
    setState(() {
      touches.clear();
      selectedPointer = null;
      isSelecting = false;
      showResult = false;
      _countdown = 0;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _selectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return OfflineGameScaffold(
        title: '👆 اختيار عشوائي',
        backgroundColor: const Color(0xFF1B5E20),
        body: GameIntroWidget(
          title: 'اختيار عشوائي',
          icon: '👆',
          description:
              'مش عارفين تختاروا مين يبدأ؟ كل واحد يحط صباعه على الشاشة والتطبيق هيختار واحد عشوائي في ثواني!\n\nأسرع طريقة لفض الاشتباك!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    return OfflineGameScaffold(
      title: '👆 اختيار عشوائي',
      backgroundColor: const Color(0xFF1B5E20),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: reset,
          tooltip: 'إعادة تعيين',
        ),
      ],
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              ),
            ),
          ),

          // Main Touch Area
          Listener(
            onPointerDown: (details) {
              // Only add touches before selection starts
              if (!showResult && !isSelecting) {
                setState(() {
                  touches[details.pointer] = details.position;
                });
                // Wait 1.5 seconds then auto-select
                if (touches.length >= 2) {
                  _countdownTimer?.cancel();
                  _countdownTimer = Timer(
                    const Duration(milliseconds: 1500),
                    () {
                      if (!showResult && !isSelecting && touches.length >= 2) {
                        _startAutoSelection();
                      }
                    },
                  );
                }
              }
            },
            onPointerUp: (details) {
              // Allow removing finger ONLY if we're in idle state
              if (!isSelecting && !showResult) {
                setState(() {
                  touches.remove(details.pointer);
                  if (touches.length < 2) _countdownTimer?.cancel();
                });
              }
              // During selecting or showing result: ignore pointer up (keep positions frozen)
            },
            onPointerMove: (details) {
              if (!isSelecting && !showResult) {
                if (touches.containsKey(details.pointer)) {
                  setState(() {
                    touches[details.pointer] = details.position;
                  });
                }
              }
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // Draw touch circles
                  ...touches.entries.map((entry) {
                    final index = touches.keys.toList().indexOf(entry.key);
                    final color = _circlePalette[index % _circlePalette.length];
                    final isChosen = showResult && selectedPointer == entry.key;
                    final isEliminated =
                        showResult && selectedPointer != entry.key;
                    final double size = isChosen ? 140 : 80;

                    return Positioned(
                      // Center circle on finger position
                      left: entry.value.dx - (size / 2),
                      top:
                          entry.value.dy -
                          (size / 2) -
                          60, // offset above finger
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: isEliminated ? 0.0 : 1.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.9),
                            border: Border.all(
                              color: isChosen ? Colors.white : Colors.white60,
                              width: isChosen ? 5 : 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(
                                  alpha: isChosen ? 0.7 : 0.3,
                                ),
                                blurRadius: isChosen ? 30 : 10,
                                spreadRadius: isChosen ? 8 : 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: isChosen
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '🎯',
                                        style: TextStyle(fontSize: 36),
                                      ),
                                      Text(
                                        'أنت!',
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Instructions
                  if (!showResult && !isSelecting && touches.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('👆', style: TextStyle(fontSize: 80)),
                          const SizedBox(height: 20),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Text(
                              'كل واحد يحط صباعه\nعلى الشاشة\nوالاختيار هيبدأ لوحده! 🎲',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Waiting for more
                  if (!showResult && !isSelecting && touches.length == 1)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'محتاج على الأقل شخصين! 👆👆',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Countdown
                  if (isSelecting)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey(_countdown),
                            tween: Tween(begin: 1.5, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (ctx, scale, child) => Transform.scale(
                              scale: scale,
                              child: Text(
                                '$_countdown',
                                style: GoogleFonts.cairo(
                                  fontSize: 120,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    const Shadow(
                                      color: Colors.black54,
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'جاري الاختيار...',
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Result - play again button
                  if (showResult)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: ElevatedButton.icon(
                          onPressed: reset,
                          icon: const Icon(Icons.refresh_rounded, size: 24),
                          label: Text(
                            'العب تاني 🎲',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B5E20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


