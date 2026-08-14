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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  firmada ? Icons.verified_rounded : Icons.draw_outlined,
                  color: firmada ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: 12),
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
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (firmada) ...[
              const SizedBox(height: 12),
              Container(
                height: 100,
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Image.memory(
                  base64Decode(firmaBase64!),
                  fit: BoxFit.contain,
                ),
              ),
            ],
            const SizedBox(height: 12),
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
