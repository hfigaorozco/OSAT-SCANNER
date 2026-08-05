import 'package:shared_preferences/shared_preferences.dart';
import '../models/empleado.dart';
import '../utils/constants.dart';
import 'api_client.dart';
import 'recientes_service.dart';

class AuthService {
  static const _usernameKey = 'osat_username';
  static const _lastActivityKey = 'osat_last_activity';

  /// RFM01 — Tiempo en segundo plano tras el cual se pide confirmar
  static const Duration inactivityTimeout = Duration(minutes: 1);

  /// RFM01 — Login con usuario empresarial y contraseña.
  /// Devuelve el Empleado autenticado y guarda el token.
  static Future<Empleado> login(String username, String password) async {
    final data = await ApiClient.post(
      ApiConfig.login,
      {'username': username, 'password': password},
      auth: false,
    );

    final token = data['token'] as String?;
    if (token == null) {
      throw ApiException('Respuesta de login inválida.');
    }
    await ApiClient.saveToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await _touchActivity();

    // Buscar los datos del empleado por username
    final empleados = await ApiClient.get(ApiConfig.empleados);
    final match = (empleados as List).firstWhere(
      (e) => e['username'] == username,
      orElse: () => null,
    );

    if (match == null) {
      // Login válido pero sin perfil de empleado vinculado todavía
      return Empleado(
        numero: 0,
        nombre: username,
        primerApell: '',
        seguApell: '',
        username: username,
        email: '',
        rol: 'Operador',
        estado: 'Activo',
      );
    }
    return Empleado.fromJson(match);
  }

  /// RFM02 — Cierre de sesión: invalida el token en el servidor y limpia local.
  static Future<void> logout() async {
    try {
      await ApiClient.post(ApiConfig.logout, {});
    } catch (_) {
      // Si falla la llamada al server, igual limpiamos localmente
    }
    await ApiClient.clearToken();
    await RecientesService.limpiar();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_lastActivityKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null;
  }

  /// Username guardado en el último login, usado para repoblar el perfil
  /// al restaurar sesión (splash / reanudar app).
  static Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// RFM01 — si la app lleva +30 min en background, se solicita re-autenticación.
  static Future<void> touchActivity() => _touchActivity();

  static Future<void> _touchActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastActivityKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> sessionExpiredByInactivity() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastActivityKey);
    if (last == null) return false;
    final diff = DateTime.now().millisecondsSinceEpoch - last;
    return diff > inactivityTimeout.inMilliseconds;
  }

  /// RFM03 — Consultar datos de perfil (solo lectura).
  static Future<Empleado> getPerfil(String username) async {
    final empleados = await ApiClient.get(ApiConfig.empleados);
    final match = (empleados as List).firstWhere(
      (e) => e['username'] == username,
      orElse: () => null,
    );
    if (match == null) {
      throw ApiException('No se encontró el perfil del empleado.');
    }
    return Empleado.fromJson(match);
  }
}
