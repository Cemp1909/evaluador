import 'dart:js_interop';

@JS('navigator.locks.request')
external JSPromise<JSAny?> _request(JSString name, JSFunction callback);

// Evita generar dos claves distintas al abrir por primera vez dos pestañas.
Future<T> conBloqueo<T>(String nombre, Future<T> Function() action) async {
  late T result;
  Object? failure;
  StackTrace? trace;
  await _request(
    nombre.toJS,
    ((JSAny? _) {
      return (() async {
        try {
          result = await action();
        } catch (error, stack) {
          failure = error;
          trace = stack;
        }
        return null as JSAny?;
      })().toJS;
    }).toJS,
  ).toDart;
  if (failure != null) Error.throwWithStackTrace(failure!, trace!);
  return result;
}
