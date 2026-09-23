import '../../models/evaluacion.dart';
import '../../models/evaluacion_clase.dart';
import '../../models/evaluacion_bloque.dart';
import '../../models/student_knowledge_report.dart';
import '../../models/configuracion_notas.dart';
import '../../models/visita_programada.dart';

class OfflineCodec {
  static Map<String, dynamic> configuracion(ConfiguracionNotas c) => {
    'notas': c.toJson(),
    'asistencia_minima_profesor': c.asistenciaMinimaProfesor,
    'evaluacion_periodos_minima_profesor': c.evaluacionPeriodosMinimaProfesor,
  };
  static Map<String, dynamic> evaluacion(Evaluacion e) => {
    ...e.toJson(),
    'fotos': e.fotosUrls,
    'clases': [
      for (final c in e.clases)
        {
          ...c.toJson(),
          'bloques': [for (final b in c.bloques) b.toJson()],
        },
    ],
  };
  static Evaluacion leerEvaluacion(Map<String, dynamic> d) =>
      Evaluacion.fromJson(
        d,
        fotosUrls: (d['fotos'] as List).cast<String>(),
        clases: [
          for (final c in d['clases'] as List)
            EvaluacionClase.fromJson(
              Map<String, dynamic>.from(c as Map),
              bloques: [
                for (final b in c['bloques'] as List)
                  EvaluacionBloque.fromJson(
                    Map<String, dynamic>.from(b as Map),
                  ),
              ],
            ),
        ],
      );
  static Map<String, dynamic> reporte(StudentKnowledgeReport r) => {
    'id': r.id,
    'fecha': r.fechaHora.toIso8601String(),
    'docente': r.docente,
    'profesor': r.profesorEvaluado,
    'colegio': r.colegio,
    'grado': r.grado,
    'periodo': r.periodo,
    'evaluaciones': r.evaluaciones,
    'compromiso': r.compromiso,
    'nota': r.nota,
    'calificacion': r.calificacion?.name,
    'contenidos': r.contenidosEvaluados,
    'total': r.totalContenidos,
    'configuracion': configuracion(r.configuracionNotas),
    'firma_colegio': r.firmaColegio,
    'firma_docente': r.firmaDocenteColegio,
    'firma_course': r.firmaDocenteCourseChild,
    'fotos': r.fotosEvidencia,
    'resultados': r.resultadosContenido.map((k, v) => MapEntry(k, v.name)),
    'nombres': r.nombresContenido,
    'comentarios': r.comentariosContenido,
    'referencias': r.referenciasFotos,
    'firma_coordinador': r.firmaCoordinador,
    'coordinador': r.nombreCoordinador,
    'aprobado': r.fechaAprobacion?.toIso8601String(),
  };
  static StudentKnowledgeReport leerReporte(
    Map<String, dynamic> d,
  ) => StudentKnowledgeReport(
    id: d['id'] as String,
    fechaHora: DateTime.parse(d['fecha'] as String),
    docente: d['docente'] as String,
    profesorEvaluado: d['profesor'] as String,
    colegio: d['colegio'] as String,
    grado: d['grado'] as String,
    periodo: d['periodo'] as int,
    evaluaciones: Map<String, String>.from(d['evaluaciones'] as Map),
    compromiso: d['compromiso'] as String,
    nota: (d['nota'] as num?)?.toDouble(),
    calificacion: d['calificacion'] == null
        ? null
        : CalificacionConocimiento.values.byName(d['calificacion'] as String),
    contenidosEvaluados: d['contenidos'] as int,
    totalContenidos: d['total'] as int,
    configuracionNotas: ConfiguracionNotas.fromDatabase(
      Map<String, dynamic>.from(d['configuracion'] as Map),
    ),
    firmaColegio: d['firma_colegio'] as String,
    firmaDocenteColegio: d['firma_docente'] as String,
    firmaDocenteCourseChild: d['firma_course'] as String,
    fotosEvidencia: (d['fotos'] as List).cast<String>(),
    resultadosContenido: (d['resultados'] as Map).map(
      (k, v) =>
          MapEntry(k as String, ResultadoContenido.values.byName(v as String)),
    ),
    nombresContenido: Map<String, String>.from(d['nombres'] as Map),
    comentariosContenido: Map<String, String>.from(d['comentarios'] as Map),
    referenciasFotos: (d['referencias'] as List).cast<String?>(),
    firmaCoordinador: d['firma_coordinador'] as String?,
    nombreCoordinador: d['coordinador'] as String?,
    fechaAprobacion: d['aprobado'] == null
        ? null
        : DateTime.parse(d['aprobado'] as String),
  );
  static Map<String, dynamic> visita(VisitaProgramada v) => {
    'id': v.id,
    'fecha': v.fecha.toIso8601String(),
    'colegio': v.colegio,
    'tipo': v.tipo,
    'responsable': v.profesorResponsable,
    'periodo': v.periodo,
    'clase': v.numeroClase,
    'observacion': v.observacion,
    'completada': v.completada,
    'cancelada': v.cancelada,
    'motivo': v.motivoCancelacion,
    'novedad': v.ultimaNovedad,
    'serie': v.serieId,
    'intervalo': v.intervaloDias,
    'duracion': v.duracionMinutos,
    'acompanantes': v.profesoresAcompanantes,
    'ubicacion': v.ubicacion,
    'estado': v.estado.name,
  };
  static VisitaProgramada leerVisita(Map<String, dynamic> d) =>
      VisitaProgramada(
        id: d['id'] as String,
        fecha: DateTime.parse(d['fecha'] as String),
        colegio: d['colegio'] as String,
        tipo: d['tipo'] as String,
        profesorResponsable: d['responsable'] as String,
        periodo: d['periodo'] as int?,
        numeroClase: d['clase'] as int?,
        observacion: d['observacion'] as String,
        completada: d['completada'] as bool,
        cancelada: d['cancelada'] as bool,
        motivoCancelacion: d['motivo'] as String,
        ultimaNovedad: d['novedad'] as String,
        serieId: d['serie'] as String?,
        intervaloDias: d['intervalo'] as int?,
        duracionMinutos: d['duracion'] as int,
        profesoresAcompanantes: (d['acompanantes'] as List).cast<String>(),
        ubicacion: d['ubicacion'] as String,
        estado: EstadoVisita.values.byName(d['estado'] as String),
      );
}
