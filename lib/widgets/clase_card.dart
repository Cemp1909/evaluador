import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'gradient_progress_bar.dart';

class ClaseCard extends StatefulWidget {
  const ClaseCard({
    super.key,
    required this.numero,
    required this.contenidosMarcados,
    required this.totalContenidos,
    required this.onTap,
    this.sinContenidosAplicables = false,
  });

  final int numero;
  final int contenidosMarcados;
  final int totalContenidos;
  final VoidCallback onTap;
  final bool sinContenidosAplicables;

  @override
  State<ClaseCard> createState() => _ClaseCardState();
}

class _ClaseCardState extends State<ClaseCard> {
  bool _pressed = false;

  bool get _completa =>
      widget.totalContenidos > 0 &&
      widget.contenidosMarcados == widget.totalContenidos;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = widget.totalContenidos == 0
        ? 0.0
        : widget.contenidosMarcados / widget.totalContenidos;
    final inProgress = widget.contenidosMarcados > 0 && !_completa;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .988 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            side: BorderSide(
              color: _completa
                  ? AppColors.success.withValues(alpha: 0.6)
                  : scheme.outlineVariant,
              width: _completa ? 1.2 : 1,
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md + 2,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _completa ? AppColors.success : AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _completa
                          ? AppColors.successContainer
                          : scheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.small + 2),
                      border: Border.all(
                        color: (_completa ? AppColors.success : scheme.primary)
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _completa
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.success,
                            size: 26,
                          )
                        : Text(
                            '${widget.numero}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class ${widget.numero}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        GradientProgressBar(
                          value: progress,
                          height: 7,
                          complete: _completa,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.sinContenidosAplicables
                              ? 'Sin contenidos aplicables por solicitud del colegio'
                              : '${widget.contenidosMarcados} of ${widget.totalContenidos} items completed',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _StatusBadge(
                    label: _completa
                        ? 'Completed'
                        : widget.sinContenidosAplicables
                        ? 'Excluded'
                        : inProgress
                        ? 'In progress'
                        : 'Pending',
                    color: _completa
                        ? AppColors.success
                        : widget.sinContenidosAplicables
                        ? AppColors.accent
                        : inProgress
                        ? AppColors.accent
                        : scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: .3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
