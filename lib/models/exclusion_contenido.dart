import 'usuario_sesion.dart';

enum EstadoContenidoClase {
  pendiente,
  ensenado,
  noEnsenado,
  excluidoPorColegio,
}

class ExclusionContenido {
  const ExclusionContenido({
    required this.contenidoId,
    required this.contenidoNombre,
    required this.bloque,
    required this.colegio,
    required this.claseId,
    required this.evaluacionId,
    required this.motivo,
    this.observacion,
    required this.fecha,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.rolUsuario,
    required this.estadoAnterior,
  });

  final String contenidoId;
  final String contenidoNombre;
  final String bloque;
  final String colegio;
  final String claseId;
  final String evaluacionId;
  final String motivo;
  final String? observacion;
  final DateTime fecha;
  final String usuarioId;
  final String nombreUsuario;
  final RolUsuario rolUsuario;
  final EstadoContenidoClase estadoAnterior;

  factory ExclusionContenido.fromJson(Map<String, dynamic> json) =>
      ExclusionContenido(
        contenidoId: json['contenido_id'] as String,
        contenidoNombre: json['contenido_nombre'] as String,
        bloque: json['bloque'] as String,
        colegio: json['colegio'] as String,
        claseId: json['clase_id'] as String,
        evaluacionId: json['evaluacion_id'] as String,
        motivo: json['motivo'] as String,
        observacion: json['observacion'] as String?,
        fecha: DateTime.parse(json['fecha'] as String),
        usuarioId: json['usuario_id'] as String,
        nombreUsuario: json['nombre_usuario'] as String,
        rolUsuario: RolUsuario.values.byName(json['rol_usuario'] as String),
        estadoAnterior: EstadoContenidoClase.values.byName(
          json['estado_anterior'] as String,
        ),
      );

  Map<String, dynamic> toJson() => {
    'contenido_id': contenidoId,
    'contenido_nombre': contenidoNombre,
    'bloque': bloque,
    'colegio': colegio,
    'clase_id': claseId,
    'evaluacion_id': evaluacionId,
    'motivo': motivo,
    if (observacion?.trim().isNotEmpty == true) 'observacion': observacion,
    'fecha': fecha.toIso8601String(),
    'usuario_id': usuarioId,
    'nombre_usuario': nombreUsuario,
    'rol_usuario': rolUsuario.name,
    'estado_anterior': estadoAnterior.name,
  };
}
