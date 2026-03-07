import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumLoadingIndicator extends StatelessWidget {
  final String message;
  final Color color;

  const PremiumLoadingIndicator({
    super.key,
    this.message = 'جاري التحميل...',
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color.withValues(alpha: 0.3),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
              Text('🎮', style: TextStyle(fontSize: 30))
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(0.8, 0.8),
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.cairo(
              color: color.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
        ],
      ),
    );
  }
}
