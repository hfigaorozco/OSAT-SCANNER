import 'package:flutter_test/flutter_test.dart';
import 'package:osat_tracer_mobile/models/etapa.dart';
import 'package:osat_tracer_mobile/models/lote.dart';

void main() {
  test('estado_oblea bloquea una etapa en curso', () {
    final lote = Lote.fromJson({
      'numero': 7,
      'estado_oblea': 'enhol',
      'etapas': [
        {'codigo': 'P1', 'nombre': 'Inspección', 'estado_paso': 'proce'},
      ],
    });

    expect(lote.estado, EstadoLote.hold);
    expect(lote.etapaActual?.estado, EstadoEtapa.enCurso);
    expect(lote.puedeCompletarEtapa, isFalse);
    expect(lote.puedePonerEnHold, isFalse);
  });

  test('estado_paso se usa para la trazabilidad', () {
    final lote = Lote.fromJson({
      'numero': 8,
      'estado_oblea': 'proce',
      'etapas': [
        {'codigo': 'P1', 'nombre': 'Preparación', 'estado_paso': 'compl'},
        {'codigo': 'P2', 'nombre': 'Inspección', 'estado_paso': 'proce'},
      ],
    });

    expect(lote.pasosCompletados, 1);
    expect(lote.etapaActual?.codigoPaso, 'P2');
    expect(lote.puedeCompletarEtapa, isTrue);
  });
}
