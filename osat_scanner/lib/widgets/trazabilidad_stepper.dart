import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../models/etapa.dart';
import '../utils/constants.dart';

/// Camino de etapas estilo "mapa de lecciones" (Duolingo): nodos circulares
/// en zig-zag directamente sobre el fondo oscuro de la app, conectados por
/// una línea curva — verde y sólida donde ya se avanzó, punteada y tenue
/// donde falta — en vez de una lista sobre una tarjeta blanca. Cada estado
/// tiene su propio color vivo (no todo "pendiente" se ve igual: hold y
/// rechazado se distinguen de una etapa que simplemente no ha empezado)
/// para que la secuencia se lea de un vistazo. La barra de progreso por
/// tiempo de la etapa activa y el botón de Completar Etapa se conservan.
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

  // El backend no persiste la hora de inicio de la etapa "en_curso" (el
  // Paso_Realizado todavía no existe, igual que en la web — ver
  // lote_detalle.html). Por eso anclamos localmente la primera vez que
  // vemos cada etapa activa, para que el % avance de forma estable en
  // vez de quedarse fijo en 0.
  final Map<String, DateTime> _inicioLocal = {};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _horaInicio(Etapa etapa) {
    if (etapa.horaInicioIso != null && etapa.horaInicioIso!.isNotEmpty) {
      try {
        final parts = etapa.horaInicioIso!.split(':');
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, int.parse(parts[0]),
            int.parse(parts[1]), int.parse(parts.length > 2 ? parts[2] : '0'));
      } catch (_) {
        // sigue al fallback local
      }
    }
    final key = '${widget.lote.numero}_${etapa.codigoPaso}';
    return _inicioLocal.putIfAbsent(key, () => DateTime.now());
  }

  double _calcularPorcentaje(Etapa etapa) {
    final estimado = etapa.tiempoEstimadoSeg;
    if (estimado == null || estimado <= 0) return 0;
    final inicio = _horaInicio(etapa);
    if (inicio == null) return 0;
    final elapsed = DateTime.now().difference(inicio).inSeconds;
    return (elapsed / estimado).clamp(0.0, 1.0);
  }

  String _formatElapsed(Etapa etapa) {
    final inicio = _horaInicio(etapa);
    if (inicio == null) return '00:00';
    final elapsed = DateTime.now().difference(inicio).inSeconds;
    final h = elapsed ~/ 3600;
    final m = (elapsed % 3600) ~/ 60;
    final sec = elapsed % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _formatSeg(int seg) {
    final h = seg ~/ 3600;
    final m = (seg % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m ${(seg % 60).toString().padLeft(2, '0')}s';
  }

  Color _barColor(double pct) {
    if (pct >= 1.0) return AppColors.red;
    if (pct >= 0.8) return AppColors.gold;
    return AppColors.turquoise;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    final etapas = widget.lote.etapas;
    // Todos los círculos van derechos, alineados a la izquierda — un
    // gutter de ancho fijo con el círculo centrado adentro (el círculo
    // activo es más grande que el resto, así que se centra para que su
    // eje quede en la misma línea vertical que los demás, sin ningún
    // desfase lateral entre etapas).
    final gutterWidth = s.sp(64);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(etapas.length, (index) {
        final etapa = etapas[index];
        final isActive = etapa.estado == EstadoEtapa.enCurso;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) SizedBox(height: s.sp(18)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: gutterWidth,
                  child: Padding(
                    padding: EdgeInsets.only(top: s.sp(2)),
                    child: Center(
                      child: _NodeCircle(
                        estado: etapa.estado,
                        numero: index + 1,
                        size: _nodeSize(etapa.estado, s),
                        s: s,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: s.sp(6),
                        bottom: index == etapas.length - 1 ? 0 : s.sp(6)),
                    child: _StepInfo(
                      s: s,
                      etapa: etapa,
                      isActive: isActive,
                      onCompletar: (isActive && !widget.lote.enHold)
                          ? widget.onCompletarEtapa
                          : null,
                      pct: isActive ? _calcularPorcentaje(etapa) : 0,
                      elapsedLabel: isActive ? _formatElapsed(etapa) : '',
                      estimadoLabel:
                          (isActive && etapa.tiempoEstimadoSeg != null)
                              ? _formatSeg(etapa.tiempoEstimadoSeg!)
                              : '',
                      barColor: isActive
                          ? _barColor(_calcularPorcentaje(etapa))
                          : AppColors.turquoise,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

double _nodeSize(EstadoEtapa estado, AppScale s) =>
    estado == EstadoEtapa.enCurso ? s.sp(58) : s.sp(46);

Color _nodeColor(EstadoEtapa estado) {
  switch (estado) {
    case EstadoEtapa.aprobado:
      return AppColors.green;
    case EstadoEtapa.enCurso:
      return AppColors.turquoise;
    case EstadoEtapa.hold:
      return AppColors.gold;
    case EstadoEtapa.rechazado:
      return AppColors.red;
    case EstadoEtapa.pendiente:
      return const Color(0xFF3D4A60);
  }
}

String _estadoLabel(EstadoEtapa estado) {
  switch (estado) {
    case EstadoEtapa.aprobado:
      return 'APROBADO';
    case EstadoEtapa.enCurso:
      return 'EN CURSO';
    case EstadoEtapa.hold:
      return 'EN HOLD';
    case EstadoEtapa.rechazado:
      return 'RECHAZADO';
    case EstadoEtapa.pendiente:
      return 'PENDIENTE';
  }
}

class _NodeCircle extends StatelessWidget {
  final EstadoEtapa estado;
  final int numero;
  final double size;
  final AppScale s;

  const _NodeCircle({
    required this.estado,
    required this.numero,
    required this.size,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final color = _nodeColor(estado);
    final isActive = estado == EstadoEtapa.enCurso;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isActive ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isActive ? 0.55 : 0.28),
            blurRadius: isActive ? 16 : 7,
            spreadRadius: isActive ? 1 : 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: _nodeContent(estado, numero, s),
    );
  }

  Widget _nodeContent(EstadoEtapa estado, int numero, AppScale s) {
    switch (estado) {
      case EstadoEtapa.aprobado:
        return Icon(Icons.check_rounded, color: Colors.white, size: s.ic(24));
      case EstadoEtapa.rechazado:
        return Icon(Icons.close_rounded, color: Colors.white, size: s.ic(22));
      case EstadoEtapa.hold:
        return Icon(Icons.pause_rounded, color: Colors.white, size: s.ic(22));
      case EstadoEtapa.enCurso:
        return Text('$numero',
            style: TextStyle(
                color: Colors.white,
                fontSize: s.f(20),
                fontWeight: FontWeight.w800));
      case EstadoEtapa.pendiente:
        return Text('$numero',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: s.f(15),
                fontWeight: FontWeight.w600));
    }
  }
}

class _StepInfo extends StatelessWidget {
  final AppScale s;
  final Etapa etapa;
  final bool isActive;
  final VoidCallback? onCompletar;
  final double pct;
  final String elapsedLabel;
  final String estimadoLabel;
  final Color barColor;

  const _StepInfo({
    required this.s,
    required this.etapa,
    required this.isActive,
    required this.onCompletar,
    required this.pct,
    required this.elapsedLabel,
    required this.estimadoLabel,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final dim = etapa.estado == EstadoEtapa.pendiente;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etapa.nombre,
          style: TextStyle(
            fontSize: s.f(15.5),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: dim ? Colors.white.withValues(alpha: 0.4) : Colors.white,
          ),
        ),
        SizedBox(height: s.sp(2)),
        Text(
          _estadoLabel(etapa.estado),
          style: TextStyle(
            fontSize: s.f(11),
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
            color: dim
                ? Colors.white.withValues(alpha: 0.35)
                : _nodeColor(etapa.estado),
          ),
        ),
        if (etapa.metaLine.isNotEmpty) ...[
          SizedBox(height: s.sp(3)),
          Text(
            etapa.metaLine,
            style: TextStyle(fontSize: s.f(11.5), color: AppColors.textMuted),
          ),
        ],
        if (isActive) ...[
          SizedBox(height: s.sp(10)),
          if (etapa.tiempoEstimadoSeg != null &&
              etapa.tiempoEstimadoSeg! > 0) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Progreso: ${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: s.f(10.5),
                      fontWeight: FontWeight.w600,
                      color: barColor),
                ),
                SizedBox(width: s.sp(8)),
                Text(
                  '$elapsedLabel / $estimadoLabel',
                  style:
                      TextStyle(fontSize: s.f(10.5), color: AppColors.textMuted),
                ),
              ],
            ),
            SizedBox(height: s.sp(5)),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: s.sp(6),
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            if (pct >= 1.0)
              Padding(
                padding: EdgeInsets.only(top: s.sp(4)),
                child: Text(
                  '⚠ Tiempo estimado superado',
                  style: TextStyle(
                      fontSize: s.f(10.5),
                      color: AppColors.red,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ] else
            Text(
              'Sin tiempo estimado configurado',
              style: TextStyle(
                  fontSize: s.f(10.5),
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic),
            ),
          if (onCompletar != null) ...[
            SizedBox(height: s.sp(10)),
            SizedBox(
              height: s.h(38),
              child: ElevatedButton(
                onPressed: onCompletar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: s.sp(16)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(s.r(8))),
                  elevation: 0,
                ),
                child: Text('Completar etapa',
                    style: TextStyle(
                        fontSize: s.f(12.5), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
