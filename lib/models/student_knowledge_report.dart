enum CalificacionConocimiento { low, regular, high }

class StudentKnowledgeReport {
  const StudentKnowledgeReport({
    required this.fechaHora,
    required this.docente,
    required this.profesorEvaluado,
    required this.colegio,
    required this.grado,
    required this.periodo,
    required this.evaluaciones,
    required this.compromiso,
    required this.calificacion,
    required this.firmaColegio,
    required this.firmaDocenteColegio,
    required this.firmaDocenteCourseChild,
    this.fotosEvidencia = const [],
  });

  final DateTime fechaHora;
  final String docente;
  final String profesorEvaluado;
  final String colegio;
  final String grado;
  final int periodo;
  final Map<String, String> evaluaciones;
  final String compromiso;
  final CalificacionConocimiento calificacion;
  final String firmaColegio;
  final String firmaDocenteColegio;
  final String firmaDocenteCourseChild;
  final List<String> fotosEvidencia;
}
