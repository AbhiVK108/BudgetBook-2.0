import 'package:flutter/material.dart';

class AppColors {
  static const LinearGradient scaffoldGradient = LinearGradient(
    colors: [
      Color(0xFFFFFFFF), // #FFFFFF
      Color(0xFFF4FAFD), // #F4FAFD
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const Color primaryTeal = Color(0xFF019788);
  static const Color secondaryTeal = Color(0xFF1BBCAC);

  static const Color incomeGreen = Color(0xFF27AE60);
  static const Color expenseRed = Color(0xFFFD9754);
  static const Color iconRed = Color(0xFFA53B29);
  static const Color iconTeal = Color(0xFF006B58);
  static const Color iconLightTeal = Color(0xFF1DB99A);

  static const Color cardBg = Color(0xFFF2F4F7);
  static const Color cardBgWhite = Color(0xFFFFFFFF);

  static const LinearGradient bannerGradient = LinearGradient(
    colors: [primaryTeal, secondaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
