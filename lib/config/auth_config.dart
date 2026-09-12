class AuthConfig {
  const AuthConfig({
    required this.adminUsername,
    required this.adminPassword,
    required this.coordinadorUsername,
    required this.coordinadorPassword,
    required this.coordinadorZona,
    this.demoProfesorUsername = '',
    this.demoProfesorPassword = '',
    this.demoProfesorNombre = 'Profesor demo',
    this.demoProfesorZona = 'Zona Demo',
    this.profesoresIniciales = const [],
  });

  final String adminUsername;
  final String adminPassword;
  final String coordinadorUsername;
  final String coordinadorPassword;
  final String coordinadorZona;
  final String demoProfesorUsername;
  final String demoProfesorPassword;
  final String demoProfesorNombre;
  final String demoProfesorZona;
  final List<ProfesorInicialConfig> profesoresIniciales;

  factory AuthConfig.fromMap(Map<String, String> values) => AuthConfig(
    adminUsername: values['ADMIN_USERNAME'] ?? '',
    adminPassword: values['ADMIN_PASSWORD'] ?? '',
    coordinadorUsername: values['COORDINADOR_USERNAME'] ?? '',
    coordinadorPassword: values['COORDINADOR_PASSWORD'] ?? '',
    coordinadorZona: values['COORDINADOR_ZONA'] ?? '',
    demoProfesorUsername: values['DEMO_PROFESOR_USERNAME'] ?? '',
    demoProfesorPassword: values['DEMO_PROFESOR_PASSWORD'] ?? '',
    demoProfesorNombre: values['DEMO_PROFESOR_NOMBRE'] ?? 'Profesor demo',
    demoProfesorZona: values['DEMO_PROFESOR_ZONA'] ?? 'Zona Demo',
    profesoresIniciales: [
      for (var indice = 1; indice <= 20; indice++)
        if ((values['PROFESOR_${indice}_USERNAME'] ?? '').trim().isNotEmpty)
          ProfesorInicialConfig(
            usuario: values['PROFESOR_${indice}_USERNAME']!.trim(),
            password: values['PROFESOR_${indice}_PASSWORD'] ?? '',
            nombre:
                (values['PROFESOR_${indice}_NOMBRE'] ??
                        values['PROFESOR_${indice}_USERNAME']!)
                    .trim(),
            zona: (values['PROFESOR_${indice}_ZONA'] ?? '').trim(),
          ),
    ],
  );

  static const test = AuthConfig(
    adminUsername: 'admin',
    adminPassword: 'cambiar_esto',
    coordinadorUsername: 'coordinador',
    coordinadorPassword: 'cambiar_esto',
    coordinadorZona: 'Zona Centro',
    demoProfesorUsername: 'demo',
    demoProfesorPassword: 'demo123',
    demoProfesorNombre: 'Profesor demo',
    demoProfesorZona: 'Zona Demo',
  );
}

class ProfesorInicialConfig {
  const ProfesorInicialConfig({
    required this.usuario,
    required this.password,
    required this.nombre,
    required this.zona,
  });

  final String usuario;
  final String password;
  final String nombre;
  final String zona;
}
