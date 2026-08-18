import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_knowledge_report.dart';
import '../providers/sesion_provider.dart';
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
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            onChanged: (value) => setState(() => _busqueda = value),
            decoration: const InputDecoration(
              labelText: 'Buscar por estudiante o colegio',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
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
              const SizedBox(width: 10),
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
          const SizedBox(height: 20),
          if (reportes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No hay evaluaciones que coincidan con los filtros. Los datos se conservan solo durante esta sesión.',
                ),
              ),
            )
          else
            for (final reporte in reportes) ...[
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(reporte.notaFinal.toStringAsFixed(1)),
                  ),
                  title: Text(reporte.profesorEvaluado),
                  subtitle: Text(
                    '${reporte.grado} · Período ${reporte.periodo}\n'
                    '${reporte.colegio} · ${reporte.desempeno}',
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
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  bool _coincide(StudentKnowledgeReport reporte) {
    final texto = _busqueda.trim().toLowerCase();
    final coincideTexto =
        texto.isEmpty ||
        reporte.profesorEvaluado.toLowerCase().contains(texto) ||
        reporte.colegio.toLowerCase().contains(texto);
    return coincideTexto &&
        (_grado == null || reporte.grado == _grado) &&
        (_periodo == null || reporte.periodo == _periodo);
  }
}
