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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Evidencia fotográfica',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('${fotosBase64.length}/2'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Puedes agregar máximo dos fotos por evaluación.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (fotosBase64.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                                AppRadius.small,
                              ),
                              child: Image.memory(
                                base64Decode(fotosBase64[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: IconButton.filled(
                                tooltip: 'Eliminar foto',
                                onPressed: () => onRemove(index),
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index == 0 && fotosBase64.length == 2)
                      const SizedBox(width: 12),
                  ],
                ],
              ),
            ],
            if (fotosBase64.length < 2) ...[
              const SizedBox(height: 16),
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
