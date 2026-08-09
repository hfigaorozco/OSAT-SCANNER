import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Servicio base que centraliza el token y los headers de autenticación.
/// Todos los demás servicios (AuthService, LoteService, etc.) lo usan.
class ApiClient {
  static const _tokenKey = 'osat_auth_token';
  static String? _cachedToken;

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  static Future<dynamic> get(String url, {bool auth = true}) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 10));
      return _handle(res);
      // _handle() ya clasifica sus propios errores (401, 400 con mensaje
      // parseado, etc.) — el catch de abajo es solo para errores de red
      // reales (timeout, sin conexión). Sin el catch ApiException/rethrow
      // aquí, ese catch genérico volvía a atrapar el ApiException de
      // _handle() y lo reescribía como "Sin conexión al servidor:
      // <mensaje real>" (perdiendo también el statusCode), aunque el
      // server sí había respondido.
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException('Sin conexión al servidor: $e');
    }
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body,
      {bool auth = true}) async {
    try {
      final res = await http
          .post(Uri.parse(url),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      return _handle(res);
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException('Sin conexión al servidor: $e');
    }
  }

  static Future<dynamic> patch(String url, Map<String, dynamic> body,
      {bool auth = true}) async {
    try {
      final res = await http
          .patch(Uri.parse(url),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      return _handle(res);
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException('Sin conexión al servidor: $e');
    }
  }

  static dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    if (res.statusCode == 401) {
      throw ApiException('Sesión expirada. Inicia sesión de nuevo.',
          statusCode: 401);
    }
    String msg = 'Error del servidor (${res.statusCode})';
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      // DRF serializa un ValidationError de string plano (como los que
      // lanza CreatePasoRealizadoSerializer.create() para reglas de
      // negocio: lote en Hold, orden rechazada, etc.) como una lista JSON
      // en la raíz — no como un Map — así que sin este caso el mensaje
      // real quedaba descartado y el operador solo veía "Error del
      // servidor (400)", que se leía como una falla de conexión genérica.
      if (decoded is List && decoded.isNotEmpty) {
        msg = _flattenError(decoded.first);
      } else if (decoded is Map && decoded.isNotEmpty) {
        msg = _flattenError(decoded.values.first);
      }
    } catch (_) {}
    throw ApiException(msg, statusCode: res.statusCode);
  }

  static String _flattenError(dynamic value) {
    if (value is List && value.isNotEmpty) return _flattenError(value.first);
    if (value is Map && value.isNotEmpty) {
      return _flattenError(value.values.first);
    }
    return value.toString();
  }
}
