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
}
