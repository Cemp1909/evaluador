import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/docente_colegio.dart';
import '../models/evaluacion.dart';
import '../providers/sesion_provider.dart';

Future<void> editarDocentesColegio(
  BuildContext context, {
  String colegio = '',
  Evaluacion? evaluacion,
}) async {
  final sesion = context.read<SesionProvider>();
  final escuela = TextEditingController(text: colegio);
  final preescolar = TextEditingController(
    text: sesion
        .docentesColegio(colegio, nivel: NivelDocente.preescolar)
        .join('\n'),
  );
  final primaria = TextEditingController(
    text: sesion
        .docentesColegio(colegio, nivel: NivelDocente.primaria)
        .join('\n'),
  );
  var guardando = false;
  final ruta = DialogRoute<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Docentes que recibirán capacitación'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: escuela,
                readOnly: colegio.isNotEmpty,
                decoration: const InputDecoration(labelText: 'Colegio'),
                onChanged: (value) {
                  preescolar.text = sesion
                      .docentesColegio(value, nivel: NivelDocente.preescolar)
                      .join('\n');
                  primaria.text = sesion
                      .docentesColegio(value, nivel: NivelDocente.primaria)
                      .join('\n');
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: preescolar,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Profesores de preescolar',
                  helperText: 'Un nombre por línea',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: primaria,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Profesores de primaria',
                  helperText: 'Un nombre por línea',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Si un profesor ya está activo en otro colegio, al guardarlo aquí se registra su traslado y se conserva el historial anterior. Un profesor nuevo comienza sin registros retroactivos.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (guardando) return;
            guardando = true;
            final error = evaluacion == null
                ? await sesion.asignarDocentesColegioPorNivelPersistente(
                    escuela.text,
                    preescolar: preescolar.text.split('\n'),
                    primaria: primaria.text.split('\n'),
                  )
                : await sesion.registrarDocentesDesdeClasePersistente(
                    evaluacion,
                    preescolar: preescolar.text.split('\n'),
                    primaria: primaria.text.split('\n'),
                  );
            guardando = false;
            if (!ctx.mounted) return;
            if (error != null) {
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(SnackBar(content: Text(error)));
              return;
            }
            Navigator.pop(ctx);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  await Navigator.of(context).push(ruta);
  ruta.completed.then((_) {
    escuela.dispose();
    preescolar.dispose();
    primaria.dispose();
  });
}

class DocentesColegioCard extends StatelessWidget {
  const DocentesColegioCard({
    super.key,
    required this.colegio,
    required this.asistencia,
    required this.onChanged,
    required this.evaluacion,
    this.nivel,
  });
  final String colegio;
  final Map<String, bool> asistencia;
  final void Function(Map<String, bool>)? onChanged;
  final Evaluacion evaluacion;
  final NivelDocente? nivel;
  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    final nombres = {
      ...sesion.docentesColegio(colegio, nivel: nivel),
      ...asistencia.keys,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asistencia de docentes${nivel == null ? '' : ' · ${nivel!.nombre}'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (sesion.puedeRegistrarDocentesEnClase(evaluacion))
              TextButton.icon(
                onPressed: () => editarDocentesColegio(
                  context,
                  colegio: colegio,
                  evaluacion: evaluacion,
                ),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Configurar docentes del colegio'),
              ),
            if (nombres.isEmpty)
              const Text('Aún no hay docentes asignados a este colegio.'),
            for (final nombre in nombres)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        nombre,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('$nombre:${asistencia[nombre]}'),
                        initialValue: asistencia[nombre] == null
                            ? 'pendiente'
                            : asistencia[nombre]!
                            ? 'si'
                            : 'no',
                        isExpanded: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Asistencia',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'pendiente',
                            child: Text('Sin marcar'),
                          ),
                          DropdownMenuItem(value: 'si', child: Text('Asistió')),
                          DropdownMenuItem(
                            value: 'no',
                            child: Text('No asistió'),
                          ),
                        ],
                        onChanged: onChanged == null
                            ? null
                            : (value) {
                                final nueva = Map<String, bool>.from(
                                  asistencia,
                                );
                                if (value == 'pendiente') {
                                  nueva.remove(nombre);
                                } else {
                                  nueva[nombre] = value == 'si';
                                }
                                onChanged!(nueva);
                              },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
