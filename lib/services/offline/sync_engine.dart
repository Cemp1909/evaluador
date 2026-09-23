import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_store.dart';
import 'network_io.dart' if (dart.library.js_interop) 'network_web.dart';

bool errorDeRed(Object error) =>
    error is TimeoutException ||
    error is http.ClientException ||
    error is AuthRetryableFetchException ||
    esErrorSocket(error) ||
    (error is StorageException &&
        (int.tryParse(error.statusCode ?? '') == null ||
            (int.tryParse(error.statusCode ?? '') ?? 0) >= 500 ||
            error.statusCode == '429')) ||
    (error is PostgrestException &&
        [
          '429',
          '502',
          '503',
          '504',
          'PGRST000',
          'PGRST001',
          'PGRST002',
          'PGRST003',
        ].contains(error.code));

class SyncEngine extends ChangeNotifier {
  SyncEngine(this.store, {required this.comprobarSesion, required this.enviar});
  final OfflineStore store;
  final Future<void> Function() comprobarSesion;
  final Future<int> Function(Map<String, dynamic>) enviar;
  List<Map<String, dynamic>> operaciones = [];
  bool sinConexion = false;
  bool sincronizando = false;
  String? ultimoError;
  bool _closed = false;
  Future<void>? _running;
  Timer? _timer;
  int _fallos = 0;

  Future<void> iniciar() async {
    await actualizar();
    _programar();
  }

  Future<void> actualizar() async {
    operaciones = await store.pendientes();
    if (!_closed) notifyListeners();
  }

  void _programar() {
    _timer?.cancel();
    if (!_closed) {
      _timer = Timer(
        Duration(
          seconds: _fallos == 0
              ? 30
              : (5 * (1 << _fallos.clamp(0, 6))).clamp(5, 300),
        ),
        () {
          sincronizar();
        },
      );
    }
  }

  Future<void> sincronizar() {
    if (_closed) return Future.value();
    return _running ??= _sincronizar().whenComplete(() {
      _running = null;
      _programar();
    });
  }

  Future<void> _sincronizar() async {
    sincronizando = true;
    notifyListeners();
    try {
      await comprobarSesion();
      sinConexion = false;
      ultimoError = null;
      // El lote se vuelve a leer después de cada confirmación: las revisiones
      // de las operaciones siguientes cambian cuando el servidor confirma.
      while (!_closed) {
        await actualizar();
        final blocked = <String>{};
        Map<String, dynamic>? siguiente;
        for (final op in operaciones) {
          if (op['error'] != null) blocked.add(op['entidad'] as String);
          if (!blocked.contains(op['entidad'])) {
            siguiente = op;
            break;
          }
        }
        if (siguiente == null) break;
        siguiente = await store.prepararEnvio(siguiente['secuencia'] as int);
        if (siguiente == null) continue;
        try {
          final revision = await enviar(siguiente);
          await store.confirmar(siguiente, revision);
        } catch (error) {
          if (errorDeRed(error) || error is AuthException) rethrow;
          final conflict =
              error is PostgrestException &&
              error.message.contains('SYNC_CONFLICT');
          await store.error(
            siguiente,
            conflict
                ? 'Otro usuario modificó este registro. Tu versión sigue guardada en este dispositivo.'
                : 'El servidor rechazó este cambio. Revisa los permisos y datos antes de reintentar.',
          );
        }
      }
      _fallos = 0;
    } catch (error) {
      sinConexion = errorDeRed(error);
      ultimoError = sinConexion
          ? 'Sin conexión. Los cambios están guardados en este dispositivo.'
          : 'No se pudo validar la sesión. Conéctate e inicia sesión de nuevo.';
      _fallos++;
    } finally {
      sincronizando = false;
      await actualizar();
    }
  }

  Future<void> cerrar() async {
    _closed = true;
    _timer?.cancel();
    await _running;
    super.dispose();
  }
}
