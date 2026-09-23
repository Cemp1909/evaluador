import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_knowledge_report.dart';
import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/signature_capture_dialog.dart';
import 'pdf_preview_screen.dart';

class ComparacionPeriodosScreen extends StatelessWidget {
  const ComparacionPeriodosScreen({super.key, required this.reporteBase});

  final StudentKnowledgeReport reporteBase;

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    final reportes =
        sesion
            .historialSalon(
              reporteBase.colegio,
              reporteBase.grado,
              profesor: reporteBase.profesorResponsableSalon,
            )
            .toList()
          ..sort((a, b) => a.periodo.compareTo(b.periodo));
    final puedeAprobar = sesion.usuarioActual?.rol == RolUsuario.coordinador;
    final categorias =
        reportes
            .expand((reporte) => reporte.resultadosContenido.keys)
            .map(_categoriaDesdeId)
            .toSet()
            .toList()
          ..sort();
    final alertas = _alertasRepetidas(reportes);
    return Scaffold(
      appBar: AppBar(title: const Text('Comparación entre períodos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            reporteBase.grado,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${reporteBase.colegio} · ${reporteBase.profesorResponsableSalon}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final periodo in [1, 2, 3, 4]) ...[
            _barraPeriodo(context, periodo, _reportePeriodo(reportes, periodo)),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (categorias.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Evolución por categoría',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final categoria in categorias)
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final periodo in [1, 2, 3, 4])
                            Chip(
                              label: Text(
                                'P$periodo: ${_notaCategoria(_reportePeriodo(reportes, periodo), categoria)}',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (alertas.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Card(
              clipBehavior: Clip.antiAlias,
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Alertas pedagógicas',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Estos contenidos aparecen como no logrados en dos o más períodos:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final alerta in alertas)
                      Text(
                        '• $alerta',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Reportes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final reporte in reportes)
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    reporte.notaFinal.toStringAsFixed(1),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                title: Text(
                  'Período ${reporte.periodo} · ${reporte.notaFinal.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(
                  reporte.aprobadoPorCoordinador
                      ? 'Aprobado por ${reporte.nombreCoordinador}'
                      : 'Pendiente de aprobación del coordinador',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Ver PDF',
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PdfPreviewScreen(reporte: reporte),
                        ),
                      ),
                    ),
                    if (puedeAprobar && !reporte.aprobadoPorCoordinador)
                      IconButton(
                        tooltip: 'Aprobar y firmar',
                        icon: const Icon(Icons.verified_outlined),
                        onPressed: () => _aprobar(context, reporte),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _barraPeriodo(
    BuildContext context,
    int periodo,
    StudentKnowledgeReport? reporte,
  ) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Período $periodo',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  reporte == null
                      ? 'Sin evaluación'
                      : reporte.notaFinal.toStringAsFixed(1),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: reporte == null ? 0 : reporte.notaFinal / 5,
            minHeight: 8,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ],
      ),
    ),
  );

  StudentKnowledgeReport? _reportePeriodo(
    List<StudentKnowledgeReport> reportes,
    int periodo,
  ) {
    for (final reporte in reportes.reversed) {
      if (reporte.periodo == periodo) return reporte;
    }
    return null;
  }

  Future<void> _aprobar(
    BuildContext context,
    StudentKnowledgeReport reporte,
  ) async {
    final firma = await SignatureCaptureDialog.show(
      context,
      'Firma de aprobación del coordinador',
    );
    if (firma == null || !context.mounted) return;
    final error = await context
        .read<SesionProvider>()
        .aprobarReporteConocimientoPersistente(
      reporteId: reporte.id,
      firma: firma,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Reporte aprobado y firmado correctamente.'),
      ),
    );
  }

  String _categoriaDesdeId(String id) {
    final partes = id.split('|');
    return partes.length > 1 ? partes[1] : 'General';
  }

  String _notaCategoria(StudentKnowledgeReport? reporte, String categoria) {
    if (reporte == null) return '—';
    final resultados = reporte.resultadosContenido.entries
        .where((entry) => _categoriaDesdeId(entry.key) == categoria)
        .map((entry) => entry.value)
        .toList();
    if (resultados.isEmpty) return '—';
    return calcularNotaConocimiento(
      resultados,
      reporte.configuracionNotas,
    ).toStringAsFixed(1);
  }

  List<String> _alertasRepetidas(List<StudentKnowledgeReport> reportes) {
    final repeticiones = <String, int>{};
    for (final reporte in reportes) {
      final delPeriodo = <String>{};
      for (final entry in reporte.resultadosContenido.entries) {
        if (entry.value != ResultadoContenido.noLogrado) continue;
        delPeriodo.add(reporte.nombresContenido[entry.key] ?? entry.key);
      }
      for (final nombre in delPeriodo) {
        repeticiones[nombre] = (repeticiones[nombre] ?? 0) + 1;
      }
    }
    return repeticiones.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => '${entry.key} (${entry.value} períodos)')
        .toList();
  }
}
