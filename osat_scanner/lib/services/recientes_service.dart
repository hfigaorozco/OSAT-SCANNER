import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lote_resumen.dart';

/// Historial local de lotes vistos recientemente (por búsqueda o escaneo).
/// El backend no tiene un endpoint de "historial por operador", así que se
/// guarda en el dispositivo para mostrarlo en Inicio.
class RecientesService {
  static const _key = 'osat_lotes_recientes';
  static const _maxItems = 15;

  static Future<List<LoteResumen>> obtener() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) {
          try {
            return LoteResumen.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<LoteResumen>()
        .toList();
  }

  /// Sube el lote al principio de la lista (o lo mueve si ya estaba) y
  /// recorta el historial a los últimos [_maxItems].
  static Future<void> agregar(LoteResumen lote) async {
    final prefs = await SharedPreferences.getInstance();
    final actuales = await obtener();
    actuales.removeWhere((l) => l.numero == lote.numero);
    actuales.insert(0, lote);
    final recortados = actuales.take(_maxItems).toList();
    await prefs.setStringList(
      _key,
      recortados.map((l) => jsonEncode(l.toJson())).toList(),
    );
  }

  /// El dispositivo suele compartirse entre operadores por turno — al cerrar
  /// sesión se borra el historial para que el siguiente operador no vea los
  /// lotes que revisó el anterior.
  static Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
