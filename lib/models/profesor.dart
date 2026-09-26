import 'usuario_sesion.dart';

class Profesor {
  const Profesor({
    required this.nombre,
    required this.usuario,
    required this.password,
    required this.zona,
    this.aprobado = false,
    this.rol = RolUsuario.profesor,
  });

  final String nombre;
  final String usuario;
  final String password;
  final String zona;
  final bool aprobado;
  final RolUsuario rol;

  Profesor copyWith({bool? aprobado, RolUsuario? rol}) => Profesor(
    nombre: nombre,
    usuario: usuario,
    password: password,
    zona: zona,
    aprobado: aprobado ?? this.aprobado,
    rol: rol ?? this.rol,
  );
}
