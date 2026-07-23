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

    // Intentamos recuperar el username guardado para repoblar el perfil
    try {
      // Si no se puede recuperar el perfil, igual deja la sesión activa
      // con datos mínimos — se completará en el primer fetch.
      _empleado = Empleado(
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
      return false;
    }
  }

  void touchActivity() => AuthService.touchActivity();
}
