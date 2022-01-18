import 'package:flutter/material.dart';

class CFColors {
  // specific colors
  static const Color spark = Color(0xFFF94167);
  static const Color flame = Color(0xFFF5595C);
  static const Color starryNight = Color(0xFF262D4A);

  static const Color success = Color(0xFF5BB192);
  static const Color warning = Color(0xFFF3B846);
  static const Color error = Color(0xFFE23F3F);
  static const Color info = Color(0xFF6880F8);

  static const Color midnight = Color(0xFF131625);
  static const Color dusk = Color(0xFF51566E);
  static const Color twilight = Color(0xFF8A95B2);

  static const Color dew = Color(0xFFB8BFD0);
  static const Color smoke = Color(0xFFDBDFE7);
  static const Color fog = Color(0xFFF0F3FA);
  static const Color mist = Color(0xFFF8F9FD);

  // notification colors
  static const Color notificationInfo = Color(0xFFE1E6FE);
  static const Color notificationError = Color(0xFFFAC3C3);
  static const Color notificationSuccess = Color(0xFFC6E8DC);

  // network status overlay colors
  static const Color dropdownConnected = Color(0xFFC6E8DC);
  static const Color dropdownSynchronizing = Color(0xFFFCEAC8);
  static const Color dropdownError = Color(0xFFFAC2C2);

  // focused textfield border
  static const Color focusedBorder =
      Color(0x80F5595C); // flame with 50% opacity
  static const Color errorBorder = error;
  static const Color successBorder = success;

  // gradients
  static const LinearGradient fireGradientHorizontal = LinearGradient(colors: [
    CFColors.spark,
    CFColors.flame,
  ]);

  static const LinearGradient fireGradientVertical = LinearGradient(
    colors: [
      CFColors.spark,
      CFColors.flame,
    ],
    end: Alignment.topCenter,
    begin: Alignment.bottomCenter,
  );

  static LinearGradient fireGradientVerticalLight = LinearGradient(
    colors: [
      CFColors.spark.withOpacity(0.7),
      CFColors.flame.withOpacity(0.7),
    ],
    end: Alignment.topCenter,
    begin: Alignment.bottomCenter,
  );

  // shadow
  static const Color shadowColor = Color(0x808A95B2);
  static const BoxShadow standardBoxShadow = BoxShadow(
    color: CFColors.shadowColor,
    spreadRadius: 1,
    blurRadius: 2,
    // offset: Offset(0, 3),
  );

  // generic
  static const Color white = Color(0xFFFFFFFF);

  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    strengths.forEach((strength) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    });
    return MaterialColor(color.value, swatch);
  }
}
