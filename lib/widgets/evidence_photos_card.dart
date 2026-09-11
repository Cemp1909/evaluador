import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EvidencePhotosCard extends StatelessWidget {
  const EvidencePhotosCard({
    super.key,
    required this.fotosBase64,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> fotosBase64;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
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
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Evidencia fotográfica',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${fotosBase64.length}/2',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Puedes agregar máximo dos fotos por evaluación.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (fotosBase64.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (var index = 0; index < fotosBase64.length; index++) ...[
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.25,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                              child: Image.memory(
                                base64Decode(fotosBase64[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.button,
                                    ),
                                    border: Border.all(
                                      color: scheme.outlineVariant,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: IconButton.filled(
                                tooltip: 'Eliminar foto',
                                onPressed: () => onRemove(index),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withValues(
                                    alpha: 0.65,
                                  ),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(32, 32),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index == 0 && fotosBase64.length == 2)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ],
            if (fotosBase64.length < 2) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Agregar evidencia'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
