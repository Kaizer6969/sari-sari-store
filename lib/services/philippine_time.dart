import 'package:flutter/foundation.dart';

enum TimeMode {
  philippineRealTime, // Live real Philippine Time (UTC+8)
  simulationSpeed,    // Game fast clock
}

class PhilippineTimeService extends ChangeNotifier {
  static final PhilippineTimeService _instance = PhilippineTimeService._internal();
  factory PhilippineTimeService() => _instance;
  PhilippineTimeService._internal();

  TimeMode mode = TimeMode.philippineRealTime;

  // For simulation mode
  int simHour = 6;
  int simMinute = 0;
  int simSecond = 0;

  /// Current Philippine DateTime (UTC+8)
  DateTime get nowPHT {
    final utc = DateTime.now().toUtc();
    return utc.add(const Duration(hours: 8));
  }

  int get hour {
    if (mode == TimeMode.philippineRealTime) {
      return nowPHT.hour;
    }
    return simHour;
  }

  int get minute {
    if (mode == TimeMode.philippineRealTime) {
      return nowPHT.minute;
    }
    return simMinute;
  }

  int get second {
    if (mode == TimeMode.philippineRealTime) {
      return nowPHT.second;
    }
    return simSecond;
  }

  /// Formatted string e.g. "08:30 AM" or "09:15 PM"
  String get formattedTime {
    final h = hour;
    final m = minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final displayMinute = m.toString().padLeft(2, '0');
    return '${displayHour.toString().padLeft(2, '0')}:$displayMinute $period';
  }

  /// Sun / Day cycle icon
  String get sunMoonIcon {
    final h = hour;
    if (h >= 5 && h < 7) return '🌅'; // Dawn
    if (h >= 7 && h < 16) return '☀️'; // Sunny day
    if (h >= 16 && h < 18) return '🌇'; // Sunset
    return '🌙'; // Night
  }

  /// Period name in Tagalog
  String get periodName {
    final h = hour;
    if (h >= 5 && h < 9) return 'Umaga';
    if (h >= 9 && h < 15) return 'Tanghali';
    if (h >= 15 && h < 18) return 'Hapon';
    return 'Gabi';
  }

  /// Is it nighttime?
  bool get isNight => hour >= 18 || hour < 5;

  /// Is it golden sunset?
  bool get isSunset => hour >= 16 && hour < 18;

  /// Is it sunrise/morning?
  bool get isSunrise => hour >= 5 && hour < 8;

  /// Sun elevation progress for rendering (0.0 at 6am to 1.0 at 12pm, down to 0.0 at 6pm)
  double get sunPosition {
    final currentMinutes = hour * 60 + minute;
    const sunriseMin = 6 * 60; // 6:00 AM
    const sunsetMin = 18 * 60;  // 6:00 PM

    if (currentMinutes < sunriseMin || currentMinutes > sunsetMin) {
      return -1.0; // Moon phase
    }
    return (currentMinutes - sunriseMin) / (sunsetMin - sunriseMin);
  }

  void tickSimulation(int minutesToAdd) {
    if (mode == TimeMode.simulationSpeed) {
      simMinute += minutesToAdd;
      while (simMinute >= 60) {
        simMinute -= 60;
        simHour = (simHour + 1) % 24;
      }
      notifyListeners();
    }
  }

  void toggleMode() {
    if (mode == TimeMode.philippineRealTime) {
      mode = TimeMode.simulationSpeed;
      simHour = nowPHT.hour;
      simMinute = nowPHT.minute;
    } else {
      mode = TimeMode.philippineRealTime;
    }
    notifyListeners();
  }
}
