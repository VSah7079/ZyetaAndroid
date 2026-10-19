import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Brand & Accents (Apple / Stripe enterprise palette)
  static const Color primary = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primarySubtle = Color(0xFFEFF6FF);

  static const Color secondary = Color(0xFF0EA5E9); // Sky / Tech Cyan
  static const Color secondarySubtle = Color(0xFFF0F9FF);

  // Backgrounds & Surfaces (Crisp Daylight Light Mode)
  static const Color bgPrimary = Color(0xFFF8FAFC); // Main canvas soft slate
  static const Color bgCard = Colors.white;
  static const Color bgSurface = Color(0xFFF1F5F9);
  static const Color bgMuted = Color(0xFFE2E8F0);

  // Typography & Content
  static const Color textPrimary = Color(0xFF0F172A); // High-contrast navy-black
  static const Color textSecondary = Color(0xFF475569); // Crisp body slate
  static const Color textMuted = Color(0xFF94A3B8); // Subtitle slate
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderFocus = Color(0xFF93C5FD);

  // Semantic Status Colors
  static const Color success = Color(0xFF059669); // Emerald
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626); // Rose / Alert
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Soft Ambient Drop Shadows (Apple / Stripe Card Elevation)
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 5),
      spreadRadius: 0,
    ),
  ];

  // Reusable Modern Compact Card Decoration
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    Border? customBorder,
    List<BoxShadow>? shadow,
  }) {
    return BoxDecoration(
      color: color ?? bgCard,
      borderRadius: borderRadius ?? BorderRadius.circular(14),
      border: customBorder ?? Border.all(color: border, width: 1),
      boxShadow: shadow ?? softShadow,
    );
  }

  // Modern Badge / Chip Decoration
  static BoxDecoration badgeDecoration({
    Color? color,
    Color? background,
    Color? borderColor,
    double radius = 8,
  }) {
    final bg = background ?? (color != null ? color.withValues(alpha: 0.1) : primarySubtle);
    final borderCol = borderColor ?? (color != null ? color.withValues(alpha: 0.3) : primary.withValues(alpha: 0.3));
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderCol, width: 1),
    );
  }

  // Global Flutter ThemeData Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: primary,
      canvasColor: bgPrimary,
      cardColor: bgCard,
      dividerColor: border,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: Brightness.light).textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: bgCard,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.06),
        iconTheme: const IconThemeData(color: textPrimary),
        actionsIconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textMuted,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: border,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
