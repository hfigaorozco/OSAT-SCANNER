import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../models/etapa.dart';
import '../models/orden_info.dart';
import '../utils/constants.dart';

/// Mismos colores, nombres y forma que los badges de la web (osat.css
/// .badge / .badge-*): rectangulares (radio chico, no píldora), colores
/// sólidos (no pasteles) y todos midiendo lo mismo — antes eran píldoras
/// redondeadas con paleta pastel propia del móvil, distinta a la web.
class BadgeEstadoLote extends StatelessWidget {
  final EstadoLote estado;
  const BadgeEstadoLote({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    late Color bg, text;
    late String label;
    switch (estado) {
      case EstadoLote.enProceso:
        bg = const Color(0xFFFFEB3B);
        text = AppColors.textDark;
        label = 'En proceso';
        break;
      case EstadoLote.terminado:
        bg = AppColors.green;
        text = Colors.white;
        label = 'Terminada';
        break;
      case EstadoLote.rechazado:
        bg = AppColors.red;
        text = Colors.white;
        label = 'Rechazada';
        break;
      case EstadoLote.hold:
        bg = AppColors.gold;
        text = Colors.white;
        label = '⏸ En Hold';
        break;
      case EstadoLote.pendiente:
        bg = const Color(0xFF4A5568);
        text = Colors.white;
        label = 'Pendiente';
        break;
    }
    return _Rect(bg: bg, text: text, label: label);
  }
}

class BadgeEstadoOrden extends StatelessWidget {
  final EstadoOrden estado;
  const BadgeEstadoOrden({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    late Color bg, text;
    late String label;
    switch (estado) {
      case EstadoOrden.enProceso:
        bg = const Color(0xFFFFEB3B);
        text = AppColors.textDark;
        label = 'En proceso';
        break;
      case EstadoOrden.aprobado:
        bg = AppColors.green;
        text = Colors.white;
        label = 'Cerrada';
        break;
      case EstadoOrden.hold:
        bg = AppColors.gold;
        text = Colors.white;
        label = 'En Hold';
        break;
      case EstadoOrden.rechazada:
        bg = AppColors.red;
        text = Colors.white;
        label = 'Rechazada';
        break;
      case EstadoOrden.pendiente:
        // "pendiente" internamente es en realidad el estado 'abier' del
        // backend — igual que en la web, se muestra como "Abierta" en
        // gris claro, no como una advertencia amarilla.
        bg = const Color(0xFFCBD5E0);
        text = const Color(0xFF2D3748);
        label = 'Abierta';
        break;
    }
    return _Rect(bg: bg, text: text, label: label);
  }
}

/// Rol del empleado (Administrador/Supervisor/Operador) — mismos colores
/// que el chip del topbar en la web (components/topbar.html): dorado,
/// verde y turquesa respectivamente. Se usa en Perfil y junto al nombre
/// en Inicio.
class RolBadge extends StatelessWidget {
  final String rol;
  const RolBadge({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    final r = rol.toLowerCase();
    late Color bg, text;
    late String label;
    if (r.contains('admin')) {
      bg = const Color(0xFFF5A623);
      text = AppColors.textDark;
      label = 'Administrador';
    } else if (r.contains('super')) {
      bg = AppColors.green;
      text = Colors.white;
      label = 'Supervisor';
    } else if (r.contains('opera')) {
      bg = AppColors.turquoise;
      text = Colors.white;
      label = 'Operador';
    } else {
      bg = const Color(0xFF4A5568);
      text = Colors.white;
      label = rol.isNotEmpty ? rol : '—';
    }
    return _Rect(bg: bg, text: text, label: label);
  }
}

class BadgeEstadoEtapa extends StatelessWidget {
  final EstadoEtapa estado;
  const BadgeEstadoEtapa({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    late Color bg, text;
    late String label;
    switch (estado) {
      case EstadoEtapa.aprobado:
        bg = AppColors.green;
        text = Colors.white;
        label = 'Aprobado';
        break;
      case EstadoEtapa.enCurso:
        bg = AppColors.turquoise;
        text = Colors.white;
        label = 'En curso';
        break;
      case EstadoEtapa.hold:
        bg = AppColors.gold;
        text = Colors.white;
        label = 'Hold';
        break;
      case EstadoEtapa.rechazado:
        bg = AppColors.red;
        text = Colors.white;
        label = 'Rechazado';
        break;
      case EstadoEtapa.pendiente:
        bg = const Color(0xFF4A5568);
        text = Colors.white;
        label = 'Pendiente';
        break;
    }
    return _Rect(bg: bg, text: text, label: label);
  }
}

/// Rectángulo de ancho fijo (no píldora) — todos los badges del sistema
/// miden exactamente lo mismo sin importar el largo de la etiqueta, igual
/// que .badge en osat.css (width fijo, no min-width, para que "Terminada"
/// y "Abierta" no se vean de tamaños distintos uno junto al otro).
class _Rect extends StatelessWidget {
  final Color bg;
  final Color text;
  final String label;
  const _Rect({required this.bg, required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    return Container(
      width: s.sp(88),
      padding: EdgeInsets.symmetric(vertical: s.sp(3)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(s.r(4)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: s.f(10.5),
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
