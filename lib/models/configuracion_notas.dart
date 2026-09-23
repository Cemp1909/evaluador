class ConfiguracionNotas {
  const ConfiguracionNotas({
    this.puntosLogrado = 5,
    this.puntosPorReforzar = 3,
    this.puntosNoLogrado = 1,
    this.inicioSuperior = 4.6,
    this.inicioAlto = 4,
    this.inicioBasico = 3,
    this.coberturaMinima = 70,
    this.asistenciaMinimaProfesor = 80,
    this.evaluacionPeriodosMinimaProfesor = 75,
  });

  final double puntosLogrado;
  final double puntosPorReforzar;
  final double puntosNoLogrado;
  final double inicioSuperior;
  final double inicioAlto;
  final double inicioBasico;
  final int coberturaMinima;
  final int asistenciaMinimaProfesor;
  final int evaluacionPeriodosMinimaProfesor;

  Map<String, dynamic> toJson() => {
    'puntos_logrado': puntosLogrado,
    'puntos_por_reforzar': puntosPorReforzar,
    'puntos_no_logrado': puntosNoLogrado,
    'inicio_superior': inicioSuperior,
    'inicio_alto': inicioAlto,
    'inicio_basico': inicioBasico,
    'cobertura_minima': coberturaMinima,
  };

  factory ConfiguracionNotas.fromDatabase(Map<String, dynamic> row) {
    final notas = Map<String, dynamic>.from(row['notas'] as Map? ?? {});
    num numero(String clave, num defecto) =>
        notas[clave] is num ? notas[clave] as num : defecto;
    return ConfiguracionNotas(
      puntosLogrado: numero('puntos_logrado', 5).toDouble(),
      puntosPorReforzar: numero('puntos_por_reforzar', 3).toDouble(),
      puntosNoLogrado: numero('puntos_no_logrado', 1).toDouble(),
      inicioSuperior: numero('inicio_superior', 4.6).toDouble(),
      inicioAlto: numero('inicio_alto', 4).toDouble(),
      inicioBasico: numero('inicio_basico', 3).toDouble(),
      coberturaMinima: numero('cobertura_minima', 70).toInt(),
      asistenciaMinimaProfesor:
          (row['asistencia_minima_profesor'] as num).toInt(),
      evaluacionPeriodosMinimaProfesor:
          (row['evaluacion_periodos_minima_profesor'] as num).toInt(),
    );
  }

  ConfiguracionNotas copyWith({
    double? puntosLogrado,
    double? puntosPorReforzar,
    double? puntosNoLogrado,
    double? inicioSuperior,
    double? inicioAlto,
    double? inicioBasico,
    int? coberturaMinima,
    int? asistenciaMinimaProfesor,
    int? evaluacionPeriodosMinimaProfesor,
  }) => ConfiguracionNotas(
    puntosLogrado: puntosLogrado ?? this.puntosLogrado,
    puntosPorReforzar: puntosPorReforzar ?? this.puntosPorReforzar,
    puntosNoLogrado: puntosNoLogrado ?? this.puntosNoLogrado,
    inicioSuperior: inicioSuperior ?? this.inicioSuperior,
    inicioAlto: inicioAlto ?? this.inicioAlto,
    inicioBasico: inicioBasico ?? this.inicioBasico,
    coberturaMinima: coberturaMinima ?? this.coberturaMinima,
    asistenciaMinimaProfesor:
        asistenciaMinimaProfesor ?? this.asistenciaMinimaProfesor,
    evaluacionPeriodosMinimaProfesor:
        evaluacionPeriodosMinimaProfesor ??
        this.evaluacionPeriodosMinimaProfesor,
  );
}
