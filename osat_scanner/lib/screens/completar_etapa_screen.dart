import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/lote_provider.dart';
import '../models/defecto.dart';
import '../services/lote_service.dart';
import '../utils/constants.dart';
import '../widgets/osat_toast.dart';

class CompletarEtapaScreen extends StatefulWidget {
  const CompletarEtapaScreen({super.key});

  @override
  State<CompletarEtapaScreen> createState() => _CompletarEtapaScreenState();
}

class _CompletarEtapaScreenState extends State<CompletarEtapaScreen> {
  String _resultado = 'compl'; // Completado | No Completado | hold
  int _unidadesDefecto = 0;
  final _obsCtrl = TextEditingController();
  final List<DefectoRegistrado> _defectos = [];
  List<Defecto> _catalogoDefectos = [];
  bool _cargandoCatalogo = true;
  bool _guardando = false;
  final Stopwatch _stopwatch = Stopwatch()..start();
  late Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => i);
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    final codigoPaso =
        context.read<LoteProvider>().loteActual?.etapaActual?.codigoPaso;
    if (codigoPaso == null) {
      setState(() => _cargandoCatalogo = false);
      return;
    }
    try {
      final lista = await LoteService.listarDefectosPorPaso(codigoPaso);
      if (!mounted) return;
      setState(() {
        _catalogoDefectos = lista;
        _cargandoCatalogo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoCatalogo = false);
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// RFM06 — Agregar un defecto con tipo, cantidad, acción y foto opcional.
  void _agregarDefecto() {
    if (_catalogoDefectos.isEmpty) {
      OsatToast.show(context,
          message: 'Este paso no tiene defectos configurados.',
          tipo: ToastTipo.warning);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AgregarDefectoSheet(
        catalogo: _catalogoDefectos,
        onAdd: (d) => setState(() => _defectos.add(d)),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_resultado == 'nocom') {
      final lote = context.read<LoteProvider>().loteActual;
      final diesActivos = lote?.diesActivos ?? 0;
      final diesIniciales = lote?.diesIniciales ?? 0;
      // Rechazar una etapa es una decisión sobre el yield GLOBAL del lote, no
      // sobre el scrap de esta etapa sola: solo se permite si, al aplicar
      // este scrap, el yield del lote completo cae por debajo del 95% — el
      // mismo umbral que usa el trigger que pone la orden en hold.
      final yieldDespues = diesIniciales > 0
          ? ((diesActivos - _unidadesDefecto) / diesIniciales * 100)
          : 0;
      if (yieldDespues >= 95) {
        OsatToast.show(
          context,
          message:
              'Solo puedes rechazar la etapa si el scrap hace que el yield global del lote caiga por debajo del 95%.',
          tipo: ToastTipo.warning,
        );
        return;
      }
    }

    if (_resultado == 'enhol' && _obsCtrl.text.trim().isEmpty) {
      OsatToast.show(
        context,
        message: 'Describe el motivo del Hold antes de continuar.',
        tipo: ToastTipo.warning,
      );
      return;
    }

    final loteProv = context.read<LoteProvider>();
    bool ok = false;

    setState(() => _guardando = true);

    if (_resultado == 'enhol') {
      ok = await loteProv.ponerEnHold(
        _obsCtrl.text.trim(),
      );

    } else {
      ok = await loteProv.completarEtapa(
        resultado: _resultado,
        unidadesDefecto: _unidadesDefecto,
        observaciones: _obsCtrl.text.trim().isEmpty
            ? null
            : _obsCtrl.text.trim(),
        defectos: _defectos,
      );

    }

    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      Navigator.pop(context);
      OsatToast.show(
        context,
        message: 'Etapa completada exitosamente.',
        tipo: ToastTipo.success,
      );

    } else {
      OsatToast.show(
        context,
        message: loteProv.error ?? 'Error al guardar.',
        tipo: ToastTipo.error,
        actionLabel: 'Reintentar',
        onAction: _guardar,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loteProv = context.watch<LoteProvider>();
    final lote = loteProv.loteActual;
    final etapa = lote?.etapaActual;
    final s = AppScale.of(context);

    if (lote == null || etapa == null || lote.enHold || lote.rechazado) {
      return Scaffold(
        backgroundColor: AppColors.bgApp,
        appBar: AppBar(backgroundColor: AppColors.bgApp),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(s.sp(24)),
            child: Text(
              lote?.enHold == true
                  ? 'Este lote está en Hold. No es posible registrar etapas.'
                  : lote?.rechazado == true
                      ? 'Este lote fue rechazado. Ya no puede continuar con más etapas.'
                      : 'No hay una etapa en curso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: s.f(14)),
            ),
          ),
        ),
      );
    }

    final yieldDespuesRechazo = lote.diesIniciales > 0
        ? ((lote.diesActivos - _unidadesDefecto) / lote.diesIniciales * 100)
        : 0;
    final habilitarRechazo = yieldDespuesRechazo < 95;
    if (_resultado == 'nocom' && !habilitarRechazo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _resultado = 'compl');
      });
    }

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: s.sp(16)),
            constraints: BoxConstraints(maxWidth: s.sp(480)),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(s.r(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(s.sp(20), s.sp(18), s.sp(16), 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(etapa.nombre,
                              style: TextStyle(
                                  fontSize: s.f(18),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                          Text(lote.folio,
                              style: TextStyle(
                                  fontSize: s.f(12.5),
                                  color: AppColors.textMuted)),
                        ],
                      ),
                      StreamBuilder<int>(
                        stream: _timerStream,
                        builder: (context, _) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: s.sp(10), vertical: s.sp(5)),
                            decoration: BoxDecoration(
                              color: AppColors.badgeYellowBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: s.ic(13),
                                    color: AppColors.badgeYellowText),
                                SizedBox(width: s.sp(4)),
                                Text(
                                  _formatElapsed(
                                      _stopwatch.elapsed.inSeconds),
                                  style: TextStyle(
                                      fontSize: s.f(12),
                                      color: AppColors.badgeYellowText,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Divider(height: s.sp(20)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: s.sp(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Unidades con defecto',
                            style: TextStyle(
                                fontSize: s.f(13),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        SizedBox(height: s.sp(8)),
                        Row(
                          children: [
                            _StepperButton(
                              s: s,
                              icon: Icons.remove,
                              onTap: () => setState(() {
                                if (_unidadesDefecto > 0) _unidadesDefecto--;
                              }),
                            ),
                            SizedBox(width: s.sp(10)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: s.sp(24), vertical: s.sp(10)),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: AppColors.borderCard),
                                borderRadius: BorderRadius.circular(s.r(8)),
                              ),
                              child: Text('$_unidadesDefecto',
                                  style: TextStyle(
                                      fontSize: s.f(16),
                                      fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(width: s.sp(10)),
                            _StepperButton(
                              s: s,
                              icon: Icons.add,
                              onTap: () =>
                                  setState(() => _unidadesDefecto++),
                            ),
                          ],
                        ),
                        SizedBox(height: s.sp(16)),
                        // Yield del lote — actual, proyectado y umbral, siempre visible
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: s.sp(14), vertical: s.sp(12)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFC),
                            border: Border.all(color: AppColors.borderCard),
                            borderRadius: BorderRadius.circular(s.r(10)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _YieldStat(
                                s: s,
                                label: 'Actual',
                                value:
                                    '${lote.yieldPct.toStringAsFixed(1)}%',
                                color: AppColors.textDark,
                              ),
                              _YieldStat(
                                s: s,
                                label: 'Proyectado',
                                value:
                                    '${yieldDespuesRechazo.toStringAsFixed(1)}%',
                                color: habilitarRechazo
                                    ? AppColors.red
                                    : (yieldDespuesRechazo < 97
                                        ? AppColors.gold
                                        : AppColors.green),
                              ),
                              _YieldStat(
                                s: s,
                                label: 'Umbral mínimo',
                                value: '95%',
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                        if (habilitarRechazo) ...[
                          SizedBox(height: s.sp(10)),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: s.sp(12), vertical: s.sp(10)),
                            decoration: BoxDecoration(
                              color: AppColors.badgeYellowBg,
                              borderRadius: BorderRadius.circular(s.r(8)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: s.ic(16),
                                    color: AppColors.badgeYellowText),
                                SizedBox(width: s.sp(8)),
                                Expanded(
                                  child: Text(
                                    'Con este scrap el yield cae por debajo del umbral: la orden completa entrará en Hold automáticamente al confirmar, y ya puedes marcar esta etapa como Rechazado si corresponde.',
                                    style: TextStyle(
                                        fontSize: s.f(11.5),
                                        color: AppColors.badgeYellowText),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: s.sp(18)),
                        Text('Resultado *',
                            style: TextStyle(
                                fontSize: s.f(13),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        SizedBox(height: s.sp(8)),
                        Row(
                          children: [
                            _ResultadoOption(
                              s: s,
                              label: 'Aprobado',
                              color: AppColors.green,
                              selected: _resultado == 'compl',
                              onTap: () =>
                                  setState(() => _resultado = 'compl'),
                            ),
                            SizedBox(width: s.sp(8)),
                            _ResultadoOption(
                              s: s,
                              label: 'Rechazado',
                              color: AppColors.red,
                              selected: _resultado == 'nocom',
                              habilitado: habilitarRechazo,
                              onTap: () =>
                                  setState(() => _resultado = 'nocom'),
                            ),
                            SizedBox(width: s.sp(8)),
                            _ResultadoOption(
                              s: s,
                              label: 'Hold',
                              color: AppColors.gold,
                              selected: _resultado == 'enhol',
                              onTap: () =>
                                  setState(() => _resultado = 'enhol'),
                            ),
                          ],
                        ),
                        SizedBox(height: s.sp(18)),
                        Text(
                          _resultado == 'enhol'
                              ? 'Motivo del Hold *'
                              : 'Observaciones (opcional)',
                          style: TextStyle(
                              fontSize: s.f(13),
                              fontWeight: FontWeight.w600,
                              color: _resultado == 'enhol'
                                  ? AppColors.gold
                                  : AppColors.textDark),
                        ),
                        SizedBox(height: s.sp(8)),
                        TextField(
                          controller: _obsCtrl,
                          maxLines: 3,
                          style: TextStyle(fontSize: s.f(14)),
                          decoration: InputDecoration(
                            hintText: _resultado == 'enhol'
                                ? 'Describe el motivo del Hold…'
                                : 'Escribe observaciones sobre esta etapa...',
                            hintStyle: TextStyle(
                                fontSize: s.f(13), color: AppColors.textMuted),
                            filled: true,
                            fillColor: const Color(0xFFF7FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(s.r(8)),
                              borderSide: BorderSide(
                                  color: _resultado == 'enhol'
                                      ? AppColors.gold
                                      : AppColors.borderCard),
                            ),
                          ),
                        ),
                        SizedBox(height: s.sp(18)),
                        Text(
                          _defectos.isEmpty
                              ? 'Defectos detectados'
                              : 'Defectos detectados (${_defectos.fold(0, (s, d) => s + d.cantidad)} unidades)',
                          style: TextStyle(
                              fontSize: s.f(13),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark),
                        ),
                        SizedBox(height: s.sp(8)),
                        ..._defectos.asMap().entries.map((entry) {
                          final i = entry.key;
                          final d = entry.value;
                          return Container(
                            margin: EdgeInsets.only(bottom: s.sp(8)),
                            padding: EdgeInsets.symmetric(
                                horizontal: s.sp(12), vertical: s.sp(10)),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(s.r(8)),
                              border:
                                  Border.all(color: AppColors.borderCard),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(d.descripcion,
                                          style: TextStyle(
                                              fontSize: s.f(13),
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                        '${d.cantidad} unidades · ${accionDefectoLabel(d.accion)}',
                                        style: TextStyle(
                                            fontSize: s.f(11.5),
                                            color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close,
                                      size: s.ic(18), color: AppColors.red),
                                  onPressed: () =>
                                      setState(() => _defectos.removeAt(i)),
                                ),
                              ],
                            ),
                          );
                        }),
                        OutlinedButton.icon(
                          onPressed: _cargandoCatalogo ? null : _agregarDefecto,
                          icon: Icon(Icons.add, size: s.ic(16)),
                          label: Text('Agregar defecto',
                              style: TextStyle(fontSize: s.f(14))),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(color: AppColors.green),
                          ),
                        ),
                        SizedBox(height: s.sp(16)),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(s.sp(16)),
                  child: SizedBox(
                    height: s.h(46),
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _resultado == 'enhol'
                            ? AppColors.gold
                            : AppColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(s.r(10))),
                      ),
                      child: _guardando
                          ? SizedBox(
                              width: s.ic(22),
                              height: s.ic(22),
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.4),
                            )
                          : Text(
                              _resultado == 'enhol'
                                  ? 'Enviar a Hold'
                                  : 'Completar etapa',
                              style: TextStyle(
                                  fontSize: s.f(15),
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultadoOption extends StatelessWidget {
  final AppScale s;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool habilitado;

  const _ResultadoOption({
    required this.s,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: habilitado ? onTap : null,
        borderRadius: BorderRadius.circular(s.r(8)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: s.sp(12)),
          decoration: BoxDecoration(
            color: !habilitado
                ? const Color(0xFFF7FAFC)
                : selected
                    ? color.withValues(alpha: 0.1)
                    : Colors.white,
            border: Border.all(
                color: selected && habilitado
                    ? color
                    : AppColors.borderCard,
                width: 1.5),
            borderRadius: BorderRadius.circular(s.r(8)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: s.f(13),
                fontWeight: FontWeight.w600,
                color: !habilitado
                    ? const Color(0xFFA0AEC0)
                    : selected
                        ? color
                        : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YieldStat extends StatelessWidget {
  final AppScale s;
  final String label;
  final String value;
  final Color color;

  const _YieldStat({
    required this.s,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: s.f(9.5),
                color: AppColors.textMuted,
                letterSpacing: .3)),
        SizedBox(height: s.sp(2)),
        Text(value,
            style: TextStyle(
                fontSize: s.f(16), fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final AppScale s;
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.s, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s.r(8)),
      child: Container(
        width: s.sp(40),
        height: s.sp(40),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderCard),
          borderRadius: BorderRadius.circular(s.r(8)),
        ),
        child: Icon(icon, size: s.ic(18), color: AppColors.textDark),
      ),
    );
  }
}

/// RFM06 — Bottom sheet para agregar un defecto con tipo, cantidad, acción y foto.
class _AgregarDefectoSheet extends StatefulWidget {
  final List<Defecto> catalogo;
  final ValueChanged<DefectoRegistrado> onAdd;

  const _AgregarDefectoSheet({required this.catalogo, required this.onAdd});

  @override
  State<_AgregarDefectoSheet> createState() => _AgregarDefectoSheetState();
}

class _AgregarDefectoSheetState extends State<_AgregarDefectoSheet> {
  Defecto? _seleccionado;
  int _cantidad = 1;
  AccionDefecto _accion = AccionDefecto.scrap;
  String? _fotoPath;

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(
        source: ImageSource.camera, imageQuality: 70);
    if (foto != null) setState(() => _fotoPath = foto.path);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: s.sp(20),
        right: s.sp(20),
        top: s.sp(20),
        bottom: MediaQuery.of(context).viewInsets.bottom + s.sp(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agregar defecto',
              style: TextStyle(fontSize: s.f(17), fontWeight: FontWeight.bold)),
          SizedBox(height: s.sp(16)),
          Text('Tipo de defecto',
              style: TextStyle(fontSize: s.f(12.5), color: AppColors.textMuted)),
          SizedBox(height: s.sp(6)),
          DropdownButtonFormField<Defecto>(
            initialValue: _seleccionado,
            isExpanded: true,
            style: TextStyle(fontSize: s.f(14), color: AppColors.textDark),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(s.r(8))),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: s.sp(12), vertical: s.sp(6)),
            ),
            items: widget.catalogo
                .map((d) => DropdownMenuItem(
                    value: d, child: Text(d.descripcion)))
                .toList(),
            onChanged: (v) => setState(() => _seleccionado = v),
          ),
          SizedBox(height: s.sp(14)),
          Text('Cantidad de unidades',
              style: TextStyle(fontSize: s.f(12.5), color: AppColors.textMuted)),
          SizedBox(height: s.sp(6)),
          Row(
            children: [
              _StepperButton(
                s: s,
                icon: Icons.remove,
                onTap: () =>
                    setState(() => _cantidad = (_cantidad - 1).clamp(1, 999)),
              ),
              SizedBox(width: s.sp(10)),
              Text('$_cantidad',
                  style: TextStyle(
                      fontSize: s.f(16), fontWeight: FontWeight.bold)),
              SizedBox(width: s.sp(10)),
              _StepperButton(
                  s: s, icon: Icons.add, onTap: () => setState(() => _cantidad++)),
            ],
          ),
          SizedBox(height: s.sp(14)),
          Text('Acción tomada',
              style: TextStyle(fontSize: s.f(12.5), color: AppColors.textMuted)),
          SizedBox(height: s.sp(6)),
          Wrap(
            spacing: s.sp(8),
            children: AccionDefecto.values.map((a) {
              final selected = _accion == a;
              return ChoiceChip(
                label: Text(accionDefectoLabel(a),
                    style: TextStyle(fontSize: s.f(13))),
                selected: selected,
                onSelected: (_) => setState(() => _accion = a),
                selectedColor: AppColors.purple.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: selected ? AppColors.purple : AppColors.textMuted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: s.sp(14)),
          OutlinedButton.icon(
            onPressed: _tomarFoto,
            icon: Icon(_fotoPath == null
                ? Icons.camera_alt_outlined
                : Icons.check_circle,
                size: s.ic(18),
                color: _fotoPath == null ? null : AppColors.green),
            label: Text(_fotoPath == null
                ? 'Tomar fotografía (opcional)'
                : 'Foto capturada',
                style: TextStyle(fontSize: s.f(14))),
          ),
          SizedBox(height: s.sp(20)),
          SizedBox(
            width: double.infinity,
            height: s.h(44),
            child: ElevatedButton(
              onPressed: _seleccionado == null
                  ? null
                  : () {
                      widget.onAdd(DefectoRegistrado(
                        codigoDefecto: _seleccionado!.codigo,
                        descripcion: _seleccionado!.descripcion,
                        cantidad: _cantidad,
                        accion: _accion,
                        fotoPath: _fotoPath,
                      ));
                      Navigator.of(context).pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Agregar', style: TextStyle(fontSize: s.f(14))),
            ),
          ),
        ],
      ),
    );
  }
}
