import 'reemplazo_contenido.dart';

class EvaluacionBloque {
  const EvaluacionBloque({
    this.id,
    this.evaluacionClaseId,
    required this.bloqueNombre,
    this.marcado = false,
    this.itemsMarcados = const {},
    this.estadosContenido = const {},
  });

  final String? id;
  final String? evaluacionClaseId;
  final String bloqueNombre;
  final bool marcado;
  final Map<String, bool> itemsMarcados;
  final Map<String, EstadoContenidoClase> estadosContenido;

  EvaluacionBloque copyWith({
    bool? marcado,
    Map<String, bool>? itemsMarcados,
    Map<String, EstadoContenidoClase>? estadosContenido,
  }) => EvaluacionBloque(
    id: id,
    evaluacionClaseId: evaluacionClaseId,
    bloqueNombre: bloqueNombre,
    marcado: marcado ?? this.marcado,
    itemsMarcados: itemsMarcados ?? this.itemsMarcados,
    estadosContenido: estadosContenido ?? this.estadosContenido,
  );

  factory EvaluacionBloque.fromJson(Map<String, dynamic> json) =>
      EvaluacionBloque(
        id: json['id'] as String?,
        evaluacionClaseId: json['evaluacion_clase_id'] as String?,
        bloqueNombre: json['bloque_nombre'] as String,
        marcado: json['marcado'] as bool? ?? false,
        itemsMarcados: (json['items_marcados'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value as bool)),
        estadosContenido:
            (json['estados_contenido'] as Map<String, dynamic>? ?? {}).map(
              (key, value) => MapEntry(
                key,
                EstadoContenidoClase.values.byName(value as String),
              ),
            ),
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (evaluacionClaseId != null) 'evaluacion_clase_id': evaluacionClaseId,
    'bloque_nombre': bloqueNombre,
    'marcado': marcado,
    if (itemsMarcados.isNotEmpty) 'items_marcados': itemsMarcados,
    if (estadosContenido.isNotEmpty)
      'estados_contenido': estadosContenido.map(
        (key, value) => MapEntry(key, value.name),
      ),
  };
}
