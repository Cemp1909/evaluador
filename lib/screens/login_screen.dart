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
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restaurarSesion();
    });
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final usaSupabase = context.watch<SesionProvider>().usaSupabase;
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: dark ? .35 : .08,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: dark ? .2 : .06,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/course_child_logo.png',
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Course Child',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Record training sessions and educational evaluations in one place.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _usuarioController,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: usaSupabase
                                ? 'Correo electrónico'
                                : 'Username',
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return usaSupabase
                                  ? 'Escribe tu correo electrónico.'
                                  : 'Enter your username.';
                            }
                            if (usaSupabase && !value.contains('@')) {
                              return 'Escribe un correo válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm + 2),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _ocultarPassword,
                          onFieldSubmitted: (_) => _ingresar(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter your password.'
                              : null,
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
                          onPressed: _cargando ? null : _ingresar,
                          icon: const Icon(Icons.login_rounded),
                          label: Text(_cargando ? 'Conectando...' : 'Sign in'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _cargando
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pushNamed(CrearProfesorScreen.solicitudRoute),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(
                            usaSupabase
                                ? 'Crear cuenta de profesor'
                                : 'Request teacher access',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          usaSupabase
                              ? 'Cuenta conectada a Supabase. Los datos académicos se guardan allí cuando están aplicadas todas las migraciones.'
                              : 'Prototype version · Data is deleted when the app closes',
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
      ),
    );
  }

  Future<void> _restaurarSesion() async {
    final sesion = context.read<SesionProvider>();
    if (!sesion.usaSupabase || !sesion.tieneSesionRemota) return;
    setState(() => _cargando = true);
    final error = await sesion.restaurarSesionSupabase();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = error;
    });
    if (error == null) _navegar(sesion.usuarioActual!.rol);
  }

  Future<void> _ingresar() async {
    if (_cargando) return;
    if (!_formKey.currentState!.validate()) return;
    final sesion = context.read<SesionProvider>();
    setState(() {
      _cargando = true;
      _error = null;
    });
    final error = sesion.usaSupabase
        ? await sesion.iniciarSesionSupabase(
            correo: _usuarioController.text,
            password: _passwordController.text,
          )
        : sesion.iniciarSesion(
            usuario: _usuarioController.text,
            password: _passwordController.text,
          );
    if (!mounted) return;
    setState(() => _cargando = false);
    if (error != null) {
      setState(() => _error = _traducirError(error));
      return;
    }

    _navegar(sesion.usuarioActual!.rol);
  }

  void _navegar(RolUsuario rol) {
    final route = switch (rol) {
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
    'No existe un profesor con ese usuario en esta sesión. Un administrador debe crearlo primero.' =>
      'No teacher with that username exists in this session. An administrator must create it first.',
    _ => error,
  };
}
