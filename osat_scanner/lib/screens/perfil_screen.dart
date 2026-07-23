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
    if (index == 3) return;
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

  /// RFM02 — No permite cerrar sesión si hay una etapa en curso sin completar.
  Future<void> _confirmarLogout(BuildContext context) async {
    final loteProv = context.read<LoteProvider>();
    if (loteProv.tieneEtapaEnCurso) {
      OsatToast.show(
        context,
        message:
            'No puedes cerrar sesión: tienes una etapa en curso sin completar.',
        tipo: ToastTipo.warning,
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar tu sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Cerrar sesión',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );

    if (confirmado == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final empleado = auth.empleado;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        title: const Text('Perfil', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.green,
                child: Text(
                  (empleado?.nombre.isNotEmpty ?? false)
                      ? empleado!.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                empleado?.nombreCompleto ?? '—',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  empleado?.rol ?? 'Operador',
                  style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
              _InfoCard(
                children: [
                  _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Usuario empresarial',
                      value: empleado?.username ?? '—'),
                  const Divider(height: 1),
                  _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Correo',
                      value: empleado?.email ?? '—'),
                  const Divider(height: 1),
                  _InfoRow(
                      icon: Icons.schedule_outlined,
                      label: 'Turno activo',
                      value: empleado?.turno ?? 'Hora-Hora'),
                  const Divider(height: 1),
                  _InfoRow(
                      icon: Icons.toggle_on_outlined,
                      label: 'Estado',
                      value: empleado?.estado ?? '—'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.badgeBlueBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.turquoise),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Para modificar tu información, contacta a tu administrador desde la plataforma web.',
                        style: TextStyle(
                            fontSize: 11.5, color: AppColors.badgeBlueText),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarLogout(context),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: OsatBottomNav(
        currentIndex: 3,
        onTap: (i) => _onNavTap(context, i),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }
}
