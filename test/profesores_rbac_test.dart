import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/main.dart';
import 'package:evaluador_app/models/visita_programada.dart';
import 'package:evaluador_app/models/usuario_sesion.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:evaluador_app/screens/crear_profesor_screen.dart';
import 'package:evaluador_app/screens/gestion_home_screen.dart';
import 'package:evaluador_app/screens/profesores_screen.dart';
import 'package:evaluador_app/security/rbac.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test(
    'coordinador conserva crear, editar, completar, cancelar y reprogramar agenda',
    () {
      final sesion = SesionProvider(AuthConfig.test)
        ..iniciarSesion(usuario: 'coordinador', password: 'cambiar_esto');
      final visita = VisitaProgramada(
        id: 'actividad',
        fecha: DateTime(2026, 10, 1),
        colegio: 'Colegio',
        tipo: 'Capacitación preescolar',
        profesorResponsable: 'Docente',
        numeroClase: 1,
      );
      expect(sesion.programarVisita(visita), isNull);
      expect(
        sesion.actualizarVisita(visita.copyWith(profesorResponsable: 'Otro')),
        isNull,
      );
      expect(sesion.visitas.single.profesorResponsable, 'Otro');
      expect(sesion.alternarVisita(visita.id), isNull);
      expect(sesion.visitas.single.completada, isTrue);
      expect(sesion.cancelarVisita(visita.id, 'Cambio de fecha'), isNull);
      expect(sesion.visitas.single.cancelada, isTrue);
      expect(
        sesion.reprogramarVisita(visita.id, DateTime(2026, 10, 2)),
        isNull,
      );
      expect(sesion.visitas.single.fecha, DateTime(2026, 10, 2));
      expect(sesion.visitas.single.cancelada, isFalse);
    },
  );

  test('conserva exactamente los permisos anteriores de los tres roles', () {
    expect(Rbac.matriz[RolUsuario.administrador], Permiso.values.toSet());
    expect(Rbac.matriz[RolUsuario.coordinador], {
      Permiso.gestionarEstructuraAcademica,
      Permiso.asignarProfesores,
      Permiso.crearEvaluaciones,
      Permiso.editarTodasLasEvaluaciones,
      Permiso.publicarEvaluaciones,
      Permiso.verResultadosAsignados,
      Permiso.generarReportesAcademicos,
      Permiso.administrarBancoPreguntas,
      Permiso.gestionarAgenda,
      Permiso.actualizarPerfil,
    });
    expect(Rbac.matriz[RolUsuario.profesor], {
      Permiso.crearEvaluaciones,
      Permiso.verResultadosAsignados,
      Permiso.administrarPreguntasPropias,
      Permiso.usarIa,
      Permiso.gestionarAgenda,
      Permiso.actualizarPerfil,
    });
  });

  test('coordinador no registra solicitudes ni produce mutaciones', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'coordinador', password: 'cambiar_esto');
    var notificaciones = 0;
    sesion.addListener(() => notificaciones++);
    expect(
      sesion.registrarSolicitudProfesor(
        nombre: 'Nuevo',
        usuario: 'nuevo',
        password: '123456',
        zona: 'Zona Centro',
      ),
      contains('Acceso no autorizado'),
    );
    expect(
      sesion.crearProfesor(
        nombre: 'Nuevo',
        usuario: 'nuevo',
        password: '123456',
        zona: 'Zona Centro',
      ),
      contains('No tienes permiso'),
    );
    expect(notificaciones, 0);
    sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    expect(sesion.profesoresVisibles(), isEmpty);
  });

  test('profesor sigue sin crear ni consultar profesores', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'demo', password: 'demo123');
    expect(
      sesion.crearProfesor(
        nombre: 'Nuevo',
        usuario: 'nuevo',
        password: '123456',
        zona: 'Zona Centro',
      ),
      contains('No tienes permiso'),
    );
    expect(sesion.profesoresVisibles(), isEmpty);
    expect(Rbac.puedeConsultarProfesores(sesion.usuarioActual), isFalse);
  });

  testWidgets('coordinador no ve creación y consulta su zona por ruta real', (
    tester,
  ) async {
    await tester.pumpWidget(const EvaluadorApp());
    final context = tester.element(find.byType(Navigator).first);
    final sesion = context.read<SesionProvider>();
    sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    for (final zona in ['Zona Centro', 'Zona Norte']) {
      sesion.crearProfesor(
        nombre: zona,
        usuario: zona,
        password: '123456',
        zona: zona,
      );
    }
    sesion.iniciarSesion(usuario: 'coordinador', password: 'cambiar_esto');
    Navigator.of(context).pushNamed(GestionHomeScreen.coordinadorRoute);
    await tester.pumpAndSettle();
    expect(find.text('Create teacher'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Teacher list'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Teacher list'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfesoresScreen), findsOneWidget);
    expect(find.textContaining('Zona Centro'), findsWidgets);
    expect(find.textContaining('Zona Norte'), findsNothing);
    expect(find.text('Approve'), findsNothing);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);
    for (final ruta in [
      CrearProfesorScreen.routeName,
      CrearProfesorScreen.solicitudRoute,
    ]) {
      Navigator.of(context).pushNamed(ruta);
      await tester.pumpAndSettle();
      expect(find.text('Acceso no autorizado'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
    }
  });

  for (final publica in [false, true]) {
    testWidgets('protege formulario directo, solicitud pública: $publica', (
      tester,
    ) async {
      final sesion = SesionProvider(AuthConfig.test)
        ..iniciarSesion(usuario: 'coordinador', password: 'cambiar_esto');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: sesion,
          child: MaterialApp(
            home: CrearProfesorScreen(solicitudPublica: publica),
          ),
        ),
      );
      expect(find.text('Acceso no autorizado'), findsOneWidget);
      expect(find.byType(Form), findsNothing);
    });
  }
}
