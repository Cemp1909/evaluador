import 'evaluacion_clase.dart';
import 'reemplazo_contenido.dart';

enum EstadoEvaluacion { borrador, enProgreso, completada }

class Evaluacion {
  const Evaluacion({
    this.id,
    required this.evaluadorTipo,
    required this.colegio,
    required this.fechaCreacion,
    this.estado = EstadoEvaluacion.borrador,
    required this.clases,
    this.fotosUrls = const [],
    this.reemplazos = const [],
    this.responsableNombre,
  });

  final String? id;
  final String evaluadorTipo;
  final String colegio;
  final DateTime fechaCreacion;
  final EstadoEvaluacion estado;
  final List<EvaluacionClase> clases;
  final List<String> fotosUrls;
  final List<ReemplazoContenido> reemplazos;
  final String? responsableNombre;

  Evaluacion copyWith({
    String? colegio,
    EstadoEvaluacion? estado,
    List<EvaluacionClase>? clases,
    List<String>? fotosUrls,
    List<ReemplazoContenido>? reemplazos,
    String? responsableNombre,
  }) => Evaluacion(
    id: id,
    evaluadorTipo: evaluadorTipo,
    colegio: colegio ?? this.colegio,
    fechaCreacion: fechaCreacion,
    estado: estado ?? this.estado,
    clases: clases ?? this.clases,
    fotosUrls: fotosUrls ?? this.fotosUrls,
    reemplazos: reemplazos ?? this.reemplazos,
    responsableNombre: responsableNombre ?? this.responsableNombre,
  );

  factory Evaluacion.fromJson(
    Map<String, dynamic> json, {
    List<EvaluacionClase> clases = const [],
    List<String> fotosUrls = const [],
  }) => Evaluacion(
    id: json['id'] as String?,
    evaluadorTipo: json['evaluador_tipo'] as String,
    colegio: json['colegio'] as String,
    fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
    estado: EstadoEvaluacion.values.byName(json['estado'] as String),
    clases: clases,
    fotosUrls: fotosUrls,
    reemplazos: (json['reemplazos'] as List<dynamic>? ?? const [])
        .map(
          (item) => ReemplazoContenido.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
    responsableNombre: json['responsable_nombre'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'evaluador_tipo': evaluadorTipo,
    'colegio': colegio,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'estado': estado.name,
    if (responsableNombre != null) 'responsable_nombre': responsableNombre,
    if (reemplazos.isNotEmpty)
      'reemplazos': reemplazos.map((item) => item.toJson()).toList(),
  };

  String get identificador =>
      id ??
      '${evaluadorTipo}_${fechaCreacion.toIso8601String()}_${colegio.trim().toLowerCase()}';
}
