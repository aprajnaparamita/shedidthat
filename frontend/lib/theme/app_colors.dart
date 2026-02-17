import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4A0E5C);
  static const Color accent = Color(0xFFE91E8C);
  static const Color background = Color(0xFFF8F7FC);
  static const Color jessBubble = Color(0xFFF0F0F0);

  static const Gradient userBubbleGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
