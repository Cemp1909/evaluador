import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/configuracion_notas.dart';
import '../providers/sesion_provider.dart';
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
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Configuración de notas',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Esta configuración vive únicamente durante la sesión de prueba.',
        ),
        const SizedBox(height: 24),
        _control(
          'Puntos por Logrado',
          _configuracion.puntosLogrado,
          1,
          5,
          (value) =>
              _configuracion = _configuracion.copyWith(puntosLogrado: value),
        ),
        _control(
          'Puntos por Por reforzar',
          _configuracion.puntosPorReforzar,
          1,
          5,
          (value) => _configuracion = _configuracion.copyWith(
            puntosPorReforzar: value,
          ),
        ),
        _control(
          'Puntos por No logrado',
          _configuracion.puntosNoLogrado,
          1,
          5,
          (value) =>
              _configuracion = _configuracion.copyWith(puntosNoLogrado: value),
        ),
        const Divider(height: 32),
        _control(
          'Inicio de Superior',
          _configuracion.inicioSuperior,
          3,
          5,
          (value) =>
              _configuracion = _configuracion.copyWith(inicioSuperior: value),
        ),
        _control(
          'Inicio de Alto',
          _configuracion.inicioAlto,
          2,
          5,
          (value) =>
              _configuracion = _configuracion.copyWith(inicioAlto: value),
        ),
        _control(
          'Inicio de Básico',
          _configuracion.inicioBasico,
          1,
          5,
          (value) =>
              _configuracion = _configuracion.copyWith(inicioBasico: value),
        ),
        const SizedBox(height: 20),
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
    ValueChanged<double> actualizar,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo)),
              Text(value.toStringAsFixed(1)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) * 10).round(),
            label: value.toStringAsFixed(1),
            onChanged: (nuevo) => setState(() => actualizar(nuevo)),
          ),
        ],
      ),
    ),
  );

  void _guardar() {
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
    context.read<SesionProvider>().actualizarConfiguracionNotas(_configuracion);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada en esta sesión.')),
    );
  }
}
