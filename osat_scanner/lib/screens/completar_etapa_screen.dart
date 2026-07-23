import 'package:flutter/material.dart';
import 'package:osat_tracer_mobile/models/lote.dart';
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
    try {
      final lista = await LoteService.listarDefectos();
      setState(() {
        _catalogoDefectos = lista;
        _cargandoCatalogo = false;
      });
    } catch (_) {
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
          message: 'No hay catálogo de defectos disponible.',
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
    if (_resultado == 'nocom' && _unidadesDefecto == 0) {
      OsatToast.show(
        context,
        message: 'Indica las unidades con defecto para rechazar.',
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

    setState(() => _guardando = false);
    if (!mounted) return;
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

    if (lote == null || etapa == null || lote.enHold) {
      return Scaffold(
        backgroundColor: AppColors.bgApp,
        appBar: AppBar(backgroundColor: AppColors.bgApp),
        body: Center(
          child: Text(
            lote?.enHold == true
                ? 'Este lote está en Hold. No es posible registrar etapas.'
                : 'No hay una etapa en curso.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(etapa.nombre,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                          Text(lote.folio,
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppColors.textMuted)),
                        ],
                      ),
                      StreamBuilder<int>(
                        stream: _timerStream,
                        builder: (context, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.badgeYellowBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 13, color: AppColors.badgeYellowText),
                                const SizedBox(width: 4),
                                Text(
                                  _formatElapsed(
                                      _stopwatch.elapsed.inSeconds),
                                  style: const TextStyle(
                                      fontSize: 12,
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
                const Divider(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resultado *',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _ResultadoOption(
                              label: 'Aprobado',
                              color: AppColors.green,
                              selected: _resultado == 'compl',
                              onTap: () =>
                                  setState(() => _resultado = 'compl'),
                            ),
                            const SizedBox(width: 8),
                            _ResultadoOption(
                              label: 'Rechazado',
                              color: AppColors.red,
                              selected: _resultado == 'nocom',
                              onTap: () =>
                                  setState(() => _resultado = 'nocom'),
                            ),
                            const SizedBox(width: 8),
                            _ResultadoOption(
                              label: 'Hold',
                              color: AppColors.gold,
                              selected: _resultado == 'enhol',
                              onTap: () =>
                                  setState(() => _resultado = 'enhol'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text('Unidades con defecto',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StepperButton(
                              icon: Icons.remove,
                              onTap: () => setState(() {
                                if (_unidadesDefecto > 0) _unidadesDefecto--;
                              }),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: AppColors.borderCard),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$_unidadesDefecto',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            _StepperButton(
                              icon: Icons.add,
                              onTap: () =>
                                  setState(() => _unidadesDefecto++),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text('Observaciones (opcional)',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _obsCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Escribe observaciones sobre esta etapa...',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted),
                            filled: true,
                            fillColor: const Color(0xFFF7FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.borderCard),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _defectos.isEmpty
                              ? 'Defectos detectados'
                              : 'Defectos detectados (${_defectos.fold(0, (s, d) => s + d.cantidad)} unidades)',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark),
                        ),
                        const SizedBox(height: 8),
                        ..._defectos.asMap().entries.map((entry) {
                          final i = entry.key;
                          final d = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(8),
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
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                        '${d.cantidad} unidades · ${accionDefectoLabel(d.accion)}',
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 18, color: AppColors.red),
                                  onPressed: () =>
                                      setState(() => _defectos.removeAt(i)),
                                ),
                              ],
                            ),
                          );
                        }),
                        OutlinedButton.icon(
                          onPressed: _cargandoCatalogo ? null : _agregarDefecto,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Agregar defecto'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(color: AppColors.green),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _resultado == 'enhol'
                          ? AppColors.gold
                          : AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.4),
                          )
                        : Text(
                            _resultado == 'enhol'
                                ? 'Enviar a Hold'
                                : 'Completar etapa',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
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
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ResultadoOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.white,
            border: Border.all(
                color: selected ? color : AppColors.borderCard, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderCard),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.textDark),
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agregar defecto',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Tipo de defecto',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          DropdownButtonFormField<Defecto>(
            value: _seleccionado,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            items: widget.catalogo
                .map((d) => DropdownMenuItem(
                    value: d, child: Text(d.descripcion)))
                .toList(),
            onChanged: (v) => setState(() => _seleccionado = v),
          ),
          const SizedBox(height: 14),
          const Text('Cantidad de unidades',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove,
                onTap: () =>
                    setState(() => _cantidad = (_cantidad - 1).clamp(1, 999)),
              ),
              const SizedBox(width: 10),
              Text('$_cantidad',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              _StepperButton(
                  icon: Icons.add, onTap: () => setState(() => _cantidad++)),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Acción tomada',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: AccionDefecto.values.map((a) {
              final selected = _accion == a;
              return ChoiceChip(
                label: Text(accionDefectoLabel(a)),
                selected: selected,
                onSelected: (_) => setState(() => _accion = a),
                selectedColor: AppColors.purple.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: selected ? AppColors.purple : AppColors.textMuted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _tomarFoto,
            icon: Icon(_fotoPath == null
                ? Icons.camera_alt_outlined
                : Icons.check_circle,
                color: _fotoPath == null ? null : AppColors.green),
            label: Text(_fotoPath == null
                ? 'Tomar fotografía (opcional)'
                : 'Foto capturada'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
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
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text('Agregar'),
            ),
          ),
        ],
      ),
    );
  }
}
