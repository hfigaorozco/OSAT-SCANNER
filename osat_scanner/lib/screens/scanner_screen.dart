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
                            color: Colors.black.withValues(alpha: 0.6),
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
}
