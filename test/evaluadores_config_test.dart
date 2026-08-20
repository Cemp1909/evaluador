import 'package:evaluador_app/config/evaluadores_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las plantillas contienen todas las clases documentadas', () {
    final preescolar = evaluadoresDisponibles.first;
    final primaria = evaluadoresDisponibles.last;

    expect(preescolar.clases, hasLength(6));
    expect(primaria.clases, hasLength(11));
    expect(
      evaluadoresDisponibles
          .expand((evaluador) => evaluador.clases)
          .any((clase) => clase.contenidoPendiente),
      isFalse,
    );
    expect(
      evaluadoresDisponibles
          .expand((evaluador) => evaluador.clases)
          .every((clase) => clase.bloques.isNotEmpty),
      isTrue,
    );
  });

  test('la clase 1 de preescolar no repite canciones entre sus bloques', () {
    final clase = evaluadoresDisponibles.first.clases.firstWhere(
      (clase) => clase.numero == 1,
    );
    final canciones = clase.bloques
        .where((bloque) => bloque.nombre.startsWith('Songs'))
        .expand((bloque) => bloque.items)
        .map((item) => item.texto.toLowerCase())
        .toList();

    expect(canciones.toSet().length, canciones.length);
  });
}
