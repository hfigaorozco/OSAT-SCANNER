import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lote_provider.dart';
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
