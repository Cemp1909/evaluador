import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:evaluador_app/screens/student_knowledge_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('categorías inician cerradas y conservan su estado', (
    tester,
  ) async {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'demo', password: 'demo123');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sesion,
        child: const MaterialApp(home: StudentKnowledgeReportScreen()),
      ),
    );
    await tester.pumpAndSettle();
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
