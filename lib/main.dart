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
        },
      ),
    );
  }
}
