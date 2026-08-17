import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_brand_title.dart';

class ProfesoresScreen extends StatefulWidget {
  const ProfesoresScreen({super.key});

  static const routeName = '/profesores';

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _ProfesoresScreenState extends State<ProfesoresScreen> {
  String _busqueda = '';
  bool? _aprobado;

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    final profesores = sesion.profesoresVisibles().where((profesor) {
      final texto = _busqueda.trim().toLowerCase();
      final coincide =
          texto.isEmpty ||
          profesor.nombre.toLowerCase().contains(texto) ||
          profesor.usuario.toLowerCase().contains(texto) ||
          profesor.zona.toLowerCase().contains(texto);
      return coincide && (_aprobado == null || profesor.aprobado == _aprobado);
    }).toList();
    final puedeAprobar = sesion.usuarioActual?.rol == RolUsuario.administrador;

    return Scaffold(
      appBar: AppBar(title: const AppBrandTitle(compact: true)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher Roster',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (value) => setState(() => _busqueda = value),
                  decoration: const InputDecoration(
                    labelText: 'Search by name, username or zone',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<bool?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(value: true, label: Text('Approved')),
                    ButtonSegment(value: false, label: Text('Pending')),
                  ],
                  selected: {_aprobado},
                  onSelectionChanged: (values) =>
                      setState(() => _aprobado = values.first),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Manage and approve field educators across zones.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: profesores.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group_off_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No teachers registered',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Teachers registered during this session will appear here.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: profesores.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final profesor = profesores[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    child: Text(
                                      profesor.nombre
                                          .split(' ')
                                          .take(2)
                                          .map((part) => part[0])
                                          .join()
                                          .toUpperCase(),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profesor.nombre,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        Text(
                                          '@${profesor.usuario} · ${profesor.zona}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _EstadoAcceso(aprobado: profesor.aprobado),
                                ],
                              ),
                              if (!profesor.aprobado && puedeAprobar) ...[
                                const SizedBox(height: AppSpacing.md),
                                FilledButton.icon(
                                  onPressed: () => _aprobar(
                                    context,
                                    profesor.usuario,
                                    profesor.nombre,
                                  ),
                                  icon: const Icon(
                                    Icons.verified_user_outlined,
                                  ),
                                  label: const Text('Approve'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _aprobar(BuildContext context, String usuario, String nombre) {
    final error = context.read<SesionProvider>().aprobarProfesor(usuario);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Access approved for $nombre.'
              : _traducirError(error),
        ),
      ),
    );
  }

  String _traducirError(String error) => switch (error) {
    'Solo el administrador puede aprobar profesores.' =>
      'Only an administrator can approve teachers.',
    'Profesor no encontrado.' => 'Teacher not found.',
    _ => error,
  };
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
            aprobado ? 'Approved' : 'Pending',
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
