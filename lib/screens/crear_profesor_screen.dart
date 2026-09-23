import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import '../security/rbac.dart';
import '../widgets/app_brand_title.dart';

class CrearProfesorScreen extends StatefulWidget {
  const CrearProfesorScreen({super.key, this.solicitudPublica = false});

  static const routeName = '/crear_profesor';
  static const solicitudRoute = '/solicitar_acceso';

  final bool solicitudPublica;

  @override
  State<CrearProfesorScreen> createState() => _CrearProfesorScreenState();
}

class _CrearProfesorScreenState extends State<CrearProfesorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _zonaController = TextEditingController();
  bool _ocultarPassword = true;
  String? _error;
  bool _creado = false;
  bool _cargando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _usuarioController.dispose();
    _passwordController.dispose();
    _zonaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    if (sesion.usaSupabase) {
      return _registroSupabase();
    }
    final autorizado = widget.solicitudPublica
        ? Rbac.puedeRegistrarSolicitudProfesor(sesion.usuarioActual)
        : Rbac.puedeCrearProfesores(sesion.usuarioActual);
    if (!autorizado) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso no autorizado')),
        body: const Center(
          child: Text('No tienes permiso para crear ni registrar profesores.'),
        ),
      );
    }
    final esCoordinador =
        !widget.solicitudPublica &&
        sesion.usuarioActual?.rol == RolUsuario.coordinador;
    final zonaAsignada = sesion.usuarioActual?.zona ?? '';

    return Scaffold(
      appBar: AppBar(title: const AppBrandTitle(compact: true)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.solicitudPublica
                              ? 'Request Teacher Access'
                              : 'Create Teacher Profile',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.solicitudPublica
                              ? 'Complete your details. An administrator must approve your access.'
                              : 'The account will remain pending until an administrator approves it.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_creado) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.successContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    widget.solicitudPublica
                                        ? 'Request sent. Wait for administrator approval.'
                                        : 'Teacher request created successfully.',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: _nombreController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: _campoObligatorio,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _usuarioController,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _campoObligatorio,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _ocultarPassword,
                          textInputAction: esCoordinador
                              ? TextInputAction.done
                              : TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            helperText: 'At least 6 characters',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _ocultarPassword = !_ocultarPassword,
                              ),
                              icon: Icon(
                                _ocultarPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required.';
                            }
                            if (value.length < 6) {
                              return 'Use at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (esCoordinador)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Assigned zone: $zonaAsignada',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          TextFormField(
                            controller: _zonaController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Zone',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            validator: _campoObligatorio,
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: () => _crear(esCoordinador, zonaAsignada),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(
                            widget.solicitudPublica
                                ? 'Send request'
                                : 'Create request',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _registroSupabase() => Scaffold(
    appBar: AppBar(title: const Text('Crear cuenta de profesor')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crear cuenta',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'La cuenta se crea con rol de profesor. Un administrador podrá asignar su zona y gestionar el acceso.',
                      ),
                      if (_creado) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.successContainer,
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                          ),
                          child: const Text(
                            'Cuenta creada. Ya puedes volver e iniciar sesión con tu usuario y contraseña.',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _nombreController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: _campoObligatorio,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _usuarioController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          helperText: 'Ejemplo: maria.gomez',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Escribe un nombre de usuario.';
                          }
                          if (!RegExp(
                            r'^[a-zA-Z0-9._-]{3,30}$',
                          ).hasMatch(value.trim())) {
                            return 'Usa de 3 a 30 letras, números, puntos o guiones.';
                          }
                          if (const {
                            'admin',
                            'administrador',
                            'administrator',
                            'superadmin',
                            'root',
                          }.contains(value.trim().toLowerCase())) {
                            return 'Ese nombre de usuario está reservado.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _ocultarPassword,
                        onFieldSubmitted: (_) => _crearCuentaSupabase(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          helperText: 'Mínimo 8 caracteres',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _ocultarPassword = !_ocultarPassword,
                            ),
                            icon: Icon(
                              _ocultarPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Escribe una contraseña.';
                          }
                          if (value.length < 8) {
                            return 'Usa mínimo 8 caracteres.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: _cargando ? null : _crearCuentaSupabase,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(
                          _cargando ? 'Creando cuenta…' : 'Crear cuenta',
                        ),
                      ),
                      TextButton(
                        onPressed: _cargando
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Volver a iniciar sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _crearCuentaSupabase() async {
    if (_cargando || !_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
      _creado = false;
    });
    final error = await context.read<SesionProvider>().registrarCuentaSupabase(
      nombre: _nombreController.text,
      usuario: _usuarioController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = error;
      _creado = error == null;
    });
    if (error == null) {
      _nombreController.clear();
      _usuarioController.clear();
      _passwordController.clear();
    }
  }

  String? _campoObligatorio(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  void _crear(bool esCoordinador, String zonaAsignada) {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<SesionProvider>();
    final zona = esCoordinador ? zonaAsignada : _zonaController.text;
    final error = widget.solicitudPublica
        ? provider.registrarSolicitudProfesor(
            nombre: _nombreController.text,
            usuario: _usuarioController.text,
            password: _passwordController.text,
            zona: zona,
          )
        : provider.crearProfesor(
            nombre: _nombreController.text,
            usuario: _usuarioController.text,
            password: _passwordController.text,
            zona: zona,
          );
    if (error != null) {
      setState(() {
        _error = _traducirError(error);
        _creado = false;
      });
      return;
    }

    _nombreController.clear();
    _usuarioController.clear();
    _passwordController.clear();
    if (!esCoordinador) _zonaController.clear();
    setState(() {
      _error = null;
      _creado = true;
    });
  }

  String _traducirError(String error) => switch (error) {
    'No tienes permiso para crear profesores.' =>
      'You do not have permission to create teachers.',
    'Todos los campos son obligatorios.' => 'All fields are required.',
    'La contraseña debe tener mínimo 6 caracteres.' =>
      'The password must be at least 6 characters long.',
    'Ese nombre de usuario ya está en uso.' =>
      'That username is already in use.',
    _ => error,
  };
}
