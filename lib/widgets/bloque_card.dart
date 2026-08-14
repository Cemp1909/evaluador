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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconoParaBloque(bloque.nombre),
                  color: marcado ? AppColors.success : scheme.primary,
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
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: AppSpacing.lg),
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
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
