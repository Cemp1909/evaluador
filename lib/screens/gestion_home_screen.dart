import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_brand_title.dart';
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
        title: const AppBrandTitle(),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _cerrarSesion(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'Hello, ${usuario?.nombre ?? ''}',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          if (usuario?.zona != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(usuario!.zona!, style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            esAdmin ? 'Administrator overview' : 'Zone coordinator overview',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          HomeActionCard(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Evaluations',
            subtitle: 'Start a Preschool or Primary training session.',
            onTap: () => Navigator.pushNamed(
              context,
              EvaluadorSelectionScreen.routeName,
            ),
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          HomeActionCard(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Create teacher',
            subtitle: esAdmin
                ? 'Register a teacher and assign a zone.'
                : 'Register a teacher for ${usuario?.zona ?? 'your zone'}.',
            onTap: () =>
                Navigator.pushNamed(context, CrearProfesorScreen.routeName),
            accentColor: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          HomeActionCard(
            icon: Icons.groups_2_outlined,
            title: 'Teacher list',
            subtitle: esAdmin
                ? 'View all registered teachers.'
                : 'View teachers assigned to your zone.',
            onTap: () =>
                Navigator.pushNamed(context, ProfesoresScreen.routeName),
            accentColor: AppColors.success,
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
