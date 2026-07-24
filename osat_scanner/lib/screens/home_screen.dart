import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/lote_resumen.dart';
import '../services/lote_service.dart';
import '../services/recientes_service.dart';
import '../utils/constants.dart';
import '../widgets/osat_bottom_nav.dart';
import '../widgets/badge_estado.dart';
import 'scanner_screen.dart';
import 'alertas_screen.dart';
import 'perfil_screen.dart';
import 'trazado_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final _codigoCtrl = TextEditingController();
  Timer? _debounce;

  List<LoteResumen> _recientes = [];
  List<LoteResumen>? _resultados; // null = no se ha buscado nada todavía
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _cargarRecientes();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargarRecientes() async {
    final lista = await RecientesService.obtener();
    if (!mounted) return;
    setState(() => _recientes = lista);
  }

  void _abrirScanner() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ScannerScreen()))
        .then((_) {
      setState(() => _navIndex = 0);
      _cargarRecientes();
    });
  }

  void _onNavTap(int index) {
    if (index == 1) { _abrirScanner(); return; }
    if (index == 2) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AlertasScreen()))
          .then((_) => setState(() => _navIndex = 0));
      return;
    }
    setState(() => _navIndex = index);
  }

  void _abrirPerfil() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PerfilScreen()))
        .then((_) => setState(() => _navIndex = 0));
  }

  void _onCambioTexto(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _resultados = null);
      return;
    }
    _debounce = Timer(
        const Duration(milliseconds: 350), () => _ejecutarBusqueda(value));
  }

  /// RFM04 — Búsqueda real por coincidencias contra la BD (no exige el
  /// código exacto).
  Future<void> _ejecutarBusqueda(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _resultados = null);
      return;
    }
    setState(() => _buscando = true);
    try {
      final resultados = await LoteService.buscarCoincidencias(query);
      if (!mounted) return;
      setState(() {
        _resultados = resultados;
        _buscando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resultados = [];
        _buscando = false;
      });
    }
  }

  Future<void> _abrirLote(int numero) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TrazadoScreen(loteNumero: numero),
    ));
    if (!mounted) return;
    _cargarRecientes();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final empleado = auth.empleado;
    final tablet = MediaQuery.of(context).size.shortestSide > 600;

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
                  InkWell(
                    onTap: _abrirPerfil,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Hola, ${empleado?.nombre ?? 'Operador'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                child: tablet ? _layoutTablet() : _layoutTelefono(),
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
  Widget _layoutTablet() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(child: _seccionLotes()),
        ),
        const SizedBox(width: 20),
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
  Widget _layoutTelefono() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _botonEscaneoGrande(size: 130)),
          const SizedBox(height: 12),
          _panelBusqueda(),
          const SizedBox(height: 20),
          _seccionLotes(),
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
                  style: const TextStyle(
                      color: AppColors.textDark, fontSize: 13),
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
                  onChanged: _onCambioTexto,
                  onSubmitted: _ejecutarBusqueda,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _ejecutarBusqueda(_codigoCtrl.text),
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

  /// Muestra los resultados de búsqueda mientras se está buscando algo,
  /// o el historial de últimos lotes escaneados cuando el buscador está vacío.
  Widget _seccionLotes() {
    final buscando = _codigoCtrl.text.trim().isNotEmpty || _resultados != null;

    if (buscando) {
      if (_buscando) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
              child: CircularProgressIndicator(color: AppColors.green)),
        );
      }
      final resultados = _resultados ?? [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resultados de búsqueda',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (resultados.isEmpty)
            _mensajeVacio('No se encontraron lotes con ese código.')
          else
            ...resultados.map(_tarjetaLote),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Últimos lotes escaneados',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (_recientes.isEmpty)
          _mensajeVacio(
              'No has escaneado ningún lote todavía.\nUsa el botón de escaneo o el buscador de arriba.')
        else
          ..._recientes.map(_tarjetaLote),
      ],
    );
  }

  Widget _mensajeVacio(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }

  Widget _tarjetaLote(LoteResumen l) {
    return InkWell(
      onTap: () => _abrirLote(l.numero),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.folio,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: AppColors.textDark),
              ),
            ),
            BadgeEstadoLote(estado: l.estado),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
