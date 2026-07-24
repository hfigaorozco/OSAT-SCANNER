enum TipoAlertaOperador { hold, stock, kpi, liberado, scrap, mantenimiento, info }

TipoAlertaOperador tipoAlertaFromString(String? raw) {
  final s = (raw ?? '').toLowerCase();
  switch (s) {
    case 'hold':
      return TipoAlertaOperador.hold;
    case 'stock':
      return TipoAlertaOperador.stock;
    case 'kpi':
      return TipoAlertaOperador.kpi;
    case 'liberado':
      return TipoAlertaOperador.liberado;
    case 'scrap':
      return TipoAlertaOperador.scrap;
    case 'mantenimiento':
      return TipoAlertaOperador.mantenimiento;
    default:
      return TipoAlertaOperador.info;
  }
}

class AlertaOperador {
  final int id;
  final TipoAlertaOperador tipo;
  final String titulo;
  final String cuerpo;
  final String tiempo;
  final bool leida;
  final String? loteFolio;
  final int? lotePk;

  AlertaOperador({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    required this.tiempo,
    required this.leida,
    this.loteFolio,
    this.lotePk,
  });

  /// El endpoint /v1/list/alertas/ del backend solo expone hoy
  /// 'descripcion' y 'estadoAlerta' (no pk, tipo, ni lote asociado), así
  /// que 'leida' se aproxima con estadoAlerta ('resue' = resuelta) y el
  /// id usa el índice de la lista mientras el backend no exponga el pk.
  factory AlertaOperador.fromJson(Map<String, dynamic> json, {int indice = 0}) {
    final estadoAlerta = json['estadoAlerta']?.toString().toLowerCase() ?? '';
    return AlertaOperador(
      id: json['pk'] ?? json['numero'] ?? indice,
      tipo: tipoAlertaFromString(json['tipo']),
      titulo: json['titulo'] ?? json['descripcion'] ?? '',
      cuerpo: json['cuerpo'] ?? json['descripcion'] ?? '',
      tiempo: json['tiempo'] ?? '—',
      leida: json['leida'] ?? estadoAlerta.contains('resue'),
      loteFolio: json['lote_folio'],
      lotePk: json['lote_pk'],
    );
  }
}
