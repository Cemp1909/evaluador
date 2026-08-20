import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/evaluadores_config.dart';
import '../services/evaluacion_service.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_brand_title.dart';
import '../widgets/home_action_card.dart';
import '../widgets/local_mode_banner.dart';
import 'clases_screen.dart';

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
            'Training classes',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 4),
          const Text('Select the training level you want to complete.'),
          const SizedBox(height: 16),
          const LocalModeBanner(),
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
                final sesion = context.read<SesionProvider>();
                final evaluacion =
                    sesion.borradorEvaluacion(tipo.codigo) ??
                    EvaluacionService().crearDesdePlantilla(tipo);
                sesion.guardarBorradorEvaluacion(evaluacion);
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
        ],
      ),
    );
  }

  String _nombreTipo(String nombre) => nombre
      .replaceAll('Capacitación', 'Training')
      .replaceAll('Preescolar', 'Preschool')
      .replaceAll('Primaria', 'Primary');
}
