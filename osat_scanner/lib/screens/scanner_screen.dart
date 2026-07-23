import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lote_provider.dart';
import '../utils/constants.dart';
import '../widgets/osat_bottom_nav.dart';
import '../widgets/lote_header_card.dart';
import '../widgets/trazabilidad_stepper.dart';
import '../widgets/osat_toast.dart';
import 'completar_etapa_screen.dart';
import 'hold_screen.dart';
import 'alertas_screen.dart';
import 'perfil_screen.dart';
import 'home_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _yaEscaneado = false;
  bool _procesando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_yaEscaneado || _procesando) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _procesando = true);
    final loteProv = context.read<LoteProvider>();
    final ok = await loteProv.buscarLote(raw);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _yaEscaneado = true;
        _procesando = false;
      });
      OsatToast.show(context,
          message: 'Lote ${loteProv.loteActual?.folio} cargado',
          tipo: ToastTipo.success);
    } else {
      setState(() => _procesando = false);
      OsatToast.show(context,
          message: loteProv.error ?? 'Código QR no reconocido.',
          tipo: ToastTipo.error);
    }
  }

  void _escanearOtro() {
    setState(() => _yaEscaneado = false);
    context.read<LoteProvider>().limpiarError();
  }

  void _onNavTap(int index) {
    if (index == 1) return; // ya estamos aquí
    Widget destino;
    switch (index) {
      case 0:
        destino = const HomeScreen();
        break;
      case 2:
        destino = const AlertasScreen();
        break;
      case 3:
        destino = const PerfilScreen();
        break;
      default:
        return;
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    final loteProv = context.watch<LoteProvider>();
    final auth = context.watch<AuthProvider>();

    if (_yaEscaneado && loteProv.loteActual != null) {
      return _buildLoteEscaneado(context, loteProv, auth);
    }
    return _buildScannerView(context);
  }

  Widget _buildScannerView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        title: const Text('Escanear', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Apunta al código QR del lote',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      shadows: [
                        Shadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 4)
                      ],
                    ),
                  ),
                ),
                if (_procesando)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: OsatBottomNav(currentIndex: 1, onTap: _onNavTap),
    );
  }

  Widget _buildLoteEscaneado(
      BuildContext context, LoteProvider loteProv, AuthProvider auth) {
    final lote = loteProv.loteActual!;
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hola, ${auth.empleado?.nombre ?? 'Operador'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _escanearOtro,
                    icon: const Icon(Icons.qr_code_scanner,
                        size: 18, color: AppColors.green),
                    label: const Text('Escanear otro',
                        style: TextStyle(color: AppColors.green)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
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
                      _ProgresoEtapa(lote: lote),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (lote.puedeCompletarEtapa)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
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
                          if (lote.puedeCompletarEtapa && lote.puedePonerEnHold)
                            const SizedBox(width: 10),
                          if (lote.puedePonerEnHold)
                            Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const HoldScreen(),
                                ));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Poner en Hold'),
                            ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: OsatBottomNav(currentIndex: 1, onTap: _onNavTap),
    );
  }
}

class _ProgresoEtapa extends StatelessWidget {
  final dynamic lote;
  const _ProgresoEtapa({required this.lote});

  @override
  Widget build(BuildContext context) {
    final pct = (lote.progresoEtapaActual as double);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progreso de Etapa',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct.clamp(0.02, 1.0),
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
