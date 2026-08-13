import 'clase.dart';

class EvaluadorTipo {
  const EvaluadorTipo({
    required this.codigo,
    required this.nombre,
    required this.clases,
  });

  final String codigo;
  final String nombre;
  final List<Clase> clases;
}
