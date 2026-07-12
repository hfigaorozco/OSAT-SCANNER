import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../models/etapa.dart';
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
      case EstadoLote.aprobado:
        bg = AppColors.badgeGreenBg;
        text = AppColors.badgeGreenText;
        label = 'Aprobado';
        break;
      case EstadoLote.rechazado:
        bg = AppColors.badgeRedBg;
        text = AppColors.badgeRedText;
        label = 'Rechazado';
        break;
      case EstadoLote.hold:
        bg = AppColors.badgeYellowBg;
        text = AppColors.badgeYellowText;
        label = 'Hold';
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
        bg = AppColors.badgeYellowBg;
        text = AppColors.badgeYellowText;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
