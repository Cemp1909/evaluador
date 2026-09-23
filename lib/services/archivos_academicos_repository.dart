import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArchivosAcademicosRepository {
  ArchivosAcademicosRepository(this.client);

  final SupabaseClient client;
  static const _bucket = 'academico';
  final Map<String, String> _rutasPorContenido = {};
  void limpiarCache() => _rutasPorContenido.clear();

  Future<String> guardarImagen({
    required String colegioId,
    required String registroId,
    required String tipo,
    required String base64,
    bool esFirma = false,
  }) async {
    final usuarioId = client.auth.currentUser?.id;
    if (usuarioId == null) throw StateError('Sesión no disponible');
    final bytes = base64Decode(base64);
    final clave =
        '$usuarioId:$colegioId:$registroId:$tipo:${sha256.convert(bytes)}';
    final rutaExistente = _rutasPorContenido[clave];
    if (rutaExistente != null) return rutaExistente;
    final png =
        esFirma ||
        (bytes.length >= 8 &&
            bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4e &&
            bytes[3] == 0x47);
    final extension = png ? 'png' : 'jpg';
    final ruta =
        '$colegioId/$usuarioId/$registroId/$tipo-${sha256.convert(bytes)}.$extension';
    try {
      await client.storage
          .from(_bucket)
          .uploadBinary(
            ruta,
            bytes,
            fileOptions: FileOptions(
              contentType: png ? 'image/png' : 'image/jpeg',
              upsert: false,
            ),
          );
    } on StorageException catch (error) {
      if (error.statusCode != '409' && error.error != 'Duplicate') rethrow;
    }
    _rutasPorContenido[clave] = ruta;
    return ruta;
  }

  Future<String> leerImagen(String ruta) async {
    final bytes = await client.storage.from(_bucket).download(ruta);
    return base64Encode(bytes);
  }
}
