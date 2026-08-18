import 'package:evaluador_app/config/evaluadores_config.dart';
import 'package:evaluador_app/services/evaluacion_service.dart';
import 'package:evaluador_app/services/pdf_export_service.dart';
import 'package:evaluador_app/models/student_knowledge_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('genera un PDF separado para una clase de preescolar', () async {
    final evaluacion = EvaluacionService().crearDesdePlantilla(
      evaluadoresDisponibles.first,
    );

    final bytes = await const PdfExportService().generarClase(
      evaluacion: evaluacion,
      clase: evaluacion.clases.first,
      evaluador: 'Evaluador de prueba',
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1000));
  });

  test('genera un PDF separado para una clase de primaria', () async {
    final evaluacion = EvaluacionService().crearDesdePlantilla(
      evaluadoresDisponibles.last,
    );

    final bytes = await const PdfExportService().generarClase(
      evaluacion: evaluacion,
      clase: evaluacion.clases.last,
      evaluador: 'Evaluador de prueba',
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1000));
  });

  test(
    'genera el Student Knowledge Report profesional en dos páginas',
    () async {
      final reporte = StudentKnowledgeReport(
        fechaHora: DateTime(2026, 8, 14, 10, 30),
        docente: 'Laura Gómez',
        profesorEvaluado: 'María Pérez',
        colegio: 'Colegio Central',
        grado: 'Segundo',
        periodo: 2,
        evaluaciones: const {
          'Commands': 'The student follows classroom commands.',
          'Songs': 'The student sings confidently.',
          'Vocabulary': 'The student recognizes the expected vocabulary.',
          'Grammar': 'The student applies the structures correctly.',
          'Dialogue': 'The student participates in short dialogues.',
          'Recommendations': 'Continue reinforcing oral participation.',
        },
        compromiso: 'Practicar vocabulario dos veces por semana.',
        calificacion: CalificacionConocimiento.high,
        firmaColegio: '',
        firmaDocenteColegio: '',
        firmaDocenteCourseChild: '',
      );

      final bytes = await const PdfExportService().generarReporte(reporte);

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    },
  );

  test('crea un nombre profesional para el reporte estudiantil', () {
    final reporte = StudentKnowledgeReport(
      fechaHora: DateTime(2026, 8, 17),
      docente: 'Laura',
      profesorEvaluado: 'María Pérez',
      colegio: 'Colegio Central',
      grado: 'Transición',
      periodo: 3,
      evaluaciones: const {},
      compromiso: 'Practicar',
      nota: 4.5,
      firmaColegio: '',
      firmaDocenteColegio: '',
      firmaDocenteCourseChild: '',
    );

    final nombre = const PdfExportService().nombreArchivoReporte(
      reporte,
      resumido: true,
    );
    expect(
      nombre,
      startsWith('CourseChild_maria_perez_transicion_P3_20260817'),
    );
    expect(nombre, endsWith('_resumido.pdf'));
  });
}
