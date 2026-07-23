import '../models/lote.dart';
import '../models/defecto.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class LoteService {
  /// RFM04 — Busca un lote por folio (desde QR o ingreso manual) y devuelve
  /// toda su información de trazabilidad.
  static Future<Lote> buscarPorFolio(String folioOrCodigo) async {
    // Acepta tanto "LOT-2026-0001" como solo "1" o "0001"
    final soloNumeros = folioOrCodigo.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloNumeros.isEmpty) {
      throw ApiException('Código de lote inválido.');
    }
    final numero = int.parse(soloNumeros);

    final data = await ApiClient.get(ApiConfig.obleaDetail(numero));
    if (data == null) {
      throw ApiException('Lote no encontrado.');
    }
    return Lote.fromJson(data as Map<String, dynamic>);
  }

  /// RFM05 — Registra la ejecución de una etapa.
  /// Restricciones de negocio (validadas también en el back, pero
  /// la app debe avisar antes de enviar):
  /// - La etapa anterior debe estar Aprobada.
  /// - El lote no debe estar en Hold.
  static Future<void> registrarEtapa({
    required Lote lote,
    required String codigoPaso,
    required String resultado, // 'aprobado' | 'rechazado' | 'hold'
    required int unidadesDefecto,
    String? observaciones,
    List<DefectoRegistrado> defectos = const [],
  }) async {
    if (lote.enHold) {
      throw ApiException(
          'Este lote está en Hold. Contacta al supervisor para continuar.');
    }

    final etapaActual = lote.etapaActual;
    if (etapaActual == null) {
      throw ApiException('No hay una etapa en curso para este lote.');
    }
    if (etapaActual.codigoPaso != codigoPaso) {
      throw ApiException(
          'Solo puedes registrar la etapa actual: ${etapaActual.nombre}');
    }

    await ApiClient.post(ApiConfig.crearPasoRealizado, {
      'paso': codigoPaso,
      'oblea': lote.numero,
      'estado': resultado,
      'unidades_defecto': unidadesDefecto,
      'observaciones': observaciones,
      'defectos': defectos.map((d) => d.toJson()).toList(),
    });
  }

  /// RFM05 — Pone el lote en Hold (bloquea avance hasta liberación del supervisor)
  static Future<void> ponerEnHold({
    required Lote lote,
    required String motivo,
  }) async {
    if (lote.enHold) {
      throw ApiException('Este lote ya está en Hold.');
    }
    await ApiClient.patch(ApiConfig.updateOblea(lote.numero), {
      'estado': 'enhol',
      'hold_motivo': motivo,
    });
  }

  /// Catálogo de defectos para el formulario de RFM06
  static Future<List<Defecto>> listarDefectos() async {
    final data = await ApiClient.get(ApiConfig.defectos);
    return (data as List).map((d) => Defecto.fromJson(d)).toList();
  }
}
