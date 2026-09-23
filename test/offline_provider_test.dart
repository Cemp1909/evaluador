import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_io.dart';
import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:evaluador_app/services/offline/offline_store.dart';
import 'persistencia_supabase_test.dart' show ServidorPrueba, draft;

void main() {
  test(
    'borrador offline persiste al reiniciar y llega al servidor al reconectar',
    () async {
      final dir = await Directory.systemTemp.createTemp('offline-provider-');
      final key = await AesGcm.with256bits().newSecretKey();
      final server = ServidorPrueba();
      final client = server.cliente();
      Future<OfflineStore> abrir(String uid) async => OfflineStore(
        await databaseFactoryIo.openDatabase('${dir.path}/$uid.db'),
        key,
        uid,
      );
      var sesion = SesionProvider(
        AuthConfig.test,
        supabaseClient: client,
        offlineFactory: abrir,
      );
      expect(
        await sesion.iniciarSesionSupabase(
          correo: 'test@test.test',
          password: 'prueba',
        ),
        isNull,
      );
      await sesion.sincronizarCambios();
      server.sinRed = true;
      expect(
        await sesion.guardarBorradorConocimientoPersistente(
          draft('Sin internet'),
        ),
        isNull,
      );
      await sesion.sincronizarCambios();
      expect(sesion.cambiosPendientes, 1);
      expect(sesion.sinConexion, isTrue);
      expect(server.borrador, isNull);
      // Simula terminar el proceso conservando la sesión persistida del SDK.
      await sesion.suspenderPersistencia();
      sesion.dispose();
      sesion = SesionProvider(
        AuthConfig.test,
        supabaseClient: client,
        offlineFactory: abrir,
      );
      expect(await sesion.restaurarSesionSupabase(), isNull);
      expect(sesion.borradorConocimiento!.compromiso, 'Sin internet');
      expect(sesion.borradorConocimiento!.firmaColegio, 'firma-prueba');
      expect(sesion.borradorConocimiento!.fotosEvidencia, ['foto-prueba']);
      expect(sesion.cambiosPendientes, 1);
      server.sinRed = false;
      await sesion.sincronizarCambios();
      expect(sesion.cambiosPendientes, 0);
      expect(server.borrador!['datos']['compromiso'], 'Sin internet');
      await sesion.cerrarSesion();
      sesion.dispose();
      await client.dispose();
      await dir.delete(recursive: true);
    },
  );
}
