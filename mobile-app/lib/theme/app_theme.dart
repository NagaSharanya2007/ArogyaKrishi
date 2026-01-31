import 'package:flutter/material.dart';

/// Modern ArogyaKrishi app theme with agri-tech aesthetic
/// Uses calm greens, earth tones, and clean typography
class AppTheme {
  // ============ PRIMARY COLORS ============
  static const Color primaryGreen = Color(
    0xFF2D7A4A,
  ); // Deep agricultural green
  static const Color primaryLightGreen = Color(
    0xFF4CAF50,
  ); // Standard growth green
  static const Color accentGreen = Color(0xFF81C784); // Light accent green

  // ============ SECONDARY COLORS ============
  static const Color earthBrown = Color(0xFF6D4C41); // Earth tone
  static const Color soilDark = Color(0xFF4E342E); // Dark soil
  static const Color cropYellow = Color(0xFFFBC02D); // Crop/wheat color
  static const Color warningOrange = Color(0xFFFF9800); // Disease warning
  static const Color dangerRed = Color(0xFFE53935); // Critical issues
  static const Color successGreen = Color(0xFF43A047); // Success

  // ============ NEUTRAL COLORS ============
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF424242);
  static const Color charcoal = Color(0xFF212121);

  // ============ SEMANTIC COLORS ============
  static const Color surfaceLight = Color(0xFFF9F9F9);
  static const Color cardLight = Color(0xFFFEFEFE);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // ============ THEME DATA ============
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      secondary: accentGreen,
      tertiary: earthBrown,
      surface: white,
      error: dangerRed,
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _headlineStyle.copyWith(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: white, size: 24),
    ),

    // Scaffold Background
    scaffoldBackgroundColor: surfaceLight,

    // Card Theme
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _bodyStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: _bodyStyle.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _bodyStyle.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerRed, width: 2),
      ),
      labelStyle: _labelStyle.copyWith(color: mediumGrey),
      hintStyle: _labelStyle.copyWith(color: mediumGrey),
      errorStyle: _labelStyle.copyWith(color: dangerRed),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: _headlineStyle.copyWith(fontSize: 20),
      contentTextStyle: _bodyStyle.copyWith(color: darkGrey),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Text Themes
    textTheme: TextTheme(
      displayLarge: _headlineStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: _headlineStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: _headlineStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: _headlineStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: _headlineStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: _headlineStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: _bodyStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: _bodyStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: _bodyStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: _bodyStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: _bodyStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: _bodyStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: _labelStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: _labelStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: _labelStyle.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 16,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: primaryGreen, size: 24),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryGreen;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: primaryGreen, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryGreen;
        }
        return mediumGrey;
      }),
    ),
  );

  // ============ TEXT STYLES ============
  static const TextStyle _headlineStyle = TextStyle(
    color: charcoal,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static const TextStyle _bodyStyle = TextStyle(
    color: darkGrey,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle _labelStyle = TextStyle(
    color: mediumGrey,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  // ============ SPACING CONSTANTS ============
  static const double paddingXXS = 4;
  static const double paddingXS = 8;
  static const double paddingS = 12;
  static const double paddingM = 16;
  static const double paddingL = 20;
  static const double paddingXL = 24;
  static const double paddingXXL = 32;

  // ============ BORDER RADIUS ============
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;

  // ============ HELPER METHODS ============
  static EdgeInsets paddingAll(double value) => EdgeInsets.all(value);

  static EdgeInsets paddingSymmetric({
    double horizontal = paddingM,
    double vertical = paddingM,
  }) => EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);

  static BorderRadius borderRadiusAll(double radius) =>
      BorderRadius.circular(radius);

  static BoxDecoration cardDecoration({
    double borderRadius = radiusL,
    Color backgroundColor = cardLight,
    Color borderColor = dividerColor,
    double elevation = 2,
  }) => BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: borderColor, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation * 0.5),
      ),
    ],
  );
}
