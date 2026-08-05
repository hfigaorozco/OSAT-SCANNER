import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lote_provider.dart';
import '../utils/constants.dart';
import '../widgets/osat_bottom_nav.dart';
import '../widgets/osat_toast.dart';
import 'home_screen.dart';
import 'scanner_screen.dart';
import 'alertas_screen.dart';
import 'login_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  void _onNavTap(BuildContext context, int index) {
    Widget destino;
    switch (index) {
      case 0:
        destino = const HomeScreen();
        break;
      case 1:
        destino = const ScannerScreen();
        break;
      case 2:
        destino = const AlertasScreen();
        break;
      default:
        return;
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => destino));
  }

  /// RFM02 — Si hay una etapa en curso sin completar, la salida normal
  /// (Cancelar) es lo recomendado; cerrar sesión de todas formas es una
  /// salida de excepción (el operador tuvo que irse) que solo se habilita
  /// poniendo el lote en Hold, para no dejarlo "abierto" sin nadie
  /// trabajándolo. Se muestra deliberadamente como la opción secundaria,
  /// no la recomendada.
  Future<void> _confirmarLogout(BuildContext context) async {
    final loteProv = context.read<LoteProvider>();
    final s = AppScale.of(context);

    if (loteProv.tieneEtapaEnCurso) {
      await _dialogEtapaEnCurso(context, s);
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cerrar sesión', style: TextStyle(fontSize: s.f(18))),
        content: Text('¿Seguro que quieres cerrar tu sesión?',
            style: TextStyle(fontSize: s.f(14))),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancelar', style: TextStyle(fontSize: s.f(14)))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Cerrar sesión',
                  style: TextStyle(color: AppColors.red, fontSize: s.f(14)))),
        ],
      ),
    );

    if (confirmado == true && context.mounted) {
      await _hacerLogout(context);
    }
  }

  Future<void> _dialogEtapaEnCurso(BuildContext context, AppScale s) async {
    bool enviando = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_rounded,
                  color: AppColors.gold, size: s.ic(22)),
              SizedBox(width: s.sp(8)),
              Expanded(
                child: Text('Tienes una etapa en curso',
                    style: TextStyle(fontSize: s.f(17))),
              ),
            ],
          ),
          content: Text(
            'Lo recomendable es completar la etapa o dejar que otro operador '
            'la continúe sin cerrar tu sesión.\n\n'
            'Si de verdad necesitas irte ahora, puedes poner el lote en Hold '
            '(indicando que fue porque cerraste sesión) y salir — pero no es '
            'lo recomendado.',
            style: TextStyle(fontSize: s.f(13.5), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: enviando ? null : () => Navigator.of(ctx).pop(),
              child: Text('Cancelar y seguir trabajando',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: s.f(13.5))),
            ),
            TextButton(
              onPressed: enviando
                  ? null
                  : () async {
                      // `enviando` recién se refleja en onPressed hasta el
                      // próximo rebuild — un doble tap real en pantalla puede
                      // disparar este mismo closure dos veces antes de que
                      // eso ocurra. Sin este guard, la segunda ejecución
                      // hace un segundo pop() sobre un diálogo que la
                      // primera ya cerró, lo que lanza una excepción y a
                      // veces se come la navegación a login de la primera.
                      if (enviando) return;
                      setDialogState(() => enviando = true);
                      final loteProv = context.read<LoteProvider>();
                      final ok = await loteProv.ponerEnHold(
                        'El operador cerró sesión con esta etapa en curso.',
                      );
                      if (!ctx.mounted) return;
                      if (!ok) {
                        setDialogState(() => enviando = false);
                        OsatToast.show(ctx,
                            message: loteProv.error ??
                                'No se pudo poner el lote en Hold.',
                            tipo: ToastTipo.error);
                        return;
                      }
                      Navigator.of(ctx).pop();
                      if (context.mounted) await _hacerLogout(context);
                    },
              child: enviando
                  ? SizedBox(
                      width: s.ic(16),
                      height: s.ic(16),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Poner en Hold y cerrar sesión',
                      style: TextStyle(color: AppColors.red, fontSize: s.f(13))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hacerLogout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final empleado = auth.empleado;
    final s = AppScale.of(context);
    final tablet = esTablet(context);

    final contenido = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: s.sp(44),
          backgroundColor: AppColors.green,
          child: Text(
            (empleado?.nombre.isNotEmpty ?? false)
                ? empleado!.nombre[0].toUpperCase()
                : '?',
            style: TextStyle(
                fontSize: s.f(32),
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: s.sp(14)),
        Text(
          empleado?.nombreCompleto ?? '—',
          style: TextStyle(
              color: Colors.white,
              fontSize: s.f(18),
              fontWeight: FontWeight.bold),
        ),
        SizedBox(height: s.sp(4)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: s.sp(12), vertical: s.sp(4)),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            empleado?.rol ?? 'Operador',
            style: TextStyle(
                color: AppColors.green,
                fontSize: s.f(12.5),
                fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(height: s.sp(24)),
        _InfoCard(
          s: s,
          children: [
            _InfoRow(
                s: s,
                icon: Icons.badge_outlined,
                label: 'Usuario empresarial',
                value: empleado?.username ?? '—'),
            const Divider(height: 1),
            _InfoRow(
                s: s,
                icon: Icons.email_outlined,
                label: 'Correo',
                value: empleado?.email ?? '—'),
            if (empleado?.lineaNombre != null) ...[
              const Divider(height: 1),
              _InfoRow(
                  s: s,
                  icon: Icons.factory_outlined,
                  label: 'Línea',
                  value: empleado!.lineaNombre!),
            ],
          ],
        ),
      ],
    );

    final botonLogout = SizedBox(
      width: double.infinity,
      height: s.h(44),
      child: OutlinedButton.icon(
        onPressed: () => _confirmarLogout(context),
        icon: Icon(Icons.logout, size: s.ic(18)),
        label: Text('Cerrar sesión', style: TextStyle(fontSize: s.f(14))),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          side: const BorderSide(color: AppColors.red),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        title: Text('Perfil',
            style: TextStyle(color: Colors.white, fontSize: s.f(20))),
        iconTheme: IconThemeData(color: Colors.white, size: s.ic(24)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s.sp(20)),
          child: tablet
              ? Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: s.sp(560)),
                    child: Column(
                      children: [
                        Expanded(child: SingleChildScrollView(child: contenido)),
                        botonLogout,
                        SizedBox(height: s.sp(8)),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(child: SingleChildScrollView(child: contenido)),
                    botonLogout,
                    SizedBox(height: s.sp(8)),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: OsatBottomNav(
        currentIndex: -1,
        onTap: (i) => _onNavTap(context, i),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final AppScale s;
  final List<Widget> children;
  const _InfoCard({required this.s, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: s.sp(16), vertical: s.sp(4)),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(s.r(12)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final AppScale s;
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.s,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.sp(12)),
      child: Row(
        children: [
          Icon(icon, size: s.ic(18), color: AppColors.textMuted),
          SizedBox(width: s.sp(12)),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: s.f(13), color: AppColors.textMuted)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: s.f(13.5),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }
}
