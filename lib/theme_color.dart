import 'package:flutter/material.dart';

import 'package:recorder/model.dart';

class ThemeColor {
  final int? themeNumber;
  final BuildContext context;

  ThemeColor({this.themeNumber, required this.context});

  Brightness get _effectiveBrightness {
    switch (themeNumber) {
      case 1:
        return Brightness.light;
      case 2:
        return Brightness.dark;
      default:
        return Theme.of(context).brightness;
    }
  }

  Color _getRainbowAccentColor(int hue, double saturation, double value) {
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, value).toColor();
  }

  bool get _isLight => _effectiveBrightness == Brightness.light;

  //main page
  Color get mainBackColor => _isLight ? Color.fromRGBO(150, 150, 150, 1.0) : Color.fromRGBO(20, 20, 20, 1.0);
  Color get mainBackColor2 => _isLight ? Color.fromRGBO(60, 60, 60, 1.0) : Color.fromRGBO(0, 0, 0, 1.0);
  Color get mainCardColor => _isLight ? Color.fromRGBO(255,255,255,0.5) : Color.fromRGBO(0,0,0,0.1);
  Color get mainForeColor => _isLight ? Color.fromRGBO(200, 200, 200, 1.0) : Color.fromRGBO(200, 200, 200, 1.0);
  Color get mainAccentForeColor => _isLight ? _getRainbowAccentColor(Model.schemeColor,1,0.5) : _getRainbowAccentColor(Model.schemeColor,0.4,1.0);
  Color get mainAccentForeColor2 => _isLight ? _getRainbowAccentColor(Model.schemeColor,0.5,0.7) : _getRainbowAccentColor(Model.schemeColor,1,0.4);
  //main page image
  String get mainRecorderBody => _isLight ? 'assets/image/recorder_body.png' : 'assets/image/recorder_body_dark.png';
  //setting page
  Color get backColor => _isLight ? Colors.grey[200]! : Colors.grey[900]!;
  Color get cardColor => _isLight ? Colors.white : Colors.grey[800]!;
  Color get appBarForegroundColor => _isLight ? Colors.grey[700]! : Colors.white70;
  Color get dropdownColor => cardColor;
  Color get borderColor => _isLight ? Colors.grey[300]! : Colors.grey[700]!;
  Color get inputFillColor => _isLight ? Colors.grey[50]! : Colors.grey[900]!;
}
