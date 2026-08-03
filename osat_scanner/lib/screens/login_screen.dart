import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_userCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = AppScale.of(context);
    final tablet = esTablet(context);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: tablet ? _layoutTablet(context, s, auth) : _layoutTelefono(context, s, auth),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LAYOUT TABLET — panel de marca + formulario, no solo texto más
  // grande centrado en una pantalla ancha.
  // ════════════════════════════════════════════════════════════════
  Widget _layoutTablet(BuildContext context, AppScale s, AuthProvider auth) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.bgTopbar,
            padding: EdgeInsets.all(s.sp(48)),
            // SingleChildScrollView + Center (en vez de solo alignment:
            // center en el Container) para que, si el teclado reduce el
            // alto disponible, el contenido pueda desplazarse en vez de
            // desbordarse ("BOTTOM OVERFLOWED").
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/img/logo.png',
                      width: s.sp(160),
                      height: s.sp(134),
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: s.sp(28)),
                    Text(
                      'O.S.A.T. Tracer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: s.f(34),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: s.sp(10)),
                    Text(
                      'Trazabilidad de Ensamblado de Semiconductores',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: s.f(17),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: s.sp(48)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: s.sp(520)),
                child: _buildForm(context, s, auth, mostrarBranding: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LAYOUT TELÉFONO — se mantiene igual que siempre.
  // ════════════════════════════════════════════════════════════════
  Widget _layoutTelefono(BuildContext context, AppScale s, AuthProvider auth) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _buildForm(context, s, auth, mostrarBranding: true),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AppScale s, AuthProvider auth,
      {required bool mostrarBranding}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (mostrarBranding) ...[
            SizedBox(height: s.sp(40)),
            Image.asset(
              'assets/img/logo.png',
              width: s.sp(96),
              height: s.sp(80),
              fit: BoxFit.contain,
            ),
            SizedBox(height: s.sp(20)),
            Text(
              'O.S.A.T. Tracer',
              style: TextStyle(
                color: Colors.white,
                fontSize: s.f(22),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Trazabilidad de Ensamblado de Semiconductores',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: s.f(12),
              ),
            ),
            SizedBox(height: s.sp(40)),
          ],
          TextFormField(
            controller: _userCtrl,
            style: TextStyle(color: Colors.white, fontSize: s.f(15)),
            decoration:
                _inputDecoration(s, 'Usuario empresarial', Icons.person_outline),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresa tu usuario' : null,
          ),
          SizedBox(height: s.sp(14)),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            style: TextStyle(color: Colors.white, fontSize: s.f(15)),
            decoration: _inputDecoration(
              s,
              'Contraseña',
              Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: s.ic(22),
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          if (auth.error != null) ...[
            SizedBox(height: s.sp(14)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(s.sp(10)),
              decoration: BoxDecoration(
                color: AppColors.badgeRedBg,
                borderRadius: BorderRadius.circular(s.r(8)),
              ),
              child: Text(
                auth.error!,
                style: TextStyle(
                    color: AppColors.badgeRedText, fontSize: s.f(13)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          SizedBox(height: s.sp(22)),
          SizedBox(
            width: double.infinity,
            height: s.h(48),
            child: ElevatedButton(
              onPressed: auth.loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(s.r(10)),
                ),
              ),
              child: auth.loading
                  ? SizedBox(
                      width: s.ic(22),
                      height: s.ic(22),
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : Text('Iniciar sesión',
                      style: TextStyle(
                          fontSize: s.f(15), fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(height: s.sp(24)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(AppScale s, String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textMuted, fontSize: s.f(14)),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: s.ic(22)),
      suffixIcon: suffix,
      contentPadding: EdgeInsets.symmetric(
          horizontal: s.sp(12), vertical: s.sp(16)),
      filled: true,
      fillColor: AppColors.bgTopbar,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(s.r(10)),
        borderSide: const BorderSide(color: Color(0xFF2E3D52)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(s.r(10)),
        borderSide: const BorderSide(color: Color(0xFF2E3D52)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(s.r(10)),
        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(s.r(10)),
        borderSide: const BorderSide(color: AppColors.red),
      ),
    );
  }
}
