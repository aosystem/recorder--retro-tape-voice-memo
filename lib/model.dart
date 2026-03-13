import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recorder/l10n/app_localizations.dart';

class Model {
  Model._();

  static const String _prefRecordFormat = 'recordFormat';
  static const String _prefVibrateEnabled = 'vibrateEnabled';
  static const String _prefSoundEnabled = 'soundEnabled';
  static const String _prefSoundVolume = 'soundVolume';
  static const String _prefRewindEnabled = 'rewindEnabled';
  static const String _prefWakelockEnabled = 'wakelockEnabled';
  static const String _prefSchemeColor = 'schemeColor';
  static const String _prefThemeNumber = 'themeNumber';
  static const String _prefLanguageCode = 'languageCode';

  static bool _ready = false;
  static String _recordFormat = 'aac';    //'aac' | 'wav'
  static bool _vibrateEnabled = true;
  static bool _soundEnabled = true;
  static double _soundVolume = 0.2;
  static bool _rewindEnabled = true;
  static bool _wakelockEnabled = false;
  static int _schemeColor = 110;
  static int _themeNumber = 0;
  static String _languageCode = '';

  static String get recordFormat => _recordFormat;
  static bool get vibrateEnabled => _vibrateEnabled;
  static bool get soundEnabled => _soundEnabled;
  static double get soundVolume => _soundVolume;
  static bool get rewindEnabled => _rewindEnabled;
  static bool get wakelockEnabled => _wakelockEnabled;
  static int get schemeColor => _schemeColor;
  static int get themeNumber => _themeNumber;
  static String get languageCode => _languageCode;

  static Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    //
    _recordFormat = prefs.getString(_prefRecordFormat) ?? 'aac';
    _vibrateEnabled = prefs.getBool(_prefVibrateEnabled) ?? true;
    _soundEnabled = prefs.getBool(_prefSoundEnabled) ?? true;
    _soundVolume = (prefs.getDouble(_prefSoundVolume) ?? 0.2).clamp(0.0, 1.0);
    _rewindEnabled = prefs.getBool(_prefRewindEnabled) ?? true;
    _wakelockEnabled = prefs.getBool(_prefWakelockEnabled) ?? false;
    _schemeColor = (prefs.getInt(_prefSchemeColor) ?? 110).clamp(0, 360);
    _themeNumber = (prefs.getInt(_prefThemeNumber) ?? 0).clamp(0, 2);
    _languageCode = prefs.getString(_prefLanguageCode) ?? ui.PlatformDispatcher.instance.locale.languageCode;
    _languageCode = _resolveLanguageCode(_languageCode);
    _ready = true;
  }

  static String _resolveLanguageCode(String code) {
    final supported = AppLocalizations.supportedLocales;
    if (supported.any((l) => l.languageCode == code)) {
      return code;
    } else {
      return '';
    }
  }

  static Future<void> setRecordFormat(String value) async {
    _recordFormat = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefRecordFormat, value);
  }

  static Future<void> setVibrateEnabled(bool value) async {
    _vibrateEnabled = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefVibrateEnabled, value);
  }

  static Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSoundEnabled, value);
  }

  static Future<void> setSoundVolume(double value) async {
    _soundVolume = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefSoundVolume, value);
  }

  static Future<void> setRewindEnabled(bool value) async {
    _rewindEnabled = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefRewindEnabled, value);
  }

  static Future<void> setWakelockEnabled(bool value) async {
    _wakelockEnabled = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefWakelockEnabled, value);
  }

  static Future<void> setSchemeColor(int value) async {
    _schemeColor = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefSchemeColor, value);
  }

  static Future<void> setThemeNumber(int value) async {
    _themeNumber = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeNumber, value);
  }

  static Future<void> setLanguageCode(String value) async {
    _languageCode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageCode, value);
  }

}
