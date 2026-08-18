import 'configuracion_notas.dart';

enum CalificacionConocimiento { low, regular, high }

enum ResultadoContenido { logrado, porReforzar, noLogrado }

double calcularNotaConocimiento(
  Iterable<ResultadoContenido> resultados, [
  ConfiguracionNotas configuracion = const ConfiguracionNotas(),
]) {
  if (resultados.isEmpty) return 0;
  final puntos = resultados.fold<double>(0, (total, resultado) {
    return total +
        switch (resultado) {
          ResultadoContenido.logrado => configuracion.puntosLogrado,
          ResultadoContenido.porReforzar => configuracion.puntosPorReforzar,
          ResultadoContenido.noLogrado => configuracion.puntosNoLogrado,
        };
  });
  return double.parse((puntos / resultados.length).toStringAsFixed(1));
}

String desempenoParaNota(
  double nota, [
  ConfiguracionNotas configuracion = const ConfiguracionNotas(),
]) {
  if (nota == 0) return 'Sin calcular';
  if (nota >= configuracion.inicioSuperior) return 'Superior';
  if (nota >= configuracion.inicioAlto) return 'Alto';
  if (nota >= configuracion.inicioBasico) return 'Básico';
  return 'Bajo';
}

class StudentKnowledgeReport {
  const StudentKnowledgeReport({
    this.id = 'REPORTE-LOCAL',
    required this.fechaHora,
    required this.docente,
    required this.profesorEvaluado,
    required this.colegio,
    required this.grado,
    required this.periodo,
    required this.evaluaciones,
    required this.compromiso,
    this.nota,
    this.calificacion,
    this.contenidosEvaluados = 0,
    this.totalContenidos = 0,
    this.configuracionNotas = const ConfiguracionNotas(),
    required this.firmaColegio,
    required this.firmaDocenteColegio,
    required this.firmaDocenteCourseChild,
    this.fotosEvidencia = const [],
    this.resultadosContenido = const {},
    this.nombresContenido = const {},
    this.comentariosContenido = const {},
    this.referenciasFotos = const [],
    this.firmaCoordinador,
    this.nombreCoordinador,
    this.fechaAprobacion,
  });

  final String id;
  final DateTime fechaHora;
  final String docente;
  final String profesorEvaluado;
  final String colegio;
  final String grado;
  final int periodo;
  final Map<String, String> evaluaciones;
  final String compromiso;
  final double? nota;
  final CalificacionConocimiento? calificacion;
  final int contenidosEvaluados;
  final int totalContenidos;
  final ConfiguracionNotas configuracionNotas;
  final String firmaColegio;
  final String firmaDocenteColegio;
  final String firmaDocenteCourseChild;
  final List<String> fotosEvidencia;
  final Map<String, ResultadoContenido> resultadosContenido;
  final Map<String, String> nombresContenido;
  final Map<String, String> comentariosContenido;
  final List<String?> referenciasFotos;
  final String? firmaCoordinador;
  final String? nombreCoordinador;
  final DateTime? fechaAprobacion;

  bool get aprobadoPorCoordinador => firmaCoordinador?.isNotEmpty == true;

  double get notaFinal =>
      nota ??
      switch (calificacion) {
        CalificacionConocimiento.low => 2.0,
        CalificacionConocimiento.regular => 3.5,
        CalificacionConocimiento.high => 4.5,
        null => 0,
      };

  String get desempeno => desempenoParaNota(notaFinal, configuracionNotas);

  StudentKnowledgeReport copyWith({
    String? firmaCoordinador,
    String? nombreCoordinador,
    DateTime? fechaAprobacion,
  }) => StudentKnowledgeReport(
    id: id,
    fechaHora: fechaHora,
    docente: docente,
    profesorEvaluado: profesorEvaluado,
    colegio: colegio,
    grado: grado,
    periodo: periodo,
    evaluaciones: evaluaciones,
    compromiso: compromiso,
    nota: nota,
    calificacion: calificacion,
    contenidosEvaluados: contenidosEvaluados,
    totalContenidos: totalContenidos,
    configuracionNotas: configuracionNotas,
    firmaColegio: firmaColegio,
    firmaDocenteColegio: firmaDocenteColegio,
    firmaDocenteCourseChild: firmaDocenteCourseChild,
    fotosEvidencia: fotosEvidencia,
    resultadosContenido: resultadosContenido,
    nombresContenido: nombresContenido,
    comentariosContenido: comentariosContenido,
    referenciasFotos: referenciasFotos,
    firmaCoordinador: firmaCoordinador ?? this.firmaCoordinador,
    nombreCoordinador: nombreCoordinador ?? this.nombreCoordinador,
    fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
  );
}
