import 'package:evaluador_app/config/planes_estudio_adicionales.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('todos los grados tienen cuatro períodos con contenido evaluable', () {
    expect(
      planesEstudioPorGrado.keys,
      containsAll(['Párvulos', 'Prejardín', 'Jardín', 'Transición']),
    );

    for (final planGrado in planesEstudioPorGrado.values) {
      expect(planGrado.keys, containsAll([1, 2, 3, 4]));
      for (final periodo in planGrado.values) {
        expect(periodo.categorias, isNotEmpty);
        expect(
          periodo.categorias.expand((categoria) => categoria.items),
          isNotEmpty,
        );
      }
    }
  });

  test(
    'los nuevos planes incluyen diálogos, comandos, vocabulario y canciones',
    () {
      for (final grado in ['Prejardín', 'Jardín', 'Transición']) {
        for (final periodo in planesEstudioPorGrado[grado]!.values) {
          final categorias = periodo.categorias.map((item) => item.nombre);
          expect(
            categorias,
            containsAll(['Commands', 'Dialogue', 'Vocabulary', 'Songs']),
          );
        }
      }
    },
  );

  test(
    'el vocabulario se agrupa por temas con pregunta y respuesta en inglés',
    () {
      for (final planGrado in planesEstudioPorGrado.values) {
        for (final periodo in planGrado.values) {
          final vocabulario = periodo.categorias.firstWhere(
            (categoria) => categoria.nombre == 'Vocabulary',
          );
          expect(vocabulario.items.every((item) => item.tema != null), isTrue);
          final guias = vocabulario.items.where((item) => item.soloIngles);
          expect(guias, isNotEmpty);
          expect(guias.every((item) => item.espanol == null), isTrue);
        }
      }
    },
  );
}
