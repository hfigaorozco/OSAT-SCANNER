import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lote_provider.dart';
import '../utils/constants.dart';
import '../widgets/osat_bottom_nav.dart';
import '../widgets/lote_header_card.dart';
import '../widgets/trazabilidad_stepper.dart';
import '../widgets/osat_toast.dart';
import 'scanner_screen.dart';
import 'alertas_screen.dart';
import 'perfil_screen.dart';
import 'completar_etapa_screen.dart';
import 'hold_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final _codigoCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  void _abrirScanner() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ScannerScreen()))
        .then((_) => setState(() => _navIndex = 0));
  }

  void _onNavTap(int index) {
    if (index == 1) { _abrirScanner(); return; }
    if (index == 2) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AlertasScreen()))
          .then((_) => setState(() => _navIndex = 0));
      return;
    }
    if (index == 3) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PerfilScreen()))
          .then((_) => setState(() => _navIndex = 0));
      return;
    }
    setState(() => _navIndex = index);
  }

  Future<void> _buscarPorCodigo() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) return;
    final loteProv = context.read<LoteProvider>();
    final ok = await loteProv.buscarLote(codigo);
    if (!mounted) return;
    if (ok) {
      _codigoCtrl.clear();
    } else if (loteProv.error != null) {
      OsatToast.show(context, message: loteProv.error!, tipo: ToastTipo.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final loteProv = context.watch<LoteProvider>();
    final empleado = auth.empleado;
    final tablet   = MediaQuery.of(context).size.shortestSide > 600;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${empleado?.nombre ?? 'Operador'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Turno ${empleado?.turno ?? 'Hora-Hora'}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12.5),
                      ),
                    ],
                  ),
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 30)),
                    builder: (context, _) {
                      final now = TimeOfDay.now();
                      final h = now.hour.toString().padLeft(2, '0');
                      final m = now.minute.toString().padLeft(2, '0');
                      return Text('$h:$m',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Contenido principal — responsive ─────────────────────────
              Expanded(
                child: tablet
                    ? _layoutTablet(loteProv, empleado)
                    : _layoutTelefono(loteProv),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: OsatBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LAYOUT TABLET — 2 columnas (landscape)
  // ════════════════════════════════════════════════════════════════
  Widget _layoutTablet(LoteProvider loteProv, dynamic empleado) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda — trazabilidad
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ultimo Lote Escaneado',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Expanded(child: _trazabilidadWidget(loteProv, hint: 'Usa el botón "Escanear Lote" →')),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Columna derecha — botón grande + búsqueda
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _botonEscaneoGrande(size: 200),
              const SizedBox(height: 18),
              _panelBusqueda(),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LAYOUT TELÉFONO — stack vertical (portrait)
  // ════════════════════════════════════════════════════════════════
  Widget _layoutTelefono(LoteProvider loteProv) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón de escaneo arriba — más pequeño en teléfono
          Center(child: _botonEscaneoGrande(size: 130)),
          const SizedBox(height: 12),
          _panelBusqueda(),
          const SizedBox(height: 20),
          const Text('Ultimo Lote Escaneado',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _trazabilidadWidget(loteProv, hint: 'Usa el botón de escaneo arriba'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGETS COMPARTIDOS
  // ════════════════════════════════════════════════════════════════

  Widget _botonEscaneoGrande({required double size}) {
    return Column(
      children: [
        GestureDetector(
          onTap: _abrirScanner,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.memory,
                color: Colors.white, size: size * 0.48),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _abrirScanner,
          child: const Text('Escanear Lote',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        const Text('Apunta tu cámara al código QR',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    );
  }

  Widget _panelBusqueda() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgTopbar,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codigoCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ingresa el código del lote',
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _buscarPorCodigo(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _buscarPorCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Buscar'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('O ingresa el código manualmente',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _trazabilidadWidget(LoteProvider loteProv,
      {required String hint}) {
    if (loteProv.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.green));
    }
    if (loteProv.loteActual != null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            LoteHeaderCard(lote: loteProv.loteActual!),
            const SizedBox(height: 10),
            TrazabilidadStepper(
              lote: loteProv.loteActual!,
              onCompletarEtapa: loteProv.puedeCompletarEtapa
                  ? () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CompletarEtapaScreen(),
                      ));
                    }
                  : null,
            ),
            if (loteProv.puedePonerEnHold) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HoldScreen(),
                    ));
                  },
                  icon: const Icon(Icons.pause, size: 18),
                  label: const Text('Poner en Hold'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        'No has escaneado ningún lote todavía.\n$hint',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}
