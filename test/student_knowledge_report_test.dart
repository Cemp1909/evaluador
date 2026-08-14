import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/models/student_knowledge_report.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  });
}
