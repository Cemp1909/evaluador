import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_brand_title.dart';
import '../widgets/home_action_card.dart';
import 'evaluador_selection_screen.dart';
import 'login_screen.dart';
import 'student_knowledge_report_screen.dart';
import 'agenda_visitas_screen.dart';

class ProfesorHomeScreen extends StatelessWidget {
  const ProfesorHomeScreen({super.key});

  static const routeName = '/profesor_home';

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionProvider>().usuarioActual;

    return Scaffold(
      appBar: AppBar(
        title: const AppBrandTitle(),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () {
              context.read<SesionProvider>().cerrarSesion();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
            },
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
            'Hello, ${usuario?.nombre ?? 'Teacher'}',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            usuario?.zona ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Select an option to continue.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          HomeActionCard(
            icon: Icons.school_outlined,
            title: 'Training classes',
            subtitle: 'Complete a Preschool or Primary training class.',
            onTap: () => Navigator.pushNamed(
              context,
              EvaluadorSelectionScreen.routeName,
            ),
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          HomeActionCard(
            icon: Icons.assignment_ind_outlined,
            title: 'Student evaluations',
            subtitle: 'Evaluate student knowledge by grade and period.',
            onTap: () => Navigator.pushNamed(
              context,
              StudentKnowledgeReportScreen.routeName,
            ),
            accentColor: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          HomeActionCard(
            icon: Icons.calendar_month_outlined,
            title: 'Calendar',
            subtitle: 'Review and schedule classes or evaluations.',
            onTap: () =>
                Navigator.pushNamed(context, AgendaVisitasScreen.routeName),
            accentColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
