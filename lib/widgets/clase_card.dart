import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'gradient_progress_bar.dart';

class ClaseCard extends StatelessWidget {
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

  bool get _completa =>
      totalContenidos > 0 && contenidosMarcados == totalContenidos;
  @override
  Widget build(BuildContext context) {
    final progress = totalContenidos == 0
        ? 0.0
        : contenidosMarcados / totalContenidos;
    final borderColor = _completa ? AppColors.success : AppColors.outline;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: borderColor, width: _completa ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 21),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _completa
                      ? AppColors.successContainer
                      : const Color(0xFFE4F1F2),
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
                        '$numero',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clase $numero',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    GradientProgressBar(
                      value: progress,
                      height: 9,
                      complete: _completa,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$contenidosMarcados de $totalContenidos contenidos realizados',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
