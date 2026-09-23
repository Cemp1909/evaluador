import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/config/evaluadores_config.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:evaluador_app/screens/student_knowledge_report_screen.dart';
import 'package:evaluador_app/services/evaluacion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

SesionProvider _sesionConContenidoEnsenado() {
  final sesion = SesionProvider(AuthConfig.test)
    ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
  sesion.asignarDocentesColegio('Colegio A', ['Ana']);
  final servicio = EvaluacionService();
  var evaluacion = servicio
      .crearDesdePlantilla(evaluadoresDisponibles.first)
      .copyWith(colegio: 'Colegio A');
  final clase = evaluacion.clases.first;
  final bloque = clase.bloques.firstWhere(
    (item) => item.bloqueNombre == 'Commands',
  );
  evaluacion = servicio.actualizarItem(
    evaluacion: evaluacion,
    claseNumero: clase.claseNumero,
    bloqueNombre: bloque.bloqueNombre,
    itemTexto: bloque.itemsMarcados.keys.first,
    marcado: true,
  );
  sesion.guardarBorradorEvaluacion(evaluacion);
  return sesion;
}

Future<void> _seleccionarColegio(WidgetTester tester, String nombre) async {
  final selector = find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField<String> &&
        widget.decoration.labelText == 'Colegio',
  );
  await tester.scrollUntilVisible(
    selector,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.tap(find.text(nombre).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('registra al profesor responsable sin cambiar el plan', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sesion = _sesionConContenidoEnsenado();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sesion,
        child: const MaterialApp(home: StudentKnowledgeReportScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await _seleccionarColegio(tester, 'Colegio A');
    final profesor = find.byWidgetPredicate(
      (w) =>
          w is DropdownButtonFormField<String> &&
          w.decoration.labelText == 'Profesor responsable del salón',
    );
    await tester.ensureVisible(profesor);
    await tester.tap(profesor);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana').last);
    await tester.pumpAndSettle();
    expect(sesion.borradorConocimiento!.profesorResponsableSalon, 'Ana');
    expect(sesion.borradorConocimiento!.colegio, 'Colegio A');
  });

  testWidgets(
    'muestra el plan completo aunque una clase tenga marcas parciales',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final sesion = _sesionConContenidoEnsenado();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: sesion,
          child: const MaterialApp(home: StudentKnowledgeReportScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await _seleccionarColegio(tester, 'Colegio A');
      await tester.scrollUntilVisible(
        find.text('Commands'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Commands'));
      await tester.pumpAndSettle();
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Sit down'), findsOneWidget);
      expect(find.text('Stand up'), findsOneWidget);
      expect(find.text('Blue Page'), findsNothing);
      expect(find.text('Editar contenidos de Commands'), findsNothing);
    },
  );

  testWidgets('categorías inician cerradas y conservan su estado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sesion = _sesionConContenidoEnsenado();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sesion,
        child: const MaterialApp(home: StudentKnowledgeReportScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await _seleccionarColegio(tester, 'Colegio A');
    await tester.scrollUntilVisible(
      find.text('Commands'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final categoria = tester.widget<ExpansionTile>(
      find.widgetWithText(ExpansionTile, 'Commands'),
    );
    expect(categoria.initiallyExpanded, isFalse);
    expect(categoria.maintainState, isTrue);
    expect(categoria.key, isA<PageStorageKey<String>>());

    expect(find.text('Logrado'), findsNothing);
    await tester.tap(find.text('Commands'));
    await tester.pumpAndSettle();
    expect(find.text('Logrado'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Contenido no evaluado'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('Commands'),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Logrado'), findsWidgets);
  });
}
