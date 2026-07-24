import 'lote.dart';

/// Versión ligera de [Lote] para listas (resultados de búsqueda, historial
/// de recientes) donde no se necesita cargar la trazabilidad completa.
class LoteResumen {
  final int numero;
  final String folio;
  final EstadoLote estado;

  LoteResumen({
    required this.numero,
    required this.folio,
    required this.estado,
  });

  factory LoteResumen.fromOblea(Map<String, dynamic> json) {
    final numero = json['numero'] is int
        ? json['numero'] as int
        : int.tryParse(json['numero'].toString()) ?? 0;
    return LoteResumen(
      numero: numero,
      folio: 'LOT-${numero.toString().padLeft(4, '0')}',
      estado: estadoLoteFromString(json['estado']?.toString()),
    );
  }

  factory LoteResumen.fromLote(Lote lote) => LoteResumen(
        numero: lote.numero,
        folio: lote.folio,
        estado: lote.estado,
      );

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'folio': folio,
        'estado': estado.name,
      };

  factory LoteResumen.fromJson(Map<String, dynamic> json) => LoteResumen(
        numero: json['numero'] as int,
        folio: json['folio'] as String,
        estado: EstadoLote.values.firstWhere(
          (e) => e.name == json['estado'],
          orElse: () => EstadoLote.pendiente,
        ),
      );
}
