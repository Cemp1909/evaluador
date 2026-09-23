import 'dart:async';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_io.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:evaluador_app/services/offline/offline_store.dart';
import 'package:evaluador_app/services/offline/sync_engine.dart';

void main() {
  late Directory dir;
  late SecretKey key;
  late OfflineStore store;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('academic-offline-');
    key = await AesGcm.with256bits().newSecretKey();
    store = OfflineStore(
      await databaseFactoryIo.openDatabase('${dir.path}/user.db'),
      key,
      'usuario-a',
    );
  });
  tearDown(() async {
    await store.cerrar();
    await dir.delete(recursive: true);
  });

  test('reinicio conserva fotos, firmas y pendientes cifrados', () async {
    final data = {
      'nombre': 'Docente privado',
      'foto': 'imagen-base64-privada',
      'firma': 'firma-privada',
    };
    await store.encolar('evaluacion', 'e1', data, 0);
    final id = (await store.pendientes()).single['id'];
    await store.cerrar();
    expect(
      await File('${dir.path}/user.db').readAsString(),
      isNot(contains('Docente privado')),
    );
    store = OfflineStore(
      await databaseFactoryIo.openDatabase('${dir.path}/user.db'),
      key,
      'usuario-a',
    );
    expect((await store.pendientes()).single['id'], id);
    expect((await store.pendientes()).single['datos'], data);
    final ajeno = OfflineStore(store.db, key, 'usuario-b');
    await expectLater(
      ajeno.pendientes(),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('compacta solo cambios nunca enviados y conserva el último', () async {
    await store.encolar('borrador', 'u', {'valor': 1}, 0);
    await store.encolar('borrador', 'u', {'valor': 2}, 0);
    expect(await store.pendientes(), hasLength(1));
    final enviada = (await store.pendientes()).single;
    await store.prepararEnvio(enviada['secuencia'] as int);
    await store.encolar('borrador', 'u', {'valor': 3}, 0);
    expect(await store.pendientes(), hasLength(2));
    await store.confirmar(enviada, 5);
    expect((await store.pendientes()).single['revision'], 5);
    expect((await store.pendientes()).single['datos'], {'valor': 3});
    await store.confirmar(enviada, 1); // respuesta tardía de otra pestaña
    expect((await store.pendientes()).single['revision'], 5);
  });

  test('pérdida de respuesta reintenta el mismo UUID sin duplicar', () async {
    await store.encolar('evaluacion', 'e1', {'valor': 1}, 0);
    final recibos = <String, int>{};
    int escrituras = 0;
    bool cortar = true;
    final sync = SyncEngine(
      store,
      comprobarSesion: () async {},
      enviar: (op) async {
        final revision = recibos.putIfAbsent(
          op['id'] as String,
          () => ++escrituras,
        );
        if (cortar) {
          cortar = false;
          throw const SocketException('sin red');
        }
        return revision;
      },
    );
    await sync.iniciar();
    await sync.sincronizar();
    expect(sync.sinConexion, isTrue);
    expect(await store.pendientes(), hasLength(1));
    await sync.sincronizar();
    expect(escrituras, 1);
    expect(await store.pendientes(), isEmpty);
    await sync.cerrar();
  });

  test('conflicto conserva datos y permite enviar otras entidades', () async {
    await store.encolar('evaluacion', 'e1', {'valor': 'mi trabajo'}, 2);
    await store.encolar('borrador', 'u', {'valor': 4}, 0);
    final sync = SyncEngine(
      store,
      comprobarSesion: () async {},
      enviar: (op) async {
        if (op['recurso'] == 'e1') {
          throw const PostgrestException(message: 'SYNC_CONFLICT');
        }
        return 1;
      },
    );
    await sync.iniciar();
    await sync.sincronizar();
    final pendiente = (await store.pendientes()).single;
    expect(pendiente['error'], contains('Otro usuario'));
    expect(pendiente['datos'], {'valor': 'mi trabajo'});
    expect(pendiente['revision'], 2);
    await sync.cerrar();
  });

  test(
    'fallo de transporte envuelto por Storage se reintenta automáticamente',
    () async {
      await store.encolar('evaluacion', 'e1', {'foto': 'pendiente'}, 0);
      bool conectado = false;
      final sync = SyncEngine(
        store,
        comprobarSesion: () async {},
        enviar: (op) async {
          if (!conectado) {
            throw const StorageException(
              'ClientException: Failed to fetch',
              statusCode: 'minified:transport',
            );
          }
          return 1;
        },
      );
      await sync.iniciar();
      await sync.sincronizar();
      expect(sync.sinConexion, isTrue);
      expect((await store.pendientes()).single['error'], isNull);
      conectado = true;
      await sync.sincronizar();
      expect(await store.pendientes(), isEmpty);
      await sync.cerrar();
    },
  );

  test('sesión revocada no envía ni elimina pendientes', () async {
    await store.encolar('borrador', 'u', {'valor': 1}, 0);
    int envios = 0;
    final sync = SyncEngine(
      store,
      comprobarSesion: () async {
        throw const AuthException('revocada');
      },
      enviar: (op) async {
        envios++;
        return 1;
      },
    );
    await sync.iniciar();
    await sync.sincronizar();
    expect(envios, 0);
    expect(await store.pendientes(), hasLength(1));
    expect(sync.sinConexion, isFalse);
    expect(sync.ultimoError, contains('sesión'));
    await sync.cerrar();
  });

  test(
    'cambio durante envío conserva revisión y contenido siguiente',
    () async {
      await store.encolar('borrador', 'u', {'valor': 1}, 0);
      final inicio = Completer<void>();
      final terminar = Completer<void>();
      final valores = <int>[];
      final sync = SyncEngine(
        store,
        comprobarSesion: () async {},
        enviar: (op) async {
          valores.add((op['datos'] as Map)['valor'] as int);
          if (valores.length == 1) {
            inicio.complete();
            await terminar.future;
          }
          expect(op['revision'], valores.length - 1);
          return valores.length;
        },
      );
      await sync.iniciar();
      final envio = sync.sincronizar();
      await inicio.future;
      await store.encolar('borrador', 'u', {'valor': 2}, 0);
      terminar.complete();
      await envio;
      expect(valores, [1, 2]);
      expect(await store.pendientes(), isEmpty);
      expect((await store.entidades()).single['datos'], {'valor': 2});
      await sync.cerrar();
    },
  );
}
