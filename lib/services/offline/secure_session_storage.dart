import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lock_io.dart' if (dart.library.js_interop) 'lock_web.dart';

class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage(this.key);
  final String key;
  final _secure = const FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> accessToken() =>
      conBloqueo('academic-secure-storage', () => _secure.read(key: key));
  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;
  @override
  Future<void> persistSession(String value) => conBloqueo(
    'academic-secure-storage',
    () => _secure.write(key: key, value: value),
  );
  @override
  Future<void> removePersistedSession() =>
      conBloqueo('academic-secure-storage', () => _secure.delete(key: key));
}
