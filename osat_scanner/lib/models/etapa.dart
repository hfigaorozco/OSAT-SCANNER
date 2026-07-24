enum EstadoEtapa { aprobado, enCurso, pendiente, hold, rechazado }

EstadoEtapa estadoEtapaFromString(String? raw) {
  final s = (raw ?? '').toLowerCase();
  // El orden importa: "No Completado" (nocom) contiene "completado" como
  // substring, así que el chequeo de rechazado debe ir antes que el de
  // aprobado o toda etapa rechazada se mostraría como aprobada.
  if (s.contains('enhol') || s.contains('hold')) return EstadoEtapa.hold;
  if (s.contains('nocom') || s.contains('no complet') || s.contains('rechaz')) {
    return EstadoEtapa.rechazado;
  }
  if (s.contains('aprob') || s.contains('complet') || s.contains('compl')) {
    return EstadoEtapa.aprobado;
  }
  if (s.contains('curso') || s.contains('proceso') || s.contains('activo')) {
    return EstadoEtapa.enCurso;
  }
  return EstadoEtapa.pendiente;
}

class Etapa {
  final String codigoPaso;
  final String nombre;
  final int orden;
  final EstadoEtapa estado;
  final String? operador;
  final String? maquina;
  final String? horaInicioIso;   // HH:MM:SS desde el backend
  final String? horaFin;
  final int unidadesDefecto;
  final String? observaciones;
  final int? tiempoEstimadoSeg;  // segundos del DurationField del backend

  Etapa({
    required this.codigoPaso,
    required this.nombre,
    required this.orden,
    required this.estado,
    this.operador,
    this.maquina,
    this.horaInicioIso,
    this.horaFin,
    this.unidadesDefecto = 0,
    this.observaciones,
    this.tiempoEstimadoSeg,
  });

  Etapa copyWith({
    EstadoEtapa? estado,
    String? operador,
    String? maquina,
    String? horaInicioIso,
    String? horaFin,
    int? unidadesDefecto,
    String? observaciones,
    int? tiempoEstimadoSeg,
  }) {
    return Etapa(
      codigoPaso: codigoPaso,
      nombre: nombre,
      orden: orden,
      estado: estado ?? this.estado,
      operador: operador ?? this.operador,
      maquina: maquina ?? this.maquina,
      horaInicioIso: horaInicioIso ?? this.horaInicioIso,
      horaFin: horaFin ?? this.horaFin,
      unidadesDefecto: unidadesDefecto ?? this.unidadesDefecto,
      observaciones: observaciones ?? this.observaciones,
      tiempoEstimadoSeg: tiempoEstimadoSeg ?? this.tiempoEstimadoSeg,
    );
  }

  String get metaLine {
    final partes = <String>[];
    if (operador != null && operador!.isNotEmpty) partes.add(operador!);
    if (maquina != null && maquina!.isNotEmpty) partes.add(maquina!);
    if (horaInicioIso != null) {
      if (horaFin != null) {
        partes.add('$horaInicioIso–$horaFin');
      } else {
        partes.add('Iniciado a las $horaInicioIso');
      }
    }
    return partes.join(' · ');
  }
}
