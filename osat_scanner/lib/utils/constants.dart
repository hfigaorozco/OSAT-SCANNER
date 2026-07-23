import 'package:flutter/material.dart';

/// Design system de OSAT Tracer — debe coincidir con el frontend web (osat.css)
class AppColors {
  static const bgApp = Color(0xFF1C2433);
  static const bgTopbar = Color(0xFF243040);
  static const bgCard = Color(0xFFFFFFFF);
  static const borderCard = Color(0xFFE2E8F0);

  static const green = Color(0xFF16A85E);
  static const turquoise = Color(0xFF009EAF);
  static const purple = Color(0xFF7C3AED);
  static const gold = Color(0xFFF5A623);
  static const red = Color(0xFFEF5350);

  static const textDark = Color(0xFF1A202C);
  static const textMuted = Color(0xFF718096);
  static const textOnDark = Color(0xFFFEFDFD);

  // Estados de badges
  static const badgeGreenBg = Color(0xFFD4EDDA);
  static const badgeGreenText = Color(0xFF155724);
  static const badgeYellowBg = Color(0xFFFFF3CD);
  static const badgeYellowText = Color(0xFF856404);
  static const badgeRedBg = Color(0xFFF8D7DA);
  static const badgeRedText = Color(0xFF721C24);
  static const badgeBlueBg = Color(0xFFE3F2FD);
  static const badgeBlueText = Color(0xFF006064);
  static const badgeGrayBg = Color(0xFFE9ECEF);
  static const badgeGrayText = Color(0xFF495057);
}

class ApiConfig {
  /// 10.0.2.2 redirige al localhost de la PC host desde el emulador Android.
  /// Si pruebas en dispositivo físico, cambia esto a la IP local de tu PC
  /// (ej. 192.168.1.50) y asegúrate que el backend corra con 0.0.0.0:8001
  static const String baseUrl = 'http://10.0.2.2:8001/api';

  static const String login = '$baseUrl/v1/auth/login/';
  static const String logout = '$baseUrl/v1/auth/logout/';

  static const String empleados = '$baseUrl/v1/list/empleados/';
  static const String obleas = '$baseUrl/v1/list/Oblea/';
  static const String ordenes = '$baseUrl/v1/list/Orden/';
  static const String pasosProceso = '$baseUrl/v1/list/PasoProceso/';
  static const String pasosRealizados = '$baseUrl/v1/list/PasoRealizado/';
  static const String crearPasoRealizado = '$baseUrl/v1/create/PasoRealizado/';
  static const String defectos = '$baseUrl/v1/list/Defecto/';
  static const String historialAlertas = '$baseUrl/v1/list/historiales_alertas/';
  static const String alertas = '$baseUrl/v1/list/alertas/';

  static String obleaDetail(int numero) => '$baseUrl/v1/detail/Oblea/$numero/';
  static String updateOblea(int numero) => '$baseUrl/v1/update/Oblea/$numero/'; // ajustar si el back lo agrega
}

class AppTextStyles {
  static const screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static const subtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
}
