import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/config/evaluadores_config.dart';
import 'package:evaluador_app/models/configuracion_notas.dart';
import 'package:evaluador_app/models/evaluacion.dart';
import 'package:evaluador_app/models/docente_colegio.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:evaluador_app/models/evaluacion_clase.dart';
import 'package:evaluador_app/models/student_knowledge_report.dart';
import 'package:evaluador_app/models/visita_programada.dart';
import 'package:evaluador_app/services/evaluacion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profesor responsable registra docentes desde su propia clase', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'demo', password: 'demo123');
    final evaluacion = EvaluacionService()
        .crearDesdePlantilla(evaluadoresDisponibles.first)
        .copyWith(colegio: 'Colegio Nuevo', responsableNombre: 'Profesor demo');
    expect(
      sesion.registrarDocentesDesdeClase(
        evaluacion,
        preescolar: const ['Marta'],
        primaria: const ['José'],
      ),
      isNull,
    );
    expect(
      sesion.docentesColegio('Colegio Nuevo', nivel: NivelDocente.preescolar),
      ['Marta'],
    );
    expect(
      sesion.registrarDocentesDesdeClase(
        evaluacion.copyWith(responsableNombre: 'Otro profesor'),
        preescolar: const ['Marta'],
        primaria: const [],
      ),
      contains('responsable de la clase'),
    );
  });

  test('asigna por colegio, normaliza duplicados y exige permisos', () {
    final sesion = SesionProvider(AuthConfig.test);
    expect(sesion.asignarDocentesColegio('Colegio A', ['Ana']), isNotNull);
    sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    expect(
      sesion.asignarDocentesColegio(' Colegio A ', [
        'Ana',
        ' ana ',
        '',
        'Luis',
      ]),
      isNull,
    );
    expect(sesion.docentesColegio('COLEGIO A'), ['ana', 'Luis']);
    expect(
      sesion.asignarDocentesColegioPorNivel(
        'Colegio A',
        preescolar: const ['Ana'],
        primaria: const ['Luis'],
      ),
      isNull,
    );
    expect(
      sesion.docentesColegio('Colegio A', nivel: NivelDocente.preescolar),
      ['Ana'],
    );
    expect(sesion.docentesColegio('Colegio A', nivel: NivelDocente.primaria), [
      'Luis',
    ]);
    expect(
      sesion.nivelDocenteColegio('Colegio A', 'luis'),
      NivelDocente.primaria,
    );
    expect(sesion.docentesColegio('Colegio B'), isEmpty);
    expect(sesion.asignarDocentesColegio(' ', ['Ana']), isNotNull);
  });

  test('conserva el historial cuando un profesor cambia de colegio', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    final inicio = DateTime(2026, 1, 10);
    final traslado = DateTime(2026, 6, 1);

    expect(
      sesion.asignarDocentesColegioPorNivel(
        'Colegio A',
        preescolar: const ['Ana'],
        primaria: const [],
        fechaInicio: inicio,
      ),
      isNull,
    );
    final plantilla = EvaluacionService().crearDesdePlantilla(
      evaluadoresDisponibles.first,
    );
    final evaluacionAnterior = Evaluacion(
      evaluadorTipo: plantilla.evaluadorTipo,
      colegio: 'Colegio A',
      fechaCreacion: DateTime(2026, 5, 1),
      clases: [
        plantilla.clases.first.copyWith(asistencia: const {'Ana': true}),
        ...plantilla.clases.skip(1),
      ],
    );
    expect(sesion.guardarBorradorEvaluacion(evaluacionAnterior), isNull);
    expect(
      sesion.transferirDocente(
        profesor: 'Ana',
        colegioDestino: 'Colegio B',
        nivel: NivelDocente.primaria,
        fecha: traslado,
      ),
      isNull,
    );

    expect(sesion.docentesColegio('Colegio A'), isEmpty);
    expect(sesion.docentesColegio('Colegio B'), ['Ana']);
    final anterior = sesion
        .asignacionesDocentesColegio('Colegio A', incluirInactivas: true)
        .single;
    expect(anterior.activo, isFalse);
    expect(anterior.fechaInicio, inicio);
    expect(anterior.fechaFin, traslado);
    final actual = sesion.asignacionesDocentesColegio('Colegio B').single;
    expect(actual.nivel, NivelDocente.primaria);
    expect(actual.fechaInicio, traslado);
    expect(sesion.historialAsignacionesDocente('ana'), hasLength(2));
    final estados = sesion.estadoEvaluacionesProfesores();
    expect(
      estados.firstWhere((item) => item.colegio == 'Colegio A').clasesAsistidas,
      1,
    );
    expect(
      estados.firstWhere((item) => item.colegio == 'Colegio B').clasesAsistidas,
      0,
    );
  });

  test('profesor nuevo inicia sin registros retroactivos', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    final servicio = EvaluacionService();
    final evaluacionAnterior = servicio
        .crearDesdePlantilla(evaluadoresDisponibles.first)
        .copyWith(colegio: 'Colegio Nuevo');
    final claseAnterior = evaluacionAnterior.clases.first.copyWith(
      asistencia: const {'Marta': true},
    );
    sesion.guardarBorradorEvaluacion(
      evaluacionAnterior.copyWith(
        clases: [claseAnterior, ...evaluacionAnterior.clases.skip(1)],
      ),
    );
    final ingreso = evaluacionAnterior.fechaCreacion.add(
      const Duration(days: 1),
    );

    expect(
      sesion.asignarDocentesColegioPorNivel(
        'Colegio Nuevo',
        preescolar: const ['Marta'],
        primaria: const [],
        fechaInicio: ingreso,
      ),
      isNull,
    );
    final estado = sesion.estadoEvaluacionesProfesores().single;
    expect(estado.fechaInicio, ingreso);
    expect(estado.clasesAsistidas, 0);
    expect(estado.contenidosEvaluables, isEmpty);
    expect(estado.estadoProceso, 'Sin capacitación iniciada');
    expect(
      sesion.seguimientoProfesores('Colegio Nuevo').single.clasesAsistidas,
      0,
    );
  });

  test('asignación docente conserva nivel y fechas en JSON', () {
    final asignacion = DocenteColegio(
      nombre: 'Laura',
      nivel: NivelDocente.primaria,
      fechaInicio: DateTime(2026, 2, 3),
      fechaFin: DateTime(2026, 8, 9),
    );

    final restaurada = DocenteColegio.fromJson(asignacion.toJson());
    expect(restaurada.nombre, 'Laura');
    expect(restaurada.nivel, NivelDocente.primaria);
    expect(restaurada.fechaInicio, DateTime(2026, 2, 3));
    expect(restaurada.fechaFin, DateTime(2026, 8, 9));
    expect(restaurada.activo, isFalse);
  });

  test(
    'asistencia conserva ausencias, no altera otras clases y sobrevive JSON',
    () {
      const primera = EvaluacionClase(
        claseNumero: 1,
        bloques: [],
        asistencia: {'Ana': true, 'Luis': false},
      );
      const segunda = EvaluacionClase(claseNumero: 2, bloques: []);
      final restaurada = EvaluacionClase.fromJson(primera.toJson());
      expect(restaurada.asistencia, {'Ana': true, 'Luis': false});
      expect(
        primera.copyWith(observaciones: 'Clase realizada').asistencia,
        primera.asistencia,
      );
      expect(segunda.asistencia, isEmpty);
      expect(EvaluacionClase.fromJson({'clase_numero': 3}).asistencia, isEmpty);
    },
  );

  test('consolida seguimiento de asistencia, contenidos y salón', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    expect(
      sesion.asignarDocentesColegioPorNivel(
        'Colegio A',
        preescolar: const ['Ana', 'Luis'],
        primaria: const [],
        fechaInicio: DateTime(2026, 1, 1),
      ),
      isNull,
    );
    final servicio = EvaluacionService();
    var evaluacion = servicio
        .crearDesdePlantilla(evaluadoresDisponibles.first)
        .copyWith(colegio: 'Colegio A');
    final primera = evaluacion.clases.first;
    final bloqueEvaluable = primera.bloques.firstWhere(
      (bloque) => !EvaluacionClase.esOpcionCanciones(bloque.bloqueNombre),
    );
    evaluacion = servicio.actualizarBloque(
      evaluacion: evaluacion,
      claseNumero: primera.claseNumero,
      bloqueNombre: bloqueEvaluable.bloqueNombre,
      marcado: true,
    );
    evaluacion = evaluacion.copyWith(
      clases: [
        evaluacion.clases.first.copyWith(
          asistencia: const {'Ana': true, 'Luis': false},
          observaciones: 'Participó activamente',
        ),
        ...evaluacion.clases.skip(1),
      ],
      estado: EstadoEvaluacion.enProgreso,
    );
    expect(sesion.guardarBorradorEvaluacion(evaluacion), isNull);
    expect(
      sesion.guardarReporteConocimiento(
        StudentKnowledgeReport(
          fechaHora: DateTime(2026, 9, 12),
          docente: 'Administrador',
          profesorEvaluado: 'Ana',
          colegio: 'Colegio A',
          grado: 'Jardín',
          periodo: 2,
          evaluaciones: const {},
          compromiso: 'Reforzar vocabulario',
          nota: 4.2,
          firmaColegio: 'firma-1',
          firmaDocenteColegio: 'firma-2',
          firmaDocenteCourseChild: 'firma-3',
        ),
      ),
      isNull,
    );

    final ana = sesion
        .seguimientoProfesores('colegio a')
        .firstWhere((resumen) => resumen.profesor == 'Ana');
    expect(ana.clasesAsistidas, 1);
    expect(ana.inasistencias, 0);
    expect(ana.clasesPendientes, evaluacion.clases.length - 1);
    expect(ana.contenidosEnsenados, greaterThan(0));
    expect(ana.avancesSalon, ['Jardín · Período 2: 4.2 (Alto)']);
    expect(ana.observaciones, contains('Clase 1: Participó activamente'));

    final luis = sesion
        .seguimientoProfesores('Colegio A')
        .firstWhere((resumen) => resumen.profesor == 'Luis');
    expect(luis.clasesAsistidas, 0);
    expect(luis.inasistencias, 1);
    expect(
      sesion.seguimientoProfesores('Colegio A').map((item) => item.profesor),
      isNot(contains('Administrador')),
    );
    expect(sesion.historialSalon('Colegio A', 'Jardín'), hasLength(1));
    expect(
      sesion.historialSalon('Colegio A', 'Jardín', profesor: 'Ana'),
      hasLength(1),
    );

    var estadoFinal = sesion.estadoEvaluacionesProfesores().firstWhere(
      (estado) => estado.profesor == 'Ana',
    );
    expect(estadoFinal.habilitada, isFalse);
    expect(estadoFinal.contenidosEvaluables, isNotEmpty);

    for (final periodo in [1, 3, 4]) {
      sesion.guardarReporteConocimiento(
        StudentKnowledgeReport(
          fechaHora: DateTime(2026, periodo),
          docente: 'Administrador',
          profesorEvaluado: 'Ana',
          colegio: 'Colegio A',
          grado: 'Jardín',
          periodo: periodo,
          evaluaciones: const {},
          compromiso: '',
          nota: 4,
          firmaColegio: '',
          firmaDocenteColegio: '',
          firmaDocenteCourseChild: '',
        ),
      );
    }
    expect(
      sesion.programarVisita(
        VisitaProgramada(
          id: 'clase-final',
          fecha: DateTime(2026, 12),
          colegio: 'Colegio A',
          tipo: 'Capacitación preescolar',
          profesorResponsable: 'Administrador',
          numeroClase: 1,
        ),
      ),
      isNull,
    );
    expect(
      sesion.actualizarEstadoVisita('clase-final', EstadoVisita.realizada),
      isNull,
    );
    estadoFinal = sesion.estadoEvaluacionesProfesores().firstWhere(
      (estado) => estado.profesor == 'Ana',
    );
    expect(estadoFinal.periodosTerminados, isTrue);
    expect(estadoFinal.nivel, NivelDocente.preescolar);
    expect(estadoFinal.clasesTerminadas, isTrue);
    expect(estadoFinal.habilitada, isTrue);
    expect(estadoFinal.evaluacionesSalon, 4);
    expect(estadoFinal.promedioSalones, closeTo(4.05, 0.001));
    expect(estadoFinal.porcentajeEvaluacionesPeriodos, closeTo(81, 0.001));
    expect(estadoFinal.porcentajeAsistencia, 100);
    expect(estadoFinal.cumpleAsistencia, isTrue);
    expect(estadoFinal.cumpleEvaluacionesPeriodos, isTrue);
    expect(estadoFinal.reconocimientoListo, isFalse);

    expect(
      sesion.actualizarConfiguracionNotas(
        const ConfiguracionNotas(evaluacionPeriodosMinimaProfesor: 82),
      ),
      isNull,
    );
    estadoFinal = sesion.estadoEvaluacionesProfesores().firstWhere(
      (estado) => estado.profesor == 'Ana',
    );
    expect(estadoFinal.cumpleEvaluacionesPeriodos, isFalse);
    expect(estadoFinal.habilitada, isFalse);
  });
}
