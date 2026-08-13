import 'bloque.dart';

class Clase {
  const Clase({
    required this.numero,
    required this.bloques,
    this.contenidoPendiente = false,
  });

  final int numero;
  final List<Bloque> bloques;
  final bool contenidoPendiente;
}
