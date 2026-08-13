/// Mismos tipos que clasifica el backend (osat_tracer/api_kpi/views.py::
/// AlertasOperadorAPIView): 'kpi' si la alerta viene de un Registro_Kpi,
/// 'produccion' si viene de un Paso_Realizado, 'hold' si el texto de la
/// alerta es un aviso de lote/orden puesto en Hold (reconocido por patrón,
/// ya que esas alertas no tienen FK propio — ver el backend), si no 'stock'.
enum TipoAlertaOperador { stock, produccion, kpi, hold }

TipoAlertaOperador tipoAlertaFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'produccion':
      return TipoAlertaOperador.produccion;
    case 'kpi':
      return TipoAlertaOperador.kpi;
    case 'hold':
      return TipoAlertaOperador.hold;
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
  final int? ordenNumero;
  final String? folioLote;
  final String? folioOrden;
  final String? empleadoNombre;
  final String? kpiNombre;
  final int? kpiValor;
  final int? kpiUmbralVerde;
  final int? kpiUmbralAmarillo;
  final int? kpiUmbralRojo;
  final String? kpiSemaforo;
  final String? pasoNombre;
  final int? pasoScrap;
  final List<String> defectos;

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
    this.ordenNumero,
    this.folioLote,
    this.folioOrden,
    this.empleadoNombre,
    this.kpiNombre,
    this.kpiValor,
    this.kpiUmbralVerde,
    this.kpiUmbralAmarillo,
    this.kpiUmbralRojo,
    this.kpiSemaforo,
    this.pasoNombre,
    this.pasoScrap,
    this.defectos = const [],
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
      ordenNumero: ordenNumero,
      folioLote: folioLote,
      folioOrden: folioOrden,
      empleadoNombre: empleadoNombre,
      kpiNombre: kpiNombre,
      kpiValor: kpiValor,
      kpiUmbralVerde: kpiUmbralVerde,
      kpiUmbralAmarillo: kpiUmbralAmarillo,
      kpiUmbralRojo: kpiUmbralRojo,
      kpiSemaforo: kpiSemaforo,
      pasoNombre: pasoNombre,
      pasoScrap: pasoScrap,
      defectos: defectos,
    );
  }

  /// El endpoint /v1/list/alertas_operador/ ya viene clasificado, priorizado
  /// y con la línea/lote/orden/kpi/paso resueltos desde el backend (misma
  /// fuente que usa la web, ver _construir_alertas_base en
  /// osat_tracer/api_kpi/views.py) — no hay que adivinar nada del lado del
  /// cliente.
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
      ordenNumero: json['orden_numero'] as int?,
      folioLote: json['folio_lote'] as String?,
      folioOrden: json['folio_orden'] as String?,
      empleadoNombre: json['empleado_nombre'] as String?,
      kpiNombre: json['kpi_nombre'] as String?,
      kpiValor: json['kpi_valor'] as int?,
      kpiUmbralVerde: json['kpi_umbral_verde'] as int?,
      kpiUmbralAmarillo: json['kpi_umbral_amarillo'] as int?,
      kpiUmbralRojo: json['kpi_umbral_rojo'] as int?,
      kpiSemaforo: json['kpi_semaforo'] as String?,
      pasoNombre: json['paso_nombre'] as String?,
      pasoScrap: json['paso_scrap'] as int?,
      defectos: (json['defectos'] as List?)?.map((d) => d.toString()).toList() ?? const [],
    );
  }
}
