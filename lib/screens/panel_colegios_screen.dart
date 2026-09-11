import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_knowledge_report.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';

class PanelColegiosScreen extends StatelessWidget {
  const PanelColegiosScreen({super.key});

  static const routeName = '/panel_colegios';

  @override
  Widget build(BuildContext context) {
    final reportes = context.watch<SesionProvider>().reportesConocimiento;
    final colegios = <String, List<StudentKnowledgeReport>>{};
    for (final reporte in reportes) {
      colegios.putIfAbsent(reporte.colegio, () => []).add(reporte);
    }
    final entradas = colegios.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de colegios')),
      body: entradas.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.domain_disabled_outlined,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Aún no hay evaluaciones para consolidar.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              itemCount: entradas.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entrada = entradas[index];
                final promedio =
                    entrada.value.fold<double>(
                      0,
                      (total, reporte) => total + reporte.notaFinal,
                    ) /
                    entrada.value.length;
                final bajos = entrada.value
                    .expand((reporte) => reporte.resultadosContenido.values)
                    .where(
                      (resultado) => resultado == ResultadoContenido.noLogrado,
                    )
                    .length;
                final grados = entrada.value.map((e) => e.grado).toSet().length;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Icon(
                        Icons.school_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      entrada.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${entrada.value.length} evaluaciones',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    children: [
                      const Divider(height: AppSpacing.md),
                      _Metrica('Nota promedio', promedio.toStringAsFixed(1)),
                      _Metrica('Grados evaluados', '$grados'),
                      _Metrica('Contenidos no logrados', '$bajos'),
                      _Metrica(
                        'Reportes aprobados',
                        '${entrada.value.where((e) => e.aprobadoPorCoordinador).length}',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            valor,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
