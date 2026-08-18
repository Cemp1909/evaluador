import 'student_knowledge_report.dart';

class StudentKnowledgeDraft {
  const StudentKnowledgeDraft({
    required this.actualizadoEn,
    required this.colegio,
    required this.profesorEvaluado,
    required this.compromiso,
    required this.periodo,
    required this.grado,
    required this.resultados,
    required this.itemsHabilitados,
    this.firmaColegio,
    this.firmaDocenteColegio,
    this.firmaCourseChild,
    this.fotosEvidencia = const [],
    this.comentariosContenido = const {},
    this.referenciasFotos = const [],
  });

  final DateTime actualizadoEn;
  final String colegio;
  final String profesorEvaluado;
  final String compromiso;
  final int periodo;
  final String grado;
  final Map<String, ResultadoContenido> resultados;
  final Set<String> itemsHabilitados;
  final String? firmaColegio;
  final String? firmaDocenteColegio;
  final String? firmaCourseChild;
  final List<String> fotosEvidencia;
  final Map<String, String> comentariosContenido;
  final List<String?> referenciasFotos;
}
