import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../models/orden_info.dart';
import '../utils/constants.dart';
import 'badge_estado.dart';

class LoteHeaderCard extends StatelessWidget {
  final Lote lote;
  /// Estado de la orden a la que pertenece — null mientras se está
  /// cargando o si no se pudo obtener; en ese caso solo se omite el badge.
  final EstadoOrden? ordenEstado;

  const LoteHeaderCard({super.key, required this.lote, this.ordenEstado});

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    // Un lote "aprobado" ya terminó todas sus etapas exitosamente — no está
    // en Hold ni fue rechazado. Igual que en la web, se anuncia con un
    // banner de éxito, no solo con el badge chico junto al folio.
    final completado = lote.estado == EstadoLote.terminado;

    return Container(
      padding: EdgeInsets.all(s.sp(16)),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(s.r(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          lote.folio,
                          style: TextStyle(
                            fontSize: s.f(17),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(width: s.sp(8)),
                        BadgeEstadoLote(estado: lote.estado),
                      ],
                    ),
                    SizedBox(height: s.sp(2)),
                    Row(
                      children: [
                        Text(
                          '${lote.ordenFolio} · ${lote.proceso}',
                          style: TextStyle(
                            fontSize: s.f(12.5),
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (ordenEstado != null) ...[
                          SizedBox(width: s.sp(6)),
                          BadgeEstadoOrden(estado: ordenEstado!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: s.sp(14)),
          if (completado) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(s.sp(10)),
              decoration: BoxDecoration(
                color: AppColors.badgeGreenBg,
                borderRadius: BorderRadius.circular(s.r(8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.badgeGreenText, size: s.ic(18)),
                  SizedBox(width: s.sp(8)),
                  Expanded(
                    child: Text(
                      'Lote completado. Todas las etapas fueron aprobadas.',
                      style: TextStyle(
                        color: AppColors.badgeGreenText,
                        fontSize: s.f(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: s.sp(14)),
          ],
          if (lote.enHold) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(s.sp(10)),
              decoration: BoxDecoration(
                color: AppColors.badgeYellowBg,
                borderRadius: BorderRadius.circular(s.r(8)),
              ),
              child: Text(
                lote.holdMotivo?.isNotEmpty == true
                    ? 'Lote en Hold: ${lote.holdMotivo}'
                    : 'Lote en Hold. El avance está bloqueado.',
                style: TextStyle(
                  color: AppColors.badgeYellowText,
                  fontSize: s.f(12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: s.sp(14)),
          ],
          if (lote.rechazado) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(s.sp(10)),
              decoration: BoxDecoration(
                color: AppColors.badgeRedBg,
                borderRadius: BorderRadius.circular(s.r(8)),
              ),
              child: Text(
                'Lote rechazado: hubo scrap de más. No puede continuar con más etapas.',
                style: TextStyle(
                  color: AppColors.badgeRedText,
                  fontSize: s.f(12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: s.sp(14)),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                  s: s, label: 'Dies iniciales', value: '${lote.diesIniciales}'),
              _StatItem(s: s, label: 'Activos', value: '${lote.diesActivos}'),
              _StatItem(
                s: s,
                label: 'Scrap',
                value: '${lote.scrap}',
                color: lote.scrap > 0 ? AppColors.red : AppColors.textDark,
              ),
              _StatItem(
                s: s,
                label: 'Yield',
                value: '${lote.yieldPct.toStringAsFixed(1)}%',
                color: lote.yieldPct >= 95
                    ? AppColors.green
                    : lote.yieldPct >= 75
                        ? AppColors.gold
                        : AppColors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final AppScale s;
  final String label;
  final String value;
  final Color? color;

  const _StatItem(
      {required this.s, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: s.f(11), color: AppColors.textMuted)),
        SizedBox(height: s.sp(2)),
        Text(
          value,
          style: TextStyle(
            fontSize: s.f(16),
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
