import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF4A0E5C);
  static const Color accent = Color(0xFFE91E8C);

  // Background Colors
  static const Color mainBackground = Color(0xFF402558);
  static const Color screenBackground = Color(0xFF402558);
  static const Color cardBubbleBackground = Color(0xFF3D1048);

  // Text Colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFC9A3D6);
  static const Color tertiaryText = Color(0xFF8B6B96);
  static const Color disabledText = Color(0xFF5A3F63);

  // Chat Bubbles
  static const Color jessBubbleBackground = Color(0xFFF5F5F5);
  static const Color jessBubbleText = Color(0xFF2D0838);
  static const Color jessBubbleBorder = Color(0xFFE6E6E6);
  static const Color userBubbleBackground = Color(0xFFE91E8C);
  static const Color userBubbleGradientEnd = Color(0xFFFF3DA1);
  static const Color userBubbleText = Color(0xFFFFFFFF);

  // UI Elements
  static const Color inputFieldBackground = Color(0xFF3D1048);
  static const Color inputFieldBorder = Color(0xFF5A3F63);
  static const Color inputFieldBorderFocus = Color(0xFFE91E8C);
  static const Color inputText = Color(0xFFFFFFFF);
  static const Color inputPlaceholder = Color(0xFF8B6B96);

  static const Color buttonPrimary = Color(0xFFE91E8C);
  static const Color buttonPrimaryHover = Color(0xFFFF3DA1);
  static const Color buttonPrimaryText = Color(0xFFFFFFFF);

  static const Color buttonSecondary = Color(0xFF5A3F63);
  static const Color buttonSecondaryHover = Color(0xFF6D4C76);
  static const Color buttonSecondaryText = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFF5A3F63);

  // Status & Feedback
  static const Color success = Color(0xFF7FD67F);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB366);
  static const Color info = Color(0xFF66B3FF);

  // Gradients
  static const LinearGradient userBubbleGradient = LinearGradient(
    colors: [userBubbleBackground, userBubbleGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [mainBackground, screenBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
