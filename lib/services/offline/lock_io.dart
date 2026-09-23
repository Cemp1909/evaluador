Future<T> conBloqueo<T>(String nombre, Future<T> Function() action) => action();
