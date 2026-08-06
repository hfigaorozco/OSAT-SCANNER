import '../models/alerta_operador.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class AlertaService {
  /// Pasar el número de empleado del operador logueado para que el backend
  /// calcule 'es_mi_linea' y ordene sus propias alertas primero — sin
  /// empleadoNumero, el backend regresa la lista sin ese cálculo (útil
  /// solo para debug).
  static Future<List<AlertaOperador>> listar({int? empleadoNumero}) async {
    final url = empleadoNumero != null
        ? '${ApiConfig.alertasOperador}?empleado=$empleadoNumero'
        : ApiConfig.alertasOperador;
    final data = await ApiClient.get(url);
    final lista = data as List;
    return [
      for (final item in lista)
        AlertaOperador.fromJson(item as Map<String, dynamic>),
    ];
  }

  static Future<void> marcarLeida(int numero) async {
    await ApiClient.patch(ApiConfig.updateAlerta(numero), {'estadoAlerta': 'resue'});
  }
}
