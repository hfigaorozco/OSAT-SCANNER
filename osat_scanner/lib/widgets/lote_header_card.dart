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

    // Sin tarjeta blanca: folio, badges y stats van directo sobre el fondo
    // oscuro — solo los banners de estado (completado/hold/rechazado)
    // conservan un bloque de color, pero tenue y con acento lateral en vez
    // de un rectángulo pastel casi blanco, para no repetir el mismo
    // problema de "modal claro flotando" con otro color.
    return Column(
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
                          fontSize: s.f(19),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: s.sp(8)),
                      BadgeEstadoLote(estado: lote.estado),
                    ],
                  ),
                  SizedBox(height: s.sp(3)),
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
        if (completado) ...[
          SizedBox(height: s.sp(14)),
          _EstadoBanner(
            s: s,
            color: AppColors.green,
            icon: Icons.check_circle,
            texto: 'Lote completado. Todas las etapas fueron aprobadas.',
          ),
        ],
        if (lote.enHold) ...[
          SizedBox(height: s.sp(14)),
          _EstadoBanner(
            s: s,
            color: AppColors.gold,
            icon: Icons.pause_circle,
            texto: lote.holdMotivo?.isNotEmpty == true
                ? 'Lote en Hold: ${lote.holdMotivo}'
                : 'Lote en Hold. El avance está bloqueado.',
          ),
        ],
        if (lote.rechazado) ...[
          SizedBox(height: s.sp(14)),
          _EstadoBanner(
            s: s,
            color: AppColors.red,
            icon: Icons.cancel,
            texto:
                'Lote rechazado: hubo scrap de más. No puede continuar con más etapas.',
          ),
        ],
        // Estos dos bloquean el AVANCE aunque el lote individual siga
        // 'proce' — la orden completa entró en Hold/Rechazada por scrap de
        // otro lote hermano o decisión del supervisor (ver Lote.ordenEnHold).
        if (!lote.enHold && !lote.rechazado && lote.ordenEnHold) ...[
          SizedBox(height: s.sp(14)),
          _EstadoBanner(
            s: s,
            color: AppColors.gold,
            icon: Icons.pause_circle,
            texto:
                'La orden de este lote está en Hold por exceso de scrap. Libérala antes de continuar.',
          ),
        ],
        if (!lote.enHold && !lote.rechazado && lote.ordenRechazada) ...[
          SizedBox(height: s.sp(14)),
          _EstadoBanner(
            s: s,
            color: AppColors.red,
            icon: Icons.cancel,
            texto:
                'La orden de este lote fue rechazada. No se pueden completar más etapas.',
          ),
        ],
        SizedBox(height: s.sp(16)),
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
              color: lote.scrap > 0 ? AppColors.red : Colors.white,
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
    );
  }
}

/// Banner de estado (completado/hold/rechazado): tenue tinte del color de
/// estado sobre el fondo oscuro, sin borde de acento (mismo criterio "sin
/// borde a la izquierda" que las cards de Alertas), en vez del bloque
/// pastel casi blanco que se usaba antes.
class _EstadoBanner extends StatelessWidget {
  final AppScale s;
  final Color color;
  final IconData icon;
  final String texto;

  const _EstadoBanner({
    required this.s,
    required this.color,
    required this.icon,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: s.sp(12), vertical: s.sp(10)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(s.r(8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: s.ic(18)),
          SizedBox(width: s.sp(8)),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: Colors.white,
                fontSize: s.f(12),
                fontWeight: FontWeight.w600,
              ),
            ),
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
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
