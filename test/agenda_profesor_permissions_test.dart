import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/models/visita_programada.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:evaluador_app/screens/agenda_visitas_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  VisitaProgramada visita(String id, String profesor) => VisitaProgramada(
    id: id,
    fecha: DateTime(
      2026,
      9,
      20,
      id == 'asignada-2'
          ? 11
          : id == 'ajena'
          ? 13
          : 9,
    ),
    colegio: 'Colegio $id',
    tipo: 'Capacitación preescolar',
    profesorResponsable: profesor,
    numeroClase: id == 'asignada-2' ? 2 : 1,
  );

  SesionProvider sesionConAgenda() {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    expect(sesion.programarVisita(visita('asignada', 'Profesor demo')), isNull);
    expect(
      sesion.programarVisita(visita('asignada-2', 'Profesor demo')),
      isNull,
    );
    expect(sesion.programarVisita(visita('ajena', 'Otra persona')), isNull);
    sesion.iniciarSesion(usuario: 'demo', password: 'demo123');
    return sesion;
  }

  test('profesor consulta solo su agenda asignada', () {
    final sesion = sesionConAgenda();

    expect(sesion.visitas.map((visita) => visita.id), [
      'asignada',
      'asignada-2',
    ]);
    expect(
      sesion
          .actividadesProximas(
            DateTime(2026, 9, 19),
            ventana: const Duration(days: 2),
          )
          .map((visita) => visita.id),
      ['asignada', 'asignada-2'],
    );
  });

  test('profesor no administra ni reprograma la agenda', () {
    final sesion = sesionConAgenda();
    final asignada = sesion.visitas.first;

    expect(
      sesion.programarVisita(visita('nueva', 'Profesor demo')),
      contains('consultar, cancelar o marcar'),
    );
    expect(
      sesion.actualizarVisita(asignada.copyWith(colegio: 'Otro colegio')),
      contains('consultar, cancelar o marcar'),
    );
    expect(
      sesion.reprogramarVisita('asignada', DateTime(2026, 9, 30)),
      contains('consultar, cancelar o marcar'),
    );
    expect(
      sesion.bloquearFecha(DateTime(2026, 9, 21)),
      contains('consultar, cancelar o marcar'),
    );
    expect(
      sesion.actualizarResponsablesVisita(
        id: 'asignada',
        profesor: 'Otro',
        acompanantes: const [],
        ubicacion: '',
      ),
      contains('consultar, cancelar o marcar'),
    );
    expect(
      sesion.actualizarEstadoVisita('asignada', EstadoVisita.reprogramada),
      contains('únicamente puede marcar'),
    );
  });

  test('profesor marca realizada y cancela únicamente una asignada', () {
    final sesion = sesionConAgenda();

    expect(
      sesion.actualizarEstadoVisita('asignada', EstadoVisita.realizada),
      isNull,
    );
    expect(sesion.visitas.first.completada, isTrue);
    expect(
      sesion.cancelarVisita('asignada-2', 'El colegio canceló la clase'),
      isNull,
    );
    expect(sesion.visitas.last.cancelada, isTrue);
    expect(
      sesion.cancelarVisita('ajena', 'Intento manual'),
      contains('no te fue asignada'),
    );
  });

  testWidgets('agenda del profesor oculta controles administrativos', (
    tester,
  ) async {
    final sesion = sesionConAgenda();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sesion,
        child: const MaterialApp(home: AgendaVisitasScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Colegio asignada'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Programar visita'), findsNothing);
    expect(find.byTooltip('Bloquear fecha'), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Responsables'), findsNothing);
    expect(find.text('Reprogramar'), findsNothing);
    expect(find.byTooltip('Cambiar estado'), findsNothing);
    expect(find.text('Marcar como realizada'), findsWidgets);
    expect(find.text('Cancelar'), findsWidgets);
    expect(find.text('Colegio ajena'), findsNothing);
  });

  testWidgets('coordinador selecciona profesor de su zona desde una lista', (
    tester,
  ) async {
    const config = AuthConfig(
      adminUsername: 'admin',
      adminPassword: 'admin123',
      coordinadorUsername: 'coordinador',
      coordinadorPassword: 'coord123',
      coordinadorZona: 'Zona Centro',
      profesoresIniciales: [
        ProfesorInicialConfig(
          usuario: 'sebastian',
          password: 'profesor123',
          nombre: 'Sebastian',
          zona: 'Zona Centro',
        ),
        ProfesorInicialConfig(
          usuario: 'vanessa',
          password: 'profesor123',
          nombre: 'Vanessa',
          zona: 'Zona Centro',
        ),
        ProfesorInicialConfig(
          usuario: 'otra',
          password: 'profesor123',
          nombre: 'Fuera de zona',
          zona: 'Zona Norte',
        ),
      ],
    );
    final sesion = SesionProvider(config)
      ..iniciarSesion(usuario: 'coordinador', password: 'coord123');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sesion,
        child: const MaterialApp(home: AgendaVisitasScreen()),
      ),
    );
    await tester.tap(find.text('Programar visita'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona un profesor'), findsOneWidget);
    expect(find.text('Separados por comas'), findsNothing);
    expect(find.text('Ninguno seleccionado'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    expect(find.text('Sebastian'), findsWidgets);
    expect(find.text('Vanessa'), findsWidgets);
    expect(find.text('Fuera de zona'), findsNothing);
  });
}
