import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/models/student_knowledge_report.dart';
import 'package:evaluador_app/models/configuracion_notas.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula la nota sin contar contenidos no evaluados', () {
    final nota = calcularNotaConocimiento(const [
      ResultadoContenido.logrado,
      ResultadoContenido.logrado,
      ResultadoContenido.porReforzar,
      ResultadoContenido.noLogrado,
    ]);

    expect(nota, 3.5);
    expect(desempenoParaNota(nota), 'Básico');
    expect(calcularNotaConocimiento(const []), 0);
  });

  test('calcula con una escala configurada por el administrador', () {
    const configuracion = ConfiguracionNotas(
      puntosLogrado: 5,
      puntosPorReforzar: 4,
      puntosNoLogrado: 2,
      inicioSuperior: 4.7,
      inicioAlto: 4.2,
      inicioBasico: 3.2,
    );
    final nota = calcularNotaConocimiento(const [
      ResultadoContenido.logrado,
      ResultadoContenido.porReforzar,
      ResultadoContenido.noLogrado,
    ], configuracion);

    expect(nota, 3.7);
    expect(desempenoParaNota(nota, configuracion), 'Básico');
  });

  test('guarda el reporte en memoria con el nombre de la sesión', () {
    final sesion = SesionProvider(AuthConfig.test);
    sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto');

    sesion.guardarReporteConocimiento(
      StudentKnowledgeReport(
        fechaHora: DateTime(2026, 8, 13, 10, 30),
        docente: sesion.usuarioActual!.nombre,
        profesorEvaluado: 'María González',
        colegio: 'Colegio Central',
        grado: 'Segundo',
        periodo: 1,
        evaluaciones: const {'Commands': 'Buen desempeño'},
        compromiso: 'Reforzar vocabulario',
        calificacion: CalificacionConocimiento.high,
        firmaColegio: 'firma-1',
        firmaDocenteColegio: 'firma-2',
        firmaDocenteCourseChild: 'firma-3',
        fotosEvidencia: const ['foto-1', 'foto-2'],
      ),
    );

    expect(sesion.reportesConocimiento, hasLength(1));
    expect(sesion.reportesConocimiento.single.docente, 'Administrador');
    expect(sesion.reportesConocimiento.single.colegio, 'Colegio Central');
    expect(
      sesion.reportesConocimiento.single.profesorEvaluado,
      'María González',
    );
    expect(sesion.reportesConocimiento.single.fotosEvidencia, hasLength(2));
    expect(sesion.historialEstudiante('maría gonzález'), hasLength(1));
  });

  test('el coordinador aprueba y firma un reporte guardado', () {
    final sesion = SesionProvider(AuthConfig.test);
    sesion.guardarReporteConocimiento(
      StudentKnowledgeReport(
        id: 'CC-PRUEBA',
        fechaHora: DateTime(2026, 8, 17),
        docente: 'Evaluador',
        profesorEvaluado: 'Laura',
        colegio: 'Colegio Central',
        grado: 'Jardín',
        periodo: 2,
        evaluaciones: const {},
        compromiso: 'Practicar',
        nota: 4.2,
        firmaColegio: 'firma-1',
        firmaDocenteColegio: 'firma-2',
        firmaDocenteCourseChild: 'firma-3',
      ),
    );

    expect(
      sesion.aprobarReporteConocimiento(
        reporteId: 'CC-PRUEBA',
        firma: 'firma-coordinador',
      ),
      contains('Solo un coordinador'),
    );
    sesion.iniciarSesion(usuario: 'coordinador', password: 'cambiar_esto');
    expect(
      sesion.aprobarReporteConocimiento(
        reporteId: 'CC-PRUEBA',
        firma: 'firma-coordinador',
      ),
      isNull,
    );
    expect(sesion.reportesConocimiento.single.aprobadoPorCoordinador, isTrue);
  });
}
