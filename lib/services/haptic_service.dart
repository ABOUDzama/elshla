import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  static Future<void> vibrate({int duration = 50, List<int>? pattern}) async {
    if (kIsWeb) return;
    try {
      if (await Vibration.hasVibrator() == true) {
        if (pattern != null) {
          Vibration.vibrate(pattern: pattern);
        } else {
          Vibration.vibrate(duration: duration);
        }
      }
    } catch (e) {
      debugPrint('HapticService Error: $e');
    }
  }

  static Future<void> lightImpact() async {
    await vibrate(duration: 10);
  }

  static Future<void> success() async {
    await vibrate(pattern: [0, 50, 50, 50]);
  }
}
