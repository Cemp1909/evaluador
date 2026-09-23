import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/estado_evaluacion_profesor.dart';
import '../models/docente_colegio.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_brand_title.dart';

class EvaluacionProfesoresScreen extends StatelessWidget {
  const EvaluacionProfesoresScreen({super.key});

  static const routeName = '/evaluacion_profesores';

  @override
  Widget build(BuildContext context) {
    final estados = context
        .watch<SesionProvider>()
        .estadoEvaluacionesProfesores();
    return Scaffold(
      appBar: AppBar(title: const AppBrandTitle(compact: true)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'Evaluación y reconocimiento de profesores',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'El profesor debe completar las clases y los cuatro períodos, '
            'cumplir la asistencia mínima y alcanzar el resultado mínimo en '
            'las evaluaciones de sus salones.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (estados.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Primero asigna profesores a un colegio para ver su proceso.',
                ),
              ),
            )
          else
            for (final estado in estados) ...[
              _EstadoProfesorCard(estado: estado),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _EstadoProfesorCard extends StatelessWidget {
  const _EstadoProfesorCard({required this.estado});

  final EstadoEvaluacionProfesor estado;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      leading: CircleAvatar(
        child: Icon(
          estado.habilitada ? Icons.lock_open_outlined : Icons.lock_outline,
        ),
      ),
      title: Text(estado.profesor),
      subtitle: Text(
        '${estado.colegio} · ${estado.nivel.nombre} · '
        '${estado.estadoProceso}',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      children: [
        _EstadoFila(
          etiqueta: 'Asignación',
          valor: estado.fechaFin == null
              ? 'Desde ${_fecha(estado.fechaInicio)}'
              : '${_fecha(estado.fechaInicio)} a ${_fecha(estado.fechaFin!)}',
          completo: estado.asignacionActiva,
        ),
        _EstadoFila(
          etiqueta: 'Períodos del salón',
          valor: '${estado.periodosCompletos.length} de 4',
          completo: estado.periodosTerminados,
        ),
        _EstadoFila(
          etiqueta: 'Clases programadas',
          valor: '${estado.clasesCompletadas} de ${estado.clasesProgramadas}',
          completo: estado.clasesTerminadas,
        ),
        _EstadoFila(
          etiqueta: 'Contenidos enseñados',
          valor: '${estado.contenidosEvaluables.length}',
          completo: estado.contenidosEvaluables.isNotEmpty,
        ),
        _EstadoFila(
          etiqueta: 'Asistencia',
          valor:
              '${estado.porcentajeAsistencia.toStringAsFixed(0)}% '
              '(mínimo ${estado.asistenciaMinima}%)',
          completo: estado.cumpleAsistencia,
        ),
        _EstadoFila(
          etiqueta: 'Evaluaciones por período',
          valor: estado.evaluacionesSalon == 0
              ? 'Sin períodos'
              : '${estado.porcentajeEvaluacionesPeriodos.toStringAsFixed(0)}% '
                    '(mínimo ${estado.evaluacionPeriodosMinima}%)',
          completo:
              estado.periodosTerminados && estado.cumpleEvaluacionesPeriodos,
        ),
        if (estado.contenidosEvaluables.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Contenidos para la futura evaluación',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final contenido in estado.contenidosEvaluables)
                  Chip(label: Text(contenido)),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reconocimiento',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                estado.reconocimientoListo
                    ? 'Información completa para calcular el reconocimiento.'
                    : estado.habilitada
                    ? 'Cumple los requisitos de asistencia y evaluaciones por período. Pendiente de completar la evaluación docente.'
                    : 'Pendiente: debe completar el proceso y cumplir los porcentajes mínimos configurados.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: estado.habilitada
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'El formulario se agregará cuando la empresa entregue los criterios de evaluación.',
                      ),
                    ),
                  )
                : null,
            icon: const Icon(Icons.assignment_ind_outlined),
            label: Text(
              estado.habilitada
                  ? 'Preparar evaluación'
                  : 'Evaluación bloqueada',
            ),
          ),
        ),
      ],
    ),
  );

  static String _fecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}

class _EstadoFila extends StatelessWidget {
  const _EstadoFila({
    required this.etiqueta,
    required this.valor,
    required this.completo,
  });

  final String etiqueta;
  final String valor;
  final bool completo;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      completo ? Icons.check_circle_outline : Icons.pending_outlined,
      color: completo
          ? AppColors.success
          : Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    title: Text(etiqueta),
    trailing: Text(valor),
  );
}
