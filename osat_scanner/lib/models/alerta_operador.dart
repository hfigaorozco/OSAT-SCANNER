/// Mismos 3 tipos que clasifica el backend (osat_tracer/api_kpi/views.py::
/// AlertasOperadorAPIView, misma regla que client/kpi/views.py::_build_alertas
/// en la web): 'kpi' si la alerta viene de un Registro_Kpi, 'produccion' si
/// viene de un Paso_Realizado, si no 'stock'.
enum TipoAlertaOperador { stock, produccion, kpi }

TipoAlertaOperador tipoAlertaFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'produccion':
      return TipoAlertaOperador.produccion;
    case 'kpi':
      return TipoAlertaOperador.kpi;
    default:
      return TipoAlertaOperador.stock;
  }
}

class AlertaOperador {
  final int numero;
  final TipoAlertaOperador tipo;
  final String descripcion;
  final String fecha;
  final String hora;
  final bool leida;
  final String? lineaCodigo;
  final String? lineaNombre;
  final bool? esMiLinea;
  final int prioridad;
  final int? loteId;

  AlertaOperador({
    required this.numero,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
    required this.hora,
    required this.leida,
    required this.prioridad,
    this.lineaCodigo,
    this.lineaNombre,
    this.esMiLinea,
    this.loteId,
  });

  String get tiempo {
    if (fecha.isNotEmpty && hora.isNotEmpty) return '$fecha $hora';
    return fecha.isNotEmpty ? fecha : (hora.isNotEmpty ? hora : '—');
  }

  AlertaOperador copyWith({bool? leida}) {
    return AlertaOperador(
      numero: numero,
      tipo: tipo,
      descripcion: descripcion,
      fecha: fecha,
      hora: hora,
      leida: leida ?? this.leida,
      prioridad: prioridad,
      lineaCodigo: lineaCodigo,
      lineaNombre: lineaNombre,
      esMiLinea: esMiLinea,
      loteId: loteId,
    );
  }

  /// El endpoint /v1/list/alertas_operador/ ya viene clasificado, priorizado
  /// y con la línea resuelta desde el backend — no hay que adivinar nada
  /// del lado del cliente.
  factory AlertaOperador.fromJson(Map<String, dynamic> json) {
    return AlertaOperador(
      numero: json['numero'] as int? ?? 0,
      tipo: tipoAlertaFromString(json['tipo'] as String?),
      descripcion: json['descripcion'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      hora: json['hora'] as String? ?? '',
      leida: json['leida'] == true,
      prioridad: json['prioridad'] as int? ?? 0,
      lineaCodigo: json['linea_codigo'] as String?,
      lineaNombre: json['linea_nombre'] as String?,
      esMiLinea: json['es_mi_linea'] as bool?,
      loteId: json['oblea_id'] as int?,
    );
  }
}
