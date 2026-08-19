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

  VisitaProgramada copyWith({
    DateTime? fecha,
    bool? completada,
    bool? cancelada,
    String? motivoCancelacion,
    String? ultimaNovedad,
  }) => VisitaProgramada(
    id: id,
    fecha: fecha ?? this.fecha,
    colegio: colegio,
    tipo: tipo,
    profesorResponsable: profesorResponsable,
    periodo: periodo,
    numeroClase: numeroClase,
    observacion: observacion,
    completada: completada ?? this.completada,
    cancelada: cancelada ?? this.cancelada,
    motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
    ultimaNovedad: ultimaNovedad ?? this.ultimaNovedad,
    serieId: serieId,
    intervaloDias: intervaloDias,
  );
}
