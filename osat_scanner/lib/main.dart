import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/alerta_operador.dart';
import 'providers/auth_provider.dart';
import 'providers/lote_provider.dart';
import 'services/alerta_service.dart';
import 'services/auth_service.dart';
import 'utils/constants.dart';
import 'utils/navigation.dart';
import 'screens/splash_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La orientación se maneja dinámicamente en _AppLifecycleWrapper
  // según el tamaño de pantalla del dispositivo
  runApp(const OsatTracerApp());
}

class OsatTracerApp extends StatelessWidget {
  const OsatTracerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LoteProvider()),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'OSAT Tracer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.bgApp,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.green,
            brightness: Brightness.dark,
          ),
          fontFamily: 'Roboto',
        ),
        builder: (context, child) =>
            _AppLifecycleWrapper(child: child ?? const SizedBox.shrink()),
        home: const SplashScreen(),
      ),
    );
  }
}

/// Detecta si es tablet o teléfono y fuerza orientación apropiada.
/// Tablet (shortestSide > 600): landscape forzado
/// Teléfono (shortestSide <= 600): portrait forzado
class _AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const _AppLifecycleWrapper({required this.child});

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
  bool _orientacionConfigurada = false;
  Timer? _inactivityTimer;
  bool _wasLocked = false;
  bool _wasLoggedIn = false;

  // ── Pop-up de Hold (feria) ── ver AlertasOperadorAPIView (backend) para
  // el tipo 'hold': se dispara cuando un lote/orden de la línea del
  // operador entra en Hold desde web (manual o por exceso de scrap),
  // avisando de inmediato sin necesidad de refrescar ninguna pantalla.
  Timer? _holdPollTimer;
  final Set<int> _alertasHoldVistas = {};
  bool _holdPollSembrado = false;
  bool _holdDialogAbierto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _intentarConfigurar());
    _reiniciarTimerInactividad();
  }

  /// RFM01 (extendido) — el bloqueo original solo revisaba el reloj al
  /// volver de segundo plano; si el usuario dejaba la app abierta en
  /// pantalla sin tocarla, nunca se disparaba. Este timer cubre ese caso:
  /// cualquier toque en cualquier parte de la app (capturado por el
  /// Listener de más abajo) lo reinicia, y si se agota sin actividad, se
  /// bloquea igual que al volver de segundo plano.
  void _reiniciarTimerInactividad() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(AuthService.inactivityTimeout, () {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn && !auth.isLocked) {
        auth.lockNow();
      }
    });
  }

  void _iniciarPollHold() {
    _holdPollTimer?.cancel();
    _alertasHoldVistas.clear();
    _holdPollSembrado = false;
    _holdPollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _revisarAlertasHold());
  }

  void _detenerPollHold() {
    _holdPollTimer?.cancel();
    _holdPollTimer = null;
  }

  /// Poll de alertas de Hold — sin esto el operador solo se entera de que
  /// debe parar producción al intentar completar una etapa y que el
  /// servidor la rechace (ver CreatePasoRealizadoSerializer en el backend,
  /// que ya bloquea eso), o si refresca manualmente la pantalla de
  /// Alertas. Este timer avisa de inmediato con un pop-up, sin refresh.
  Future<void> _revisarAlertasHold() async {
    if (!mounted || _holdDialogAbierto) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.isLocked) return;

    List<AlertaOperador> alertas;
    try {
      alertas = await AlertaService.listar(empleadoNumero: auth.empleado?.numero);
    } catch (_) {
      return; // red inestable — se reintenta solo en el próximo tick
    }
    final holds = alertas.where((a) =>
        a.tipo == TipoAlertaOperador.hold && a.esMiLinea == true && !a.leida);

    if (!_holdPollSembrado) {
      // Primer poll tras iniciar sesión: las alertas de Hold que ya
      // existían de antes no deben disparar el pop-up, solo las nuevas.
      _alertasHoldVistas.addAll(holds.map((a) => a.numero));
      _holdPollSembrado = true;
      return;
    }

    for (final a in holds) {
      if (_alertasHoldVistas.contains(a.numero)) continue;
      _alertasHoldVistas.add(a.numero);
      await _mostrarDialogHold(a);
      break; // una a la vez — si hay más, el siguiente tick muestra la próxima
    }
  }

  Future<void> _mostrarDialogHold(AlertaOperador alerta) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    _holdDialogAbierto = true;
    try {
      bool enviando = false;
      await showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogCtx) => PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (dialogCtx, setDialogState) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.pause_circle_filled, color: AppColors.gold, size: 26),
                  SizedBox(width: 8),
                  Expanded(child: Text('Producción en Hold')),
                ],
              ),
              content: Text(
                alerta.descripcion,
                style: const TextStyle(height: 1.4),
              ),
              actions: [
                FilledButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          setDialogState(() => enviando = true);
                          try {
                            await AlertaService.marcarLeida(alerta.numero);
                          } catch (_) {}
                          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                        },
                  child: Text(enviando
                      ? 'Confirmando…'
                      : 'Confirmar que se detuvo la producción'),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      _holdDialogAbierto = false;
    }
  }

  // El primer frame de Flutter arranca con la superficie en 0x0 (todavía no
  // llegan las métricas reales de la ventana de Android) — ni
  // didChangeDependencies ni el primer postFrameCallback tienen un tamaño
  // válido en ese instante. Sin esto, cualquier tablet se detectaba como
  // teléfono (shortestSide=0), se le forzaba portrait, y Android 12L+ la
  // dejaba "letterboxeada" (recuadrada, angosta) el resto de la sesión ya
  // que la detección solo corría una vez. didChangeMetrics() se dispara de
  // nuevo cuando llegan las métricas reales, así que se reintenta ahí hasta
  // tener una medición válida.
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _intentarConfigurar();
  }

  void _intentarConfigurar() {
    if (_orientacionConfigurada || !mounted) return;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide <= 0) return; // aún no llegan las métricas reales
    _configurarOrientacion(shortestSide);
    _orientacionConfigurada = true;
  }

  void _configurarOrientacion(double shortestSide) {
    final esTablet = shortestSide > 600;

    if (esTablet) {
      // En pantallas grandes NO se fuerza una orientación: Android 12L+
      // le mete "letterbox" (recuadra la app en una ventana angosta tipo
      // teléfono) a cualquier actividad que pida una orientación fija en
      // un dispositivo grande, sin importar resizeableActivity en el
      // manifest. Se deja libre y el layout responsive de cada pantalla
      // (ver esTablet()/shortestSide en home_screen.dart) se adapta sola
      // tanto en portrait como en landscape.
      SystemChrome.setPreferredOrientations([]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _holdPollTimer?.cancel();
    // Restaurar todas las orientaciones al salir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = context.read<AuthProvider>();
    if (state == AppLifecycleState.paused) {
      auth.touchActivity();
      // Android suspende los timers en segundo plano de cualquier forma —
      // se cancela explícito y el caso de "+1 min en background" ya lo
      // cubre el check de touchActivity/checkInactivityLock al volver.
      _inactivityTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && auth.isLoggedIn) {
      // RFM01 — +1 min en segundo plano: se bloquea localmente la app y se
      // pide confirmar identidad, sin invalidar el token en el servidor.
      auth.checkInactivityLock();
      if (!auth.isLocked) _reiniciarTimerInactividad();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Se reinicia el conteo de inactividad en primer plano al desbloquear
    // (confirmó contraseña) o al iniciar sesión — sin esto, un login
    // seguido de cero toques no arrancaría ningún timer nuevo.
    if ((_wasLocked && !auth.isLocked) || (!_wasLoggedIn && auth.isLoggedIn)) {
      _reiniciarTimerInactividad();
    }
    if (!_wasLoggedIn && auth.isLoggedIn) {
      _iniciarPollHold();
    } else if (_wasLoggedIn && !auth.isLoggedIn) {
      _detenerPollHold();
    }
    _wasLocked = auth.isLocked;
    _wasLoggedIn = auth.isLoggedIn;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (auth.isLoggedIn && !auth.isLocked) _reiniciarTimerInactividad();
      },
      child: Stack(
        children: [
          widget.child,
          if (auth.isLoggedIn && auth.isLocked) const LockScreen(),
        ],
      ),
    );
  }
}
