import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/score_service.dart';
import '../widgets/base_game_scaffold.dart';

class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scoreService = ScoreService();

    return ListenableBuilder(
      listenable: scoreService,
      builder: (context, _) {
        final players = scoreService.rankedPlayers;

        return BaseGameScaffold(
          title: '🏆 لوحة الشرف',
          backgroundColor: const Color(0xFF121212),
          actions: [
            if (players.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                tooltip: 'تصفير النقاط',
                onPressed: () => _showResetConfirm(context, scoreService),
              ),
            if (players.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                tooltip: 'إنهاء الجلسة',
                onPressed: () => _showClearConfirm(context, scoreService),
              ),
          ],
          body: players.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return _buildPlayerCard(player, index);
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😶', style: TextStyle(fontSize: 80)).animate().shake(),
          const SizedBox(height: 20),
          Text(
            'مفيش حد بيلعب لسه!',
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ابدأ أي لعبة واختار أسماء الشلة عشان تظهر هنا.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: Colors.white60),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'رجوع',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerScore player, int index) {
    final isFirst = index == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFirst
              ? [Colors.amber.withAlpha(50), Colors.amber.withAlpha(10)]
              : [Colors.white.withAlpha(20), Colors.white.withAlpha(5)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isFirst ? Colors.amber.withAlpha(100) : Colors.white12,
          width: isFirst ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isFirst ? Colors.amber : Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    color: isFirst ? Colors.black : Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                player.name,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${player.score}',
                  style: GoogleFonts.cairo(
                    color: isFirst ? Colors.amber : Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'نقطة',
                  style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            if (isFirst) ...[
              const SizedBox(width: 10),
              const Text(
                '👑',
                style: TextStyle(fontSize: 24),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2, end: 0);
  }

  void _showResetConfirm(BuildContext context, ScoreService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'تصفير النقاط؟',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        content: Text(
          'متأكد إنك عايز تخلي كل النقط صفر؟',
          style: GoogleFonts.cairo(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              service.resetScores();
              Navigator.pop(ctx);
            },
            child: const Text('تصفير', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context, ScoreService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'إنهاء الجلسة؟',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        content: Text(
          'ده هيفتح السهم وهيخليك تبدأ من جديد بالأسماء.',
          style: GoogleFonts.cairo(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              service.clearSession();
              Navigator.pop(ctx);
            },
            child: const Text(
              'إنهاء',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
