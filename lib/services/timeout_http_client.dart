import 'package:http/http.dart' as http;

/// Cada petición tiene un límite; los reintentos de escritura pertenecen a la
/// cola persistente, con el mismo identificador de operación.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();
  final http.Client _inner;
  static const limite = Duration(seconds: 25);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request).timeout(limite);
    return http.StreamedResponse(
      response.stream.timeout(limite),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
