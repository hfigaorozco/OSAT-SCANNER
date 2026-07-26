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

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
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
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                if (lote != null)
                  Text(lote.folio,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                        fontSize: 13.5, color: AppColors.textDark, height: 1.5),
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
                const SizedBox(height: 18),
                const Text('Motivo *',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                const SizedBox(height: 8),
                TextField(
                  controller: _motivoCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe el motivo del hold...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF7FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderCard),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _enviando ? null : _confirmar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: _enviando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.2),
                              )
                            : const Text('Confirmar Hold'),
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
