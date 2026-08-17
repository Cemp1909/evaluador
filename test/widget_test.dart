import 'package:evaluador_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('credenciales desconocidas no ingresan como profesor', (
    tester,
  ) async {
    await tester.pumpWidget(const EvaluadorApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'usuario_inexistente',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'cualquiera',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(
      find.textContaining('No teacher with that username'),
      findsOneWidget,
    );
    expect(find.text('Inicio'), findsNothing);
  });

  testWidgets('admin aprueba un profesor y permite iniciar sesión con él', (
    tester,
  ) async {
    await tester.pumpWidget(const EvaluadorApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'admin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'cambiar_esto',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Administrador'), findsOneWidget);
    expect(find.text('Evaluations'), findsOneWidget);
    await tester.tap(find.text('Create teacher'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Laura Gómez',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'laura',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'prueba123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Zone'),
      'Zona Norte',
    );
    final crearButton = find.widgetWithText(FilledButton, 'Create request');
    await tester.ensureVisible(crearButton);
    await tester.tap(crearButton);
    await tester.pumpAndSettle();

    expect(find.text('Teacher request created successfully.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teacher list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(find.text('Approved'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'laura',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'prueba123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Laura Gómez'), findsOneWidget);
    expect(find.text('Zona Norte'), findsOneWidget);
    expect(find.text('Evaluations'), findsOneWidget);
  });

  testWidgets('el coordinador tiene acceso al flujo de evaluaciones', (
    tester,
  ) async {
    await tester.pumpWidget(const EvaluadorApp());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'coordinador',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'cambiar_esto',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Coordinador de zona'), findsOneWidget);
    expect(find.text('Evaluations'), findsOneWidget);
    await tester.tap(find.text('Evaluations'));
    await tester.pumpAndSettle();
    expect(find.text('Training Preschool'), findsOneWidget);
    expect(find.text('Training Primary'), findsOneWidget);
  });
}
