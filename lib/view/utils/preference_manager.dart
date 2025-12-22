import 'package:shared_preferences/shared_preferences.dart';

class PreferenceManager {
  static SharedPreferences? _sharedPreferences;

  static Future<SharedPreferences> get _instance async =>
      _sharedPreferences ??= await SharedPreferences.getInstance();

  static Future<void> init() async => await _instance;

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