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
      if (decoded is Map && decoded.isNotEmpty) {
        msg = decoded.values.first.toString();
      }
    } catch (_) {}
    throw ApiException(msg, statusCode: res.statusCode);
  }
}
