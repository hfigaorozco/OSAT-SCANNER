/// Defecto del catálogo (api_produccion.Defecto)
class Defecto {
  final String codigo;
  final String descripcion;

  Defecto({required this.codigo, required this.descripcion});

  factory Defecto.fromJson(Map<String, dynamic> json) {
    return Defecto(
      codigo: json['codigo'] ?? '',
      descripcion: json['descripcion'] ?? '',
    );
  }
}

enum AccionDefecto { scrap, rework, hold }

String accionDefectoLabel(AccionDefecto a) {
  switch (a) {
    case AccionDefecto.scrap:
      return 'Scrap';
    case AccionDefecto.rework:
      return 'Rework';
    case AccionDefecto.hold:
      return 'Hold';
  }
}

/// Defecto que el operador registra en el formulario (RFM06)
class DefectoRegistrado {
  final String codigoDefecto;
  final String descripcion;
  int cantidad;
  AccionDefecto accion;
  String? fotoPath;

  DefectoRegistrado({
    required this.codigoDefecto,
    required this.descripcion,
    this.cantidad = 1,
    this.accion = AccionDefecto.scrap,
    this.fotoPath,
  });

  Map<String, dynamic> toJson() => {
        'defecto': codigoDefecto,
        'cantidad': cantidad,
        'accion': accion.name,
        'foto': fotoPath,
      };
}
