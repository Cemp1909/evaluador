import 'package:flutter/material.dart';

import '../models/bloque.dart';
import '../models/reemplazo_contenido.dart';
import '../theme/app_theme.dart';

class BloqueCard extends StatelessWidget {
  const BloqueCard({
    super.key,
    required this.bloque,
    required this.marcado,
    required this.itemsMarcados,
    required this.onItemChanged,
    required this.onBloqueChanged,
    this.habilitado = true,
    this.mensajeDeshabilitado,
    this.reemplazos = const {},
    this.onCambiar,
    this.onDeshacerCambio,
    this.estadosContenido = const {},
  });

  final Bloque bloque;
  final bool marcado;
  final Map<String, bool> itemsMarcados;
  final void Function(String itemTexto, bool marcado) onItemChanged;
  final ValueChanged<bool> onBloqueChanged;
  final bool habilitado;
  final String? mensajeDeshabilitado;
  final Map<String, String> reemplazos;
  final ValueChanged<String>? onCambiar;
  final ValueChanged<String>? onDeshacerCambio;
  final Map<String, EstadoContenidoClase> estadosContenido;

  @override
  Widget build(BuildContext context) {
    final completados = itemsMarcados.values.where((value) => value).length;
    final categoryColor = _colorParaBloque(bloque.nombre);

    return IgnorePointer(
      ignoring: !habilitado,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: habilitado ? 1 : .46,
        child: Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 38,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (marcado ? AppColors.success : categoryColor)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Icon(
                        _iconoParaBloque(bloque.nombre),
                        size: 20,
                        color: marcado ? AppColors.success : categoryColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bloque.nombre,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (bloque.items.isNotEmpty)
                            Text(
                              '$completados of ${bloque.items.length} items',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    if (!habilitado && mensajeDeshabilitado != null)
                      Chip(label: Text(mensajeDeshabilitado!))
                    else if (bloque.items.isNotEmpty)
                      TextButton(
                        onPressed: () => onBloqueChanged(!marcado),
                        child: Text(marcado ? 'Clear all' : 'Select all'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: AppSpacing.md),
                const SizedBox(height: AppSpacing.xs),
                if (bloque.items.isEmpty)
                  _ChecklistItem(
                    label: 'Content taught',
                    checked: marcado,
                    onChanged: onBloqueChanged,
                    estado: marcado
                        ? EstadoContenidoClase.ensenado
                        : EstadoContenidoClase.pendiente,
                    nombreTemporal: reemplazos[bloque.nombre],
                    onCambiar: onCambiar == null
                        ? null
                        : () => onCambiar!(bloque.nombre),
                    onDeshacer: onDeshacerCambio == null
                        ? null
                        : () => onDeshacerCambio!(bloque.nombre),
                  )
                else
                  for (final item in bloque.items)
                    Padding(
                      key: ValueKey('${bloque.nombre}-${item.texto}'),
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _ChecklistItem(
                        label: item.texto,
                        checked: itemsMarcados[item.texto] ?? false,
                        onChanged: (value) => onItemChanged(item.texto, value),
                        nombreTemporal: reemplazos[item.texto],
                        estado:
                            estadosContenido[item.texto] ??
                            EstadoContenidoClase.pendiente,
                        onCambiar: onCambiar == null
                            ? null
                            : () => onCambiar!(item.texto),
                        onDeshacer: onDeshacerCambio == null
                            ? null
                            : () => onDeshacerCambio!(item.texto),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconoParaBloque(String nombre) {
    final normalizado = nombre.toLowerCase();
    if (normalizado.contains('cancion') || normalizado.contains('song')) {
      return Icons.music_note_rounded;
    }
    if (normalizado.contains('diálogo') || normalizado.contains('dialogue')) {
      return Icons.forum_outlined;
    }
    if (normalizado.contains('vocabulario') ||
        normalizado.contains('vocabulary')) {
      return Icons.menu_book_outlined;
    }
    if (normalizado.contains('pregunta') || normalizado.contains('question')) {
      return Icons.quiz_outlined;
    }
    if (normalizado.contains('comando') || normalizado.contains('command')) {
      return Icons.touch_app_outlined;
    }
    if (normalizado.contains('gramática') || normalizado.contains('grammar')) {
      return Icons.spellcheck_rounded;
    }
    if (normalizado == 'abc') return Icons.abc_rounded;
    if (normalizado.contains('estrategia') ||
        normalizado.contains('strategy')) {
      return Icons.lightbulb_outline;
    }
    return Icons.checklist_rounded;
  }

  Color _colorParaBloque(String nombre) {
    final normalizado = nombre.toLowerCase();
    if (normalizado.contains('vocabulary') ||
        normalizado.contains('vocabulario')) {
      return AppColors.accent;
    }
    if (normalizado.contains('command') || normalizado.contains('comando')) {
      return AppColors.success;
    }
    return AppColors.primary;
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.label,
    required this.checked,
    required this.onChanged,
    this.nombreTemporal,
    this.onCambiar,
    this.onDeshacer,
    this.estado = EstadoContenidoClase.pendiente,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final String? nombreTemporal;
  final VoidCallback? onCambiar;
  final VoidCallback? onDeshacer;
  final EstadoContenidoClase estado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: checked
            ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF17352D)
                  : AppColors.successContainer)
            : scheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: checked
              ? AppColors.success.withValues(alpha: .45)
              : scheme.outline,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(!checked),
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: checked ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: checked ? AppColors.success : scheme.outline,
                    width: 1.4,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                    child: child,
                  ),
                  child: checked
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('check'),
                          size: 16,
                          color: Colors.white,
                        )
                      : const SizedBox(key: ValueKey('unchecked')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: checked ? AppColors.success : scheme.onSurface,
                    decoration: checked ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.success,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombreTemporal ?? label),
                      if (nombreTemporal != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Cambio temporal para esta clase · Original: $label',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.accent,
                                decoration: TextDecoration.none,
                              ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(switch (estado) {
                          EstadoContenidoClase.pendiente => 'Pendiente',
                          EstadoContenidoClase.ensenado => 'Enseñado',
                          EstadoContenidoClase.noEnsenado => 'No enseñado',
                          EstadoContenidoClase.reemplazadoTemporalmente =>
                            'Cambiado temporalmente',
                        }, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),
              if (nombreTemporal == null && onCambiar != null)
                Tooltip(
                  message: 'Cambiar temporalmente para esta clase',
                  child: SizedBox(
                    width: 62,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 48),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onCambiar,
                      child: const Text(
                        'Cambiar\nclase',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              if (nombreTemporal != null && onDeshacer != null)
                Tooltip(
                  message: 'Restaurar contenido original',
                  child: SizedBox(
                    width: 62,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 48),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onDeshacer,
                      child: const Text(
                        'Restaurar\noriginal',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
