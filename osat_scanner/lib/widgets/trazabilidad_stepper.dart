import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../models/etapa.dart';
import '../utils/constants.dart';
import 'badge_estado.dart';

class TrazabilidadStepper extends StatelessWidget {
  final Lote lote;
  final VoidCallback? onCompletarEtapa;
  final VoidCallback? onIniciarSiguiente;

  const TrazabilidadStepper({
    super.key,
    required this.lote,
    this.onCompletarEtapa,
    this.onIniciarSiguiente,
  });

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
        itemCount: lote.etapas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final etapa = lote.etapas[index];
          return _EtapaRow(
            etapa: etapa,
            index: index,
            onCompletarEtapa:
                etapa.estado == EstadoEtapa.enCurso ? onCompletarEtapa : null,
          );
        },
      ),
    );
  }
}

class _EtapaRow extends StatelessWidget {
  final Etapa etapa;
  final int index;
  final VoidCallback? onCompletarEtapa;

  const _EtapaRow({
    required this.etapa,
    required this.index,
    this.onCompletarEtapa,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = etapa.estado == EstadoEtapa.aprobado;
    final isActive = etapa.estado == EstadoEtapa.enCurso;
    final isPending = !isCompleted && !isActive;

    final circleColor = isCompleted
        ? AppColors.green
        : isActive
            ? AppColors.turquoise
            : const Color(0xFFE2E8F0);

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
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          etapa.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isPending
                                ? const Color(0xFFA0AEC0)
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (etapa.metaLine.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        etapa.metaLine,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (onCompletarEtapa != null)
              ElevatedButton(
                onPressed: onCompletarEtapa,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Completar etapa',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              )
            else if (isCompleted)
              BadgeEstadoEtapa(estado: etapa.estado),
          ],
        ),
      ),
    );
  }
}
