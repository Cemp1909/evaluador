class AuthConfig {
  const AuthConfig({
    required this.adminUsername,
    required this.adminPassword,
    required this.coordinadorUsername,
    required this.coordinadorPassword,
    required this.coordinadorZona,
  });

  final String adminUsername;
  final String adminPassword;
  final String coordinadorUsername;
  final String coordinadorPassword;
  final String coordinadorZona;

  factory AuthConfig.fromMap(Map<String, String> values) => AuthConfig(
    adminUsername: values['ADMIN_USERNAME'] ?? '',
    adminPassword: values['ADMIN_PASSWORD'] ?? '',
    coordinadorUsername: values['COORDINADOR_USERNAME'] ?? '',
    coordinadorPassword: values['COORDINADOR_PASSWORD'] ?? '',
    coordinadorZona: values['COORDINADOR_ZONA'] ?? '',
  );

  static const test = AuthConfig(
    adminUsername: 'admin',
    adminPassword: 'cambiar_esto',
    coordinadorUsername: 'coordinador',
    coordinadorPassword: 'cambiar_esto',
    coordinadorZona: 'Zona Centro',
  );
}
