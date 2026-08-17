import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
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
    final esCoordinador =
        !widget.solicitudPublica &&
        sesion.usuarioActual?.rol == RolUsuario.coordinador;
    final zonaAsignada = sesion.usuarioActual?.zona ?? '';

    return Scaffold(
      appBar: AppBar(title: const AppBrandTitle(compact: true)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                side: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.solicitudPublica
                          ? 'Request Teacher Access'
                          : 'Create Teacher Profile',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.solicitudPublica
                          ? 'Complete your details. An administrator must approve your access.'
                          : 'The account will remain pending until an administrator approves it.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_creado) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
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
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    if (esCoordinador)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4F1F2),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Assigned zone: $zonaAsignada',
                                style: Theme.of(context).textTheme.titleMedium,
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
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
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
    );
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
