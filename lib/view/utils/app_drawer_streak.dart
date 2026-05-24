import 'package:spokiai/view/utils/preference_manager.dart';

/// Drawer streak: local consecutive-day usage, capped at [maxStreak] (min 0).
///
/// Uses the device **local calendar** (midnight boundaries). Opening again the
/// same day does **not** change the value (fixes Dashboard + Home both calling sync).
///
/// Missed days: loses one streak level per skipped calendar day, then today's
/// open adds one again (floored at 0, capped at [maxStreak]).
class AppDrawerStreak {
  AppDrawerStreak._();

  static const String _daysKey = 'home_drawer_streak_days';
  static const String _lastOpenKey = 'home_drawer_streak_last_open';
  static const int maxStreak = 3;

  static String _dateStorageKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  static DateTime? _dateFromStorageKey(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  /// Safe to invoke multiple times per day (e.g. Dashboard + Home); intraday repeats
  /// leave the streak unchanged unless prefs were migrated.
  /// Returns the streak value persisted for the drawer UI.
  static int syncToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _dateStorageKey(today);

    final String? lastKey =
        PreferenceManager.getStringValue(key: _lastOpenKey);
    final int prevRaw =
        PreferenceManager.getIntegerValue(key: _daysKey) ?? 0;
    int streak = prevRaw.clamp(0, maxStreak);

    if (lastKey == null) {
      streak = 0;
      PreferenceManager.insertValue(key: _daysKey, value: streak);
      PreferenceManager.insertValue(key: _lastOpenKey, value: todayKey);
      return streak;
    }

    if (lastKey == todayKey) {
      PreferenceManager.insertValue(key: _daysKey, value: streak);
      return streak;
    }

    final DateTime? lastDate = _dateFromStorageKey(lastKey);
    if (lastDate == null) {
      streak = 0;
      PreferenceManager.insertValue(key: _daysKey, value: streak);
      PreferenceManager.insertValue(key: _lastOpenKey, value: todayKey);
      return streak;
    }

    final dayDiff = today.difference(lastDate).inDays;
    if (dayDiff < 1) {
      PreferenceManager.insertValue(key: _daysKey, value: streak);
      PreferenceManager.insertValue(key: _lastOpenKey, value: todayKey);
      return streak;
    }

    if (dayDiff == 1) {
      streak = (streak + 1).clamp(0, maxStreak);
    } else {
      final lost = dayDiff - 1;
      streak = (streak - lost).clamp(0, maxStreak);
      streak = (streak + 1).clamp(0, maxStreak);
    }

    PreferenceManager.insertValue(key: _daysKey, value: streak);
    PreferenceManager.insertValue(key: _lastOpenKey, value: todayKey);
    return streak;
  }

  /// Label for streak chip (singular only for exactly `1`).
  static String streakLabel(int days) {
    final clipped = days.clamp(0, maxStreak);
    return '$clipped ${clipped == 1 ? 'Day' : 'Days'} Streak';
  }
}
