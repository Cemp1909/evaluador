import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ReportSignatureCard extends StatelessWidget {
  const ReportSignatureCard({
    super.key,
    required this.titulo,
    required this.firmaBase64,
    required this.onFirmar,
    this.nombre,
  });

  final String titulo;
  final String? nombre;
  final String? firmaBase64;
  final VoidCallback onFirmar;

  @override
  Widget build(BuildContext context) {
    final firmada = firmaBase64 != null && firmaBase64!.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (firmada ? AppColors.success : scheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Icon(
                    firmada ? Icons.verified_rounded : Icons.draw_outlined,
                    size: 20,
                    color: firmada ? AppColors.success : scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (nombre != null)
                        Text(
                          nombre!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (firmada) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 104,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Image.memory(
                  base64Decode(firmaBase64!),
                  fit: BoxFit.contain,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onFirmar,
              icon: const Icon(Icons.edit_outlined),
              label: Text(firmada ? 'Firmar nuevamente' : 'Firmar'),
            ),
          ],
        ),
      ),
    );
  }
}
