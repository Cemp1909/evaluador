import 'student_knowledge_report.dart';

class StudentKnowledgeDraft {
  const StudentKnowledgeDraft({
    required this.actualizadoEn,
    required this.colegio,
    this.profesorResponsableSalon = '',
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
  final String profesorResponsableSalon;
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

  Map<String, dynamic> toJson() => {
    'actualizado_en': actualizadoEn.toUtc().toIso8601String(),
    'colegio': colegio,
    'profesor': profesorResponsableSalon,
    'compromiso': compromiso,
    'periodo': periodo,
    'grado': grado,
    'resultados': resultados.map((k, v) => MapEntry(k, v.name)),
    'items': itemsHabilitados.toList(),
    'firma_colegio': firmaColegio,
    'firma_docente': firmaDocenteColegio,
    'firma_course_child': firmaCourseChild,
    'fotos': fotosEvidencia,
    'comentarios': comentariosContenido,
    'referencias': referenciasFotos,
  };

  factory StudentKnowledgeDraft.fromJson(Map<String, dynamic> json) =>
      StudentKnowledgeDraft(
        actualizadoEn: DateTime.parse(json['actualizado_en'] as String),
        colegio: json['colegio'] as String,
        profesorResponsableSalon: json['profesor'] as String? ?? '',
        compromiso: json['compromiso'] as String,
        periodo: (json['periodo'] as num).toInt(),
        grado: json['grado'] as String,
        resultados: (json['resultados'] as Map).map(
          (k, v) => MapEntry(k as String, ResultadoContenido.values.byName(v as String)),
        ),
        itemsHabilitados: (json['items'] as List).cast<String>().toSet(),
        firmaColegio: json['firma_colegio'] as String?,
        firmaDocenteColegio: json['firma_docente'] as String?,
        firmaCourseChild: json['firma_course_child'] as String?,
        fotosEvidencia: (json['fotos'] as List).cast<String>(),
        comentariosContenido: Map<String, String>.from(json['comentarios'] as Map),
        referenciasFotos: (json['referencias'] as List).cast<String?>(),
      );
}
