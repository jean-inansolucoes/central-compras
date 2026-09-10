import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  // Nunito: moderna, terminações arredondadas, boa legibilidade em telas
  // densas de formulário/lista mesmo nos pesos mais leves — substitui a
  // pilha de fontes de sistema (Segoe UI/Arial) usada antes.
  static const _fontFamily = 'Nunito';
  static const _fontFamilyFallback = ['Arial', 'Helvetica'];

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.roxo,
      brightness: Brightness.light,
      primary: AppColors.roxo,
      secondary: AppColors.pink,
      error: AppColors.perigo,
      surface: AppColors.fundoCard,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.fundoPagina,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.roxo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.fundoCard,
      ),
      cardTheme: CardThemeData(
        color: AppColors.fundoCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borda),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fundoCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.roxoMedio, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.perigo),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.roxo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.texto,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.texto,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.texto,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textoSuave,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
      ),
    );
  }
}
