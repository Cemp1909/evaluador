import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sesion_provider.dart';

class LocalModeBanner extends StatelessWidget {
  const LocalModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sesion = context.watch<SesionProvider>();
    final usaSupabase = sesion.usaSupabase;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            usaSupabase ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sesion.offlineHabilitado
                  ? 'Los cambios se guardan en este dispositivo y se envían a Supabase cuando hay conexión. Consulta el estado de sincronización al pie de la pantalla.'
                  : usaSupabase
                  ? 'Las evaluaciones, asistencias, firmas y fotos se guardan en Supabase al confirmar los cambios.'
                  : 'Modo local · Los cambios se guardan solo durante esta sesión. No hay sincronización activa.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
