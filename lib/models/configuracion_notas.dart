class ConfiguracionNotas {
  const ConfiguracionNotas({
    this.puntosLogrado = 5,
    this.puntosPorReforzar = 3,
    this.puntosNoLogrado = 1,
    this.inicioSuperior = 4.6,
    this.inicioAlto = 4,
    this.inicioBasico = 3,
    this.coberturaMinima = 70,
  });

  final double puntosLogrado;
  final double puntosPorReforzar;
  final double puntosNoLogrado;
  final double inicioSuperior;
  final double inicioAlto;
  final double inicioBasico;
  final int coberturaMinima;

  ConfiguracionNotas copyWith({
    double? puntosLogrado,
    double? puntosPorReforzar,
    double? puntosNoLogrado,
    double? inicioSuperior,
    double? inicioAlto,
    double? inicioBasico,
    int? coberturaMinima,
  }) => ConfiguracionNotas(
    puntosLogrado: puntosLogrado ?? this.puntosLogrado,
    puntosPorReforzar: puntosPorReforzar ?? this.puntosPorReforzar,
    puntosNoLogrado: puntosNoLogrado ?? this.puntosNoLogrado,
    inicioSuperior: inicioSuperior ?? this.inicioSuperior,
    inicioAlto: inicioAlto ?? this.inicioAlto,
    inicioBasico: inicioBasico ?? this.inicioBasico,
    coberturaMinima: coberturaMinima ?? this.coberturaMinima,
  );
}
