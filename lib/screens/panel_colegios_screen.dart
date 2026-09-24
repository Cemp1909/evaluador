import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_knowledge_report.dart';
import '../models/docente_colegio.dart';
import '../models/contacto_colegio.dart';
import '../models/resumen_seguimiento_profesor.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/docentes_colegio_card.dart';
import '../security/rbac.dart';

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
    final sesion = context.watch<SesionProvider>();
    for (final nombre in sesion.colegiosRegistrados) {
      if (!colegios.keys.any(
        (key) => key.trim().toLowerCase() == nombre.trim().toLowerCase(),
      )) {
        colegios[nombre] = [];
      }
    }
    final entradas = colegios.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final puedeGestionar = sesion.tienePermiso(Permiso.asignarProfesores);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de colegios'),
        actions: [
          if (puedeGestionar)
            TextButton.icon(
              onPressed: () => _agregarColegio(context),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Agregar colegio'),
            ),
        ],
      ),
      floatingActionButton: sesion.tienePermiso(Permiso.asignarProfesores)
          ? FloatingActionButton.extended(
              onPressed: () => editarDocentesColegio(context),
              icon: const Icon(Icons.group_add),
              label: const Text('Asignar docentes'),
            )
          : null,
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
                      puedeGestionar
                          ? 'Aún no hay colegios registrados.'
                          : 'Aún no hay evaluaciones para consolidar.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (puedeGestionar) ...[
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => _agregarColegio(context),
                        icon: const Icon(Icons.add_business_outlined),
                        label: const Text('Agregar primer colegio'),
                      ),
                    ],
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
                    (entrada.value.isEmpty ? 1 : entrada.value.length);
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
                      if (sesion.contactoColegio(entrada.key).ciudad.isNotEmpty)
                        Text(
                          'Ciudad: ${sesion.contactoColegio(entrada.key).ciudad}',
                        ),
                      if (sesion
                          .contactoColegio(entrada.key)
                          .direccion
                          .isNotEmpty)
                        Text(
                          'Dirección: ${sesion.contactoColegio(entrada.key).direccion}',
                        ),
                      if (sesion
                          .contactoColegio(entrada.key)
                          .telefono
                          .isNotEmpty)
                        Text(
                          'Teléfono: ${sesion.contactoColegio(entrada.key).telefono}',
                        ),
                      if (sesion.tienePermiso(Permiso.asignarProfesores))
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                _editarContactoColegio(context, entrada.key),
                            icon: const Icon(Icons.edit_location_alt_outlined),
                            label: const Text('Editar datos del colegio'),
                          ),
                        ),
                      Text(
                        'Preescolar: ${sesion.docentesColegio(entrada.key, nivel: NivelDocente.preescolar).join(', ')}',
                      ),
                      Text(
                        'Primaria: ${sesion.docentesColegio(entrada.key, nivel: NivelDocente.primaria).join(', ')}',
                      ),
                      if (sesion
                          .asignacionesDocentesColegio(
                            entrada.key,
                            incluirInactivas: true,
                          )
                          .any((item) => !item.activo)) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Historial de asignaciones',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        for (final asignacion
                            in sesion
                                .asignacionesDocentesColegio(
                                  entrada.key,
                                  incluirInactivas: true,
                                )
                                .where((item) => !item.activo))
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${asignacion.nombre} · ${asignacion.nivel.nombre} · '
                              '${_fechaCorta(asignacion.fechaInicio)} a ${_fechaCorta(asignacion.fechaFin!)}',
                            ),
                          ),
                      ],
                      if (sesion.tienePermiso(Permiso.asignarProfesores))
                        TextButton(
                          onPressed: () => editarDocentesColegio(
                            context,
                            colegio: entrada.key,
                          ),
                          child: const Text('Editar docentes'),
                        ),
                      const Divider(height: AppSpacing.md),
                      _Metrica('Nota promedio', promedio.toStringAsFixed(1)),
                      _Metrica('Grados evaluados', '$grados'),
                      _Metrica('Contenidos no logrados', '$bajos'),
                      _Metrica(
                        'Reportes aprobados',
                        '${entrada.value.where((e) => e.aprobadoPorCoordinador).length}',
                      ),
                      const Divider(height: AppSpacing.lg),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Seguimiento por profesor',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (sesion.seguimientoProfesores(entrada.key).isEmpty)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('No hay profesores asignados.'),
                        )
                      else
                        for (final resumen in sesion.seguimientoProfesores(
                          entrada.key,
                        ))
                          _ProfesorSeguimientoCard(resumen: resumen),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

