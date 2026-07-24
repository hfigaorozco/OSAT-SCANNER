import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  Empleado? _empleado;
  bool _loading = false;
  String? _error;

  Empleado? get empleado => _empleado;
  bool get isLoggedIn => _empleado != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _empleado = await AuthService.login(username, password);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error inesperado. Intenta de nuevo.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// RFM02 — no permite cerrar sesión con una etapa en curso sin completar.
  /// El llamador (UI) debe verificar esto contra el HomeProvider antes de invocar.
  Future<void> logout() async {
    await AuthService.logout();
    _empleado = null;
    notifyListeners();
  }

  Future<bool> tryRestoreSession() async {
    final logged = await AuthService.isLoggedIn();
    if (!logged) return false;

    final expired = await AuthService.sessionExpiredByInactivity();
    if (expired) {
      await AuthService.logout();
      return false;
    }

    // Recuperamos el username guardado en el último login para repoblar
    // el perfil real del operador (nombre, rol, etc.) en vez de dejar un
    // placeholder genérico cada vez que se reabre la app.
    final username = await AuthService.getSavedUsername();
    try {
      _empleado = username != null
          ? await AuthService.getPerfil(username)
          : Empleado(
              numero: 0,
              nombre: 'Operador',
              primerApell: '',
              seguApell: '',
              username: '',
              email: '',
              rol: 'Operador',
              estado: 'Activo',
            );
      notifyListeners();
      return true;
    } catch (_) {
      // Si falla el fetch del perfil, igual dejamos la sesión activa
      // con datos mínimos para no forzar un re-login innecesario.
      _empleado = Empleado(
        numero: 0,
        nombre: username ?? 'Operador',
        primerApell: '',
        seguApell: '',
        username: username ?? '',
        email: '',
        rol: 'Operador',
        estado: 'Activo',
      );
      notifyListeners();
      return true;
    }
  }

  void touchActivity() => AuthService.touchActivity();
}
