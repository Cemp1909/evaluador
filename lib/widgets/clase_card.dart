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
  });

  final int numero;
  final int contenidosMarcados;
  final int totalContenidos;
  final VoidCallback onTap;

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
    final borderColor = _completa ? AppColors.success : scheme.outline;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .988 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            side: BorderSide(color: borderColor, width: _completa ? 1.25 : 1),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _completa
                          ? AppColors.successContainer
                          : scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    alignment: Alignment.center,
                    child: _completa
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.success,
                            size: 30,
                          )
                        : Text(
                            '${widget.numero}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: scheme.onPrimaryContainer),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clase ${widget.numero}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GradientProgressBar(
                          value: progress,
                          height: 9,
                          complete: _completa,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${widget.contenidosMarcados} de ${widget.totalContenidos} contenidos realizados',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
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