Future<void> _agregarColegio(BuildContext context) async {
  final nombre = TextEditingController();
  final zona = TextEditingController();
  final ciudad = TextEditingController();
  final direccion = TextEditingController();
  final telefono = TextEditingController();
  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar colegio'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombre,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del colegio *',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: zona,
                  decoration: const InputDecoration(labelText: 'Zona *'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: ciudad,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad o municipio',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: direccion,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: telefono,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final error = await context.read<SesionProvider>().crearColegio(
                nombre: nombre.text,
                zona: zona.text,
                contacto: ContactoColegio(
                  ciudad: ciudad.text,
                  direccion: direccion.text,
                  telefono: telefono.text,
                ),
              );
              if (!dialogContext.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar colegio'),
          ),
        ],
      ),
    );
  } finally {
    nombre.dispose();
    zona.dispose();
    ciudad.dispose();
    direccion.dispose();
    telefono.dispose();
  }
}

Future<void> _editarContactoColegio(
  BuildContext context,
  String colegio,
) async {
  final sesion = context.read<SesionProvider>();
  final actual = sesion.contactoColegio(colegio);
  final ciudad = TextEditingController(text: actual.ciudad);
  final direccion = TextEditingController(text: actual.direccion);
  final telefono = TextEditingController(text: actual.telefono);
  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Datos de $colegio'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ciudad,
                decoration: const InputDecoration(
                  labelText: 'Ciudad o municipio',
                ),
              ),
              TextField(
                controller: direccion,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              TextField(
                controller: telefono,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final error = await sesion.guardarContactoColegio(
                colegio,
                ContactoColegio(
                  ciudad: ciudad.text,
                  direccion: direccion.text,
                  telefono: telefono.text,
                ),
              );
              if (!dialogContext.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  } finally {
    ciudad.dispose();
    direccion.dispose();
    telefono.dispose();
  }
}

String _fechaCorta(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

class _ProfesorSeguimientoCard extends StatelessWidget {
  const _ProfesorSeguimientoCard({required this.resumen});

  final ResumenSeguimientoProfesor resumen;

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: ExpansionTile(
      leading: const Icon(Icons.person_outline),
      title: Text(resumen.profesor),
      subtitle: Text(
        resumen.clasesAsistidas + resumen.inasistencias == 0
            ? '${resumen.nivel?.nombre ?? 'Nivel sin asignar'} · Asistencia aún sin registrar'
            : '${resumen.nivel?.nombre ?? 'Nivel sin asignar'} · Asistencia ${resumen.porcentajeAsistencia.toStringAsFixed(0)}%',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      children: [
        _Metrica('Clases cumplidas', '${resumen.clasesAsistidas}'),
        _Metrica('Inasistencias', '${resumen.inasistencias}'),
        _Metrica('Clases por registrar', '${resumen.clasesPendientes}'),
        _Metrica('Contenidos enseñados', '${resumen.contenidosEnsenados}'),
        _Metrica('Contenidos pendientes', '${resumen.contenidosPendientes}'),
        _Metrica(
          'Contenidos reemplazados',
          '${resumen.contenidosReemplazados}',
        ),
        if (resumen.avancesSalon.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _DetalleSeguimiento(
            titulo: 'Avance del salón por período (informativo)',
            valores: resumen.avancesSalon,
          ),
        ],
        if (resumen.observaciones.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _DetalleSeguimiento(
            titulo: 'Observaciones',
            valores: resumen.observaciones,
          ),
        ],
      ],
    ),
  );
}

class _DetalleSeguimiento extends StatelessWidget {
  const _DetalleSeguimiento({required this.titulo, required this.valores});

  final String titulo;
  final List<String> valores;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        for (final valor in valores)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('• $valor'),
          ),
      ],
    ),
  );
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
