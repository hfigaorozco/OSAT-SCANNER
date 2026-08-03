import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import 'login_screen.dart';

/// RFM01 — La app estuvo +30 min en segundo plano. Se pide confirmar la
/// identidad del operador antes de seguir usando la app. El token de sesión
/// sigue siendo válido en el servidor: esto es solo un candado local.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.confirmIdentity(_passCtrl.text);
    if (mounted) _passCtrl.clear();
  }

  Future<void> _cerrarSesion() async {
    final auth = context.read<AuthProvider>();
    // LockScreen se dibuja como overlay fuera del Navigator normal (ver
    // main.dart), así que Navigator.of(context) no encuentra ruta a dónde
    // ir. Usamos el navigator raíz de la app en su lugar. Navegamos primero
    // y cerramos sesión después para no dejar ver, ni por un instante, la
    // pantalla de atrás ya sin usuario.
    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombre = auth.empleado?.nombre ?? 'Operador';
    final s = AppScale.of(context);
    final tablet = esTablet(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgApp,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: tablet ? s.sp(48) : 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tablet ? s.sp(520) : 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: s.sp(24)),
                      Image.asset(
                        'assets/img/logo.png',
                        width: s.sp(80),
                        height: s.sp(66),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: s.sp(18)),
                      Container(
                        width: s.sp(64),
                        height: s.sp(64),
                        decoration: const BoxDecoration(
                          color: AppColors.badgeYellowBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lock_outline,
                            color: AppColors.badgeYellowText, size: s.ic(32)),
                      ),
                      SizedBox(height: s.sp(18)),
                      Text(
                        'Sesión bloqueada por inactividad',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: s.f(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: s.sp(6)),
                      Text(
                        'Confirma tu contraseña para continuar, $nombre.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: s.f(13),
                        ),
                      ),
                      SizedBox(height: s.sp(32)),
                      TextFormField(
                        controller: _passCtrl,
                        autofocus: true,
                        obscureText: _obscure,
                        style: TextStyle(color: Colors.white, fontSize: s.f(15)),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(
                              color: AppColors.textMuted, fontSize: s.f(14)),
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppColors.textMuted, size: s.ic(22)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textMuted,
                              size: s.ic(22),
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: s.sp(12), vertical: s.sp(16)),
                          filled: true,
                          fillColor: AppColors.bgTopbar,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(s.r(10)),
                            borderSide:
                                const BorderSide(color: Color(0xFF2E3D52)),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(s.r(10)),
                            borderSide:
                                const BorderSide(color: Color(0xFF2E3D52)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(s.r(10)),
                            borderSide: const BorderSide(
                                color: AppColors.green, width: 1.5),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Ingresa tu contraseña'
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (auth.lockError != null) ...[
                        SizedBox(height: s.sp(14)),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(s.sp(10)),
                          decoration: BoxDecoration(
                            color: AppColors.badgeRedBg,
                            borderRadius: BorderRadius.circular(s.r(8)),
                          ),
                          child: Text(
                            auth.lockError!,
                            style: TextStyle(
                                color: AppColors.badgeRedText,
                                fontSize: s.f(13)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      SizedBox(height: s.sp(22)),
                      SizedBox(
                        width: double.infinity,
                        height: s.h(48),
                        child: ElevatedButton(
                          onPressed:
                              auth.confirmandoIdentidad ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(s.r(10)),
                            ),
                          ),
                          child: auth.confirmandoIdentidad
                              ? SizedBox(
                                  width: s.ic(22),
                                  height: s.ic(22),
                                  child: const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.4),
                                )
                              : Text('Continuar',
                                  style: TextStyle(
                                      fontSize: s.f(15),
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(height: s.sp(18)),
                      TextButton(
                        onPressed:
                            auth.confirmandoIdentidad ? null : _cerrarSesion,
                        child: Text(
                          '¿No eres tú? Cerrar sesión',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: s.f(13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
