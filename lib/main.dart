import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/auth_config.dart';
import 'providers/sesion_provider.dart';
import 'security/rbac.dart';
import 'screens/crear_profesor_screen.dart';
import 'screens/evaluador_selection_screen.dart';
import 'screens/evaluacion_profesores_screen.dart';
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
import 'widgets/permission_gate.dart';
import 'widgets/sync_status.dart';
import 'services/offline/offline_store.dart';
import 'services/timeout_http_client.dart';
import 'services/offline/secure_session_storage.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    const envFile = String.fromEnvironment('ENV_FILE', defaultValue: '.env');
    await dotenv.load(fileName: envFile);
    const urlDesdeBuild = String.fromEnvironment('SUPABASE_URL');
    const claveDesdeBuild = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    final supabaseUrl =
        (urlDesdeBuild.isNotEmpty
                ? urlDesdeBuild
                : dotenv.env['SUPABASE_URL'] ?? '')
            .trim();
    final supabaseKey =
        (claveDesdeBuild.isNotEmpty
                ? claveDesdeBuild
                : dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '')
            .trim();
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw const FormatException(
        'Configura SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY juntos.',
      );
    }
    if (supabaseKey.startsWith('sb_secret_')) {
      throw const FormatException(
        'Nunca uses una clave secreta de Supabase en Flutter.',
      );
    }
    if (supabaseUrl.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseKey,
        httpClient: TimeoutHttpClient(),
        postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
        storageOptions: const StorageClientOptions(retryAttempts: 0),
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureSessionStorage(
            'sesion-${Uri.parse(supabaseUrl).host}',
          ),
        ),
      );
    }
    runApp(
      EvaluadorApp(
        authConfig: AuthConfig.fromMap(dotenv.env),
        supabaseClient: supabaseUrl.isEmpty ? null : Supabase.instance.client,
        proyectoOffline: supabaseUrl,
      ),
    );
  } catch (error, stack) {
    debugPrint('Error al iniciar la app: ${error.runtimeType}');
    debugPrintStack(stackTrace: stack);
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
  const EvaluadorApp({
    super.key,
    this.authConfig = AuthConfig.test,
    this.supabaseClient,
    this.proyectoOffline,
  });

  final String? proyectoOffline;
  final AuthConfig authConfig;
  final SupabaseClient? supabaseClient;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SesionProvider(
        authConfig,
        supabaseClient: supabaseClient,
        offlineFactory: proyectoOffline == null
            ? null
            : (uid) => OfflineStore.abrir(proyectoOffline!, uid),
      ),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Course Child - Evaluator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        builder: (context, child) => _ProteccionSesion(
          child: SyncStatus(navigatorKey: _navigatorKey, child: child!),
        ),
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          EvaluadorSelectionScreen.routeName: (_) => const PermissionGate(
            permission: Permiso.crearEvaluaciones,
            child: EvaluadorSelectionScreen(),
          ),
          EvaluacionProfesoresScreen.routeName: (_) => const PermissionGate(
            permission: Permiso.verResultadosAsignados,
            child: EvaluacionProfesoresScreen(),
          ),
          GestionHomeScreen.adminRoute: (_) => const PermissionGate(
            permission: Permiso.administrarUsuarios,
            child: GestionHomeScreen.admin(),
          ),
          GestionHomeScreen.coordinadorRoute: (_) => const PermissionGate(
            permission: Permiso.gestionarEstructuraAcademica,
            child: GestionHomeScreen.coordinador(),
          ),
          CrearProfesorScreen.routeName: (_) => const CrearProfesorScreen(),
          CrearProfesorScreen.solicitudRoute: (_) =>
              const CrearProfesorScreen(solicitudPublica: true),
          ProfesoresScreen.routeName: (_) => const ProfesoresScreen(),
          ProfesorHomeScreen.routeName: (_) => const PermissionGate(
            permission: Permiso.actualizarPerfil,
            child: ProfesorHomeScreen(),
          ),
          StudentKnowledgeReportScreen.routeName: (_) => const PermissionGate(
            permission: Permiso.crearEvaluaciones,
            child: StudentKnowledgeReportScreen(),
          ),
          ConfiguracionNotasScreen.routeName: (_) => const PermissionGate(
            permission: Permiso.configurarSistema,
            child: ConfiguracionNotasScreen(),
          ),
          HistorialEstudiantesScreen.routeName: (_) => const PermissionGate(
            permission: Permiso.verResultadosAsignados,
            child: HistorialEstudiantesScreen(),
          ),
          PanelColegiosScreen.routeName: (_) => const PermissionGate(
            permission: Permiso.verResultadosAsignados,
            child: PanelColegiosScreen(),
          ),
          AgendaVisitasScreen.routeName: (_) => const PermissionGate(
            permission: Permiso.gestionarAgenda,
            child: AgendaVisitasScreen(),
          ),
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
    if (context.read<SesionProvider>().offlineHabilitado) {
      context.read<SesionProvider>().sincronizarCambios();
      return;
    }
    if (tiempoFuera >= const Duration(minutes: 5) &&
        context.read<SesionProvider>().estaAutenticado) {
      _cerrarPorInactividad();
    }
  }

  Future<void> _cerrarPorInactividad() async {
    await context.read<SesionProvider>().cerrarSesion();
    if (!mounted) return;
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
