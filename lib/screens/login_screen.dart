import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario_sesion.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';
import 'gestion_home_screen.dart';
import 'crear_profesor_screen.dart';
import 'profesor_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEAF4F3),
              AppColors.background,
              Color(0xFFFFF7EC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          child: Image.asset(
                            'assets/images/course_child_logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bienvenido al Evaluador Course Child',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Registra capacitaciones y evaluaciones educativas en un solo lugar.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _usuarioController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Ingresa tu usuario.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _ocultarPassword,
                        onFieldSubmitted: (_) => _ingresar(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _ocultarPassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
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
                        validator: (value) => value == null || value.isEmpty
                            ? 'Ingresa tu contraseña.'
                            : null,
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
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _ingresar,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Ingresar'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(CrearProfesorScreen.solicitudRoute),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Solicitar acceso como profesor'),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Versión de prueba · Los datos se eliminan al cerrar la app',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _ingresar() {
    if (!_formKey.currentState!.validate()) return;
    final sesion = context.read<SesionProvider>();
    final error = sesion.iniciarSesion(
      usuario: _usuarioController.text,
      password: _passwordController.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final route = switch (sesion.usuarioActual!.rol) {
      RolUsuario.administrador => GestionHomeScreen.adminRoute,
      RolUsuario.coordinador => GestionHomeScreen.coordinadorRoute,
      RolUsuario.profesor => ProfesorHomeScreen.routeName,
    };
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }
}
