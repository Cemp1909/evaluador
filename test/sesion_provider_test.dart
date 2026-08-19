import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/models/usuario_sesion.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:evaluador_app/models/configuracion_notas.dart';
import 'package:evaluador_app/models/student_knowledge_draft.dart';
import 'package:evaluador_app/models/student_knowledge_report.dart';
import 'package:evaluador_app/models/visita_programada.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rechaza credenciales desconocidas y no asigna rol de profesor', () {
    final sesion = SesionProvider(AuthConfig.test);

    expect(
      sesion.iniciarSesion(usuario: 'inventado', password: 'cualquiera'),
      contains('No existe un profesor'),
    );
    expect(sesion.usuarioActual, isNull);
  });

  test('autentica los tres roles y conserva profesores al cerrar sesión', () {
    final sesion = SesionProvider(AuthConfig.test);

    expect(
      sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto'),
      isNull,
    );
    expect(sesion.usuarioActual?.rol, RolUsuario.administrador);
    expect(
      sesion.crearProfesor(
        nombre: 'Laura Gómez',
        usuario: 'laura',
        password: 'prueba123',
        zona: 'Zona Norte',
      ),
      isNull,
    );
    expect(
      sesion.iniciarSesion(usuario: 'laura', password: 'prueba123'),
      contains('pendiente'),
    );
    sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    expect(sesion.aprobarProfesor('laura'), isNull);
    sesion.cerrarSesion();

    expect(
      sesion.iniciarSesion(usuario: 'laura', password: 'prueba123'),
      isNull,
    );
    expect(sesion.usuarioActual?.rol, RolUsuario.profesor);
    expect(sesion.usuarioActual?.zona, 'Zona Norte');
  });

  test('un profesor puede registrarse pero requiere aprobación del admin', () {
    final sesion = SesionProvider(AuthConfig.test);

    expect(
      sesion.registrarSolicitudProfesor(
        nombre: 'Profesor Nuevo',
        usuario: 'nuevo',
        password: 'prueba123',
        zona: 'Zona Sur',
      ),
      isNull,
    );
    expect(
      sesion.iniciarSesion(usuario: 'nuevo', password: 'prueba123'),
      contains('pendiente'),
    );
    expect(sesion.aprobarProfesor('nuevo'), contains('Solo el administrador'));

    sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    expect(sesion.aprobarProfesor('nuevo'), isNull);
    sesion.cerrarSesion();
    expect(
      sesion.iniciarSesion(usuario: 'nuevo', password: 'prueba123'),
      isNull,
    );
  });

  test('el coordinador solo ve y crea profesores de su zona', () {
    final sesion = SesionProvider(AuthConfig.test);
    sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    sesion.crearProfesor(
      nombre: 'Profesor Norte',
      usuario: 'norte',
      password: 'prueba123',
      zona: 'Zona Norte',
    );
    sesion.crearProfesor(
      nombre: 'Profesor Centro',
      usuario: 'centro',
      password: 'prueba123',
      zona: 'Zona Centro',
    );
    sesion.cerrarSesion();
    sesion.iniciarSesion(usuario: 'coordinador', password: 'cambiar_esto');

    expect(sesion.profesoresVisibles(), hasLength(1));
    expect(sesion.profesoresVisibles().single.usuario, 'centro');
    sesion.crearProfesor(
      nombre: 'Profesor Forzado',
      usuario: 'forzado',
      password: 'prueba123',
      zona: 'Zona Diferente',
    );
    expect(sesion.profesores.last.zona, 'Zona Centro');
  });

  test('valida duplicados y contraseña mínima', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');

    expect(
      sesion.crearProfesor(
        nombre: 'Laura',
        usuario: 'laura',
        password: '123',
        zona: 'Centro',
      ),
      contains('mínimo'),
    );
    sesion.crearProfesor(
      nombre: 'Laura',
      usuario: 'laura',
      password: '123456',
      zona: 'Centro',
    );
    expect(
      sesion.crearProfesor(
        nombre: 'Otra Laura',
        usuario: 'LAURA',
        password: '123456',
        zona: 'Centro',
      ),
      contains('ya está en uso'),
    );
  });

  test('conserva borrador y configuración durante la sesión', () {
    final sesion = SesionProvider(AuthConfig.test);
    sesion.guardarBorradorConocimiento(
      StudentKnowledgeDraft(
        actualizadoEn: DateTime(2026, 8, 17),
        colegio: 'Colegio Central',
        profesorEvaluado: 'Laura',
        compromiso: '',
        periodo: 2,
        grado: 'Jardín',
        resultados: const {'item': ResultadoContenido.logrado},
        itemsHabilitados: const {'item'},
      ),
    );
    sesion.actualizarConfiguracionNotas(
      const ConfiguracionNotas(puntosPorReforzar: 3.5),
    );

    expect(sesion.borradorConocimiento?.grado, 'Jardín');
    expect(sesion.configuracionNotas.puntosPorReforzar, 3.5);
    sesion.descartarBorradorConocimiento();
    expect(sesion.borradorConocimiento, isNull);
  });

  test('programa, ordena y completa visitas durante la sesión', () {
    final sesion = SesionProvider(AuthConfig.test);
    sesion.programarVisita(
      VisitaProgramada(
        id: '2',
        fecha: DateTime(2026, 9, 20),
        colegio: 'Colegio B',
        tipo: 'Capacitación primaria',
        profesorResponsable: 'Laura Gómez',
        numeroClase: 3,
      ),
    );
    sesion.programarVisita(
      VisitaProgramada(
        id: '1',
        fecha: DateTime(2026, 9, 10),
        colegio: 'Colegio A',
        tipo: 'Evaluación por colegio',
        profesorResponsable: 'Carlos Díaz',
        periodo: 2,
      ),
    );

    expect(sesion.visitas.map((visita) => visita.id), ['1', '2']);
    sesion.alternarVisita('1');
    expect(sesion.visitas.first.completada, isTrue);
    sesion.cancelarVisita('1', 'El colegio suspendió actividades');
    expect(sesion.visitas.first.cancelada, isTrue);
    expect(sesion.visitas.first.completada, isFalse);
    sesion.reprogramarVisita('1', DateTime(2026, 10, 5));
    final reprogramada = sesion.visitas.firstWhere(
      (visita) => visita.id == '1',
    );
    expect(reprogramada.cancelada, isFalse);
    expect(reprogramada.fecha, DateTime(2026, 10, 5));
  });

  test('impide repetir período o clase en el mismo colegio', () {
    final sesion = SesionProvider(AuthConfig.test);
    expect(
      sesion.programarVisita(
        VisitaProgramada(
          id: 'p1',
          fecha: DateTime(2026, 9, 1),
          colegio: 'Colegio Central',
          tipo: 'Evaluación por colegio',
          profesorResponsable: 'Laura',
          periodo: 2,
        ),
      ),
      isNull,
    );
    expect(
      sesion.programarVisita(
        VisitaProgramada(
          id: 'p2',
          fecha: DateTime(2026, 10, 1),
          colegio: ' colegio central ',
          tipo: 'Evaluación por colegio',
          profesorResponsable: 'Carlos',
          periodo: 2,
        ),
      ),
      contains('período 2'),
    );
    expect(
      sesion.programarVisita(
        VisitaProgramada(
          id: 'c1',
          fecha: DateTime(2026, 9, 2),
          colegio: 'Colegio Central',
          tipo: 'Capacitación preescolar',
          profesorResponsable: 'Laura',
          numeroClase: 3,
        ),
      ),
      isNull,
    );
    expect(
      sesion.programarVisita(
        VisitaProgramada(
          id: 'c2',
          fecha: DateTime(2026, 9, 3),
          colegio: 'COLEGIO CENTRAL',
          tipo: 'Capacitación preescolar',
          profesorResponsable: 'Laura',
          numeroClase: 3,
        ),
      ),
      contains('clase 3'),
    );
    expect(sesion.visitas, hasLength(2));
  });

  test(
    'programa semanalmente todas las clases restantes y reserva la hora',
    () {
      final sesion = SesionProvider(AuthConfig.test);
      final inicio = DateTime(2026, 9, 7, 8, 30);
      expect(
        sesion.programarSerieClases(
          VisitaProgramada(
            id: 'serie',
            fecha: inicio,
            colegio: 'Colegio Semanal',
            tipo: 'Capacitación preescolar',
            profesorResponsable: 'Laura',
            numeroClase: 2,
          ),
        ),
        isNull,
      );

      expect(sesion.visitas, hasLength(5));
      expect(sesion.visitas.first.numeroClase, 2);
      expect(sesion.visitas.last.numeroClase, 6);
      expect(sesion.visitas.last.fecha, inicio.add(const Duration(days: 28)));
      expect(
        sesion.programarVisita(
          VisitaProgramada(
            id: 'cruce',
            fecha: inicio.add(const Duration(days: 7)),
            colegio: 'Otro Colegio',
            tipo: 'Evaluación por colegio',
            profesorResponsable: 'Carlos',
            periodo: 1,
          ),
        ),
        contains('día y hora'),
      );
      final clase2Antes = sesion.visitas
          .firstWhere((visita) => visita.numeroClase == 2)
          .fecha;
      final clase3 = sesion.visitas.firstWhere(
        (visita) => visita.numeroClase == 3,
      );
      sesion.posponerSerieDesde(clase3.id, 'El colegio cerró ese día');
      expect(
        sesion.visitas.firstWhere((visita) => visita.numeroClase == 2).fecha,
        clase2Antes,
      );
      expect(
        sesion.visitas.firstWhere((visita) => visita.numeroClase == 3).fecha,
        clase3.fecha.add(const Duration(days: 7)),
      );
    },
  );
}
