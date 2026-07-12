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
    final auth = context.watch<AuthProvider>();
    final loteProv = context.watch<LoteProvider>();
    final empleado = auth.empleado;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      return Text(
                        '$h:$m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // ── Layout de 2 columnas: trazabilidad (izq) + scan grande (der) ──
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna izquierda — último lote
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ultimo Lote Escaneado',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: loteProv.loading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.green))
                                : loteProv.loteActual != null
                                    ? SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            LoteHeaderCard(
                                                lote: loteProv.loteActual!),
                                            const SizedBox(height: 10),
                                            TrazabilidadStepper(
                                              lote: loteProv.loteActual!,
                                              onCompletarEtapa: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const CompletarEtapaScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                            if (loteProv.tieneEtapaEnCurso) ...[
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const HoldScreen(),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.pause,
                                                      size: 18),
                                                  label: const Text(
                                                      'Poner en Hold'),
                                                  style: OutlinedButton
                                                      .styleFrom(
                                                    foregroundColor:
                                                        AppColors.gold,
                                                    side: const BorderSide(
                                                        color: AppColors.gold),
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            vertical: 12),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppColors.bgCard,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'No has escaneado ningún lote todavía.\nUsa el botón "Escanear Lote" →',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 13),
                                        ),
                                      ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Columna derecha — botón grande de escaneo (siempre visible)
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Botón circular grande — pensado para uso con guantes
                          GestureDetector(
                            onTap: _abrirScanner,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: const BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.memory,
                                color: Colors.white,
                                size: 96,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          GestureDetector(
                            onTap: _abrirScanner,
                            child: const Text(
                              'Escanear Lote',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Apunta tu cámara al código QR',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          // Búsqueda manual alternativa al QR
                          Container(
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
                                            color: Colors.white, fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Placeholder',
                                          hintStyle: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 13),
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 10),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Buscar'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'O ingresa el código',
                                  style: TextStyle(
                                    color: AppColors.textMuted
                                        .withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
}

