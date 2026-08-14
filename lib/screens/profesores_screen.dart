import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';

class ProfesoresScreen extends StatelessWidget {
  const ProfesoresScreen({super.key});

  static const routeName = '/profesores';

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    final profesores = sesion.profesoresVisibles();
    final puedeAprobar = sesion.usuarioActual?.rol == RolUsuario.administrador;

    return Scaffold(
      appBar: AppBar(title: const Text('Profesores')),
      body: profesores.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.group_off_outlined,
                      size: 56,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay profesores registrados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aquí aparecerán los profesores registrados durante esta sesión.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: profesores.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final profesor = profesores[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      child: Text(
                        profesor.nombre.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(profesor.nombre),
                    subtitle: Text('${profesor.usuario} · ${profesor.zona}'),
                    trailing: profesor.aprobado
                        ? const _EstadoAcceso(aprobado: true)
                        : puedeAprobar
                        ? TextButton.icon(
                            onPressed: () {
                              final error = context
                                  .read<SesionProvider>()
                                  .aprobarProfesor(profesor.usuario);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error ??
                                        'Acceso aprobado para ${profesor.nombre}.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.verified_user_outlined),
                            label: const Text('Aprobar'),
                          )
                        : const _EstadoAcceso(aprobado: false),
                  ),
                );
              },
            ),
    );
  }
}

class _EstadoAcceso extends StatelessWidget {
  const _EstadoAcceso({required this.aprobado});

  final bool aprobado;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = aprobado
        ? (dark ? const Color(0xFF74CDB0) : AppColors.success)
        : (dark ? const Color(0xFFF2C46D) : AppColors.warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? .14 : .10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            aprobado ? 'Aprobado' : 'Pendiente',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
