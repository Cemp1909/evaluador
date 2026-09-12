import 'usuario_sesion.dart';

enum EstadoContenidoClase {
  pendiente,
  ensenado,
  noEnsenado,
  reemplazadoTemporalmente,
}

class ReemplazoContenido {
  const ReemplazoContenido({
    required this.contenidoId,
    required this.nombreOriginal,
    required this.nombreTemporal,
    required this.bloque,
    required this.colegio,
    required this.claseId,
    required this.evaluacionId,
    required this.fecha,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.rolUsuario,
  });

  final String contenidoId;
  final String nombreOriginal;
  final String nombreTemporal;
  final String bloque;
  final String colegio;
  final String claseId;
  final String evaluacionId;
  final DateTime fecha;
  final String usuarioId;
  final String nombreUsuario;
  final RolUsuario rolUsuario;

  factory ReemplazoContenido.fromJson(Map<String, dynamic> json) =>
      ReemplazoContenido(
        contenidoId: json['contenido_id'] as String,
        nombreOriginal: json['nombre_original'] as String,
        nombreTemporal: json['nombre_temporal'] as String,
        bloque: json['bloque'] as String,
        colegio: json['colegio'] as String,
        claseId: json['clase_id'] as String,
        evaluacionId: json['evaluacion_id'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        usuarioId: json['usuario_id'] as String,
        nombreUsuario: json['nombre_usuario'] as String,
        rolUsuario: RolUsuario.values.byName(json['rol_usuario'] as String),
      );

  Map<String, dynamic> toJson() => {
    'contenido_id': contenidoId,
    'nombre_original': nombreOriginal,
    'nombre_temporal': nombreTemporal,
    'bloque': bloque,
    'colegio': colegio,
    'clase_id': claseId,
    'evaluacion_id': evaluacionId,
    'fecha': fecha.toIso8601String(),
    'usuario_id': usuarioId,
    'nombre_usuario': nombreUsuario,
    'rol_usuario': rolUsuario.name,
  };
}
