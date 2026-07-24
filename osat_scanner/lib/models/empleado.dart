class Empleado {
  final int numero;
  final String nombre;
  final String primerApell;
  final String seguApell;
  final String username;
  final String email;
  final String rol;
  final String estado;

  Empleado({
    required this.numero,
    required this.nombre,
    required this.primerApell,
    required this.seguApell,
    required this.username,
    required this.email,
    required this.rol,
    required this.estado,
  });

  String get nombreCompleto => '$nombre $primerApell $seguApell';

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      numero: json['numero'] ?? 0,
      nombre: json['nombre'] ?? '',
      primerApell: json['primerApell'] ?? '',
      seguApell: json['seguApell'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol']?.toString() ?? 'Operador',
      estado: json['estado']?.toString() ?? '—',
    );
  }
}
