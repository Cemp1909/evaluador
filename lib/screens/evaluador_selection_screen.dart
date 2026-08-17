import 'package:flutter/material.dart';

import '../config/evaluadores_config.dart';
import '../services/evaluacion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_brand_title.dart';
import '../widgets/home_action_card.dart';
import 'clases_screen.dart';
import 'student_knowledge_report_screen.dart';

class EvaluadorSelectionScreen extends StatelessWidget {
  const EvaluadorSelectionScreen({super.key});

  static const routeName = '/evaluaciones';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppBrandTitle()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'New evaluation',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 4),
          const Text('Select the form you want to complete.'),
          const SizedBox(height: 26),
          for (
            var index = 0;
            index < evaluadoresDisponibles.length;
            index++
          ) ...[
            HomeActionCard(
              icon: index == 0
                  ? Icons.child_care_rounded
                  : Icons.auto_stories_rounded,
              title: _nombreTipo(evaluadoresDisponibles[index].nombre),
              subtitle:
                  '${evaluadoresDisponibles[index].clases.length} classes',
              badge:
                  '${evaluadoresDisponibles[index].clases.length} class sessions',
              prominent: true,
              accentColor: index == 0 ? AppColors.accent : AppColors.primary,
              onTap: () {
                final tipo = evaluadoresDisponibles[index];
                final evaluacion = EvaluacionService().crearDesdePlantilla(
                  tipo,
                );
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ClasesScreen(tipo: tipo, evaluacionInicial: evaluacion),
                  ),
                );
              },
            ),
            if (index < evaluadoresDisponibles.length - 1)
              const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          HomeActionCard(
            icon: Icons.assignment_ind_outlined,
            title: 'Student Knowledge Report',
            subtitle: 'Evaluate a student’s English knowledge.',
            badge: 'Final assessment',
            prominent: true,
            accentColor: AppColors.success,
            onTap: () => Navigator.pushNamed(
              context,
              StudentKnowledgeReportScreen.routeName,
            ),
          ),
        ],
      ),
    );
  }

  String _nombreTipo(String nombre) => nombre
      .replaceAll('Capacitación', 'Training')
      .replaceAll('Preescolar', 'Preschool')
      .replaceAll('Primaria', 'Primary');
}
