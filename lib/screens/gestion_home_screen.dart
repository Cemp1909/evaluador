import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
import '../widgets/home_action_card.dart';
import 'crear_profesor_screen.dart';
import 'evaluador_selection_screen.dart';
import 'login_screen.dart';
import 'profesores_screen.dart';

class GestionHomeScreen extends StatelessWidget {
  const GestionHomeScreen.admin({super.key})
    : rolEsperado = RolUsuario.administrador;

  const GestionHomeScreen.coordinador({super.key})
    : rolEsperado = RolUsuario.coordinador;

  static const adminRoute = '/admin_home';
  static const coordinadorRoute = '/coordinador_home';

  final RolUsuario rolEsperado;

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    final usuario = sesion.usuarioActual;
    final esAdmin = rolEsperado == RolUsuario.administrador;

    return Scaffold(
      appBar: AppBar(
        title: Text(esAdmin ? 'Administración' : 'Coordinación'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Hola, ${usuario?.nombre ?? ''}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (usuario?.zona != null) ...[
            const SizedBox(height: 4),
            Text(usuario!.zona!, style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: 8),
          Text(
            'Gestiona los profesores disponibles durante esta sesión.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          HomeActionCard(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Evaluaciones',
            subtitle: 'Inicia una capacitación de Preescolar o Primaria.',
            onTap: () => Navigator.pushNamed(
              context,
              EvaluadorSelectionScreen.routeName,
            ),
          ),
          const SizedBox(height: 14),
          HomeActionCard(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Crear profesor',
            subtitle: esAdmin
                ? 'Registra un profesor y asígnale una zona.'
                : 'Registra un profesor para ${usuario?.zona ?? 'tu zona'}.',
            onTap: () =>
                Navigator.pushNamed(context, CrearProfesorScreen.routeName),
          ),
          const SizedBox(height: 14),
          HomeActionCard(
            icon: Icons.groups_2_outlined,
            title: 'Lista de profesores',
            subtitle: esAdmin
                ? 'Consulta todos los profesores creados.'
                : 'Consulta los profesores asignados a tu zona.',
            onTap: () =>
                Navigator.pushNamed(context, ProfesoresScreen.routeName),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion(BuildContext context) {
    context.read<SesionProvider>().cerrarSesion();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
  }
}
