import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_knowledge_report.dart';
import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
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
            .historialEstudiante(reporteBase.profesorEvaluado)
            .where((reporte) => reporte.grado == reporteBase.grado)
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
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            reporteBase.profesorEvaluado,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('${reporteBase.grado} · ${reporteBase.colegio}'),
          const SizedBox(height: 22),
          for (final periodo in [1, 2, 3, 4]) ...[
            _barraPeriodo(context, periodo, _reportePeriodo(reportes, periodo)),
            const SizedBox(height: 12),
          ],
          if (categorias.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Evolución por categoría',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            for (final categoria in categorias)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
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
            const SizedBox(height: 18),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alertas pedagógicas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Estos contenidos aparecen como no logrados en dos o más períodos:',
                    ),
                    const SizedBox(height: 6),
                    for (final alerta in alertas) Text('• $alerta'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text('Reportes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final reporte in reportes)
            Card(
              child: ListTile(
                title: Text(
                  'Período ${reporte.periodo} · ${reporte.notaFinal.toStringAsFixed(1)}',
                ),
                subtitle: Text(
                  reporte.aprobadoPorCoordinador
                      ? 'Aprobado por ${reporte.nombreCoordinador}'
                      : 'Pendiente de aprobación del coordinador',
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
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text('Período $periodo')),
          Text(
            reporte == null
                ? 'Sin evaluación'
                : reporte.notaFinal.toStringAsFixed(1),
          ),
        ],
      ),
      const SizedBox(height: 5),
      LinearProgressIndicator(
        value: reporte == null ? 0 : reporte.notaFinal / 5,
        minHeight: 12,
        borderRadius: BorderRadius.circular(20),
      ),
    ],
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
    final error = context.read<SesionProvider>().aprobarReporteConocimiento(
      reporteId: reporte.id,
      firma: firma,
    );
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
