enum CalificacionConocimiento { low, regular, high }

enum ResultadoContenido { logrado, porReforzar, noLogrado }

double calcularNotaConocimiento(Iterable<ResultadoContenido> resultados) {
  if (resultados.isEmpty) return 0;
  final puntos = resultados.fold<double>(0, (total, resultado) {
    return total +
        switch (resultado) {
          ResultadoContenido.logrado => 5,
          ResultadoContenido.porReforzar => 3,
          ResultadoContenido.noLogrado => 1,
        };
  });
  return double.parse((puntos / resultados.length).toStringAsFixed(1));
}

String desempenoParaNota(double nota) => switch (nota) {
  >= 4.6 => 'Superior',
  >= 4.0 => 'Alto',
  >= 3.0 => 'Básico',
  > 0 => 'Bajo',
  _ => 'Sin calcular',
};

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
    this.nota,
    this.calificacion,
    this.contenidosEvaluados = 0,
    this.totalContenidos = 0,
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
  final double? nota;
  final CalificacionConocimiento? calificacion;
  final int contenidosEvaluados;
  final int totalContenidos;
  final String firmaColegio;
  final String firmaDocenteColegio;
  final String firmaDocenteCourseChild;
  final List<String> fotosEvidencia;

  double get notaFinal =>
      nota ??
      switch (calificacion) {
        CalificacionConocimiento.low => 2.0,
        CalificacionConocimiento.regular => 3.5,
        CalificacionConocimiento.high => 4.5,
        null => 0,
      };

  String get desempeno => desempenoParaNota(notaFinal);
}
