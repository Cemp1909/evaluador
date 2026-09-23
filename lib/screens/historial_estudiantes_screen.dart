import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_knowledge_report.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import 'pdf_preview_screen.dart';
import 'comparacion_periodos_screen.dart';

class HistorialEstudiantesScreen extends StatefulWidget {
  const HistorialEstudiantesScreen({super.key});

  static const routeName = '/historial_estudiantes';

  @override
  State<HistorialEstudiantesScreen> createState() =>
      _HistorialEstudiantesScreenState();
}

class _HistorialEstudiantesScreenState
    extends State<HistorialEstudiantesScreen> {
  String _busqueda = '';
  String? _grado;
  int? _periodo;

  @override
  Widget build(BuildContext context) {
    final reportes =
        context
            .watch<SesionProvider>()
            .reportesConocimiento
            .where(_coincide)
            .toList()
          ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluaciones por período')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          TextField(
            onChanged: (value) => setState(() => _busqueda = value),
            decoration: const InputDecoration(
              labelText: 'Buscar por colegio o profesor responsable',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _grado,
                  decoration: const InputDecoration(labelText: 'Grado'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(
                      value: 'Párvulos',
                      child: Text('Párvulos'),
                    ),
                    DropdownMenuItem(
                      value: 'Prejardín',
                      child: Text('Prejardín'),
                    ),
                    DropdownMenuItem(value: 'Jardín', child: Text('Jardín')),
                    DropdownMenuItem(
                      value: 'Transición',
                      child: Text('Transición'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _grado = value),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _periodo,
                  decoration: const InputDecoration(labelText: 'Período'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 1, child: Text('1')),
                    DropdownMenuItem(value: 2, child: Text('2')),
                    DropdownMenuItem(value: 3, child: Text('3')),
                    DropdownMenuItem(value: 4, child: Text('4')),
                  ],
                  onChanged: (value) => setState(() => _periodo = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (reportes.isEmpty)
            Center(
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
                        Icons.search_off_rounded,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No hay evaluaciones que coincidan con los filtros. Los datos se conservan solo durante esta sesión.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            for (final reporte in reportes) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      reporte.notaFinal.toStringAsFixed(1),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  title: Text(
                    '${reporte.colegio} · ${reporte.grado}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Profesor responsable: ${reporte.profesorResponsableSalon}\n'
                    'Período ${reporte.periodo} · ${reporte.desempeno}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Ver PDF',
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PdfPreviewScreen(reporte: reporte),
                      ),
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ComparacionPeriodosScreen(reporteBase: reporte),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  bool _coincide(StudentKnowledgeReport reporte) {
    final texto = _busqueda.trim().toLowerCase();
    final coincideTexto =
        texto.isEmpty ||
        reporte.colegio.toLowerCase().contains(texto) ||
        reporte.profesorResponsableSalon.toLowerCase().contains(texto);
    return coincideTexto &&
        (_grado == null || reporte.grado == _grado) &&
        (_periodo == null || reporte.periodo == _periodo);
  }
}
