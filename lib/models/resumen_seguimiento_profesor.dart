import 'docente_colegio.dart';

class ResumenSeguimientoProfesor {
  const ResumenSeguimientoProfesor({
    required this.profesor,
    required this.colegio,
    required this.nivel,
    required this.clasesAsistidas,
    required this.inasistencias,
    required this.clasesPendientes,
    required this.contenidosEnsenados,
    required this.contenidosPendientes,
    required this.contenidosReemplazados,
    required this.avancesSalon,
    required this.observaciones,
  });

  final String profesor;
  final String colegio;
  final NivelDocente? nivel;
  final int clasesAsistidas;
  final int inasistencias;
  final int clasesPendientes;
  final int contenidosEnsenados;
  final int contenidosPendientes;
  final int contenidosReemplazados;
  final List<String> avancesSalon;
  final List<String> observaciones;

  int get clasesProgramadas =>
      clasesAsistidas + inasistencias + clasesPendientes;

  double get porcentajeAsistencia {
    final registradas = clasesAsistidas + inasistencias;
    return registradas == 0 ? 0 : clasesAsistidas * 100 / registradas;
  }
}
