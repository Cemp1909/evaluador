import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';

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
      appBar: AppBar(
        title: Text(
          widget.solicitudPublica ? 'Solicitar acceso' : 'Crear profesor',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.solicitudPublica
                      ? 'Registro de profesor'
                      : 'Nuevo usuario',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.solicitudPublica
                      ? 'Completa tus datos. El administrador debe aprobar tu acceso.'
                      : 'La cuenta quedará pendiente de aprobación del administrador.',
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
                                ? 'Solicitud enviada. Espera la aprobación del administrador.'
                                : 'Solicitud del profesor creada correctamente.',
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
                    labelText: 'Nombre completo',
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
                    labelText: 'Usuario',
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
                    labelText: 'Contraseña',
                    helperText: 'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _ocultarPassword = !_ocultarPassword),
                      icon: Icon(
                        _ocultarPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es obligatorio.';
                    }
                    if (value.length < 6) {
                      return 'Usa mínimo 6 caracteres.';
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
                            'Zona asignada: $zonaAsignada',
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
                      labelText: 'Zona',
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
                        ? 'Enviar solicitud'
                        : 'Crear solicitud',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _campoObligatorio(String? value) =>
      value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

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
        _error = error;
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
}
