import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/sesion_provider.dart';

class SyncStatus extends StatelessWidget {
  const SyncStatus({
    super.key,
    required this.child,
    required this.navigatorKey,
  });
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  Future<void> _revisar(BuildContext context, SesionProvider sesion) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambios pendientes de revisión'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final op in sesion.conflictos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${op['tipo']} · ${op['recurso']}'),
                        Text(op['error'] as String),
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: () async {
                                try {
                                  final bytes = Uint8List.fromList(
                                    utf8.encode(
                                      const JsonEncoder.withIndent(
                                        '  ',
                                      ).convert(op),
                                    ),
                                  );
                                  await SharePlus.instance.share(
                                    ShareParams(
                                      files: [
                                        XFile.fromData(
                                          bytes,
                                          mimeType: 'application/json',
                                        ),
                                      ],
                                      fileNameOverrides: [
                                        'cambio-pendiente-${op['id']}.json',
                                      ],
                                      sharePositionOrigin: Rect.fromLTWH(
                                        0,
                                        0,
                                        MediaQuery.sizeOf(dialogContext).width,
                                        100,
                                      ),
                                    ),
                                  );
                                } catch (_) {
                                  if (dialogContext.mounted) {
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No se pudo exportar. El cambio sigue guardado en la app.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Exportar mi copia'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final confirmado = await showDialog<bool>(
                                  context: dialogContext,
                                  builder: (c) => AlertDialog(
                                    title: const Text(
                                      'Usar la versión de Supabase',
                                    ),
                                    content: const Text(
                                      'Se descartarán los cambios pendientes de este registro en este dispositivo. Exporta tu copia primero si necesitas conservarla. La pantalla se volverá a abrir para mostrar los datos del servidor.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text(
                                          'Conservar pendientes',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Usar Supabase'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmado != true ||
                                    !dialogContext.mounted) {
                                  return;
                                }
                                Navigator.pop(dialogContext);
                                final error = await sesion.usarVersionServidor(
                                  op,
                                );
                                if (!context.mounted) return;
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                } else {
                                  // Los formularios tienen controladores propios; volver al inicio
                                  // evita que uno abierto vuelva a guardar una copia descartada.
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                }
                              },
                              child: const Text('Usar Supabase'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    if (!sesion.offlineHabilitado || !sesion.estaAutenticado) return child;
    return Column(
      children: [
        Expanded(child: child),
        Material(
          color: sesion.conflictos.isNotEmpty
              ? Colors.orange.shade100
              : Theme.of(context).colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    sesion.sinConexion
                        ? Icons.cloud_off
                        : sesion.cambiosPendientes > 0
                        ? Icons.cloud_upload_outlined
                        : Icons.cloud_done_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sesion.estadoGuardado,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (sesion.conflictos.isNotEmpty)
                    TextButton(
                      onPressed: () => _revisar(
                        navigatorKey.currentState!.overlay!.context,
                        sesion,
                      ),
                      child: const Text('Revisar'),
                    ),
                  IconButton(
                    tooltip: 'Reintentar sincronización',
                    onPressed: sesion.sincronizando
                        ? null
                        : () => sesion.sincronizarCambios(reintentar: true),
                    icon: const Icon(Icons.sync),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
