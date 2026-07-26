import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lote_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_orientacionConfigurada) {
      _configurarOrientacion();
      _orientacionConfigurada = true;
    }
  }

  void _configurarOrientacion() {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final esTablet = shortestSide > 600;

    if (esTablet) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
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
    } else if (state == AppLifecycleState.resumed && auth.isLoggedIn) {
      // RFM01 — +30 min en segundo plano: se bloquea localmente la app y se
      // pide confirmar identidad, sin invalidar el token en el servidor.
      auth.checkInactivityLock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Stack(
      children: [
        widget.child,
        if (auth.isLoggedIn && auth.isLocked) const LockScreen(),
      ],
    );
  }
}

/// Helper global para saber si el dispositivo es tablet
bool esTablet(BuildContext context) {
  return MediaQuery.of(context).size.shortestSide > 600;
}
