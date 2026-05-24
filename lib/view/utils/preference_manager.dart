import 'package:shared_preferences/shared_preferences.dart';

class PreferenceManager {
  static SharedPreferences? _sharedPreferences;

  /// Mirrors backend-confirmed entitlement after IAP register (`subscriptions/iap/register`).
  /// Not used for authoritative chat metering — cleared by [clearPreferences].
  static const String premiumSubscribedKey = 'premium_subscribed';

  /// Mirrored from `users/me` for drawer / chrome where Bloc may be unavailable.
  static const String profileDisplayNameKey = 'profile_display_name';

  /// Mirrored from `users/me`; used client-side hints only — server validates QA bypass emails.
  static const String profileCachedEmailKey = 'profile_cached_email';

  /// Matches server allow-list (`subscriptions/qa/test-grant`).
  static const String qaSubscriptionBypassEmail = 'saifimunshad0@gmail.com';

  /// Profile email lowercase; skips network if mismatched vs [qaSubscriptionBypassEmail].
  static void cacheProfileEmail(String? email) {
    final e = email?.trim().toLowerCase() ?? '';
    insertValue(key: profileCachedEmailKey, value: e);
  }

  static bool cachedProfileMatchesQaSubscriptionBypass() {
    final e = getStringValue(key: profileCachedEmailKey)?.trim().toLowerCase() ?? '';
    return e.isNotEmpty && e == qaSubscriptionBypassEmail;
  }

  static Future<SharedPreferences> get _instance async =>
      _sharedPreferences ??= await SharedPreferences.getInstance();

  static Future<void> init() async => await _instance;

  /// Persists trimmed display name; empty clears the cached value.
  static void cacheProfileDisplayName(String? name) {
    insertValue(key: profileDisplayNameKey, value: name?.trim() ?? '');
  }

  /// Cached profile name or [fallback] (default "User").
  static String profileDisplayNameForDrawer({String fallback = 'User'}) {
    final t = getStringValue(key: profileDisplayNameKey)?.trim() ?? '';
    return t.isNotEmpty ? t : fallback;
  }

  static String? getStringValue({required String key}) {
    String? value;

    try {
      value = _sharedPreferences?.getString(key);
    }
    catch (e) {
      value = null;
    }
    return value;
  }

  static bool? getBooleanValue({required String key}) {
    bool? value;

    try {
      value = _sharedPreferences?.getBool(key);
    }
    catch (e) {
      value = null;
    }
    return value;
  }

  static int? getIntegerValue({required String key}) {
    int? value;

    try {
      value = _sharedPreferences?.getInt(key);
    }
    catch (e) {
      value = null;
    }
    return value;
  }

  static insertValue({required String key, required dynamic value}) {
    switch(value.runtimeType) {
      case String: _sharedPreferences?.setString(key, value);
      break;
      case bool: _sharedPreferences?.setBool(key, value);
      break;
      case int: _sharedPreferences?.setInt(key, value);
      break;
    }
  }

  static clearPreferences() {
    _sharedPreferences?.clear();
  }
}