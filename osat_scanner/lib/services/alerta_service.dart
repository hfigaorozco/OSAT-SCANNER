import '../models/alerta_operador.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class AlertaService {
  static Future<List<AlertaOperador>> listar() async {
    final data = await ApiClient.get(ApiConfig.historialAlertas);
    return (data as List)
        .map((a) => AlertaOperador.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  static Future<void> marcarLeida(int id) async {
    // Ajustar endpoint cuando el backend lo implemente
    await ApiClient.patch('${ApiConfig.alertas}$id/', {'leida': true});
  }
}
