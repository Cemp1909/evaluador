import 'package:flutter/material.dart';

import '../models/evaluacion.dart';
import '../models/evaluacion_clase.dart';
import '../models/evaluador_tipo.dart';
import '../services/evaluacion_service.dart';
import '../widgets/clase_card.dart';
import '../widgets/evaluacion_progress_card.dart';
import 'clase_detail_screen.dart';

class ClasesScreen extends StatefulWidget {
  const ClasesScreen({
    super.key,
    required this.tipo,
    required this.evaluacionInicial,
  });

  final EvaluadorTipo tipo;
  final Evaluacion evaluacionInicial;

  @override
  State<ClasesScreen> createState() => _ClasesScreenState();
}

class _ClasesScreenState extends State<ClasesScreen> {
  final _service = EvaluacionService();
  late Evaluacion _evaluacion = widget.evaluacionInicial;

  @override
  Widget build(BuildContext context) {
    final totalContenidos = _evaluacion.clases.fold<int>(
      0,
      (total, clase) => total + _totalContenidosClase(clase),
    );
    final contenidosMarcados = _evaluacion.clases.fold<int>(
      0,
      (total, clase) => total + _contenidosMarcadosClase(clase),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Clases')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              widget.tipo.nombre,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Revisa el avance y selecciona una clase para continuar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            EvaluacionProgressCard(
              completados: contenidosMarcados,
              total: totalContenidos,
            ),
            const SizedBox(height: 28),
            Text(
              'Plan de clases',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < widget.tipo.clases.length; index++) ...[
              ClaseCard(
                numero: widget.tipo.clases[index].numero,
                contenidosMarcados: _contenidosMarcadosClase(
                  _evaluacion.clases[index],
                ),
                totalContenidos: _totalContenidosClase(
                  _evaluacion.clases[index],
                ),
                onTap: () => _abrirClase(index),
              ),
              if (index < widget.tipo.clases.length - 1)
                const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  int _totalContenidosClase(EvaluacionClase clase) => clase.bloques.fold<int>(
    0,
    (total, bloque) =>
        total +
        (bloque.itemsMarcados.isEmpty ? 1 : bloque.itemsMarcados.length),
  );

  int _contenidosMarcadosClase(EvaluacionClase clase) =>
      clase.bloques.fold<int>(
        0,
        (total, bloque) =>
            total +
            (bloque.itemsMarcados.isEmpty
                ? (bloque.marcado ? 1 : 0)
                : bloque.itemsMarcados.values.where((valor) => valor).length),
      );

  Future<void> _abrirClase(int index) async {
    final resultado = await Navigator.of(context).push<Evaluacion>(
      MaterialPageRoute(
        builder: (_) => ClaseDetailScreen(
          plantilla: widget.tipo.clases[index],
          evaluacion: _evaluacion,
          service: _service,
        ),
      ),
    );
    if (resultado != null && mounted) {
      setState(() => _evaluacion = resultado);
    }
  }
}
