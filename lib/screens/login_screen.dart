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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? const [Color(0xFF121722), AppColors.darkBackground]
                : const [Color(0xFFF1F3FF), AppColors.background],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .08),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -AppSpacing.lg,
                        top: 20,
                        bottom: 20,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.medium,
                                ),
                                child: Image.asset(
                                  'assets/images/course_child_logo.png',
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Welcome to Course Child Evaluator',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Record training sessions and educational evaluations in one place.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            TextFormField(
                              controller: _usuarioController,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Enter your username.'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _ocultarPassword,
                              onFieldSubmitted: (_) => _ingresar(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _ocultarPassword
                                      ? 'Show password'
                                      : 'Hide password',
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
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Enter your password.'
                                  : null,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: AppSpacing.sm),
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
                              onPressed: _ingresar,
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Sign in'),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(CrearProfesorScreen.solicitudRoute),
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text('Request teacher access'),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Prototype version · Data is deleted when the app closes',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
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
      setState(() => _error = _traducirError(error));
      return;
    }

    final route = switch (sesion.usuarioActual!.rol) {
      RolUsuario.administrador => GestionHomeScreen.adminRoute,
      RolUsuario.coordinador => GestionHomeScreen.coordinadorRoute,
      RolUsuario.profesor => ProfesorHomeScreen.routeName,
    };
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  String _traducirError(String error) => switch (error) {
    'Tu solicitud está pendiente de aprobación del administrador.' =>
      'Your request is awaiting administrator approval.',
    'La contraseña del profesor es incorrecta.' =>
      'The teacher password is incorrect.',
    'No existe un profesor con ese usuario en esta sesión. Un administrador o coordinador debe crearlo primero.' =>
      'No teacher with that username exists in this session. An administrator or coordinator must create it first.',
    _ => error,
  };
}
