import 'etapa.dart';

enum EstadoLote { enProceso, aprobado, rechazado, hold, pendiente }

EstadoLote estadoLoteFromString(String? raw) {
  final s = (raw ?? '').toLowerCase();
  // "recha" (código backend de Rechazada) no contiene "rechaz", por eso
  // el chequeo va antes y usa el prefijo corto para calzar con ambos.
  if (s.contains('enhol') || s.contains('hold')) return EstadoLote.hold;
  if (s.contains('recha')) return EstadoLote.rechazado;
  if (s.contains('aprob') || s.contains('complet') || s.contains('termi')) {
    return EstadoLote.aprobado;
  }
  if (s.contains('proceso') || s.contains('activo') || s.contains('proce')) {
    return EstadoLote.enProceso;
  }
  return EstadoLote.pendiente;
}

class Lote {
  final int numero;
  final String folio;
  final int? ordenNumero;
  final String ordenFolio;
  final String proceso;
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

  /// Un lote rechazado quedó fuera de línea: hubo scrap de más y no puede
  /// seguir avanzando por más etapas.
  bool get rechazado => estado == EstadoLote.rechazado;

  bool get puedeCompletarEtapa =>
      !enHold && !rechazado && etapaActual != null;
  bool get puedePonerEnHold => !enHold && !rechazado && etapaActual != null;

  factory Lote.fromJson(Map<String, dynamic> json) {
    final etapasJson = (json['etapas'] as List?) ?? [];
    final etapas = <Etapa>[];

    for (var i = 0; i < etapasJson.length; i++) {
      final e = etapasJson[i] as Map<String, dynamic>;

      // tiempoEstimado puede venir como int (segundos) o string HH:MM:SS
      int? tiempoSeg;
      final te = e['tiempoEstimado'] ?? e['tiempo_estimado_seg'];
      if (te is int) {
        tiempoSeg = te;
      } else if (te is String && te.isNotEmpty) {
        try {
          final parts = te.split(':');
          tiempoSeg = int.parse(parts[0]) * 3600 +
              int.parse(parts[1]) * 60 +
              int.parse(parts.length > 2 ? parts[2] : '0');
        } catch (_) {
          tiempoSeg = null;
        }
      }

      etapas.add(Etapa(
        codigoPaso: e['codigo']?.toString() ?? 'P$i',
        nombre: e['nombre'] ?? 'Paso ${i + 1}',
        orden: i + 1,
        
        estado: estadoEtapaFromString(
          e['estado_paso']?.toString() ?? e['estado']?.toString(),
        ),
        operador: e['operador'],
        maquina: e['maquina'],
        horaInicioIso: e['hora_inicio'],
        horaFin: e['hora_fin'],
        unidadesDefecto: e['unidades_defecto'] ?? 0,
        observaciones: e['observaciones'],
        tiempoEstimadoSeg: tiempoSeg,
      ));
    }

    final numero = json['numero'] is int
        ? json['numero']
        : int.tryParse(json['numero'].toString()) ?? 0;

    return Lote(
      numero: numero,
      folio: 'LOT-${numero.toString().padLeft(4, '0')}',
      ordenNumero: json['orden'] is int ? json['orden'] : null,
      ordenFolio:
          'ORD-${(json['orden'] ?? '').toString().padLeft(4, '0')}',
      proceso: json['proceso']?.toString() ?? '—',
      estado: estadoLoteFromString(
        json['estado_oblea']?.toString() ?? json['estado']?.toString(),
      ),
      diesIniciales: json['diesGenerados'] ?? 0,
      diesActivos: json['dies_activos'] ?? json['diesGenerados'] ?? 0,
      scrap: json['scrap'] ?? 0,
      etapas: etapas,
      fechaRegistro: json['fecha_registro'],
      holdMotivo: json['hold_motivo'],
    );
  }
}
