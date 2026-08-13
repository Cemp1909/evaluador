enum RolUsuario { administrador, coordinador, profesor }

class UsuarioSesion {
  const UsuarioSesion({required this.rol, required this.nombre, this.zona});

  final RolUsuario rol;
  final String nombre;
  final String? zona;
}
