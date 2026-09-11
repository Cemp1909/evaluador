import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sesion_provider.dart';
import '../security/rbac.dart';
import '../screens/login_screen.dart';

/// Protege rutas, incluidas las abiertas manualmente o mediante deep links.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
  });

  final Permiso permission;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    if (!sesion.estaAutenticado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
        }
      });
      return const _AccessDenied(message: 'Debes iniciar sesión.');
    }
    if (!sesion.tienePermiso(permission)) {
      return const _AccessDenied(
        message: 'No tienes permisos para acceder a esta sección.',
      );
    }
    return child;
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Acceso restringido')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    ),
  );
}
