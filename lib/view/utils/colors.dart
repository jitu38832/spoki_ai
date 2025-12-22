import 'dart:ui';

import 'package:flutter/material.dart';

class HexColor {
  static Color convertHexToColor(String hexColorCode) {
    if (hexColorCode.length != 7 || hexColorCode[0] != '#') {
      throw ArgumentError("Invalid color code format. Expected format: #RRGGBB");
    }

    int red = int.parse(hexColorCode.substring(1, 3), radix: 16);
    int green = int.parse(hexColorCode.substring(3, 5), radix: 16);
    int blue = int.parse(hexColorCode.substring(5, 7), radix: 16);

    return Color.fromARGB(255, red, green, blue);
  }
}

final Color greyColor = HexColor.convertHexToColor('#6B6B6B');
final Color appColor = HexColor.convertHexToColor('#252787');
final Color orangeColor = HexColor.convertHexToColor('#FFA500');

final Color primaryBlue = HexColor.convertHexToColor('#3070EA');
final Color textFieldBorderColor = HexColor.convertHexToColor('#D4D4D4').withOpacity(0.5);
