import 'docente_colegio.dart';

class EstadoEvaluacionProfesor {
  const EstadoEvaluacionProfesor({
    required this.profesor,
    required this.colegio,
    required this.nivel,
    required this.fechaInicio,
    this.fechaFin,
    required this.periodosCompletos,
    required this.clasesProgramadas,
    required this.clasesCompletadas,
    required this.contenidosEvaluables,
    required this.clasesAsistidas,
    required this.inasistencias,
    required this.evaluacionesSalon,
    required this.promedioSalones,
    required this.porcentajeEvaluacionesPeriodos,
    required this.asistenciaMinima,
    required this.evaluacionPeriodosMinima,
    this.notaEvaluacionDocente,
  });

  final String profesor;
  final String colegio;
  final NivelDocente nivel;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final Set<int> periodosCompletos;
  final int clasesProgramadas;
  final int clasesCompletadas;
  final List<String> contenidosEvaluables;
  final int clasesAsistidas;
  final int inasistencias;
  final int evaluacionesSalon;
  final double promedioSalones;
  final double porcentajeEvaluacionesPeriodos;
  final int asistenciaMinima;
  final int evaluacionPeriodosMinima;
  final double? notaEvaluacionDocente;

  bool get periodosTerminados =>
      periodosCompletos.containsAll(const {1, 2, 3, 4});
  bool get clasesTerminadas =>
      clasesProgramadas > 0 && clasesProgramadas == clasesCompletadas;
  bool get cumpleAsistencia => porcentajeAsistencia >= asistenciaMinima;
  bool get cumpleEvaluacionesPeriodos =>
      porcentajeEvaluacionesPeriodos >= evaluacionPeriodosMinima;
  bool get habilitada =>
      periodosTerminados &&
      clasesTerminadas &&
      contenidosEvaluables.isNotEmpty &&
      cumpleAsistencia &&
      cumpleEvaluacionesPeriodos;
  double get porcentajeAsistencia {
    if (clasesProgramadas == 0) return 0;
    return (clasesAsistidas * 100 / clasesProgramadas).clamp(0, 100).toDouble();
  }

  bool get evaluacionDocenteCompletada => notaEvaluacionDocente != null;
  bool get reconocimientoListo => habilitada && evaluacionDocenteCompletada;
  bool get asignacionActiva => fechaFin == null;
  bool get sinCapacitacionIniciada =>
      clasesProgramadas == 0 &&
      clasesAsistidas + inasistencias == 0 &&
      contenidosEvaluables.isEmpty &&
      evaluacionesSalon == 0;
  bool get procesoTerminadoSinMinimos =>
      periodosTerminados &&
      clasesTerminadas &&
      contenidosEvaluables.isNotEmpty &&
      (!cumpleAsistencia || !cumpleEvaluacionesPeriodos);
  String get estadoProceso => sinCapacitacionIniciada
      ? 'Sin capacitación iniciada'
      : habilitada
      ? 'Lista para evaluar'
      : procesoTerminadoSinMinimos
      ? 'No alcanza los mínimos'
      : asignacionActiva
      ? 'Proceso en curso'
      : 'Asignación finalizada';
}
