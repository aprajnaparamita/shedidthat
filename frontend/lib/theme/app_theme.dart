import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final darkBase = ThemeData.dark();
    return darkBase.copyWith(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.screenBackground,
      colorScheme: darkBase.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        background: AppColors.screenBackground,
        surface: AppColors.cardBubbleBackground,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.mainBackground,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: kIsWeb ? 'Lato' : null,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      textTheme: darkBase.textTheme.apply(fontFamily: 'Lato').copyWith(
            headlineMedium: darkBase.textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryText,
            ),
            bodyMedium: darkBase.textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryText,
            ),
            titleMedium: darkBase.textTheme.titleMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
            labelSmall: darkBase.textTheme.labelSmall?.copyWith(
              color: AppColors.tertiaryText, // For timestamps
            ),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFieldBackground,
        hintStyle: const TextStyle(color: AppColors.inputPlaceholder),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
          borderSide: BorderSide(color: AppColors.inputFieldBorder, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
          borderSide: BorderSide(color: AppColors.inputFieldBorderFocus, width: 2.0),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.buttonPrimary,
        foregroundColor: AppColors.buttonPrimaryText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.buttonPrimaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondaryText,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBubbleBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  // Keeping light theme for completeness, but it's not currently used.
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.white,
      // Define other light theme properties if needed in the future
    );
  }
}