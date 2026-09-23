import 'package:flutter/material.dart';

/// Selector reutilizable para catálogos; permite escritura mientras no hay datos.
class SelectorRegistro extends StatelessWidget {
  const SelectorRegistro({
    super.key,
    required this.controller,
    required this.opciones,
    required this.etiqueta,
    required this.icono,
    required this.onChanged,
    this.validator,
  });
  final TextEditingController controller;
  final List<String> opciones;
  final String etiqueta;
  final IconData icono;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final decoracion = InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono),
    );
    if (opciones.isEmpty) {
      return TextFormField(
        controller: controller,
        decoration: decoracion,
        textCapitalization: TextCapitalization.words,
        onChanged: onChanged,
        validator: validator,
      );
    }
    final valor = opciones
        .where(
          (e) => e.trim().toLowerCase() == controller.text.trim().toLowerCase(),
        )
        .firstOrNull;
    // Conserva los nombres de borradores anteriores aunque cambie el catálogo.
    final anteriores = valor == null && controller.text.trim().isNotEmpty
        ? [controller.text.trim()]
        : <String>[];
    return DropdownButtonFormField<String>(
      key: ValueKey('$etiqueta:${controller.text}:${opciones.join('|')}'),
      initialValue: valor ?? anteriores.firstOrNull,
      isExpanded: true,
      decoration: decoracion,
      validator: validator,
      items: [
        for (final nombre in [...opciones, ...anteriores])
          DropdownMenuItem(value: nombre, child: Text(nombre)),
      ],
      onChanged: (nombre) {
        if (nombre == null) return;
        controller.text = nombre;
        onChanged(nombre);
      },
    );
  }
}
