class Profesor {
  const Profesor({
    required this.nombre,
    required this.usuario,
    required this.password,
    required this.zona,
    this.aprobado = false,
  });

  final String nombre;
  final String usuario;
  final String password;
  final String zona;
  final bool aprobado;

  Profesor copyWith({bool? aprobado}) => Profesor(
    nombre: nombre,
    usuario: usuario,
    password: password,
    zona: zona,
    aprobado: aprobado ?? this.aprobado,
  );
}
