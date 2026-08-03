import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lote_provider.dart';
import '../utils/constants.dart';
import '../widgets/osat_toast.dart';

class HoldScreen extends StatefulWidget {
  const HoldScreen({super.key});

  @override
  State<HoldScreen> createState() => _HoldScreenState();
}

class _HoldScreenState extends State<HoldScreen> {
  final _motivoCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final motivo = _motivoCtrl.text.trim();
    if (motivo.isEmpty) {
      OsatToast.show(context,
          message: 'Describe el motivo del Hold.', tipo: ToastTipo.warning);
      return;
    }

    setState(() => _enviando = true);
    final loteProv = context.read<LoteProvider>();
    final ok = await loteProv.ponerEnHold(motivo);
    if (!mounted) return;
    setState(() => _enviando = false);

    if (ok) {
      Navigator.of(context).pop();
      OsatToast.show(context,
          message: 'Lote puesto en Hold.', tipo: ToastTipo.warning);
    } else {
      OsatToast.show(context,
          message: loteProv.error ?? 'Error al guardar. Intenta de nuevo.',
          tipo: ToastTipo.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loteProv = context.watch<LoteProvider>();
    final lote = loteProv.loteActual;
    final etapa = lote?.etapaActual;
    final s = AppScale.of(context);

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: s.sp(16)),
            constraints: BoxConstraints(maxWidth: s.sp(480)),
            padding: EdgeInsets.all(s.sp(20)),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(s.r(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      etapa?.nombre ?? 'Poner en Hold',
                      style: TextStyle(
                          fontSize: s.f(18),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: AppColors.textMuted, size: s.ic(24)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                if (lote != null)
                  Text(lote.folio,
                      style: TextStyle(
                          fontSize: s.f(12.5), color: AppColors.textMuted)),
                SizedBox(height: s.sp(16)),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                        fontSize: s.f(13.5),
                        color: AppColors.textDark,
                        height: 1.5),
                    children: [
                      const TextSpan(text: 'El lote '),
                      TextSpan(
                        text: lote?.folio ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                          text: ' quedará detenido hasta que se resuelva el motivo.'),
                    ],
                  ),
                ),
                SizedBox(height: s.sp(18)),
                Text('Motivo *',
                    style: TextStyle(
                        fontSize: s.f(13),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                SizedBox(height: s.sp(8)),
                TextField(
                  controller: _motivoCtrl,
                  maxLines: 4,
                  style: TextStyle(fontSize: s.f(14)),
                  decoration: InputDecoration(
                    hintText: 'Describe el motivo del hold...',
                    hintStyle: TextStyle(
                        fontSize: s.f(13), color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF7FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(s.r(8)),
                      borderSide: const BorderSide(color: AppColors.borderCard),
                    ),
                  ),
                ),
                SizedBox(height: s.sp(20)),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: s.h(44),
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            textStyle: TextStyle(fontSize: s.f(14)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ),
                    SizedBox(width: s.sp(12)),
                    Expanded(
                      child: SizedBox(
                        height: s.h(44),
                        child: ElevatedButton(
                          onPressed: _enviando ? null : _confirmar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.white,
                            textStyle: TextStyle(fontSize: s.f(14)),
                          ),
                          child: _enviando
                              ? SizedBox(
                                  width: s.ic(20),
                                  height: s.ic(20),
                                  child: const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.2),
                                )
                              : const Text('Confirmar Hold'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
