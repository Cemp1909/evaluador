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
          ? const Center(
              child: Text('Aún no hay evaluaciones para consolidar.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: entradas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                  child: ExpansionTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.school_outlined),
                    ),
                    title: Text(entrada.key),
                    subtitle: Text('${entrada.value.length} evaluaciones'),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
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
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(etiqueta)),
        Text(valor, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
