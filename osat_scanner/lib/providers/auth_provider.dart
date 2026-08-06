import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  Empleado? _empleado;
  bool _loading = false;
  String? _error;
  bool _locked = false;
  String? _lockError;
  bool _confirmandoIdentidad = false;

  Empleado? get empleado => _empleado;
  bool get isLoggedIn => _empleado != null;
  bool get loading => _loading;
  String? get error => _error;

  /// RFM01 — la app estuvo +30 min en segundo plano: hay que confirmar la
  /// identidad del operador antes de seguir, sin tocar el token del server.
  bool get isLocked => _locked;
  String? get lockError => _lockError;
  bool get confirmandoIdentidad => _confirmandoIdentidad;

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _empleado = await AuthService.login(username, password);
      // Se espera a que termine (falla en silencio si no hay red, dejando
      // el valor de respaldo) — main.dart arma el timer de inactividad
      // justo después de este login, así que si no se espera aquí, el
      // timer se crea con la duración vieja/por defecto y el valor nuevo
      // llega demasiado tarde para tener efecto (un Timer ya creado no
      // cambia de duración aunque se reasigne la variable después).
      await AuthService.cargarConfiguracion();
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
    _locked = false;
    _lockError = null;
    notifyListeners();
  }

  Future<bool> tryRestoreSession() async {
    final logged = await AuthService.isLoggedIn();
    if (!logged) return false;

    // Refresca el timeout de inactividad por si se cambió desde la web
    // mientras la app estaba cerrada — ANTES de revisar si la sesión ya
    // expiró por inactividad, porque esa revisión lee este mismo valor.
    // Si se esperara a después, el check de expiración correría contra la
    // duración vieja/por defecto en vez de la configurada en el server.
    await AuthService.cargarConfiguracion();

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

  /// Se llama al volver del segundo plano. Si pasaron +1 min sin actividad,
  /// bloquea la app localmente — el token sigue válido en el servidor, solo
  /// se pide confirmar identidad antes de dejar seguir usándola.
  Future<void> checkInactivityLock() async {
    if (!isLoggedIn) return;
    final expired = await AuthService.sessionExpiredByInactivity();
    if (expired) {
      _locked = true;
      _lockError = null;
      notifyListeners();
    }
  }

  /// Igual que checkInactivityLock, pero para el timer de inactividad en
  /// primer plano (main.dart): ahí el propio timer ya demostró que pasó el
  /// tiempo sin actividad, así que no hace falta volver a consultar la hora
  /// guardada — solo bloquea.
  void lockNow() {
    if (!isLoggedIn || _locked) return;
    _locked = true;
    _lockError = null;
    notifyListeners();
  }

  /// Confirmación de identidad local: valida la contraseña del operador ya
  /// logueado contra el servidor, pero sin invalidar ni reemplazar la sesión
  /// existente — solo desbloquea la app si la contraseña es correcta.
  Future<bool> confirmIdentity(String password) async {
    if (_empleado == null) return false;
    _confirmandoIdentidad = true;
    _lockError = null;
    notifyListeners();

    try {
      await AuthService.login(_empleado!.username, password);
      _locked = false;
      _confirmandoIdentidad = false;
      touchActivity();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lockError = e.message;
      _confirmandoIdentidad = false;
      notifyListeners();
      return false;
    } catch (_) {
      _lockError = 'Error inesperado. Intenta de nuevo.';
      _confirmandoIdentidad = false;
      notifyListeners();
      return false;
    }
  }
}
