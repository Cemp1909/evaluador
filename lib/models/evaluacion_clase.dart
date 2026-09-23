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
    this.asistencia = const {},
    this.observaciones = '',
    this.bloqueCancionesSeleccionado,
    required this.bloques,
  });

  final String? id;
  final String? evaluacionId;
  final int claseNumero;
  final DateTime? fecha;
  final String? firmaDocenteUrl;
  final List<FirmaDocente> firmasAsistentes;
  final Map<String, bool> asistencia;
  final String observaciones;
  final String? bloqueCancionesSeleccionado;
  final List<EvaluacionBloque> bloques;

  static bool esOpcionCanciones(String nombre) {
    final normalizado = nombre.trim().toLowerCase();
    return normalizado == 'songs 1' ||
        normalizado == 'songs 2' ||
        normalizado == 'canciones 1' ||
        normalizado == 'canciones 2';
  }

  bool get requiereSeleccionCanciones =>
      bloques.where((bloque) => esOpcionCanciones(bloque.bloqueNombre)).length >
      1;

  List<EvaluacionBloque> get bloquesEvaluables => bloques
      .where((bloque) {
        if (!esOpcionCanciones(bloque.bloqueNombre)) return true;
        return bloque.bloqueNombre == bloqueCancionesSeleccionado;
      })
      .toList(growable: false);

  bool get estaCompleta =>
      (!requiereSeleccionCanciones || bloqueCancionesSeleccionado != null) &&
      bloquesEvaluables.isNotEmpty &&
      bloquesEvaluables.every((bloque) => bloque.marcado);

  String contenidoId(String bloque, String contenido) =>
      '$claseNumero::$bloque::$contenido';

  EvaluacionClase copyWith({
    DateTime? fecha,
    String? firmaDocenteUrl,
    List<FirmaDocente>? firmasAsistentes,
    Map<String, bool>? asistencia,
    String? observaciones,
    String? bloqueCancionesSeleccionado,
    List<EvaluacionBloque>? bloques,
  }) => EvaluacionClase(
    asistencia: asistencia ?? this.asistencia,
    id: id,
    evaluacionId: evaluacionId,
    claseNumero: claseNumero,
    fecha: fecha ?? this.fecha,
    firmaDocenteUrl: firmaDocenteUrl ?? this.firmaDocenteUrl,
    firmasAsistentes: firmasAsistentes ?? this.firmasAsistentes,
    observaciones: observaciones ?? this.observaciones,
    bloqueCancionesSeleccionado:
        bloqueCancionesSeleccionado ?? this.bloqueCancionesSeleccionado,
    bloques: bloques ?? this.bloques,
  );

  factory EvaluacionClase.fromJson(
    Map<String, dynamic> json, {
    List<EvaluacionBloque> bloques = const [],
  }) => EvaluacionClase(
    asistencia: Map<String, bool>.from(json['asistencia'] as Map? ?? {}),
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
    bloqueCancionesSeleccionado:
        json['bloque_canciones_seleccionado'] as String?,
    bloques: bloques,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (evaluacionId != null) 'evaluacion_id': evaluacionId,
    'clase_numero': claseNumero,
    'asistencia': asistencia,
    'fecha': fecha?.toIso8601String(),
    'firma_docente_url': firmaDocenteUrl,
    'firmas_asistentes': firmasAsistentes
        .map((firma) => firma.toJson())
        .toList(),
    'observaciones': observaciones,
    if (bloqueCancionesSeleccionado != null)
      'bloque_canciones_seleccionado': bloqueCancionesSeleccionado,
  };
}
