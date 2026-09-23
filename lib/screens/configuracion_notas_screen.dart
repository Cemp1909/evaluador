import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/configuracion_notas.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_brand_title.dart';

class ConfiguracionNotasScreen extends StatefulWidget {
  const ConfiguracionNotasScreen({super.key});

  static const routeName = '/configuracion_notas';

  @override
  State<ConfiguracionNotasScreen> createState() =>
      _ConfiguracionNotasScreenState();
}

class _ConfiguracionNotasScreenState extends State<ConfiguracionNotasScreen> {
  late ConfiguracionNotas _configuracion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configuracion = context.read<SesionProvider>().configuracionNotas;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
          'Configuración de notas y requisitos',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Esta configuración vive únicamente durante la sesión de prueba.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        _control(
          'Puntos por Logrado',
          _configuracion.puntosLogrado,
          1,
          5,
          (value) =>
              _configuracion = _configuracion.copyWith(puntosLogrado: value),
        ),
        const SizedBox(height: AppSpacing.sm),
        _control(
          'Puntos por Por reforzar',
          _configuracion.puntosPorReforzar,
          1,
          5,
          (value) => _configuracion = _configuracion.copyWith(
            puntosPorReforzar: value,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _control(
          'Puntos por No logrado',
          _configuracion.puntosNoLogrado,
          1,
          5,
          (value) =>
              _configuracion = _configuracion.copyWith(puntosNoLogrado: value),
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: AppSpacing.lg),
        const SizedBox(height: AppSpacing.md),
        _control(
          'Inicio de Superior',
          _configuracion.inicioSuperior,
          3,
          5,
          (value) =>
              _configuracion = _configuracion.copyWith(inicioSuperior: value),
        ),
        const SizedBox(height: AppSpacing.sm),
        _control(
          'Inicio de Alto',
          _configuracion.inicioAlto,
          2,
          5,
          (value) =>
              _configuracion = _configuracion.copyWith(inicioAlto: value),
        ),
        const SizedBox(height: AppSpacing.sm),
        _control(
          'Inicio de Básico',
          _configuracion.inicioBasico,
          1,
          5,
          (value) =>
              _configuracion = _configuracion.copyWith(inicioBasico: value),
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: AppSpacing.lg),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Requisitos para profesores',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Porcentajes mínimos para aprobar el proceso.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _control(
          'Asistencia mínima',
          _configuracion.asistenciaMinimaProfesor.toDouble(),
          0,
          100,
          (value) => _configuracion = _configuracion.copyWith(
            asistenciaMinimaProfesor: value.round(),
          ),
          unidad: '%',
          divisiones: 100,
        ),
        const SizedBox(height: AppSpacing.sm),
        _control(
          'Evaluaciones por período mínimas',
          _configuracion.evaluacionPeriodosMinimaProfesor.toDouble(),
          0,
          100,
          (value) => _configuracion = _configuracion.copyWith(
            evaluacionPeriodosMinimaProfesor: value.round(),
          ),
          unidad: '%',
          divisiones: 100,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: _guardar,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar configuración'),
        ),
      ],
    ),
  );

  Widget _control(
    String titulo,
    double value,
    double min,
    double max,
    ValueChanged<double> actualizar, {
    String unidad = '',
    int? divisiones,
  }) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${unidad.isEmpty ? value.toStringAsFixed(1) : value.toStringAsFixed(0)}$unidad',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisiones ?? ((max - min) * 10).round(),
            label:
                '${unidad.isEmpty ? value.toStringAsFixed(1) : value.toStringAsFixed(0)}$unidad',
            onChanged: (nuevo) => setState(() => actualizar(nuevo)),
          ),
        ],
      ),
    ),
  );

  Future<void> _guardar() async {
    if (!(_configuracion.puntosLogrado >= _configuracion.puntosPorReforzar &&
        _configuracion.puntosPorReforzar >= _configuracion.puntosNoLogrado &&
        _configuracion.inicioSuperior > _configuracion.inicioAlto &&
        _configuracion.inicioAlto > _configuracion.inicioBasico)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa el orden de los puntajes y rangos.'),
        ),
      );
      return;
    }
    final error = await context
        .read<SesionProvider>()
        .actualizarConfiguracionNotasPersistente(_configuracion);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (context.read<SesionProvider>().usaSupabase
                  ? 'Configuración guardada en Supabase.'
                  : 'Configuración guardada en esta sesión.'),
        ),
      ),
    );
  }
}
