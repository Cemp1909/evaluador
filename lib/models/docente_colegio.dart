enum NivelDocente { preescolar, primaria }

extension NivelDocenteTexto on NivelDocente {
  String get nombre => switch (this) {
    NivelDocente.preescolar => 'Preescolar',
    NivelDocente.primaria => 'Primaria',
  };
}

class DocenteColegio {
  const DocenteColegio({
    required this.nombre,
    required this.nivel,
    required this.fechaInicio,
    this.fechaFin,
  });

  final String nombre;
  final NivelDocente nivel;
  final DateTime fechaInicio;
  final DateTime? fechaFin;

  bool get activo => fechaFin == null;

  bool estabaAsignadoEn(DateTime fecha) =>
      !fecha.isBefore(fechaInicio) &&
      (fechaFin == null || fecha.isBefore(fechaFin!));

  DocenteColegio cerrar(DateTime fecha) => DocenteColegio(
    nombre: nombre,
    nivel: nivel,
    fechaInicio: fechaInicio,
    fechaFin: fecha,
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'nivel': nivel.name,
    'fecha_inicio': fechaInicio.toIso8601String(),
    'fecha_fin': fechaFin?.toIso8601String(),
  };

  factory DocenteColegio.fromJson(Map<String, dynamic> json) => DocenteColegio(
    nombre: json['nombre'] as String,
    nivel: NivelDocente.values.byName(json['nivel'] as String),
    fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
    fechaFin: json['fecha_fin'] == null
        ? null
        : DateTime.parse(json['fecha_fin'] as String),
  );
}
