import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as hashes;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';
import 'lease_io.dart' if (dart.library.js_interop) 'lease_web.dart';
import 'lock_io.dart' if (dart.library.js_interop) 'lock_web.dart';
import 'database_io.dart' if (dart.library.js_interop) 'database_web.dart';

/// Cada usuario y proyecto tienen una base y una clave independientes.
/// La escritura de la vista local y la cola se confirma en una transacción.
class OfflineStore {
  OfflineStore(this.db, this.secret, this.scope, {void Function()? liberar})
    : _liberar = liberar;
  final void Function()? _liberar;
  final Database db;
  final SecretKey secret;
  final String scope;
  final _cipher = AesGcm.with256bits();
  final _cache = stringMapStoreFactory.store('cache');
  final _queue = intMapStoreFactory.store('outbox');

  static Future<OfflineStore> abrir(String proyecto, String usuario) async {
    final scope = hashes.sha256
        .convert(utf8.encode('$proyecto:$usuario'))
        .toString();
    final liberar = await tomarSesion('academic-editor-$scope');
    try {
      return await conBloqueo('academic-secure-storage', () async {
        const secure = FlutterSecureStorage(
          mOptions: MacOsOptions(usesDataProtectionKeychain: false),
        );
        final stored = await secure.read(key: 'offline-key-$scope');
        final key = stored == null
            ? await AesGcm.with256bits().newSecretKey()
            : SecretKey(base64Decode(stored));
        if (stored == null) {
          await secure.write(
            key: 'offline-key-$scope',
            value: base64Encode(await key.extractBytes()),
          );
        }
        return OfflineStore(
          await abrirBase('academico-$scope'),
          key,
          scope,
          liberar: liberar,
        );
      });
    } catch (_) {
      liberar();
      rethrow;
    }
  }

  Future<Map<String, Object?>> _encode(Map<String, dynamic> data) async {
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(data)),
      secretKey: secret,
      aad: utf8.encode(scope),
    );
    return {'cipher': base64Encode(box.concatenation())};
  }

  Future<Map<String, dynamic>> _decode(Map<String, Object?> data) async {
    final box = SecretBox.fromConcatenation(
      base64Decode(data['cipher'] as String),
      nonceLength: 12,
      macLength: 16,
    );
    final bytes = await _cipher.decrypt(
      box,
      secretKey: secret,
      aad: utf8.encode(scope),
    );
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
  }

  Future<Map<String, dynamic>?> leer(String key) async {
    final data = await _cache.record(key).get(db);
    return data == null ? null : _decode(data);
  }

  Future<void> guardar(String key, Map<String, dynamic> value) async =>
      _cache.record(key).put(db, await _encode(value));

  Future<void> encolar(
    String tipo,
    String recurso,
    Map<String, dynamic> data,
    int revision,
  ) async {
    final id = const Uuid().v4();
    final entidad = '$tipo:$recurso';
    await db.transaction((txn) async {
      final cached = await _cache.record(entidad).get(txn);
      final previous = cached == null ? null : await _decode(cached);
      final version = previous?['revision'] as int? ?? revision;
      final operation = <String, dynamic>{
        'id': id,
        'tipo': tipo,
        'recurso': recurso,
        'entidad': entidad,
        'datos': data,
        'revision': version,
        'creado': DateTime.now().toUtc().toIso8601String(),
      };
      // Solo se compactan cambios que nunca se han intentado enviar.
      // Un envío incierto conserva su UUID y contenido para el reintento.
      int? compactar;
      for (final row in await _queue.find(
        txn,
        finder: Finder(sortOrders: [SortOrder(Field.key, false)]),
      )) {
        final pending = await _decode(row.value);
        if (pending['entidad'] != entidad) continue;
        if (pending['enviada'] != true && pending['error'] == null) {
          compactar = row.key;
        }
        break;
      }
      if (compactar == null) {
        await _queue.add(txn, await _encode(operation));
      } else {
        await _queue.record(compactar).put(txn, await _encode(operation));
      }
      await _cache
          .record(entidad)
          .put(
            txn,
            await _encode({
              'tipo': tipo,
              'recurso': recurso,
              'datos': data,
              'revision': version,
              'pendiente': true,
            }),
          );
    });
  }

  Future<List<Map<String, dynamic>>> pendientes() async {
    final rows = await _queue.find(
      db,
      finder: Finder(sortOrders: [SortOrder(Field.key)]),
    );
    return [
      for (final row in rows)
        {...await _decode(row.value), 'secuencia': row.key},
    ];
  }

  Future<List<Map<String, dynamic>>> entidades() async {
    final rows = await _cache.find(db);
    return [
      for (final row in rows)
        if (row.key != 'sesion') await _decode(row.value),
    ];
  }

  Future<void> confirmar(Map<String, dynamic> operation, int revision) async {
    await db.transaction((txn) async {
      if (await _queue.record(operation['secuencia'] as int).get(txn) == null) {
        return;
      }
      await _queue.record(operation['secuencia'] as int).delete(txn);
      var remains = false;
      for (final row in await _queue.find(txn)) {
        final data = await _decode(row.value);
        if (data['entidad'] != operation['entidad']) continue;
        remains = true;
        data['revision'] = revision;
        await _queue.record(row.key).put(txn, await _encode(data));
      }
      final record = _cache.record(operation['entidad'] as String);
      final cached = await record.get(txn);
      if (cached != null) {
        final data = await _decode(cached);
        data['revision'] = revision;
        data['pendiente'] = remains;
        await record.put(txn, await _encode(data));
      }
    });
  }

  Future<Map<String, dynamic>?> prepararEnvio(int secuencia) =>
      db.transaction((txn) async {
        final row = await _queue.record(secuencia).get(txn);
        if (row == null) return null;
        final data = await _decode(row);
        data['enviada'] = true;
        await _queue.record(secuencia).put(txn, await _encode(data));
        return {...data, 'secuencia': secuencia};
      });

  Future<void> error(Map<String, dynamic> operation, String mensaje) async {
    final data = Map<String, dynamic>.from(operation)..remove('secuencia');
    data['error'] = mensaje;
    await db.transaction((txn) async {
      final record = _queue.record(operation['secuencia'] as int);
      if (await record.get(txn) != null) {
        await record.put(txn, await _encode(data));
      }
    });
  }

  Future<void> descartar(
    String entidad, {
    Map<String, dynamic>? snapshot,
  }) async {
    await db.transaction((txn) async {
      for (final row in await _queue.find(txn)) {
        if ((await _decode(row.value))['entidad'] == entidad) {
          await _queue.record(row.key).delete(txn);
        }
      }
      await _cache.record(entidad).delete(txn);
      if (snapshot != null) {
        await _cache.record('sesion').put(txn, await _encode(snapshot));
      }
    });
  }

  Future<void> limpiarConfirmados() async {
    await db.transaction((txn) async {
      for (final row in await _cache.find(txn)) {
        if (row.key != 'sesion' &&
            (await _decode(row.value))['pendiente'] != true) {
          await _cache.record(row.key).delete(txn);
        }
      }
    });
  }

  Future<void> reintentar() async {
    await db.transaction((txn) async {
      for (final row in await _queue.find(txn)) {
        final data = await _decode(row.value)
          ..remove('error');
        await _queue.record(row.key).put(txn, await _encode(data));
      }
    });
  }

  Future<void> cerrar() async {
    try {
      await db.close();
    } finally {
      _liberar?.call();
    }
  }
}
