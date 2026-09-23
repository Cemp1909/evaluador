import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../security/rbac.dart';
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
    if (!Rbac.puedeConsultarProfesores(sesion.usuarioActual)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso no autorizado')),
        body: const Center(
          child: Text('No tienes permiso para consultar profesores.'),
        ),
      );
    }
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher Roster',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  puedeAprobar
                      ? 'Manage and approve field educators across zones.'
                      : 'Consulta los profesores de tu zona.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  onChanged: (value) => setState(() => _busqueda = value),
                  decoration: const InputDecoration(
                    labelText: 'Search by name, username or zone',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
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
              ],
            ),
          ),
          Expanded(
            child: profesores.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.group_off_outlined,
                              size: 32,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No teachers registered',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    itemCount: profesores.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final profesor = profesores[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
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
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
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
                                        const SizedBox(height: 2),
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
                              if (puedeAprobar) ...[
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    if (!profesor.aprobado)
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
                                    OutlinedButton.icon(
                                      onPressed: () => _hacerCoordinador(
                                        context,
                                        profesor.usuario,
                                        profesor.nombre,
                                        profesor.zona,
                                      ),
                                      icon: const Icon(
                                        Icons.manage_accounts_outlined,
                                      ),
                                      label: const Text('Hacer coordinador'),
                                    ),
                                  ],
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

  Future<void> _aprobar(
    BuildContext context,
    String usuario,
    String nombre,
  ) async {
    final error = await context
        .read<SesionProvider>()
        .aprobarProfesorPersistente(usuario);
    if (!context.mounted) return;
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

  Future<void> _hacerCoordinador(
    BuildContext context,
    String usuario,
    String nombre,
    String zonaActual,
  ) async {
    final controller = TextEditingController(text: zonaActual);
    final zona = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Convertir a $nombre en coordinador'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Zona asignada'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!context.mounted || zona == null) return;
    final error = await context
        .read<SesionProvider>()
        .convertirProfesorEnCoordinador(usuario: usuario, zona: zona);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '$nombre ahora tiene acceso como coordinador.'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? .18 : .12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: dark ? .35 : .25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            aprobado ? 'Approved' : 'Pending',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
