import 'evaluacion_bloque.dart';
import 'firma_docente.dart';

class EvaluacionClase {
  const EvaluacionClase({
    this.id,
    this.evaluacionId,
    required this.claseNumero,
    this.fecha,
    this.firmaDocenteUrl,
    this.firmasAsistentes = const [],
    this.observaciones = '',
    required this.bloques,
  });

  final String? id;
  final String? evaluacionId;
  final int claseNumero;
  final DateTime? fecha;
  final String? firmaDocenteUrl;
  final List<FirmaDocente> firmasAsistentes;
  final String observaciones;
  final List<EvaluacionBloque> bloques;

  bool get estaCompleta =>
      bloques.isNotEmpty && bloques.every((bloque) => bloque.marcado);

  EvaluacionClase copyWith({
    DateTime? fecha,
    String? firmaDocenteUrl,
    List<FirmaDocente>? firmasAsistentes,
    String? observaciones,
    List<EvaluacionBloque>? bloques,
  }) => EvaluacionClase(
    id: id,
    evaluacionId: evaluacionId,
    claseNumero: claseNumero,
    fecha: fecha ?? this.fecha,
    firmaDocenteUrl: firmaDocenteUrl ?? this.firmaDocenteUrl,
    firmasAsistentes: firmasAsistentes ?? this.firmasAsistentes,
    observaciones: observaciones ?? this.observaciones,
    bloques: bloques ?? this.bloques,
  );

  factory EvaluacionClase.fromJson(
    Map<String, dynamic> json, {
    List<EvaluacionBloque> bloques = const [],
  }) => EvaluacionClase(
    id: json['id'] as String?,
    evaluacionId: json['evaluacion_id'] as String?,
    claseNumero: json['clase_numero'] as int,
    fecha: json['fecha'] == null
        ? null
        : DateTime.parse(json['fecha'] as String),
    firmaDocenteUrl: json['firma_docente_url'] as String?,
    firmasAsistentes: (json['firmas_asistentes'] as List<dynamic>? ?? const [])
        .map((item) => FirmaDocente.fromJson(item as Map<String, dynamic>))
        .toList(),
    observaciones: json['observaciones'] as String? ?? '',
    bloques: bloques,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (evaluacionId != null) 'evaluacion_id': evaluacionId,
    'clase_numero': claseNumero,
    'fecha': fecha?.toIso8601String(),
    'firma_docente_url': firmaDocenteUrl,
    'firmas_asistentes': firmasAsistentes
        .map((firma) => firma.toJson())
        .toList(),
    'observaciones': observaciones,
  };
}
