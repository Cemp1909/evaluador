import 'package:evaluador_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('credenciales desconocidas no ingresan como profesor', (
    tester,
  ) async {
    await tester.pumpWidget(const EvaluadorApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Usuario'),
      'usuario_inexistente',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'cualquiera',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pump();

    expect(find.textContaining('No existe un profesor'), findsOneWidget);
    expect(find.text('Inicio'), findsNothing);
  });

  testWidgets('admin aprueba un profesor y permite iniciar sesión con él', (
    tester,
  ) async {
    await tester.pumpWidget(const EvaluadorApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Usuario'),
      'admin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'cambiar_esto',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Administración'), findsOneWidget);
    expect(find.text('Evaluaciones'), findsOneWidget);
    await tester.tap(find.text('Crear profesor'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre completo'),
      'Laura Gómez',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Usuario'),
      'laura',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'prueba123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Zona'),
      'Zona Norte',
    );
    final crearButton = find.widgetWithText(FilledButton, 'Crear solicitud');
    await tester.ensureVisible(crearButton);
    await tester.tap(crearButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Solicitud de profesor creada correctamente.'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lista de profesores'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aprobar'));
    await tester.pumpAndSettle();
    expect(find.text('Aprobado'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Usuario'),
      'laura',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'prueba123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Laura Gómez'), findsOneWidget);
    expect(find.text('Zona Norte'), findsOneWidget);
    expect(find.text('Evaluaciones'), findsOneWidget);
  });

  testWidgets('el coordinador tiene acceso al flujo de evaluaciones', (
    tester,
  ) async {
    await tester.pumpWidget(const EvaluadorApp());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Usuario'),
      'coordinador',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'cambiar_esto',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Coordinación'), findsOneWidget);
    expect(find.text('Evaluaciones'), findsOneWidget);
    await tester.tap(find.text('Evaluaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Capacitación Preescolar'), findsOneWidget);
    expect(find.text('Capacitación Primaria'), findsOneWidget);
  });
}
