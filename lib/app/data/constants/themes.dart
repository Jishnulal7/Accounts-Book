import 'package:account_book/app/data/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData themes(ThemeMode themeMode, Color primaryColor) {
  final brightness =
      themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  final textColor = brightness == Brightness.light
      ? AppColor.kGrayscaleDark100
      : AppColor.kWhite;

  return ThemeData(
    brightness: brightness,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    ),
    fontFamily: GoogleFonts.urbanist().fontFamily,
    iconTheme: IconThemeData(color: textColor),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 85,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontFamily: GoogleFonts.poppins().fontFamily,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      showUnselectedLabels: true,
      unselectedItemColor: textColor,
      unselectedLabelStyle: TextStyle(color: textColor),
      selectedLabelStyle: TextStyle(color: textColor),
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: CircleBorder(),
    ),
  );
}
