import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/evaluadores_config.dart';
import '../services/evaluacion_service.dart';
import '../services/pdf_export_service.dart';
import '../providers/sesion_provider.dart';
import '../security/rbac.dart';
import '../theme/app_theme.dart';
import '../widgets/app_brand_title.dart';
import '../widgets/home_action_card.dart';
import '../widgets/local_mode_banner.dart';
import 'clases_screen.dart';
import 'panel_colegios_screen.dart';
import 'reporte_capacitaciones_preview_screen.dart';

class EvaluadorSelectionScreen extends StatefulWidget {
  const EvaluadorSelectionScreen({super.key});

  static const routeName = '/evaluaciones';

  @override
  State<EvaluadorSelectionScreen> createState() =>
      _EvaluadorSelectionScreenState();
}

class _EvaluadorSelectionScreenState extends State<EvaluadorSelectionScreen> {
  String? _colegioSeleccionado;

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    final colegios = sesion.colegiosRegistrados;
    if (_colegioSeleccionado != null &&
        !colegios.contains(_colegioSeleccionado)) {
      _colegioSeleccionado = null;
    }
    if (_colegioSeleccionado == null && colegios.length == 1) {
      _colegioSeleccionado = colegios.single;
    }
    return Scaffold(
      appBar: AppBar(title: const AppBrandTitle()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'Training classes',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Select the training level you want to complete.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          const LocalModeBanner(),
          const SizedBox(height: AppSpacing.md),
          if (sesion.usaSupabase) ...[
            if (colegios.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No hay colegios disponibles',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        sesion.tienePermiso(Permiso.asignarProfesores)
                            ? 'Registra un colegio y sus docentes antes de comenzar la capacitación.'
                            : 'El administrador o coordinador debe asignarte una visita a un colegio.',
                      ),
                      if (sesion.tienePermiso(Permiso.asignarProfesores)) ...[
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            PanelColegiosScreen.routeName,
                          ),
                          icon: const Icon(Icons.add_business_outlined),
                          label: const Text('Registrar o asignar colegio'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey(_colegioSeleccionado),
                initialValue: _colegioSeleccionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Colegio de la capacitación',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: [
                  for (final colegio in colegios)
                    DropdownMenuItem(value: colegio, child: Text(colegio)),
                ],
                onChanged: (value) =>
                    setState(() => _colegioSeleccionado = value),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
          OutlinedButton.icon(
            onPressed: () => _generarReporteQuincenal(context),
            icon: const Icon(Icons.summarize_outlined),
            label: const Text('Generar reporte quincenal'),
          ),
          const SizedBox(height: AppSpacing.lg),
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
              onTap: () async {
                final tipo = evaluadoresDisponibles[index];
                final sesion = context.read<SesionProvider>();
                final colegio = _colegioSeleccionado?.trim() ?? '';
                if (sesion.usaSupabase && colegio.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        colegios.isEmpty
                            ? 'Primero registra o asigna un colegio.'
                            : 'Selecciona un colegio en el menú superior.',
                      ),
                    ),
                  );
                  return;
                }
                var evaluacion =
                    sesion.borradorEvaluacion(
                      tipo.codigo,
                      colegio: sesion.usaSupabase ? colegio : null,
                    ) ??
                    EvaluacionService()
                        .crearDesdePlantilla(tipo)
                        .copyWith(
                          responsableNombre: sesion.usuarioActual?.nombre,
                          colegio: colegio,
                        );
                final error = await sesion.guardarBorradorEvaluacionPersistente(
                  evaluacion,
                );
                if (!context.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
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

  Future<void> _generarReporteQuincenal(BuildContext context) async {
    final hoy = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year - 2),
      lastDate: hoy,
      initialDateRange: DateTimeRange(
        start: hoy.subtract(const Duration(days: 14)),
        end: hoy,
      ),
      helpText: 'Selecciona hasta 15 días',
      saveText: 'GENERAR REPORTE',
    );
    if (rango == null || !context.mounted) return;
    if (rango.duration.inDays > 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El reporte puede abarcar máximo 15 días.'),
        ),
      );
      return;
    }
    final sesion = context.read<SesionProvider>();
    final evaluaciones = sesion.evaluacionesCapacitacionVisibles;
    final registros = const PdfExportService().clasesCapacitacionEnRango(
      evaluaciones: evaluaciones,
      inicio: rango.start,
      fin: rango.end,
    );
    if (registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay clases evaluadas en el periodo seleccionado.'),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReporteCapacitacionesPreviewScreen(
          evaluaciones: evaluaciones,
          inicio: rango.start,
          fin: rango.end,
          generadoPor: sesion.usuarioActual?.nombre ?? 'Sin especificar',
        ),
      ),
    );
  }
}
