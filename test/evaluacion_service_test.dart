import 'package:evaluador_app/config/evaluadores_config.dart';
import 'package:evaluador_app/services/evaluacion_service.dart';
import 'package:evaluador_app/models/firma_docente.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('genera observaciones con cada contenido no enseñado', () {
    final service = EvaluacionService();
    var evaluacion = service.crearDesdePlantilla(evaluadoresDisponibles.first);

    expect(
      service.crearObservacionAutomatica(evaluacion.clases.first),
      contains('Hello song'),
    );

    evaluacion = service.actualizarItem(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloqueNombre: 'Songs 1',
      itemTexto: 'Hello song',
      marcado: true,
    );

    final observaciones = service.crearObservacionAutomatica(
      evaluacion.clases.first,
    );
    expect(observaciones, isNot(contains('Songs 1: Hello song,')));
    expect(observaciones, contains('Hello dear teacher'));
  });

  test(
    'completa el bloque solo cuando todos sus contenidos están marcados',
    () {
      final service = EvaluacionService();
      var evaluacion = service.crearDesdePlantilla(
        evaluadoresDisponibles.first,
      );
      final canciones = evaluadoresDisponibles.first.clases.first.bloques.first;

      for (final item in canciones.items) {
        evaluacion = service.actualizarItem(
          evaluacion: evaluacion,
          claseNumero: 1,
          bloqueNombre: canciones.nombre,
          itemTexto: item.texto,
          marcado: true,
        );
      }

      expect(evaluacion.clases.first.bloques.first.marcado, isTrue);
    },
  );

  test('conserva las observaciones escritas por la docente', () {
    final service = EvaluacionService();
    var evaluacion = service.crearDesdePlantilla(evaluadoresDisponibles.first);

    evaluacion = service.actualizarObservaciones(
      evaluacion: evaluacion,
      claseNumero: 1,
      observaciones: 'El grupo necesita reforzar pronunciación.',
    );
    evaluacion = service.actualizarItem(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloqueNombre: 'Songs 1',
      itemTexto: 'Hello song',
      marcado: true,
    );

    expect(
      evaluacion.clases.first.observaciones,
      'El grupo necesita reforzar pronunciación.',
    );
  });

  test('guarda firmas del representante y docentes asistentes', () {
    final service = EvaluacionService();
    var evaluacion = service.crearDesdePlantilla(evaluadoresDisponibles.first);

    evaluacion = service.actualizarFirmaRepresentante(
      evaluacion: evaluacion,
      claseNumero: 1,
      firmaBase64: 'firma-representante',
    );
    evaluacion = service.agregarFirmaAsistente(
      evaluacion: evaluacion,
      claseNumero: 1,
      firma: const FirmaDocente(
        nombre: 'Docente asistente',
        firmaBase64: 'firma-asistente',
      ),
    );

    expect(evaluacion.clases.first.firmaDocenteUrl, 'firma-representante');
    expect(evaluacion.clases.first.firmasAsistentes, hasLength(1));
  });

  test('limita la evidencia fotográfica a dos imágenes', () {
    final service = EvaluacionService();
    var evaluacion = service.crearDesdePlantilla(evaluadoresDisponibles.first);

    evaluacion = service.agregarFoto(evaluacion, 'foto-1');
    evaluacion = service.agregarFoto(evaluacion, 'foto-2');
    evaluacion = service.agregarFoto(evaluacion, 'foto-3');

    expect(evaluacion.fotosUrls, ['foto-1', 'foto-2']);
  });
}
