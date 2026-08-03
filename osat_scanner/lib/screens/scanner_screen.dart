import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/lote_provider.dart';
import '../utils/constants.dart';
import '../widgets/osat_bottom_nav.dart';
import '../widgets/osat_toast.dart';
import 'alertas_screen.dart';
import 'home_screen.dart';
import 'trazado_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _procesando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _procesando = true);
    final loteProv = context.read<LoteProvider>();
    final ok = await loteProv.buscarLote(raw);
    if (!mounted) return;

    if (ok) {
      final numero = loteProv.loteActual!.numero;
      OsatToast.show(context,
          message: 'Lote ${loteProv.loteActual?.folio} cargado',
          tipo: ToastTipo.success);
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TrazadoScreen(loteNumero: numero),
      ));
      if (!mounted) return;
      setState(() => _procesando = false);
    } else {
      setState(() => _procesando = false);
      OsatToast.show(context,
          message: loteProv.error ?? 'Código QR no reconocido.',
          tipo: ToastTipo.error);
    }
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
      default:
        return;
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    final tablet = esTablet(context);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        title: Text('Escanear',
            style: TextStyle(color: Colors.white, fontSize: s.f(20))),
        iconTheme: IconThemeData(color: Colors.white, size: s.ic(24)),
      ),
      body: tablet ? _layoutTablet(s) : _layoutTelefono(s),
      bottomNavigationBar: OsatBottomNav(currentIndex: 1, onTap: _onNavTap),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LAYOUT TABLET — cámara acotada al centro + panel de instrucciones al
  // lado, en vez de estirar la cámara a todo el ancho de la pantalla.
  // ════════════════════════════════════════════════════════════════
  Widget _layoutTablet(AppScale s) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.all(s.sp(20)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(s.r(20)),
              child: _camaraConMarco(s, marco: 320),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: s.sp(28)),
            // SingleChildScrollView: si el contenido no cabe en el alto
            // disponible, se desplaza en vez de desbordarse.
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.turquoise, size: s.ic(56)),
                  SizedBox(height: s.sp(20)),
                  Text(
                    'Escanea el código QR del lote',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: s.f(24),
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: s.sp(12)),
                  Text(
                    'Centra el código dentro del recuadro. La cámara lo detecta automáticamente, no hace falta tomar una foto.',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: s.f(15),
                        height: 1.5),
                  ),
                  SizedBox(height: s.sp(28)),
                  _tipItem(
                      s, Icons.wb_sunny_outlined, 'Busca buena iluminación'),
                  SizedBox(height: s.sp(14)),
                  _tipItem(
                      s, Icons.straighten, 'Mantén el código a unos 20 cm'),
                  SizedBox(height: s.sp(14)),
                  _tipItem(
                      s, Icons.crop_free, 'Evita reflejos sobre la etiqueta'),
                  if (_procesando) ...[
                    SizedBox(height: s.sp(28)),
                    Row(
                      children: [
                        SizedBox(
                          width: s.ic(20),
                          height: s.ic(20),
                          child: const CircularProgressIndicator(
                              color: AppColors.green, strokeWidth: 2.4),
                        ),
                        SizedBox(width: s.sp(12)),
                        Text('Buscando lote…',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: s.f(14))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tipItem(AppScale s, IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: s.ic(18)),
        SizedBox(width: s.sp(10)),
        Expanded(
          child: Text(texto,
              style: TextStyle(color: AppColors.textMuted, fontSize: s.f(14))),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LAYOUT TELÉFONO — cámara a pantalla completa, como siempre.
  // ════════════════════════════════════════════════════════════════
  Widget _layoutTelefono(AppScale s) {
    return _camaraConMarco(s, marco: 240);
  }

  Widget _camaraConMarco(AppScale s, {required double marco}) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),
        Center(
          child: Container(
            width: marco,
            height: marco,
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
              fontSize: s.f(15),
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha: 0.6), blurRadius: 4)
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
    );
  }
}
