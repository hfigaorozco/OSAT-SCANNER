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

  // Tipos de alerta — mismos colores que kpi/views.py::_COLOR_MAP en la web,
  // para que un operador vea el mismo código de color en móvil y en la
  // pantalla de Alertas del admin/supervisor.
  static const alertaKpi = Color(0xFF8E44AD);

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
  /// Emulador de Android (teléfono o tablet, ej. Pixel_6/Pixel_Tablet AVD):
  /// usa 10.0.2.2 — es el alias que el emulador usa para apuntar al
  /// localhost de la PC host, y NO requiere ningún paso manual (adb reverse).
  /// Este es el valor por defecto porque el desarrollo/pruebas se hacen
  /// contra emuladores.
  ///
  /// Dispositivo físico por USB: corre `adb reverse tcp:8001 tcp:8001` y usa
  /// 127.0.0.1 (el teléfono reenvía ese puerto al localhost de la PC por el cable).
  /// Dispositivo físico por WiFi (sin cable): usa la IP local de tu PC
  /// (ej. 192.168.1.50) y corre el backend con 0.0.0.0:8001 en vez de 127.0.0.1.
  ///
  /// Se puede sobreescribir en tiempo de compilación sin tocar este archivo:
  /// flutter run --dart-define=API_HOST=127.0.0.1
  static const String _host =
      String.fromEnvironment('API_HOST', defaultValue: '10.0.2.2');
  static const String baseUrl = 'http://$_host:8001/api';

  static const String login = '$baseUrl/v1/auth/login/';
  static const String logout = '$baseUrl/v1/auth/logout/';

  static const String empleados = '$baseUrl/v1/list/empleados/';
  static const String obleas = '$baseUrl/v1/list/Oblea/';
  static const String ordenes = '$baseUrl/v1/list/Orden/';
  static const String pasosProceso = '$baseUrl/v1/list/PasoProceso/';
  static const String pasosRealizados = '$baseUrl/v1/list/PasoRealizado/';
  static const String crearPasoRealizado = '$baseUrl/v1/create/PasoRealizado/';
  static const String defectos = '$baseUrl/v1/list/Defecto/';
  static const String pasoDefectos = '$baseUrl/v1/list/PasoDefecto/';
  // OJO: 'historiales_alertas' es la tabla puente de KPI (Registro_Kpi<->Alerta)
  // y no trae 'descripcion'; las alertas del operador (hold, rechazos, etc.)
  // viven en 'alertas'.
  static const String alertas = '$baseUrl/v1/list/alertas/';
  // Alertas ya clasificadas por tipo (stock/produccion/kpi) y priorizadas
  // según la línea del operador (?empleado=<numero>) — ver
  // osat_tracer/api_kpi/views.py::AlertasOperadorAPIView.
  static const String alertasOperador = '$baseUrl/v1/list/alertas_operador/';
  // Configuración de la app móvil, editable desde Configuración > Configuración
  // de la app móvil en la web (independiente del horario laboral, que es de
  // otra pantalla). Solo trae minutos de inactividad antes de bloquear sesión.
  static const String configMovil = '$baseUrl/v1/config/movil/';

  static String obleaDetail(int numero) => '$baseUrl/v1/detail/Oblea/$numero/';
  static String updateOblea(int numero) => '$baseUrl/v1/update/Oblea/$numero/'; // ajustar si el back lo agrega
  static String updateAlerta(int pk) => '$baseUrl/v1/update/alerta/$pk/';
}

/// Umbral de lado más corto (dp) a partir del cual un dispositivo se
/// considera tablet — mismo criterio en toda la app (main.dart, layouts
/// responsive de cada pantalla).
bool esTablet(BuildContext context) {
  return MediaQuery.of(context).size.shortestSide > 600;
}

/// Uso: `final s = AppScale.of(context);` y luego `s.f(14)` para texto,
/// `s.sp(12)` para espaciados/paddings, `s.ic(20)` para iconos.
class AppScale {
  final bool tablet;
  const AppScale._(this.tablet);

  factory AppScale.of(BuildContext context) => AppScale._(esTablet(context));

  /// Tamaño de fuente.
  double f(double phoneSize) => tablet ? phoneSize * 1.45 : phoneSize;

  /// Espaciado / padding / margen.
  double sp(double phoneSize) => tablet ? phoneSize * 1.4 : phoneSize;

  /// Iconos.
  double ic(double phoneSize) => tablet ? phoneSize * 1.35 : phoneSize;

  /// Alto de botones y campos de formulario.
  double h(double phoneSize) => tablet ? phoneSize * 1.3 : phoneSize;

  /// Radio de bordes — se exagera menos que el resto para que no se vea
  /// "globoso".
  double r(double phoneSize) => tablet ? phoneSize * 1.15 : phoneSize;
}
