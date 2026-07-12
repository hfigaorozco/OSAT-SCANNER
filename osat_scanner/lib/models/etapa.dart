/// Estado de una etapa dentro del proceso de un lote
enum EstadoEtapa { aprobado, enCurso, pendiente, hold, rechazado }

EstadoEtapa estadoEtapaFromString(String? raw) {
  final s = (raw ?? '').toLowerCase();
  if (s.contains('aprob') || s.contains('complet')) return EstadoEtapa.aprobado;
  if (s.contains('curso') || s.contains('proceso') || s.contains('activo')) {
    return EstadoEtapa.enCurso;
  }
  if (s.contains('hold')) return EstadoEtapa.hold;
  if (s.contains('rechaz')) return EstadoEtapa.rechazado;
  return EstadoEtapa.pendiente;
}

class Etapa {
  final String codigoPaso;
  final String nombre;
  final int orden;
  final EstadoEtapa estado;
  final String? operador;
  final String? maquina;
  final String? horaInicio;
  final String? horaFin;
  final int unidadesDefecto;
  final String? observaciones;

  Etapa({
    required this.codigoPaso,
    required this.nombre,
    required this.orden,
    required this.estado,
    this.operador,
    this.maquina,
    this.horaInicio,
    this.horaFin,
    this.unidadesDefecto = 0,
    this.observaciones,
  });

  Etapa copyWith({
    EstadoEtapa? estado,
    String? operador,
    String? maquina,
    String? horaInicio,
    String? horaFin,
    int? unidadesDefecto,
    String? observaciones,
  }) {
    return Etapa(
      codigoPaso: codigoPaso,
      nombre: nombre,
      orden: orden,
      estado: estado ?? this.estado,
      operador: operador ?? this.operador,
      maquina: maquina ?? this.maquina,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      unidadesDefecto: unidadesDefecto ?? this.unidadesDefecto,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  String get metaLine {
    final partes = <String>[];
    if (operador != null && operador!.isNotEmpty) partes.add(operador!);
    if (maquina != null && maquina!.isNotEmpty) partes.add(maquina!);
    if (horaInicio != null) {
      if (horaFin != null) {
        partes.add('$horaInicio–$horaFin');
      } else {
        partes.add('En curso · Iniciado a las $horaInicio');
      }
    }
    return partes.join(' · ');
  }
}
