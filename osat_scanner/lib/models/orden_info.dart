// Mismo vocabulario que Estado_Orden en la web (client/produccion/views.py
// ::_estado_orden_display): abier/proce/cerra/enhol/recha. "Aprobado" es la
// palabra real que usa la web para una orden cerrada (a diferencia de un
// lote, que usa "Terminado"). 'recha' es el rechazo manual de una orden que
// estaba en Hold (distinto del "rechazado" derivado que la web calcula
// cuando una orden cerrada terminó con todos sus lotes rechazados — para
// el operador ambos se ven igual).
enum EstadoOrden { pendiente, enProceso, aprobado, hold, rechazada }

EstadoOrden estadoOrdenFromString(String? raw) {
  final s = (raw ?? '').toLowerCase();
  if (s.contains('recha')) return EstadoOrden.rechazada;
  if (s.contains('enhol') || s.contains('hold')) return EstadoOrden.hold;
  if (s.contains('cerra')) return EstadoOrden.aprobado;
  if (s.contains('proce') || s.contains('activo')) return EstadoOrden.enProceso;
  return EstadoOrden.pendiente; // abier
}

/// Datos ligeros de la Orden a la que pertenece un lote — solo lo necesario
/// para mostrar en la trazabilidad y para listar los lotes hermanos.
class OrdenInfo {
  final int numero;
  final String folio;
  final String proceso;
  final EstadoOrden estado;

  OrdenInfo({
    required this.numero,
    required this.folio,
    required this.proceso,
    required this.estado,
  });

  factory OrdenInfo.fromJson(Map<String, dynamic> json) {
    final numero = json['numero'] is int
        ? json['numero'] as int
        : int.tryParse(json['numero'].toString()) ?? 0;
    return OrdenInfo(
      numero: numero,
      folio: 'ORD-${numero.toString().padLeft(4, '0')}',
      proceso: json['proceso']?.toString() ?? '—',
      estado: estadoOrdenFromString(json['estado']?.toString()),
    );
  }
}
