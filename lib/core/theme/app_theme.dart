import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF9B7EBD);
  static const Color secondary = Color(0xFFE8A0BF);
  static const Color surface = Color(0xFFF8F4FF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF12101C);
  static const Color darkCard = Color(0xFF1E1B2E);
  // Family / caregiver mode accent (pink)
  static const Color familyPrimary = Color(0xFFD06090);

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      surface: surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineLarge: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black87),
        headlineMedium: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
        headlineSmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
        titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        bodyLarge: GoogleFonts.nunito(fontSize: 17, color: Colors.black87),
        bodyMedium: GoogleFonts.nunito(fontSize: 15, color: Colors.black54),
        labelLarge: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
        labelMedium: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: cardBg,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.nunito(fontSize: 15),
        hintStyle: GoogleFonts.nunito(fontSize: 15, color: Colors.grey.shade400),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        indicatorColor: primary.withValues(alpha:0.15),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      surface: darkSurface,
      brightness: Brightness.dark,
    ).copyWith(surface: darkSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: darkSurface,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge:  GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold,  color: Colors.white),
        headlineLarge: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700,  color: Colors.white),
        headlineMedium:GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600,  color: Colors.white),
        headlineSmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600,  color: Colors.white),
        titleLarge:    GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,  color: Colors.white),
        titleMedium:   GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500,  color: Colors.white),
        bodyLarge:     GoogleFonts.nunito(fontSize: 17, color: Colors.white70),
        bodyMedium:    GoogleFonts.nunito(fontSize: 15, color: Colors.white54),
        labelLarge:    GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        labelMedium:   GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: darkCard,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.nunito(fontSize: 15, color: Colors.white70),
        hintStyle:  GoogleFonts.nunito(fontSize: 15, color: Colors.white38),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: darkCard,
        elevation: 0,
        indicatorColor: primary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
