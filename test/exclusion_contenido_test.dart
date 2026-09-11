import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/config/evaluadores_config.dart';
import 'package:evaluador_app/models/evaluacion.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:evaluador_app/services/evaluacion_service.dart';
import 'package:evaluador_app/services/pdf_export_service.dart';
import 'package:evaluador_app/screens/clase_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Evaluacion nueva(String responsable, {String colegio = 'Colegio Central'}) =>
      EvaluacionService()
          .crearDesdePlantilla(evaluadoresDisponibles.first)
          .copyWith(colegio: colegio, responsableNombre: responsable);

  String primerContenido(Evaluacion evaluacion) =>
      evaluacion.clases.first.bloques.first.itemsMarcados.keys.first;

  test('administrador, coordinador y profesor asignado pueden excluir', () {
    for (final credenciales in [
      ('admin', 'cambiar_esto', 'Administrador'),
      ('coordinador', 'cambiar_esto', 'Coordinador de zona'),
      ('demo', 'demo123', 'Profesor demo'),
    ]) {
      final sesion = SesionProvider(AuthConfig.test)
        ..iniciarSesion(usuario: credenciales.$1, password: credenciales.$2);
      final evaluacion = nueva(credenciales.$3);
      expect(
        sesion.excluirContenidoClase(
          evaluacion: evaluacion,
          claseNumero: 1,
          bloque: evaluacion.clases.first.bloques.first.bloqueNombre,
          contenido: primerContenido(evaluacion),
          motivo: 'Solicitud expresa del colegio',
        ),
        isNull,
      );
      expect(
        sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!.exclusiones,
        hasLength(1),
      );
    }
  });

  test('profesor no modifica una clase ajena y el motivo es obligatorio', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'demo', password: 'demo123');
    final ajena = nueva('Otro profesor');
    final bloque = ajena.clases.first.bloques.first.bloqueNombre;
    final contenido = primerContenido(ajena);
    expect(
      sesion.excluirContenidoClase(
        evaluacion: ajena,
        claseNumero: 1,
        bloque: bloque,
        contenido: contenido,
        motivo: 'Solicitud',
      ),
      contains('no te pertenece'),
    );
    final propia = nueva('Profesor demo');
    expect(
      sesion.excluirContenidoClase(
        evaluacion: propia,
        claseNumero: 1,
        bloque: bloque,
        contenido: contenido,
        motivo: '   ',
      ),
      contains('obligatorio'),
    );
    expect(sesion.borradorEvaluacion(propia.evaluadorTipo), isNull);
  });

  testWidgets('cancelar el diálogo no genera cambios', (tester) async {
    final service = EvaluacionService();
    var evaluacion = nueva('Administrador');
    evaluacion = service.seleccionarBloqueCanciones(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloqueNombre: 'Songs 1',
    );
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto')
      ..guardarBorradorEvaluacion(evaluacion);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sesion,
        child: MaterialApp(
          home: ClaseDetailScreen(
            plantilla: evaluadoresDisponibles.first.clases.first,
            evaluacion: evaluacion,
            service: service,
          ),
        ),
      ),
    );
    final excluir = find.text('Excluir para esta clase').first;
    await tester.ensureVisible(excluir);
    await tester.tap(excluir);
    await tester.pumpAndSettle();
    expect(find.text('Confirmar exclusión'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(
      sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!.exclusiones,
      isEmpty,
    );
  });

  test('exclusión es local, persiste en borrador y se puede deshacer', () {
    final plantilla = evaluadoresDisponibles.first;
    final contenidoOriginal =
        plantilla.clases.first.bloques.first.items.first.texto;
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    final evaluacion = nueva('Administrador');
    final bloque = evaluacion.clases.first.bloques.first.bloqueNombre;
    final contenido = primerContenido(evaluacion);
    sesion.excluirContenidoClase(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloque: bloque,
      contenido: contenido,
      motivo: 'Solicitud del colegio',
    );
    final borrador = sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!;
    expect(borrador.exclusiones.single.colegio, 'Colegio Central');
    expect(borrador.exclusiones.single.claseId, '1');
    expect(
      borrador.clases[1].bloques.expand((b) => b.itemsMarcados.keys),
      isNotEmpty,
    );
    expect(
      plantilla.clases.first.bloques.first.items.first.texto,
      contenidoOriginal,
    );
    expect(
      sesion.deshacerExclusionContenido(
        borrador,
        borrador.exclusiones.single.contenidoId,
      ),
      isNull,
    );
    expect(
      sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!.exclusiones,
      isEmpty,
    );
  });

  test('excluidos no son pendientes ni reducen cobertura', () {
    final service = EvaluacionService();
    var evaluacion = nueva('Administrador');
    evaluacion = service.seleccionarBloqueCanciones(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloqueNombre: 'Songs 1',
    );
    final bloque = evaluacion.clases.first.bloques.firstWhere(
      (item) => item.bloqueNombre == 'Songs 1',
    );
    final excluido = bloque.itemsMarcados.keys.first;
    for (final bloqueActual in evaluacion.clases.first.bloquesEvaluables) {
      if (bloqueActual.itemsMarcados.isEmpty) {
        evaluacion = service.actualizarBloque(
          evaluacion: evaluacion,
          claseNumero: 1,
          bloqueNombre: bloqueActual.bloqueNombre,
          marcado: true,
        );
      } else {
        for (final contenido in bloqueActual.itemsMarcados.keys) {
          if (contenido == excluido && bloqueActual.bloqueNombre == 'Songs 1') {
            continue;
          }
          evaluacion = service.actualizarItem(
            evaluacion: evaluacion,
            claseNumero: 1,
            bloqueNombre: bloqueActual.bloqueNombre,
            itemTexto: contenido,
            marcado: true,
          );
        }
      }
    }
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    sesion.excluirContenidoClase(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloque: bloque.bloqueNombre,
      contenido: excluido,
      motivo: 'Solicitud',
    );
    final actualizada = sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!;
    expect(service.cobertura(actualizada, actualizada.clases.first), 1);
    expect(
      service.crearObservacionAutomatica(
        actualizada.clases.first,
        exclusiones: actualizada.exclusiones,
      ),
      isNot(contains(excluido)),
    );
  });

  test('todos excluidos evita división por cero', () {
    final service = EvaluacionService();
    var evaluacion = nueva('Administrador');
    evaluacion = service.seleccionarBloqueCanciones(
      evaluacion: evaluacion,
      claseNumero: 1,
      bloqueNombre: 'Songs 1',
    );
    final clase = evaluacion.clases.first;
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    for (final bloque in clase.bloquesEvaluables) {
      final contenidos = bloque.itemsMarcados.isEmpty
          ? [bloque.bloqueNombre]
          : bloque.itemsMarcados.keys;
      for (final contenido in contenidos) {
        sesion.excluirContenidoClase(
          evaluacion: evaluacion,
          claseNumero: 1,
          bloque: bloque.bloqueNombre,
          contenido: contenido,
          motivo: 'Solicitud',
        );
        evaluacion = sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!;
      }
    }
    expect(
      service.contenidosAplicables(evaluacion, evaluacion.clases.first),
      0,
    );
    expect(service.cobertura(evaluacion, evaluacion.clases.first), 1);
  });

  test('evaluación finalizada no admite cambios', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    final evaluacion = nueva(
      'Administrador',
    ).copyWith(estado: EstadoEvaluacion.completada);
    expect(
      sesion.excluirContenidoClase(
        evaluacion: evaluacion,
        claseNumero: 1,
        bloque: evaluacion.clases.first.bloques.first.bloqueNombre,
        contenido: primerContenido(evaluacion),
        motivo: 'Solicitud',
      ),
      contains('finalizada'),
    );
  });

  test('PDF se genera con y sin exclusiones', () async {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    final base = nueva('Administrador');
    sesion.excluirContenidoClase(
      evaluacion: base,
      claseNumero: 1,
      bloque: base.clases.first.bloques.first.bloqueNombre,
      contenido: primerContenido(base),
      motivo: 'No enseñar esta canción',
      observacion: 'Acuerdo con rectoría',
    );
    final conExclusion = sesion.borradorEvaluacion(base.evaluadorTipo)!;
    final pdf = const PdfExportService();
    final con = await pdf.generarClase(
      evaluacion: conExclusion,
      clase: conExclusion.clases.first,
      evaluador: 'Administrador',
    );
    final sin = await pdf.generarClase(
      evaluacion: base,
      clase: base.clases.first,
      evaluador: 'Administrador',
    );
    expect(con, isNotEmpty);
    expect(sin, isNotEmpty);
    expect(con.length, isNot(equals(sin.length)));
  });
}
