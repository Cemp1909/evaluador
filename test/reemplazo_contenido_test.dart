import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/config/evaluadores_config.dart';
import 'package:evaluador_app/models/evaluacion.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:evaluador_app/services/evaluacion_service.dart';
import 'package:evaluador_app/services/pdf_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Evaluacion nueva(String responsable, {String colegio = 'Colegio Central'}) =>
      EvaluacionService()
          .crearDesdePlantilla(evaluadoresDisponibles.first)
          .copyWith(colegio: colegio, responsableNombre: responsable);

  test('cambio temporal se guarda sin modificar la plantilla', () {
    final plantilla = evaluadoresDisponibles.first;
    final original = plantilla.clases.first.bloques.first.items.first.texto;
    final evaluacion = nueva('Administrador');
    final bloque = evaluacion.clases.first.bloques.first.bloqueNombre;
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');

    expect(
      sesion.reemplazarContenidoClase(
        evaluacion: evaluacion,
        claseNumero: 1,
        bloque: bloque,
        contenido: original,
        nombreTemporal: 'Nueva canción del colegio',
      ),
      isNull,
    );
    final borrador = sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!;
    expect(borrador.reemplazos.single.nombreOriginal, original);
    expect(
      borrador.reemplazos.single.nombreTemporal,
      'Nueva canción del colegio',
    );
    expect(borrador.reemplazos.single.colegio, 'Colegio Central');
    expect(plantilla.clases.first.bloques.first.items.first.texto, original);
    expect(
      borrador.clases[1].bloques.expand((b) => b.itemsMarcados.keys),
      isNot(contains('Nueva canción del colegio')),
    );
  });

  test('reemplazo sigue contando y puede marcarse como enseñado', () {
    final service = EvaluacionService();
    var evaluacion = nueva('Administrador');
    evaluacion = service.seleccionarBloqueCanciones(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloqueNombre: 'Songs 1',
    );
    final bloque = evaluacion.clases.first.bloques.firstWhere(
      (bloque) => bloque.bloqueNombre == 'Songs 1',
    );
    final original = bloque.itemsMarcados.keys.first;
    final totalAntes = service.contenidosAplicables(
      evaluacion,
      evaluacion.clases.first,
    );
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    sesion.reemplazarContenidoClase(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloque: bloque.bloqueNombre,
      contenido: original,
      nombreTemporal: 'Canción alternativa',
    );
    evaluacion = sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!;
    evaluacion = service.actualizarItem(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloqueNombre: bloque.bloqueNombre,
      itemTexto: original,
      marcado: true,
    );
    expect(
      service.contenidosAplicables(evaluacion, evaluacion.clases.first),
      totalAntes,
    );
    expect(service.contenidosEnsenados(evaluacion, evaluacion.clases.first), 1);
  });

  test('administrador, coordinador y profesor asignado pueden cambiar', () {
    for (final datos in [
      ('admin', 'cambiar_esto', 'Administrador'),
      ('coordinador', 'cambiar_esto', 'Coordinador de zona'),
      ('demo', 'demo123', 'Profesor demo'),
    ]) {
      final sesion = SesionProvider(AuthConfig.test)
        ..iniciarSesion(usuario: datos.$1, password: datos.$2);
      final evaluacion = nueva(datos.$3);
      final bloque = evaluacion.clases.first.bloques.first;
      expect(
        sesion.reemplazarContenidoClase(
          evaluacion: evaluacion,
          claseNumero: 1,
          bloque: bloque.bloqueNombre,
          contenido: bloque.itemsMarcados.keys.first,
          nombreTemporal: 'Contenido alternativo',
        ),
        isNull,
      );
    }
  });

  test('profesor no cambia clase ajena ni evaluación finalizada', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'demo', password: 'demo123');
    final ajena = nueva('Otro profesor');
    final bloque = ajena.clases.first.bloques.first;
    expect(
      sesion.reemplazarContenidoClase(
        evaluacion: ajena,
        claseNumero: 1,
        bloque: bloque.bloqueNombre,
        contenido: bloque.itemsMarcados.keys.first,
        nombreTemporal: 'Alternativa',
      ),
      contains('no te pertenece'),
    );
    final finalizada = nueva(
      'Profesor demo',
    ).copyWith(estado: EstadoEvaluacion.completada);
    expect(
      sesion.reemplazarContenidoClase(
        evaluacion: finalizada,
        claseNumero: 1,
        bloque: bloque.bloqueNombre,
        contenido: bloque.itemsMarcados.keys.first,
        nombreTemporal: 'Alternativa',
      ),
      contains('finalizada'),
    );
  });

  test('puede restaurarse antes de finalizar', () {
    final evaluacion = nueva('Administrador');
    final bloque = evaluacion.clases.first.bloques.first;
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    sesion.reemplazarContenidoClase(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloque: bloque.bloqueNombre,
      contenido: bloque.itemsMarcados.keys.first,
      nombreTemporal: 'Alternativa',
    );
    final borrador = sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!;
    expect(
      sesion.deshacerReemplazoContenido(
        borrador,
        borrador.reemplazos.single.contenidoId,
      ),
      isNull,
    );
    expect(
      sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!.reemplazos,
      isEmpty,
    );
  });

  test('PDF se genera con el cambio temporal guardado', () async {
    final evaluacion = nueva('Administrador');
    final bloque = evaluacion.clases.first.bloques.first;
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    sesion.reemplazarContenidoClase(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloque: bloque.bloqueNombre,
      contenido: bloque.itemsMarcados.keys.first,
      nombreTemporal: 'Canción solicitada por el colegio',
    );
    final actualizada = sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!;
    final bytes = await const PdfExportService().generarClase(
      evaluacion: actualizada,
      clase: actualizada.clases.first,
      evaluador: 'Administrador',
    );
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1000));
  });
}
