import 'package:evaluador_app/config/plan_estudio_parvulos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el plan de Párvulos contiene sus cuatro períodos', () {
    expect(planEstudioParvulos.keys, containsAll([1, 2, 3, 4]));
    expect(planEstudioParvulos, hasLength(4));
  });

  test('cada período contiene comandos, canciones y vocabulario', () {
    for (final periodo in planEstudioParvulos.values) {
      expect(
        periodo.categorias.map((categoria) => categoria.nombre),
        containsAll(['Commands', 'Songs', 'Vocabulary']),
      );
      expect(
        periodo.categorias.every((categoria) => categoria.items.isNotEmpty),
        isTrue,
      );
    }
  });
}
