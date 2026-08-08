import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/lote_resumen.dart';
import '../models/orden_info.dart';
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

  List<OrdenInfo> _ordenesLinea = [];
  bool _cargandoOrdenesLinea = false;

  @override
  void initState() {
    super.initState();
    _cargarRecientes();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarOrdenesLinea());
  }

  Future<void> _cargarOrdenesLinea() async {
    final lineaCodigo = context.read<AuthProvider>().empleado?.lineaCodigo;
    if (lineaCodigo == null) return;
    setState(() => _cargandoOrdenesLinea = true);
    try {
      final ordenes = await LoteService.obtenerOrdenesPorLinea(lineaCodigo);
      if (!mounted) return;
      setState(() {
        _ordenesLinea = ordenes;
        _cargandoOrdenesLinea = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoOrdenesLinea = false);
    }
  }

  /// Abre el primer lote de la orden — de ahí el operador puede saltar
  /// entre todos los lotes hermanos de esa misma orden (selector que ya
  /// existe dentro de Trazado).
  Future<void> _abrirOrden(int ordenNumero) async {
    final lotes = await LoteService.obtenerLotesDeOrden(ordenNumero);
    if (!mounted || lotes.isEmpty) return;
    await _abrirLote(lotes.first.numero);
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
    if (index == 1) {
      _abrirScanner();
      return;
    }
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
    _cargarOrdenesLinea();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final empleado = auth.empleado;
    final s = AppScale.of(context);
    final tablet = esTablet(context);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(s.sp(16), s.sp(16), s.sp(16), 0),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Hola, ${empleado?.nombre ?? 'Operador'}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: s.f(19),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: s.sp(8)),
                              RolBadge(rol: empleado?.rol ?? 'Operador'),
                            ],
                          ),
                          if (empleado?.lineaNombre != null)
                            Text(
                              empleado!.lineaNombre!,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: s.f(12.5),
                              ),
                            ),
                        ],
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
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: s.f(20),
                              fontWeight: FontWeight.bold));
                    },
                  ),
                ],
              ),
              SizedBox(height: s.sp(16)),

              // ── Contenido principal — responsive ─────────────────────────
              Expanded(
                child: tablet ? _layoutTablet(s) : _layoutTelefono(s),
              ),
              SizedBox(height: s.sp(12)),
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
  // LAYOUT TABLET — 2 columnas (landscape), todo más grande
  // ════════════════════════════════════════════════════════════════
  Widget _layoutTablet(AppScale s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(child: _seccionLotes(s)),
        ),
        SizedBox(width: s.sp(24)),
        Expanded(
          flex: 2,
          // SingleChildScrollView en vez de solo Column+center: en pantallas
          // más bajas (o con el header ocupando más espacio) el botón grande
          // + el panel de búsqueda pueden no caber y se desbordaban
          // ("BOTTOM OVERFLOWED") en vez de simplemente permitir scroll.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _botonEscaneoGrande(s, size: s.sp(200)),
                SizedBox(height: s.sp(22)),
                _panelBusqueda(s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LAYOUT TELÉFONO — stack vertical (portrait)
  // ════════════════════════════════════════════════════════════════
  Widget _layoutTelefono(AppScale s) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _botonEscaneoGrande(s, size: 130)),
          const SizedBox(height: 12),
          _panelBusqueda(s),
          const SizedBox(height: 20),
          _seccionLotes(s),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGETS COMPARTIDOS
  // ════════════════════════════════════════════════════════════════

  Widget _botonEscaneoGrande(AppScale s, {required double size}) {
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
            child: Icon(Icons.qr_code_scanner_rounded,
                color: Colors.white, size: size * 0.48),
          ),
        ),
        SizedBox(height: s.sp(14)),
        GestureDetector(
          onTap: _abrirScanner,
          child: Text('Escanear Lote',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: s.f(20),
                  fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: s.sp(4)),
        Text('Apunta tu cámara al código QR',
            style: TextStyle(color: AppColors.textMuted, fontSize: s.f(13))),
      ],
    );
  }

  Widget _panelBusqueda(AppScale s) {
    final alturaCampo = s.h(44);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.sp(12)),
      decoration: BoxDecoration(
        color: AppColors.bgTopbar,
        borderRadius: BorderRadius.circular(s.r(10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              // El fondo blanco y la altura ahora los pone ESTE Container,
              // no el TextField/InputDecorator — con isDense/isCollapsed
              // seguía quedando más bajo que el botón "Buscar" porque el
              // InputDecorator no siempre estira su fillColor a ocupar
              // toda la altura del SizedBox padre (medido: 56px de alto
              // real contra 115px del botón, con la MISMA alturaCampo).
              // Así, el alto de la caja blanca depende solo de este
              // Container, sin ninguna lógica interna de Flutter de por
              // medio que lo pueda achicar.
              height: alturaCampo,
              padding: EdgeInsets.symmetric(horizontal: s.sp(10)),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(s.r(8)),
              ),
              child: TextField(
                controller: _codigoCtrl,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                textAlignVertical: TextAlignVertical.center,
                style:
                    TextStyle(color: AppColors.textDark, fontSize: s.f(13)),
                decoration: InputDecoration(
                  hintText: 'Código del lote o de la orden',
                  hintStyle: TextStyle(
                      color: AppColors.textMuted, fontSize: s.f(13)),
                  isDense: true,
                  isCollapsed: true,
                  border: InputBorder.none,
                ),
                onChanged: _onCambioTexto,
                onSubmitted: _ejecutarBusqueda,
              ),
            ),
          ),
          SizedBox(width: s.sp(8)),
          // Container + InkWell en vez de ElevatedButton: medido en
          // pantalla, el ElevatedButton (aun con tapTargetSize.shrinkWrap +
          // minimumSize.zero) seguía sin respetar la altura del SizedBox —
          // el campo de texto medía 56px reales contra 115px del botón,
          // con la misma alturaCampo. Un Container con altura explícita no
          // tiene ninguna lógica interna de Material que lo pueda inflar.
          Material(
            color: AppColors.purple,
            borderRadius: BorderRadius.circular(s.r(8)),
            child: InkWell(
              onTap: () => _ejecutarBusqueda(_codigoCtrl.text),
              borderRadius: BorderRadius.circular(s.r(8)),
              child: Container(
                height: alturaCampo,
                padding: EdgeInsets.symmetric(horizontal: s.sp(18)),
                alignment: Alignment.center,
                child: Text('Buscar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: s.f(14),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra los resultados de búsqueda mientras se está buscando algo,
  /// o el historial de últimos lotes escaneados cuando el buscador está vacío.
  Widget _seccionLotes(AppScale s) {
    final buscando = _codigoCtrl.text.trim().isNotEmpty || _resultados != null;

    if (buscando) {
      if (_buscando) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child:
              Center(child: CircularProgressIndicator(color: AppColors.green)),
        );
      }
      final resultados = _resultados ?? [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resultados de búsqueda',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: s.f(15),
                  fontWeight: FontWeight.w600)),
          SizedBox(height: s.sp(10)),
          if (resultados.isEmpty)
            _mensajeVacio(s, 'No se encontraron lotes con ese código.')
          else
            ...List.generate(
              resultados.length,
              (i) => _tarjetaLote(s, resultados[i],
                  ultima: i == resultados.length - 1),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_cargandoOrdenesLinea || _ordenesLinea.isNotEmpty) ...[
          _seccionOrdenesLinea(s),
          SizedBox(height: s.sp(20)),
        ],
        Text('Últimos lotes escaneados',
            style: TextStyle(
                color: Colors.white,
                fontSize: s.f(15),
                fontWeight: FontWeight.w600)),
        SizedBox(height: s.sp(10)),
        if (_recientes.isEmpty)
          _mensajeVacio(s,
              'No has escaneado ningún lote todavía.\nUsa el botón de escaneo o el buscador de arriba.')
        else
          ...List.generate(
            _recientes.length,
            (i) => _tarjetaLote(s, _recientes[i],
                ultima: i == _recientes.length - 1),
          ),
      ],
    );
  }

  /// Órdenes activas en la línea del operador — para que ya las vea
  /// listas y pueda entrar directo a trazarlas sin buscarlas a mano.
  Widget _seccionOrdenesLinea(AppScale s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Órdenes en tu línea',
            style: TextStyle(
                color: Colors.white,
                fontSize: s.f(15),
                fontWeight: FontWeight.w600)),
        SizedBox(height: s.sp(10)),
        if (_cargandoOrdenesLinea)
          Padding(
            padding: EdgeInsets.symmetric(vertical: s.sp(12)),
            child: const Center(
                child: CircularProgressIndicator(color: AppColors.green)),
          )
        else
          ...List.generate(
            _ordenesLinea.length,
            (i) => _tarjetaOrden(s, _ordenesLinea[i],
                ultima: i == _ordenesLinea.length - 1),
          ),
      ],
    );
  }

  // Filas planas separadas por una línea tenue en vez de tarjetas blancas
  // apiladas — el texto queda directo sobre el fondo oscuro y el divisor
  // (con padding a los lados) evita que una fila "toque" a la siguiente.
  Widget _filaLista({
    required AppScale s,
    required VoidCallback onTap,
    required String titulo,
    required String? subtitulo,
    required Widget badge,
    bool ultima = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: s.sp(12)),
        decoration: BoxDecoration(
          border: ultima
              ? null
              : const Border(bottom: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: s.f(14),
                        fontFamily: 'monospace',
                        color: Colors.white),
                  ),
                  if (subtitulo != null)
                    Text(
                      subtitulo,
                      style: TextStyle(
                          fontSize: s.f(11.5), color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            badge,
            SizedBox(width: s.sp(6)),
            Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: s.ic(20)),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaOrden(AppScale s, OrdenInfo o, {bool ultima = false}) {
    return _filaLista(
      s: s,
      onTap: () => _abrirOrden(o.numero),
      titulo: o.folio,
      subtitulo: o.proceso,
      badge: BadgeEstadoOrden(estado: o.estado),
      ultima: ultima,
    );
  }

  Widget _mensajeVacio(AppScale s, String texto) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.sp(24)),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: s.f(13)),
      ),
    );
  }

  Widget _tarjetaLote(AppScale s, LoteResumen l, {bool ultima = false}) {
    return _filaLista(
      s: s,
      onTap: () => _abrirLote(l.numero),
      titulo: l.folio,
      subtitulo: l.ordenFolio != null ? 'De ${l.ordenFolio}' : null,
      badge: BadgeEstadoLote(estado: l.estado),
      ultima: ultima,
    );
  }
}
