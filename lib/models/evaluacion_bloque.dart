class EvaluacionBloque {
  const EvaluacionBloque({
    this.id,
    this.evaluacionClaseId,
    required this.bloqueNombre,
    this.marcado = false,
    this.itemsMarcados = const {},
  });

  final String? id;
  final String? evaluacionClaseId;
  final String bloqueNombre;
  final bool marcado;
  final Map<String, bool> itemsMarcados;

  EvaluacionBloque copyWith({
    bool? marcado,
    Map<String, bool>? itemsMarcados,
  }) => EvaluacionBloque(
    id: id,
    evaluacionClaseId: evaluacionClaseId,
    bloqueNombre: bloqueNombre,
    marcado: marcado ?? this.marcado,
    itemsMarcados: itemsMarcados ?? this.itemsMarcados,
  );

  factory EvaluacionBloque.fromJson(Map<String, dynamic> json) =>
      EvaluacionBloque(
        id: json['id'] as String?,
        evaluacionClaseId: json['evaluacion_clase_id'] as String?,
        bloqueNombre: json['bloque_nombre'] as String,
        marcado: json['marcado'] as bool? ?? false,
        itemsMarcados: (json['items_marcados'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value as bool)),
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (evaluacionClaseId != null) 'evaluacion_clase_id': evaluacionClaseId,
    'bloque_nombre': bloqueNombre,
    'marcado': marcado,
    if (itemsMarcados.isNotEmpty) 'items_marcados': itemsMarcados,
  };
}
