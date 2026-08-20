enum EstadoVisita {
  programada,
  pendienteConfirmacion,
  confirmada,
  realizada,
  cancelada,
  reprogramada,
}

class VisitaProgramada {
  const VisitaProgramada({
    required this.id,
    required this.fecha,
    required this.colegio,
    required this.tipo,
    required this.profesorResponsable,
    this.periodo,
    this.numeroClase,
    this.observacion = '',
    this.completada = false,
    this.cancelada = false,
    this.motivoCancelacion = '',
    this.ultimaNovedad = '',
    this.serieId,
    this.intervaloDias,
    this.duracionMinutos = 60,
    this.profesoresAcompanantes = const [],
    this.ubicacion = '',
    this.estado = EstadoVisita.programada,
  });

  final String id;
  final DateTime fecha;
  final String colegio;
  final String tipo;
  final String profesorResponsable;
  final int? periodo;
  final int? numeroClase;
  final String observacion;
  final bool completada;
  final bool cancelada;
  final String motivoCancelacion;
  final String ultimaNovedad;
  final String? serieId;
  final int? intervaloDias;
  final int duracionMinutos;
  final List<String> profesoresAcompanantes;
  final String ubicacion;
  final EstadoVisita estado;

  VisitaProgramada copyWith({
    DateTime? fecha,
    String? colegio,
    String? tipo,
    bool? completada,
    bool? cancelada,
    String? motivoCancelacion,
    String? ultimaNovedad,
    String? profesorResponsable,
    int? periodo,
    int? numeroClase,
    String? observacion,
    bool limpiarPeriodo = false,
    bool limpiarNumeroClase = false,
    List<String>? profesoresAcompanantes,
    String? ubicacion,
    int? duracionMinutos,
    EstadoVisita? estado,
  }) => VisitaProgramada(
    id: id,
    fecha: fecha ?? this.fecha,
    colegio: colegio ?? this.colegio,
    tipo: tipo ?? this.tipo,
    profesorResponsable: profesorResponsable ?? this.profesorResponsable,
    periodo: limpiarPeriodo ? null : periodo ?? this.periodo,
    numeroClase: limpiarNumeroClase ? null : numeroClase ?? this.numeroClase,
    observacion: observacion ?? this.observacion,
    completada: completada ?? this.completada,
    cancelada: cancelada ?? this.cancelada,
    motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
    ultimaNovedad: ultimaNovedad ?? this.ultimaNovedad,
    serieId: serieId,
    intervaloDias: intervaloDias,
    duracionMinutos: duracionMinutos ?? this.duracionMinutos,
    profesoresAcompanantes:
        profesoresAcompanantes ?? this.profesoresAcompanantes,
    ubicacion: ubicacion ?? this.ubicacion,
    estado: estado ?? this.estado,
  );
}
