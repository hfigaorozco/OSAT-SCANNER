import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alerta_operador.dart';
import '../services/alerta_service.dart';
import '../providers/auth_provider.dart';
import '../providers/lote_provider.dart';
import '../utils/constants.dart';
import '../widgets/osat_bottom_nav.dart';
import 'home_screen.dart';
import 'scanner_screen.dart';
import 'trazado_screen.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<AlertaOperador> _alertas = [];
  AlertaOperador? _seleccionada;
  bool _loading = true;
  String _filtro = 'todas'; // todas | no_leidas | produccion | kpi | stock

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final empleadoNumero = context.read<AuthProvider>().empleado?.numero;
      // El backend ya regresa la lista ordenada por prioridad: alertas de la
      // línea propia del operador primero, luego por tipo (producción > kpi
      // > stock) y no leídas antes que leídas — no hay que reordenar aquí.
      final lista = await AlertaService.listar(empleadoNumero: empleadoNumero);
      if (!mounted) return;
      setState(() {
        _alertas = lista;
        _loading = false;
        if (_alertas.isNotEmpty) _seleccionada = _alertas.first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Selecciona una alerta para verla en el panel de detalle y, si no
  /// estaba leída, la marca como leída en el backend — antes esto nunca
  /// pasaba (el onTap solo cambiaba la selección), así que el chip "No
  /// leídas" y el badge del bottom nav nunca bajaban por nada que hiciera
  /// el operador en la app.
  Future<void> _seleccionar(AlertaOperador a) async {
    setState(() => _seleccionada = a);
    if (a.leida) return;
    final idx = _alertas.indexWhere((x) => x.numero == a.numero);
    final actualizada = a.copyWith(leida: true);
    setState(() {
      if (idx != -1) _alertas[idx] = actualizada;
      _seleccionada = actualizada;
    });
    try {
      await AlertaService.marcarLeida(a.numero);
    } catch (_) {
      if (idx != -1 && mounted) setState(() => _alertas[idx] = a);
    }
  }

  List<AlertaOperador> get _filtradas {
    switch (_filtro) {
      case 'no_leidas':
        return _alertas.where((a) => !a.leida).toList();
      case 'produccion':
        return _alertas.where((a) => a.tipo == TipoAlertaOperador.produccion).toList();
      case 'kpi':
        return _alertas.where((a) => a.tipo == TipoAlertaOperador.kpi).toList();
      case 'stock':
        return _alertas.where((a) => a.tipo == TipoAlertaOperador.stock).toList();
      default:
        return _alertas;
    }
  }

  void _onNavTap(int index) {
    if (index == 2) return;
    Widget destino;
    switch (index) {
      case 0:
        destino = const HomeScreen();
        break;
      case 1:
        destino = const ScannerScreen();
        break;
      default:
        return;
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = AppScale.of(context);
    final tablet = esTablet(context);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(s.sp(16), s.sp(12), s.sp(16), 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${auth.empleado?.nombre ?? 'Operador'}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: s.f(18),
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: s.sp(14)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FiltroChip(
                        s: s,
                        label: 'Todas',
                        value: 'todas',
                        current: _filtro,
                        onTap: (v) => setState(() => _filtro = v)),
                    _FiltroChip(
                        s: s,
                        label: 'No leídas',
                        value: 'no_leidas',
                        current: _filtro,
                        onTap: (v) => setState(() => _filtro = v)),
                    _FiltroChip(
                        s: s,
                        label: 'Producción',
                        value: 'produccion',
                        current: _filtro,
                        onTap: (v) => setState(() => _filtro = v)),
                    _FiltroChip(
                        s: s,
                        label: 'KPI',
                        value: 'kpi',
                        current: _filtro,
                        onTap: (v) => setState(() => _filtro = v)),
                    _FiltroChip(
                        s: s,
                        label: 'Stock',
                        value: 'stock',
                        current: _filtro,
                        onTap: (v) => setState(() => _filtro = v)),
                  ],
                ),
              ),
              SizedBox(height: s.sp(12)),
              Expanded(
                child: tablet ? _layoutTablet(s) : _layoutTelefono(s),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: OsatBottomNav(
        currentIndex: 2,
        onTap: _onNavTap,
        alertasNoLeidas: _alertas.where((a) => !a.leida).length,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LAYOUT TABLET — maestro-detalle lado a lado, no apilado.
  // ════════════════════════════════════════════════════════════════
  Widget _layoutTablet(AppScale s) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_filtradas.isEmpty) {
      return Center(
        child: Text('Sin alertas',
            style: TextStyle(color: AppColors.textMuted, fontSize: s.f(15))),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: ListView.separated(
            itemCount: _filtradas.length,
            separatorBuilder: (_, __) => SizedBox(height: s.sp(8)),
            itemBuilder: (context, index) {
              final a = _filtradas[index];
              return _AlertaListItem(
                s: s,
                alerta: a,
                selected: _seleccionada?.numero == a.numero,
                onTap: () => _seleccionar(a),
              );
            },
          ),
        ),
        SizedBox(width: s.sp(20)),
        Expanded(
          flex: 3,
          child: _seleccionada != null
              ? _AlertaDetalle(s: s, alerta: _seleccionada!)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LAYOUT TELÉFONO — lista arriba, detalle abajo, como siempre.
  // ════════════════════════════════════════════════════════════════
  Widget _layoutTelefono(AppScale s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.green))
              : _filtradas.isEmpty
                  ? const Center(
                      child: Text('Sin alertas',
                          style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      itemCount: _filtradas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final a = _filtradas[index];
                        return _AlertaListItem(
                          s: s,
                          alerta: a,
                          selected: _seleccionada?.numero == a.numero,
                          onTap: () => _seleccionar(a),
                        );
                      },
                    ),
        ),
        if (_seleccionada != null) _AlertaDetalle(s: s, alerta: _seleccionada!),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final AppScale s;
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;

  const _FiltroChip({
    required this.s,
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return Padding(
      padding: EdgeInsets.only(right: s.sp(8)),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: s.sp(14), vertical: s.sp(7)),
          decoration: BoxDecoration(
            color: selected ? AppColors.purple : AppColors.bgTopbar,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textMuted,
              fontSize: s.f(12.5),
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Colores/íconos por tipo — mismos 3 colores que la web (kpi/views.py::
/// _COLOR_MAP): stock=dorado, producción=rojo, kpi=morado.
IconData _iconoPorTipo(TipoAlertaOperador tipo) {
  switch (tipo) {
    case TipoAlertaOperador.produccion:
      return Icons.precision_manufacturing;
    case TipoAlertaOperador.kpi:
      return Icons.bar_chart;
    case TipoAlertaOperador.stock:
      return Icons.inventory_2;
  }
}

Color _colorPorTipo(TipoAlertaOperador tipo) {
  switch (tipo) {
    case TipoAlertaOperador.produccion:
      return AppColors.red;
    case TipoAlertaOperador.kpi:
      return AppColors.alertaKpi;
    case TipoAlertaOperador.stock:
      return AppColors.gold;
  }
}

class _AlertaListItem extends StatelessWidget {
  final AppScale s;
  final AlertaOperador alerta;
  final bool selected;
  final VoidCallback onTap;

  const _AlertaListItem({
    required this.s,
    required this.alerta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorPorTipo(alerta.tipo);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s.r(10)),
      child: Container(
        padding: EdgeInsets.all(s.sp(12)),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F7FA) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(s.r(10)),
          border: selected
              ? Border.all(color: AppColors.turquoise, width: 1.3)
              : (alerta.esMiLinea == true
                  ? Border.all(color: AppColors.green, width: 1.1)
                  : null),
        ),
        child: Row(
          children: [
            Container(
              width: s.sp(34),
              height: s.sp(34),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(s.r(8)),
              ),
              child: Icon(_iconoPorTipo(alerta.tipo), size: s.ic(18), color: color),
            ),
            SizedBox(width: s.sp(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alerta.descripcion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: s.f(13),
                        fontWeight:
                            alerta.leida ? FontWeight.normal : FontWeight.w600,
                        color: AppColors.textDark,
                      )),
                  Row(
                    children: [
                      Text(alerta.tiempo,
                          style: TextStyle(
                              fontSize: s.f(11), color: AppColors.textMuted)),
                      if (alerta.esMiLinea == true) ...[
                        SizedBox(width: s.sp(6)),
                        Icon(Icons.factory, size: s.ic(11), color: AppColors.green),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!alerta.leida)
              Container(
                width: s.sp(8),
                height: s.sp(8),
                decoration: const BoxDecoration(
                    color: AppColors.red, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

/// Alertas de tipo producción/kpi vienen con el lote (oblea) del que
/// salieron — al tocar el detalle expandido se navega directo a su
/// trazado, igual que ya se hace desde home/scanner. Las de tipo stock no
/// tienen lote asociado (son de inventario, no de un lote específico), así
/// que ahí no hay nada que abrir.
Future<void> _abrirLoteDeAlerta(BuildContext context, int loteNumero) async {
  final loteProv = context.read<LoteProvider>();
  final ok = await loteProv.buscarLote(loteNumero.toString());
  if (!context.mounted) return;
  if (ok) {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TrazadoScreen(loteNumero: loteNumero),
    ));
  }
}

class _AlertaDetalle extends StatelessWidget {
  final AppScale s;
  final AlertaOperador alerta;
  const _AlertaDetalle({required this.s, required this.alerta});

  String get _etiquetaTipo {
    switch (alerta.tipo) {
      case TipoAlertaOperador.produccion:
        return 'Producción';
      case TipoAlertaOperador.kpi:
        return 'KPI';
      case TipoAlertaOperador.stock:
        return 'Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorPorTipo(alerta.tipo);
    final tieneLote = alerta.loteId != null;
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(s.r(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(s.r(12)),
        onTap: tieneLote ? () => _abrirLoteDeAlerta(context, alerta.loteId!) : null,
        child: Padding(
          padding: EdgeInsets.all(s.sp(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: s.sp(8), vertical: s.sp(3)),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(s.r(4)),
                    ),
                    child: Text(_etiquetaTipo,
                        style: TextStyle(
                            fontSize: s.f(11),
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                  if (alerta.esMiLinea == true) ...[
                    SizedBox(width: s.sp(8)),
                    Icon(Icons.factory, size: s.ic(13), color: AppColors.green),
                    SizedBox(width: s.sp(3)),
                    Text('Tu línea',
                        style: TextStyle(
                            fontSize: s.f(11),
                            fontWeight: FontWeight.w600,
                            color: AppColors.green)),
                  ] else if (alerta.lineaNombre != null) ...[
                    SizedBox(width: s.sp(8)),
                    Text(alerta.lineaNombre!,
                        style: TextStyle(fontSize: s.f(11), color: AppColors.textMuted)),
                  ],
                ],
              ),
              SizedBox(height: s.sp(10)),
              Text(alerta.descripcion,
                  style: TextStyle(
                      fontSize: s.f(15),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.4)),
              SizedBox(height: s.sp(6)),
              Text(alerta.tiempo,
                  style: TextStyle(fontSize: s.f(12), color: AppColors.textMuted)),
              if (tieneLote) ...[
                SizedBox(height: s.sp(12)),
                Row(
                  children: [
                    Text('Ver lote',
                        style: TextStyle(
                            fontSize: s.f(12.5),
                            fontWeight: FontWeight.w600,
                            color: AppColors.turquoise)),
                    SizedBox(width: s.sp(2)),
                    Icon(Icons.chevron_right, size: s.ic(16), color: AppColors.turquoise),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


