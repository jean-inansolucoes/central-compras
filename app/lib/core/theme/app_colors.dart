import 'package:flutter/material.dart';

/// Paleta de marca do SmartSupply/INAN, reaproveitada das notificações
/// in-app (skill protheus-notification-html) para manter a identidade
/// visual consistente entre o Protheus e este app.
abstract final class AppColors {
  static const roxoEscuro = Color(0xFF2E105D);
  static const roxo = Color(0xFF441C7D);
  static const roxoMedio = Color(0xFF6B31B0);
  static const roxoClaro = Color(0xFFA57DD0);
  static const roxoSuave = Color(0xFF8256B9);

  static const pink = Color(0xFFF41DAB);
  static const pinkEscuro = Color(0xFFCD1F92);

  static const cinzaLilas = Color(0xFFB6ACC7);
  static const texto = Color(0xFF2B2536);
  static const textoSuave = Color(0xFF5B5468);

  static const fundoPagina = Color(0xFFFAF9FC);
  static const fundoCard = Color(0xFFFFFFFF);
  static const borda = Color(0xFFE6E0F0);

  static const sucesso = Color(0xFF1F9D63);
  static const alerta = Color(0xFFE0A300);
  static const perigo = Color(0xFFD63B5C);

  static const gradientePrincipal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [roxoEscuro, roxo],
  );

  static const gradienteDestaque = LinearGradient(
    colors: [roxoMedio, pink, pinkEscuro],
  );
}
