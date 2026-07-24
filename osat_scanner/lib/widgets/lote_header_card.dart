import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../utils/constants.dart';
import 'badge_estado.dart';

class LoteHeaderCard extends StatelessWidget {
  final Lote lote;

  const LoteHeaderCard({super.key, required this.lote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
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
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        BadgeEstadoLote(estado: lote.estado),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lote.ordenFolio} · ${lote.proceso}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (lote.enHold) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.badgeYellowBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                lote.holdMotivo?.isNotEmpty == true
                    ? 'Lote en Hold: ${lote.holdMotivo}'
                    : 'Lote en Hold. El avance está bloqueado.',
                style: const TextStyle(
                  color: AppColors.badgeYellowText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (lote.rechazado) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.badgeRedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Lote rechazado: hubo scrap de más. No puede continuar con más etapas.',
                style: TextStyle(
                  color: AppColors.badgeRedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'Dies iniciales', value: '${lote.diesIniciales}'),
              _StatItem(label: 'Activos', value: '${lote.diesActivos}'),
              _StatItem(
                label: 'Scrap',
                value: '${lote.scrap}',
                color: lote.scrap > 0 ? AppColors.red : AppColors.textDark,
              ),
              _StatItem(
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
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
