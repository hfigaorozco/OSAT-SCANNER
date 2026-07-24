import '../models/alerta_operador.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class AlertaService {
  static Future<List<AlertaOperador>> listar() async {
    final data = await ApiClient.get(ApiConfig.alertas);
    final lista = data as List;
    return [
      for (var i = 0; i < lista.length; i++)
        AlertaOperador.fromJson(lista[i] as Map<String, dynamic>, indice: i),
    ];
  }

  /// El modelo Alerta del backend todavía no tiene un campo "leida"
  /// (solo 'estadoAlerta': resuelta/sin resolver) ni expone el pk en el
  /// listado, así que esto queda pendiente de soporte real del backend.
  static Future<void> marcarLeida(int id) async {
    await ApiClient.patch(ApiConfig.updateAlerta(id), {'estadoAlerta': 'resue'});
  }
}
