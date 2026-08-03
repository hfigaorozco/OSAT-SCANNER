import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alerta_operador.dart';
import '../services/alerta_service.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/osat_bottom_nav.dart';
import 'home_screen.dart';
import 'scanner_screen.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<AlertaOperador> _alertas = [];
  AlertaOperador? _seleccionada;
  bool _loading = true;
  String _filtro = 'todas'; // todas | no_leidas | hold | stock

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final lista = await AlertaService.listar();
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

  List<AlertaOperador> get _filtradas {
    switch (_filtro) {
      case 'no_leidas':
        return _alertas.where((a) => !a.leida).toList();
      case 'hold':
        return _alertas.where((a) => a.tipo == TipoAlertaOperador.hold).toList();
      case 'stock':
        return _alertas
            .where((a) => a.tipo == TipoAlertaOperador.stock)
            .toList();
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
                        label: 'Hold',
                        value: 'hold',
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
                selected: _seleccionada?.id == a.id,
                onTap: () => setState(() => _seleccionada = a),
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
                          selected: _seleccionada?.id == a.id,
                          onTap: () => setState(() => _seleccionada = a),
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

  IconData get _icono {
    switch (alerta.tipo) {
      case TipoAlertaOperador.hold:
        return Icons.pause_circle;
      case TipoAlertaOperador.stock:
        return Icons.inventory_2;
      case TipoAlertaOperador.kpi:
        return Icons.bar_chart;
      case TipoAlertaOperador.liberado:
        return Icons.check_circle;
      case TipoAlertaOperador.scrap:
        return Icons.delete;
      case TipoAlertaOperador.mantenimiento:
        return Icons.build;
      case TipoAlertaOperador.info:
        return Icons.info;
    }
  }

  Color get _color {
    switch (alerta.tipo) {
      case TipoAlertaOperador.hold:
        return AppColors.gold;
      case TipoAlertaOperador.stock:
        return AppColors.red;
      case TipoAlertaOperador.kpi:
        return AppColors.turquoise;
      case TipoAlertaOperador.liberado:
        return AppColors.green;
      case TipoAlertaOperador.scrap:
        return AppColors.red;
      case TipoAlertaOperador.mantenimiento:
        return AppColors.turquoise;
      case TipoAlertaOperador.info:
        return AppColors.turquoise;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: s.sp(34),
              height: s.sp(34),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(s.r(8)),
              ),
              child: Icon(_icono, size: s.ic(18), color: _color),
            ),
            SizedBox(width: s.sp(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alerta.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: s.f(13),
                        fontWeight:
                            alerta.leida ? FontWeight.normal : FontWeight.w600,
                        color: AppColors.textDark,
                      )),
                  Text(alerta.tiempo,
                      style: TextStyle(
                          fontSize: s.f(11), color: AppColors.textMuted)),
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

class _AlertaDetalle extends StatelessWidget {
  final AppScale s;
  final AlertaOperador alerta;
  const _AlertaDetalle({required this.s, required this.alerta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(s.sp(16)),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(s.r(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alerta.titulo,
              style: TextStyle(
                  fontSize: s.f(16),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          SizedBox(height: s.sp(6)),
          Text(alerta.cuerpo,
              style: TextStyle(
                  fontSize: s.f(13), color: AppColors.textDark, height: 1.5)),
          if (alerta.loteFolio != null) ...[
            SizedBox(height: s.sp(12)),
            Container(
              padding: EdgeInsets.all(s.sp(10)),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(s.r(8)),
              ),
              child: Row(
                children: [
                  Text('Lote: ',
                      style: TextStyle(
                          fontSize: s.f(12), color: AppColors.textMuted)),
                  Text(alerta.loteFolio!,
                      style: TextStyle(
                          fontSize: s.f(13),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
