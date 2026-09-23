import 'dart:async';
import 'dart:js_interop';
import 'store_busy.dart';

@JS('navigator.locks.request')
external JSPromise<JSAny?> _request(
  JSString name,
  JSObject options,
  JSFunction callback,
);

// Un solo editor por cuenta en el mismo navegador evita formularios obsoletos
// que escriban sobre cambios de otra pestaña. El navegador libera al cerrarla.
Future<void Function()> tomarSesion(String nombre) async {
  final obtenido = Completer<void Function()>();
  final liberar = Completer<void>();
  final future = _request(
    nombre.toJS,
    {'ifAvailable': true}.jsify()! as JSObject,
    ((JSAny? lock) {
      return (() async {
        if (lock == null) {
          obtenido.completeError(const OfflineStoreBusy());
        } else {
          obtenido.complete(() {
            if (!liberar.isCompleted) liberar.complete();
          });
          await liberar.future;
        }
        return null as JSAny?;
      })().toJS;
    }).toJS,
  ).toDart;
  unawaited(
    future.then<void>(
      (_) {},
      onError: (Object error) {
        if (!obtenido.isCompleted) obtenido.completeError(error);
      },
    ),
  );
  return obtenido.future;
}
