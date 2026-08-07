import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../models/etapa.dart';
import '../models/orden_info.dart';
import '../utils/constants.dart';

class BadgeEstadoLote extends StatelessWidget {
  final EstadoLote estado;
  const BadgeEstadoLote({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    late Color bg, text;
    late String label;
    switch (estado) {
      case EstadoLote.enProceso:
        bg = AppColors.badgeYellowBg;
        text = AppColors.badgeYellowText;
        label = 'En proceso';
        break;
      case EstadoLote.terminado:
        bg = AppColors.badgeGreenBg;
        text = AppColors.badgeGreenText;
        label = 'Terminado';
        break;
      case EstadoLote.rechazado:
        bg = AppColors.badgeRedBg;
        text = AppColors.badgeRedText;
        label = 'Rechazado';
        break;
      case EstadoLote.hold:
        bg = AppColors.badgeOrangeBg;
        text = AppColors.badgeOrangeText;
        label = 'En Hold';
        break;
      case EstadoLote.pendiente:
        bg = AppColors.badgeGrayBg;
        text = AppColors.badgeGrayText;
        label = 'Pendiente';
        break;
    }
    return _Pill(bg: bg, text: text, label: label);
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
        bg = AppColors.badgeYellowBg;
        text = AppColors.badgeYellowText;
        label = 'En proceso';
        break;
      case EstadoOrden.aprobado:
        bg = AppColors.badgeGreenBg;
        text = AppColors.badgeGreenText;
        label = 'Aprobado';
        break;
      case EstadoOrden.hold:
        bg = AppColors.badgeOrangeBg;
        text = AppColors.badgeOrangeText;
        label = 'En Hold';
        break;
      case EstadoOrden.rechazada:
        bg = AppColors.badgeRedBg;
        text = AppColors.badgeRedText;
        label = 'Rechazada';
        break;
      case EstadoOrden.pendiente:
        bg = AppColors.badgeGrayBg;
        text = AppColors.badgeGrayText;
        label = 'Pendiente';
        break;
    }
    return _Pill(bg: bg, text: text, label: label);
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
        bg = AppColors.badgeGreenBg;
        text = AppColors.badgeGreenText;
        label = 'Aprobado';
        break;
      case EstadoEtapa.enCurso:
        bg = AppColors.badgeBlueBg;
        text = AppColors.badgeBlueText;
        label = 'En curso';
        break;
      case EstadoEtapa.hold:
        bg = AppColors.badgeOrangeBg;
        text = AppColors.badgeOrangeText;
        label = 'Hold';
        break;
      case EstadoEtapa.rechazado:
        bg = AppColors.badgeRedBg;
        text = AppColors.badgeRedText;
        label = 'Rechazado';
        break;
      case EstadoEtapa.pendiente:
        bg = AppColors.badgeGrayBg;
        text = AppColors.badgeGrayText;
        label = 'Pendiente';
        break;
    }
    return _Pill(bg: bg, text: text, label: label);
  }
}

class _Pill extends StatelessWidget {
  final Color bg;
  final Color text;
  final String label;
  const _Pill({required this.bg, required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sp(10), vertical: s.sp(2)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: s.f(11),
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
