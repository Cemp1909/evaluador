import 'package:flutter/material.dart';

class LocalModeBanner extends StatelessWidget {
  const LocalModeBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      children: [
        Icon(Icons.cloud_off_outlined, size: 19),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Modo local · Los cambios se guardan solo durante esta sesión. No hay sincronización activa.',
          ),
        ),
      ],
    ),
  );
}
