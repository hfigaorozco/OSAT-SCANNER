import 'package:flutter/material.dart';
import '../models/lote.dart';
import '../models/defecto.dart';
import '../services/lote_service.dart';
import '../services/api_client.dart';

class LoteProvider extends ChangeNotifier {
  Lote? _loteActual;
  bool _loading = false;
  String? _error;

  Lote? get loteActual => _loteActual;
  bool get loading => _loading;
  String? get error => _error;
  bool get tieneEtapaEnCurso => _loteActual?.etapaActual != null;
  bool get puedeCompletarEtapa => _loteActual?.puedeCompletarEtapa ?? false;
  bool get puedePonerEnHold => _loteActual?.puedePonerEnHold ?? false;

  Future<bool> buscarLote(String codigo) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _loteActual = await LoteService.buscarPorFolio(codigo);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'No se pudo cargar el lote. Verifica el código.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// RFM05 + RFM06 + RFM07 — Registra el resultado de la etapa actual.
  Future<bool> completarEtapa({
    required String resultado,
    required int unidadesDefecto,
    String? observaciones,
    List<DefectoRegistrado> defectos = const [],
  }) async {
    if (_loteActual == null) return false;
    if (_loteActual!.enHold) {
      _error = 'Este lote está en Hold. Contacta al supervisor para continuar.';
      notifyListeners();
      return false;
    }
    final etapa = _loteActual!.etapaActual;
    if (etapa == null) {
      _error = 'No hay etapa en curso.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await LoteService.registrarEtapa(
        lote: _loteActual!,
        codigoPaso: etapa.codigoPaso,
        resultado: resultado,
        unidadesDefecto: unidadesDefecto,
        observaciones: observaciones,
        defectos: defectos,
      );
      // Refrescar el lote para reflejar el nuevo estado de las etapas
      _loteActual = await LoteService.buscarPorFolio(_loteActual!.folio);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al guardar. Intenta de nuevo.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> ponerEnHold(String motivo) async {
    if (_loteActual == null) return false;
    if (_loteActual!.enHold) {
      _error = 'Este lote ya está en Hold.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await LoteService.ponerEnHold(lote: _loteActual!, motivo: motivo);
      _loteActual = await LoteService.buscarPorFolio(_loteActual!.folio);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al guardar. Intenta de nuevo.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
