import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lote_provider.dart';
import '../utils/constants.dart';
import '../widgets/lote_header_card.dart';
import '../widgets/trazabilidad_stepper.dart';
import 'completar_etapa_screen.dart';
import 'hold_screen.dart';

/// RFM04 — Trazabilidad completa de un lote: header, pasos con su barra de
/// progreso por tiempo, avance general del lote y las acciones de
/// completar etapa / poner en hold. Se llega aquí desde el buscador de
/// Inicio, el historial de recientes o al escanear un QR.
class TrazadoScreen extends StatefulWidget {
  final int loteNumero;
  const TrazadoScreen({super.key, required this.loteNumero});

  @override
  State<TrazadoScreen> createState() => _TrazadoScreenState();
}

class _TrazadoScreenState extends State<TrazadoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    await context.read<LoteProvider>().buscarLote(widget.loteNumero.toString());
  }

  @override
  Widget build(BuildContext context) {
    final loteProv = context.watch<LoteProvider>();
    final lote = loteProv.loteActual;
    final cargandoInicial = loteProv.loading && lote == null;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          children: [
            Icon(Icons.memory, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Trazado', style: TextStyle(color: Colors.white)),
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
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        LoteHeaderCard(lote: lote),
                        const SizedBox(height: 10),
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
                        const SizedBox(height: 14),
                        _ProgresoGeneralLote(pct: lote.progresoEtapaActual),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if (lote.puedeCompletarEtapa)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (_) =>
                                          const CompletarEtapaScreen(),
                                    ));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: const Text('Completar Etapa'),
                                ),
                              ),
                            if (lote.puedeCompletarEtapa &&
                                lote.puedePonerEnHold)
                              const SizedBox(width: 10),
                            if (lote.puedePonerEnHold)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (_) => const HoldScreen(),
                                    ));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: const Text('Poner en Hold'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

/// Avance general del lote (pasos aprobados / total). Usa una barra estándar
/// con el % como texto aparte para que a 0% no se vea un pedazo de texto
/// apachurrado dentro de una franja de 2% de ancho.
class _ProgresoGeneralLote extends StatelessWidget {
  final double pct;
  const _ProgresoGeneralLote({required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progreso general del lote',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textDark)),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.purple)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 14,
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
