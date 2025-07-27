import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ## PALET WARNA BARU ##
  // Warna utama baru
  static const Color primaryColor = Color(0xFFE53888);
  // Warna putih untuk latar belakang dan elemen lainnya
  static const Color whiteColor = Colors.white;
  // Aksen: versi transparan dari warna utama untuk elemen non-aktif
  static const Color accentColor =
      Color(0x66E53888); // Primary color with 40% opacity

  // Warna teks untuk keterbacaan
  static const Color primaryTextColor = Color(0xFF1A1A1A); // Hitam pekat
  static const Color secondaryTextColor = Color(0xFF666666); // Abu-abu

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Skema warna utama
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: primaryColor, // Secondary juga menggunakan warna utama
        background: whiteColor,
      ),
      scaffoldBackgroundColor: whiteColor,
      cardColor: whiteColor,
      // Tema untuk AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: whiteColor,
        ),
        iconTheme: const IconThemeData(color: whiteColor),
      ),
      // Tema untuk semua teks di aplikasi
      textTheme: GoogleFonts.nunitoTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: primaryTextColor),
          headlineMedium: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryTextColor),
          headlineSmall: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryTextColor),
          bodyLarge: TextStyle(fontSize: 16, color: primaryTextColor),
          bodyMedium: TextStyle(fontSize: 14, color: secondaryTextColor),
        ),
      ),
      // Tema untuk Tombol
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Tema untuk Input Field
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Sedikit warna abu-abu agar field terlihat di atas latar putih
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        hintStyle: const TextStyle(color: secondaryTextColor),
        labelStyle: const TextStyle(color: primaryTextColor),
      ),
      // Tema untuk Ikon
      iconTheme: const IconThemeData(
        color: primaryColor,
      ),
      // Tema untuk Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
      ),
    );
  }
}
