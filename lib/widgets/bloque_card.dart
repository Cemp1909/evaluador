import 'package:flutter/material.dart';

import '../models/bloque.dart';
import '../theme/app_theme.dart';

class BloqueCard extends StatelessWidget {
  const BloqueCard({
    super.key,
    required this.bloque,
    required this.marcado,
    required this.itemsMarcados,
    required this.onItemChanged,
    required this.onBloqueChanged,
  });

  final Bloque bloque;
  final bool marcado;
  final Map<String, bool> itemsMarcados;
  final void Function(String itemTexto, bool marcado) onItemChanged;
  final ValueChanged<bool> onBloqueChanged;

  @override
  Widget build(BuildContext context) {
    final completados = itemsMarcados.values.where((value) => value).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconoParaBloque(bloque.nombre),
                  color: marcado ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: 12),
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
                          '$completados de ${bloque.items.length} contenidos',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                if (bloque.items.isNotEmpty)
                  TextButton(
                    onPressed: () => onBloqueChanged(!marcado),
                    child: Text(marcado ? 'Desmarcar todo' : 'Marcar todo'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 20),
            if (bloque.items.isEmpty)
              _ChecklistItem(
                label: 'Contenido enseñado',
                checked: marcado,
                onChanged: onBloqueChanged,
              )
            else
              for (final item in bloque.items)
                Padding(
                  key: ValueKey('${bloque.nombre}-${item.texto}'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChecklistItem(
                    label: item.texto,
                    checked: itemsMarcados[item.texto] ?? false,
                    onChanged: (value) => onItemChanged(item.texto, value),
                  ),
                ),
          ],
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
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: checked ? AppColors.successContainer : const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: checked ? const Color(0xFFB9DFCC) : AppColors.outline,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(!checked),
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              AnimatedScale(
                scale: checked ? 1.08 : 1,
                duration: const Duration(milliseconds: 180),
                child: Checkbox(
                  value: checked,
                  onChanged: (value) => onChanged(value ?? false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: checked ? AppColors.success : AppColors.textPrimary,
                    decoration: checked ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.success,
                  ),
                  child: Text(label),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: checked
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('done'),
                        color: AppColors.success,
                        size: 22,
                      )
                    : const SizedBox(key: ValueKey('empty'), width: 22),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
