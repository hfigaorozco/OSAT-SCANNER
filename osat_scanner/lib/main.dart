import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lote_provider.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // App pensada para tablet en horizontal (landscape)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
        home: const _AppLifecycleWrapper(child: SplashScreen()),
      ),
    );
  }
}

/// RFM01 — Si la app lleva más de 30 minutos en segundo plano,
/// se solicita autenticación de nuevo al volver a foreground.
class _AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const _AppLifecycleWrapper({required this.child});

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = context.read<AuthProvider>();
    if (state == AppLifecycleState.paused) {
      auth.touchActivity();
    } else if (state == AppLifecycleState.resumed && auth.isLoggedIn) {
      _checkInactivity();
    }
  }

  Future<void> _checkInactivity() async {
    final auth = context.read<AuthProvider>();
    // tryRestoreSession ya valida los 30 min y hace logout si expiró
    final stillValid = await auth.tryRestoreSession();
    if (!stillValid && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
