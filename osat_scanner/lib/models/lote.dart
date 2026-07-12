import 'etapa.dart';

enum EstadoLote { enProceso, aprobado, rechazado, hold, pendiente }

EstadoLote estadoLoteFromString(String? raw) {
  final s = (raw ?? '').toLowerCase();
  if (s.contains('hold')) return EstadoLote.hold;
  if (s.contains('aprob') || s.contains('complet')) return EstadoLote.aprobado;
  if (s.contains('rechaz')) return EstadoLote.rechazado;
  if (s.contains('proceso') || s.contains('activo')) return EstadoLote.enProceso;
  return EstadoLote.pendiente;
}

/// Representa una Oblea del backend, mostrada como "Lote" en el front.
class Lote {
  final int numero;
  final String folio; // LOT-2026-0001
  final int? ordenNumero;
  final String ordenFolio; // ORD-2026-042
  final String proceso; // OSAT Estándar
  final EstadoLote estado;
  final int diesIniciales;
  final int diesActivos;
  final int scrap;
  final List<Etapa> etapas;
  final String? fechaRegistro;
  final String? holdMotivo;

  Lote({
    required this.numero,
    required this.folio,
    this.ordenNumero,
    required this.ordenFolio,
    required this.proceso,
    required this.estado,
    required this.diesIniciales,
    required this.diesActivos,
    required this.scrap,
    required this.etapas,
    this.fechaRegistro,
    this.holdMotivo,
  });

  double get yieldPct {
    if (diesIniciales == 0) return 0;
    return (diesActivos / diesIniciales) * 100;
  }

  int get pasosCompletados =>
      etapas.where((e) => e.estado == EstadoEtapa.aprobado).length;

  double get progresoEtapaActual {
    if (etapas.isEmpty) return 0;
    return pasosCompletados / etapas.length;
  }

  Etapa? get etapaActual {
    try {
      return etapas.firstWhere((e) => e.estado == EstadoEtapa.enCurso);
    } catch (_) {
      return null;
    }
  }

  Etapa? get siguienteEtapaPendiente {
    try {
      return etapas.firstWhere((e) => e.estado == EstadoEtapa.pendiente);
    } catch (_) {
      return null;
    }
  }

  bool get enHold => estado == EstadoLote.hold;

  factory Lote.fromJson(Map<String, dynamic> json) {
    final etapasJson = (json['etapas'] as List?) ?? [];
    final etapas = <Etapa>[];
    for (var i = 0; i < etapasJson.length; i++) {
      final e = etapasJson[i] as Map<String, dynamic>;
      etapas.add(Etapa(
        codigoPaso: e['codigo']?.toString() ?? 'P$i',
        nombre: e['nombre'] ?? 'Paso ${i + 1}',
        orden: i + 1,
        estado: estadoEtapaFromString(e['estado']),
        operador: e['operador'],
        maquina: e['maquina'],
        horaInicio: e['hora_inicio'],
        horaFin: e['hora_fin'],
        unidadesDefecto: e['unidades_defecto'] ?? 0,
        observaciones: e['observaciones'],
      ));
    }

    final numero = json['numero'] is int
        ? json['numero']
        : int.tryParse(json['numero'].toString()) ?? 0;

    return Lote(
      numero: numero,
      folio: 'LOT-${numero.toString().padLeft(4, '0')}',
      ordenNumero: json['orden'] is int ? json['orden'] : null,
      ordenFolio: 'ORD-${(json['orden'] ?? '').toString().padLeft(4, '0')}',
      proceso: json['proceso']?.toString() ?? '—',
      estado: estadoLoteFromString(json['estado']?.toString()),
      diesIniciales: json['diesGenerados'] ?? 0,
      diesActivos: json['dies_activos'] ?? json['diesGenerados'] ?? 0,
      scrap: json['scrap'] ?? 0,
      etapas: etapas,
      fechaRegistro: json['fecha_registro'],
      holdMotivo: json['hold_motivo'],
    );
  }
}
