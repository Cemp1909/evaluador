class FirmaDocente {
  const FirmaDocente({required this.nombre, required this.firmaBase64});

  final String nombre;
  final String firmaBase64;

  factory FirmaDocente.fromJson(Map<String, dynamic> json) => FirmaDocente(
    nombre: json['nombre'] as String,
    firmaBase64: json['firma_base64'] as String,
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'firma_base64': firmaBase64,
  };
}
