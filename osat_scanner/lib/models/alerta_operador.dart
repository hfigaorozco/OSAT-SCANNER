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

  factory AlertaOperador.fromJson(Map<String, dynamic> json) {
    return AlertaOperador(
      id: json['pk'] ?? json['numero'] ?? 0,
      tipo: tipoAlertaFromString(json['tipo']),
      titulo: json['titulo'] ?? json['descripcion'] ?? '',
      cuerpo: json['cuerpo'] ?? json['descripcion'] ?? '',
      tiempo: json['tiempo'] ?? '—',
      leida: json['leida'] ?? false,
      loteFolio: json['lote_folio'],
      lotePk: json['lote_pk'],
    );
  }
}
