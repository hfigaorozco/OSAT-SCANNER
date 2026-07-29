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

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgApp,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Image.asset(
                      'assets/img/logo.png',
                      width: 80,
                      height: 66,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.badgeYellowBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline,
                          color: AppColors.badgeYellowText, size: 32),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Sesión bloqueada por inactividad',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Confirma tu contraseña para continuar, $nombre.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _passCtrl,
                      autofocus: true,
                      obscureText: _obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        filled: true,
                        fillColor: AppColors.bgTopbar,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2E3D52)),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2E3D52)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.green, width: 1.5),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Ingresa tu contraseña'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (auth.lockError != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.badgeRedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          auth.lockError!,
                          style: const TextStyle(
                              color: AppColors.badgeRedText, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: auth.confirmandoIdentidad ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: auth.confirmandoIdentidad
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.4),
                              )
                            : const Text('Continuar',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: auth.confirmandoIdentidad ? null : _cerrarSesion,
                      child: const Text(
                        '¿No eres tú? Cerrar sesión',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
