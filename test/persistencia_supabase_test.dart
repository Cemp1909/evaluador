import 'dart:convert';
import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/config/evaluadores_config.dart';
import 'package:evaluador_app/services/evaluacion_service.dart';
import 'package:evaluador_app/models/contacto_colegio.dart';
import 'package:evaluador_app/models/evaluacion.dart';
import 'package:evaluador_app/models/student_knowledge_draft.dart';
import 'package:evaluador_app/models/student_knowledge_report.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Transporte HTTP simulado: estas pruebas no certifican las políticas del servidor.
class ServidorPrueba {
  static const uid = '00000000-0000-4000-8000-000000000001';
  Map<String, dynamic>? borrador;
  bool rechazar = false;
  bool sinRed = false;
  final recibos = <String, int>{};
  final archivos = <String, List<int>>{};
  final tablas = <String, List<Map<String, dynamic>>>{};
  final colegio = <String, dynamic>{
    'id': '00000000-0000-4000-8000-000000000002',
    'nombre': 'Colegio de prueba',
    'ciudad': '',
    'direccion': '',
    'telefono': '',
  };

  SupabaseClient cliente() => SupabaseClient(
    'https://prueba.supabase.co',
    'clave-publica-de-prueba',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    httpClient: MockClient((r) async {
      if (sinRed) throw http.ClientException("Sin conexión", r.url);
      http.Response json(Object? value, [int status = 200]) => http.Response(
        jsonEncode(value),
        status,
        request: r,
        headers: {'content-type': 'application/json'},
      );
      final single = (r.headers['Accept'] ?? r.headers['accept'] ?? '')
          .contains('object');
      http.Response filas(List<Map<String, dynamic>> rows) =>
          json(single ? (rows.isEmpty ? null : rows.single) : rows);
      if (r.url.path.endsWith('/token')) {
        String b64(Object value) => base64Url
            .encode(utf8.encode(jsonEncode(value)))
            .replaceAll('=', '');
        final token =
            '${b64({'alg': 'HS256'})}.${b64({'sub': uid, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.firma';
        return json({
          'access_token': token,
          'refresh_token': 'refresh-prueba',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': uid,
            'aud': 'authenticated',
            'email': 'prueba@example.test',
            'app_metadata': {},
            'user_metadata': {},
            'created_at': '2026-01-01T00:00:00Z',
          },
        });
      }
      if (r.url.path.endsWith('/logout')) {
        return http.Response('', 204, request: r);
      }
      if (rechazar && r.method != 'GET') {
        return json({'code': '42501', 'message': 'Guardado rechazado'}, 403);
      }
      if (r.url.path.startsWith('/storage/v1/object/')) {
        final ruta = r.url.path
            .replaceFirst('/storage/v1/object/', '')
            .replaceFirst('authenticated/', '');
        if (r.method == 'POST') {
          final contentType = r.headers['content-type']!;
          if (contentType.startsWith('multipart/')) {
            final boundary = contentType.split('boundary=').last;
            final part = latin1
                .decode(r.bodyBytes)
                .split('--$boundary')
                .firstWhere((part) => part.contains('filename='));
            final contenido = part.substring(part.indexOf('\r\n\r\n') + 4);
            archivos[ruta] = latin1.encode(
              contenido.substring(0, contenido.length - 2),
            );
          } else {
            archivos[ruta] = r.bodyBytes;
          }
          return json({'Key': ruta, 'Id': ruta});
        }
        return http.Response.bytes(archivos[ruta]!, 200, request: r);
      }
      final tabla = r.url.path.split('/').last;
      if (tabla == 'version_sincronizacion_academica') return json(1);
      if (tabla == 'sincronizar_academico') {
        final op = jsonDecode(r.body) as Map<String, dynamic>;
        final id = op['p_operacion'] as String;
        if (recibos.containsKey(id)) return json(recibos[id]);
        if (op['p_tipo'] == 'borrador') {
          final revision = (borrador?['revision'] as int?) ?? 0;
          if (revision != op['p_revision']) {
            return json({'message': 'SYNC_CONFLICT', 'code': 'P0001'}, 409);
          }
          borrador = {
            'autor_id': uid,
            ...op['p_datos'] as Map<String, dynamic>,
            'revision': revision + 1,
          };
          recibos[id] = revision + 1;
          return json(revision + 1);
        }
        return json({'message': 'Tipo no implementado por el mock'}, 400);
      }
      if (tabla == 'guardar_evaluacion_academica') {
        final datos =
            (jsonDecode(r.body) as Map)['p_evaluacion'] as Map<String, dynamic>;
        tablas['evaluaciones_capacitacion'] = [Map.of(datos)..remove('clases')];
        tablas['clases_capacitacion'] = [
          for (final clase in datos['clases'] as List)
            {...clase as Map<String, dynamic>, 'evaluacion_id': datos['id']},
        ];
        tablas['asistencias'] = [
          for (final clase in datos['clases'] as List)
            for (final marca in clase['asistencias'] as List)
              {...marca as Map<String, dynamic>, 'clase_id': clase['id']},
        ];
        return http.Response('', 204, request: r);
      }
      if (tabla == 'reportes_periodo' && r.method != 'GET') {
        if (r.method == 'POST') {
          tablas[tabla] = [
            {'id': 'reporte-db', ...jsonDecode(r.body) as Map<String, dynamic>},
          ];
        } else {
          tablas[tabla]!.single.addAll(
            jsonDecode(r.body) as Map<String, dynamic>,
          );
        }
        return filas(tablas[tabla]!);
      }
      if (tablas.containsKey(tabla)) return filas(tablas[tabla]!);
      if (tabla == 'perfiles') {
        return filas([
          {
            'id': uid,
            'nombre': 'Prueba',
            'rol': 'administrador',
            'zona': null,
            'activo': true,
          },
        ]);
      }
      if (tabla == 'configuracion_academica') {
        return filas([
          {
            'id': true,
            'notas': {},
            'asistencia_minima_profesor': 80,
            'evaluacion_periodos_minima_profesor': 75,
          },
        ]);
      }
      if (tabla == 'colegios') {
        if (r.method == 'PATCH') {
          colegio.addAll(jsonDecode(r.body) as Map<String, dynamic>);
        }
        return filas([colegio]);
      }
      if (tabla == 'borradores_reportes') {
        if (r.method == 'POST') {
          borrador = jsonDecode(r.body) as Map<String, dynamic>;
        }
        if (r.method == 'DELETE') {
          borrador = null;
          return http.Response('', 204, request: r);
        }
        return filas(borrador == null ? [] : [borrador!]);
      }
      return filas([]);
    }),
  );
}

