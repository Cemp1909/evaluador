import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'config/auth_config.dart';
import 'providers/sesion_provider.dart';
import 'screens/crear_profesor_screen.dart';
import 'screens/evaluador_selection_screen.dart';
import 'screens/gestion_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profesor_home_screen.dart';
import 'screens/profesores_screen.dart';
import 'screens/student_knowledge_report_screen.dart';
import 'screens/configuracion_notas_screen.dart';
import 'screens/historial_estudiantes_screen.dart';
import 'screens/panel_colegios_screen.dart';
import 'screens/agenda_visitas_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    runApp(EvaluadorApp(authConfig: AuthConfig.fromMap(dotenv.env)));
  } catch (_) {
    runApp(const ConfigurationErrorApp());
  }
}

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Configuration failed to load. Please reinstall the app.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EvaluadorApp extends StatelessWidget {
  const EvaluadorApp({super.key, this.authConfig = AuthConfig.test});

  final AuthConfig authConfig;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SesionProvider(authConfig),
      child: MaterialApp(
        title: 'Course Child - Evaluator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        builder: (context, child) => _ProteccionSesion(child: child!),
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          EvaluadorSelectionScreen.routeName: (_) =>
              const EvaluadorSelectionScreen(),
          GestionHomeScreen.adminRoute: (_) => const GestionHomeScreen.admin(),
          GestionHomeScreen.coordinadorRoute: (_) =>
              const GestionHomeScreen.coordinador(),
          CrearProfesorScreen.routeName: (_) => const CrearProfesorScreen(),
          CrearProfesorScreen.solicitudRoute: (_) =>
              const CrearProfesorScreen(solicitudPublica: true),
          ProfesoresScreen.routeName: (_) => const ProfesoresScreen(),
          ProfesorHomeScreen.routeName: (_) => const ProfesorHomeScreen(),
          StudentKnowledgeReportScreen.routeName: (_) =>
              const StudentKnowledgeReportScreen(),
          ConfiguracionNotasScreen.routeName: (_) =>
              const ConfiguracionNotasScreen(),
          HistorialEstudiantesScreen.routeName: (_) =>
              const HistorialEstudiantesScreen(),
          PanelColegiosScreen.routeName: (_) => const PanelColegiosScreen(),
          AgendaVisitasScreen.routeName: (_) => const AgendaVisitasScreen(),
        },
      ),
    );
  }
}

class _ProteccionSesion extends StatefulWidget {
  const _ProteccionSesion({required this.child});
  final Widget child;

  @override
  State<_ProteccionSesion> createState() => _ProteccionSesionState();
}

class _ProteccionSesionState extends State<_ProteccionSesion>
    with WidgetsBindingObserver {
  DateTime? _salioEn;
  bool _ocultarContenido = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _salioEn ??= DateTime.now();
      if (mounted) setState(() => _ocultarContenido = true);
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final tiempoFuera = _salioEn == null
        ? Duration.zero
        : DateTime.now().difference(_salioEn!);
    _salioEn = null;
    if (mounted) setState(() => _ocultarContenido = false);
    if (tiempoFuera >= const Duration(minutes: 5) &&
        context.read<SesionProvider>().estaAutenticado) {
      context.read<SesionProvider>().cerrarSesion();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La sesión se cerró por seguridad.')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (_ocultarContenido)
        const ColoredBox(
          color: AppColors.primary,
          child: Center(
            child: Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
        ),
    ],
  );
}
