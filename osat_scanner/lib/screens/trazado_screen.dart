import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lote.dart';
import '../models/lote_resumen.dart';
import '../models/orden_info.dart';
import '../providers/lote_provider.dart';
import '../services/lote_service.dart';
import '../utils/constants.dart';
import '../widgets/lote_header_card.dart';
import '../widgets/trazabilidad_stepper.dart';
import 'completar_etapa_screen.dart';
import 'hold_screen.dart';

/// RFM04 — Trazabilidad completa de un lote: header, pasos con su barra de
/// progreso por tiempo, avance general del lote y las acciones de
/// completar etapa / poner en hold. Se llega aquí desde el buscador de
/// Inicio, el historial de recientes, al escanear un QR, o cambiando de
/// lote hermano dentro de la misma orden.
class TrazadoScreen extends StatefulWidget {
  final int loteNumero;
  const TrazadoScreen({super.key, required this.loteNumero});

  @override
  State<TrazadoScreen> createState() => _TrazadoScreenState();
}

class _TrazadoScreenState extends State<TrazadoScreen> {
  late int _loteNumeroActual;
  List<LoteResumen> _lotesHermanos = [];
  OrdenInfo? _ordenInfo;

  @override
  void initState() {
    super.initState();
    _loteNumeroActual = widget.loteNumero;
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final ok = await context
        .read<LoteProvider>()
        .buscarLote(_loteNumeroActual.toString());
    if (!ok || !mounted) return;

    final lote = context.read<LoteProvider>().loteActual;
    final ordenNumero = lote?.ordenNumero;
    if (ordenNumero == null) return;

    // Lotes hermanos (misma orden) + estado de la orden — para el
    // selector de navegación y el badge junto al folio de la orden.
    final resultados = await Future.wait([
      LoteService.obtenerLotesDeOrden(ordenNumero),
      LoteService.obtenerOrden(ordenNumero),
    ]);
    if (!mounted) return;
    setState(() {
      _lotesHermanos = resultados[0] as List<LoteResumen>;
      _ordenInfo = resultados[1] as OrdenInfo?;
    });
  }

  Future<void> _cambiarLote(int nuevoNumero) async {
    if (nuevoNumero == _loteNumeroActual) return;
    setState(() => _loteNumeroActual = nuevoNumero);
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final loteProv = context.watch<LoteProvider>();
    final lote = loteProv.loteActual;
    final cargandoInicial = loteProv.loading && lote == null;
    final s = AppScale.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: s.ic(24)),
        title: Row(
          children: [
            Icon(Icons.memory, color: Colors.white, size: s.ic(20)),
            SizedBox(width: s.sp(8)),
            Text('Trazado',
                style: TextStyle(color: Colors.white, fontSize: s.f(20))),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _cargar,
          child: cargandoInicial
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Center(
                        child:
                            CircularProgressIndicator(color: AppColors.green)),
                  ],
                )
              : lote == null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 120),
                        Text(
                          loteProv.error ?? 'No se pudo cargar el lote.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.white, fontSize: s.f(14)),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                          s.sp(16), s.sp(12), s.sp(16), s.sp(24)),
                      children: [
                        LoteHeaderCard(
                            lote: lote, ordenEstado: _ordenInfo?.estado),
                        if (_lotesHermanos.length > 1) ...[
                          SizedBox(height: s.sp(10)),
                          _SelectorLotesHermanos(
                            s: s,
                            lotes: _lotesHermanos,
                            actual: _loteNumeroActual,
                            onSeleccionar: _cambiarLote,
                          ),
                        ],
                        SizedBox(height: s.sp(14)),
                        TrazabilidadStepper(
                          lote: lote,
                          onCompletarEtapa: lote.puedeCompletarEtapa
                              ? () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) =>
                                        const CompletarEtapaScreen(),
                                  ));
                                }
                              : null,
                        ),
                        SizedBox(height: s.sp(14)),
                        _ProgresoGeneralLote(pct: lote.progresoEtapaActual, s: s),
                        SizedBox(height: s.sp(14)),
                        _botonesAccion(context, s, lote),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _botonesAccion(BuildContext context, AppScale s, Lote lote) {
    final botonCompletar = lote.puedeCompletarEtapa
        ? ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CompletarEtapaScreen(),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: s.sp(14)),
              textStyle: TextStyle(fontSize: s.f(14)),
            ),
            child: const Text('Completar Etapa'),
          )
        : null;
    final botonHold = lote.puedePonerEnHold
        ? ElevatedButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const HoldScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: s.sp(14)),
              textStyle: TextStyle(fontSize: s.f(14)),
            ),
            child: const Text('Poner en Hold'),
          )
        : null;

    if (botonCompletar == null && botonHold == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (botonCompletar != null) Expanded(child: botonCompletar),
        if (botonCompletar != null && botonHold != null)
          SizedBox(width: s.sp(10)),
        if (botonHold != null) Expanded(child: botonHold),
      ],
    );
  }
}

/// Selector horizontal para saltar entre los lotes de la misma orden sin
/// tener que volver al buscador — ej. al revisar LOT-0008 se ve de un
/// vistazo que ORD-0007 también tiene LOT-0009 y LOT-0010.
class _SelectorLotesHermanos extends StatelessWidget {
  final AppScale s;
  final List<LoteResumen> lotes;
  final int actual;
  final ValueChanged<int> onSeleccionar;

  const _SelectorLotesHermanos({
    required this.s,
    required this.lotes,
    required this.actual,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: s.sp(10), horizontal: s.sp(12)),
      decoration: BoxDecoration(
        color: AppColors.bgTopbar,
        borderRadius: BorderRadius.circular(s.r(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Otros lotes de esta orden',
              style: TextStyle(color: AppColors.textMuted, fontSize: s.f(11.5))),
          SizedBox(height: s.sp(8)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: lotes.map((l) {
                final seleccionado = l.numero == actual;
                return Padding(
                  padding: EdgeInsets.only(right: s.sp(8)),
                  child: GestureDetector(
                    onTap: () => onSeleccionar(l.numero),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: s.sp(14), vertical: s.sp(9)),
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? AppColors.purple
                            : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: seleccionado
                            ? null
                            : Border.all(color: AppColors.borderCard),
                      ),
                      child: Text(
                        l.folio,
                        style: TextStyle(
                          fontSize: s.f(12.5),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: seleccionado
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avance general del lote (pasos aprobados / total). Usa una barra estándar
/// con el % como texto aparte para que a 0% no se vea un pedazo de texto
/// apachurrado dentro de una franja de 2% de ancho.
class _ProgresoGeneralLote extends StatelessWidget {
  final double pct;
  final AppScale s;
  const _ProgresoGeneralLote({required this.pct, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(s.sp(14)),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(s.r(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progreso general del lote',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: s.f(14),
                      color: AppColors.textDark)),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: s.f(14),
                      color: AppColors.purple)),
            ],
          ),
          SizedBox(height: s.sp(8)),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: s.sp(14),
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }
}