StudentKnowledgeDraft draft(String texto) => StudentKnowledgeDraft(
  actualizadoEn: DateTime.utc(2026, 9, 19),
  colegio: 'Colegio de prueba',
  compromiso: texto,
  periodo: 1,
  grado: 'Párvulos',
  resultados: const {'tema': ResultadoContenido.logrado},
  itemsHabilitados: const {'tema'},
  firmaColegio: 'firma-prueba',
  fotosEvidencia: const ['foto-prueba'],
  comentariosContenido: const {'tema': 'Comentario'},
  referenciasFotos: const [null],
);

Future<SesionProvider> entrar(ServidorPrueba servidor) async {
  final cliente = servidor.cliente();
  addTearDown(cliente.dispose);
  final provider = SesionProvider(AuthConfig.test, supabaseClient: cliente);
  addTearDown(provider.dispose);
  expect(
    await provider.iniciarSesionSupabase(
      usuario: 'prueba@example.test',
      password: 'prueba',
    ),
    isNull,
  );
  return provider;
}

void main() {
  test(
    'evaluación, asistencia y archivos se recuperan desde otra sesión',
    () async {
      final backend = ServidorPrueba();
      backend.tablas['docentes_colegio'] = [
        {'id': 'docente-1', 'nombre': 'Docente escolar'},
      ];
      backend.tablas['asignaciones_docentes'] = [
        {
          'id': 'asignacion-1',
          'docente_id': 'docente-1',
          'colegio_id': backend.colegio['id'],
          'nivel': 'preescolar',
          'fecha_inicio': '2020-01-01T00:00:00Z',
          'fecha_fin': null,
        },
      ];
      final sesion = await entrar(backend);
      final foto = base64Encode([137, 80, 78, 71, 13, 10, 26, 10]);
      final inicial = EvaluacionService().crearDesdePlantilla(
        evaluadoresDisponibles.first,
      );
      final evaluacion = inicial.copyWith(
        colegio: 'Colegio de prueba',
        responsableNombre: 'Prueba',
        fotosUrls: [foto],
        clases: [
          inicial.clases.first.copyWith(
            asistencia: {'Docente escolar': true},
            firmaDocenteUrl: foto,
            observaciones: 'Observación guardada',
            fecha: DateTime.now(),
          ),
          ...inicial.clases.skip(1),
        ],
      );
      expect(
        await sesion.guardarBorradorEvaluacionPersistente(evaluacion),
        isNull,
      );
      final recuperada = (await entrar(
        backend,
      )).borradorEvaluacion(evaluacion.evaluadorTipo)!;
      expect(recuperada.clases.length, evaluacion.clases.length);
      expect(recuperada.clases.first.asistencia, {'Docente escolar': true});
      expect(recuperada.clases.first.observaciones, 'Observación guardada');
      expect(recuperada.clases.first.firmaDocenteUrl, foto);
      expect(recuperada.fotosUrls, [foto]);
      backend.rechazar = true;
      expect(
        await sesion.guardarBorradorEvaluacionPersistente(
          evaluacion.copyWith(estado: EstadoEvaluacion.completada),
        ),
        isNotNull,
      );
      expect(
        sesion.borradorEvaluacion(evaluacion.evaluadorTipo)!.estado,
        evaluacion.estado,
      );
    },
  );

  test(
    'reporte y aprobación conservan contenido y firmas tras iniciar otra sesión',
    () async {
      final backend = ServidorPrueba();
      final sesion = await entrar(backend);
      final foto = base64Encode([137, 80, 78, 71, 13, 10, 26, 10]);
      final reporte = StudentKnowledgeReport(
        id: 'prueba-reporte',
        fechaHora: DateTime.now(),
        docente: 'Prueba',
        profesorEvaluado: 'Docente escolar',
        colegio: 'Colegio de prueba',
        grado: 'Párvulos',
        periodo: 1,
        evaluaciones: const {'tema': 'Logrado'},
        compromiso: 'Practicar',
        firmaColegio: foto,
        firmaDocenteColegio: foto,
        firmaDocenteCourseChild: foto,
        fotosEvidencia: [foto],
        resultadosContenido: const {'tema': ResultadoContenido.logrado},
      );
      expect(
        await sesion.guardarReporteConocimientoPersistente(reporte),
        isNull,
      );
      expect(
        await sesion.aprobarReporteConocimientoPersistente(
          reporteId: reporte.id,
          firma: foto,
        ),
        isNull,
      );
      final nuevo = (await entrar(backend)).reportesConocimiento.single;
      expect(nuevo.compromiso, reporte.compromiso);
      expect(nuevo.resultadosContenido, reporte.resultadosContenido);
      expect(nuevo.firmaColegio, foto);
      expect(nuevo.firmaCoordinador, foto);
      expect(nuevo.fotosEvidencia, [foto]);
      expect(nuevo.aprobadoPorCoordinador, isTrue);
    },
  );

  test(
    'borrador y contacto sobreviven a una nueva sesión sin reutilizar memoria',
    () async {
      final backend = ServidorPrueba();
      final sesion = await entrar(backend);
      expect(
        await sesion.guardarBorradorConocimientoPersistente(
          draft('Compromiso'),
        ),
        isNull,
      );
      expect(
        await sesion.guardarContactoColegio(
          'Colegio de prueba',
          const ContactoColegio(
            ciudad: 'Bogotá',
            direccion: 'Calle 10',
            telefono: '+57 123',
          ),
        ),
        isNull,
      );
      await sesion.cerrarSesion();
      expect(sesion.borradorConocimiento, isNull);
      expect(sesion.colegiosRegistrados, isEmpty);
      final nueva = await entrar(backend);
      expect(
        nueva.borradorConocimiento!.toJson(),
        draft('Compromiso').toJson(),
      );
      expect(nueva.contactoColegio('Colegio de prueba').telefono, '+57 123');
      expect(await nueva.descartarBorradorConocimientoPersistente(), isNull);
      expect((await entrar(backend)).borradorConocimiento, isNull);
    },
  );

  test(
    'rechazo remoto no deja un borrador o contacto marcado como guardado',
    () async {
      final backend = ServidorPrueba();
      final sesion = await entrar(backend);
      backend.rechazar = true;
      expect(
        await sesion.guardarBorradorConocimientoPersistente(
          draft('No guardar'),
        ),
        isNotNull,
      );
      expect(sesion.borradorConocimiento, isNull);
      expect(backend.borrador, isNull);
      expect(
        await sesion.guardarContactoColegio(
          'Colegio de prueba',
          const ContactoColegio(telefono: '123'),
        ),
        isNotNull,
      );
      expect(sesion.contactoColegio('Colegio de prueba').telefono, isEmpty);
    },
  );

  test('guardados rápidos del borrador conservan el último cambio', () async {
    final backend = ServidorPrueba();
    final sesion = await entrar(backend);
    expect(
      await Future.wait([
        sesion.guardarBorradorConocimientoPersistente(draft('Uno')),
        sesion.guardarBorradorConocimientoPersistente(draft('Dos')),
      ]),
      [null, null],
    );
    expect((await entrar(backend)).borradorConocimiento!.compromiso, 'Dos');
  });

  test(
    'evaluación sin colegio no se guarda localmente en modo Supabase',
    () async {
      final sesion = await entrar(ServidorPrueba());
      final evaluacion = Evaluacion(
        evaluadorTipo: 'prueba',
        colegio: '',
        fechaCreacion: DateTime.now(),
        clases: const [],
      );
      expect(
        await sesion.guardarBorradorEvaluacionPersistente(evaluacion),
        isNotNull,
      );
      expect(sesion.borradorEvaluacion('prueba'), isNull);
    },
  );
}
