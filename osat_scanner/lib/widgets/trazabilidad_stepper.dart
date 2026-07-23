import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../models/etapa.dart';
import '../utils/constants.dart';
import 'badge_estado.dart';

class TrazabilidadStepper extends StatefulWidget {
  final Lote lote;
  final VoidCallback? onCompletarEtapa;

  const TrazabilidadStepper({
    super.key,
    required this.lote,
    this.onCompletarEtapa,
  });

  @override
  State<TrazabilidadStepper> createState() => _TrazabilidadStepperState();
}

class _TrazabilidadStepperState extends State<TrazabilidadStepper> {
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    // Actualiza cada 10 segundos para la barra de progreso
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _calcularPorcentaje(Etapa etapa) {
    final estimado = etapa.tiempoEstimadoSeg;
    if (estimado == null || estimado <= 0) return 0;
    if (etapa.horaInicioIso == null || etapa.horaInicioIso!.isEmpty) return 0;

    try {
      final parts = etapa.horaInicioIso!.split(':');
      final now = DateTime.now();
      final inicio = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]),
          int.parse(parts.length > 2 ? parts[2] : '0'));
      final elapsed = now.difference(inicio).inSeconds;
      return (elapsed / estimado).clamp(0.0, 1.0);
    } catch (_) {
      return 0;
    }
  }

  String _formatElapsed(Etapa etapa) {
    if (etapa.horaInicioIso == null || etapa.horaInicioIso!.isEmpty) {
      return '00:00';
    }
    try {
      final parts = etapa.horaInicioIso!.split(':');
      final now = DateTime.now();
      final inicio = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]),
          int.parse(parts.length > 2 ? parts[2] : '0'));
      final elapsed = now.difference(inicio).inSeconds;
      final h = elapsed ~/ 3600;
      final m = (elapsed % 3600) ~/ 60;
      final s = elapsed % 60;
      if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } catch (_) {
      return '00:00';
    }
  }

  Color _barColor(double pct) {
    if (pct >= 1.0) return AppColors.red;
    if (pct >= 0.8) return AppColors.gold;
    return AppColors.turquoise;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: widget.lote.etapas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final etapa = widget.lote.etapas[index];
          final isCompleted = etapa.estado == EstadoEtapa.aprobado;
          final isActive    = etapa.estado == EstadoEtapa.enCurso;
          final isPending   = !isCompleted && !isActive;

          final circleColor = isCompleted
              ? AppColors.green
              : isActive ? AppColors.turquoise : const Color(0xFFE2E8F0);

          // Barra de progreso para etapa activa
          double pct = 0;
          if (isActive) pct = _calcularPorcentaje(etapa);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE0F7FA) : null,
              border: isActive
                  ? Border.all(color: const Color(0xFFB2EBF2), width: 1.4)
                  : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Opacity(
              opacity: isPending ? 0.5 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Círculo de estado
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: isCompleted
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(width: 10),
                      // Nombre y meta
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              etapa.nombre,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isPending
                                    ? const Color(0xFFA0AEC0)
                                    : AppColors.textDark,
                              ),
                            ),
                            if (etapa.metaLine.isNotEmpty)
                              Text(
                                etapa.metaLine,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                      // Badge o botón completar
                      if (isActive && widget.onCompletarEtapa != null)
                        ElevatedButton(
                          onPressed: widget.onCompletarEtapa,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7)),
                            elevation: 0,
                          ),
                          child: const Text('Completar',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        )
                      else if (isCompleted)
                        BadgeEstadoEtapa(estado: etapa.estado),
                    ],
                  ),

                  // ── Barra de progreso — solo etapa activa ──
                  if (isActive && etapa.tiempoEstimadoSeg != null && etapa.tiempoEstimadoSeg! > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progreso: ${(pct * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _barColor(pct)),
                                  ),
                                  Text(
                                    '${_formatElapsed(etapa)} / ${_formatSeg(etapa.tiempoEstimadoSeg!)}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFB2EBF2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      _barColor(pct)),
                                ),
                              ),
                              if (pct >= 1.0)
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Text(
                                    '⚠ Tiempo estimado superado',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.red,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else if (isActive) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Sin tiempo estimado configurado',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatSeg(int seg) {
    final h = seg ~/ 3600;
    final m = (seg % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m ${(seg % 60).toString().padLeft(2, '0')}s';
  }
}
