import 'package:evaluador_app/config/auth_config.dart';
import 'package:evaluador_app/models/usuario_sesion.dart';
import 'package:evaluador_app/providers/sesion_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rechaza credenciales desconocidas y no asigna rol de profesor', () {
    final sesion = SesionProvider(AuthConfig.test);

    expect(
      sesion.iniciarSesion(usuario: 'inventado', password: 'cualquiera'),
      contains('No existe un profesor'),
    );
    expect(sesion.usuarioActual, isNull);
  });

  test('autentica los tres roles y conserva profesores al cerrar sesión', () {
    final sesion = SesionProvider(AuthConfig.test);

    expect(
      sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto'),
      isNull,
    );
    expect(sesion.usuarioActual?.rol, RolUsuario.administrador);
    expect(
      sesion.crearProfesor(
        nombre: 'Laura Gómez',
        usuario: 'laura',
        password: 'prueba123',
        zona: 'Zona Norte',
      ),
      isNull,
    );
    expect(
      sesion.iniciarSesion(usuario: 'laura', password: 'prueba123'),
      contains('pendiente'),
    );
    sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    expect(sesion.aprobarProfesor('laura'), isNull);
    sesion.cerrarSesion();

    expect(
      sesion.iniciarSesion(usuario: 'laura', password: 'prueba123'),
      isNull,
    );
    expect(sesion.usuarioActual?.rol, RolUsuario.profesor);
    expect(sesion.usuarioActual?.zona, 'Zona Norte');
  });

  test('un profesor puede registrarse pero requiere aprobación del admin', () {
    final sesion = SesionProvider(AuthConfig.test);

    expect(
      sesion.registrarSolicitudProfesor(
        nombre: 'Profesor Nuevo',
        usuario: 'nuevo',
        password: 'prueba123',
        zona: 'Zona Sur',
      ),
      isNull,
    );
    expect(
      sesion.iniciarSesion(usuario: 'nuevo', password: 'prueba123'),
      contains('pendiente'),
    );
    expect(sesion.aprobarProfesor('nuevo'), contains('Solo el administrador'));

    sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    expect(sesion.aprobarProfesor('nuevo'), isNull);
    sesion.cerrarSesion();
    expect(
      sesion.iniciarSesion(usuario: 'nuevo', password: 'prueba123'),
      isNull,
    );
  });

  test('el coordinador solo ve y crea profesores de su zona', () {
    final sesion = SesionProvider(AuthConfig.test);
    sesion.iniciarSesion(usuario: 'admin', password: 'cambiar_esto');
    sesion.crearProfesor(
      nombre: 'Profesor Norte',
      usuario: 'norte',
      password: 'prueba123',
      zona: 'Zona Norte',
    );
    sesion.crearProfesor(
      nombre: 'Profesor Centro',
      usuario: 'centro',
      password: 'prueba123',
      zona: 'Zona Centro',
    );
    sesion.cerrarSesion();
    sesion.iniciarSesion(usuario: 'coordinador', password: 'cambiar_esto');

    expect(sesion.profesoresVisibles(), hasLength(1));
    expect(sesion.profesoresVisibles().single.usuario, 'centro');
    sesion.crearProfesor(
      nombre: 'Profesor Forzado',
      usuario: 'forzado',
      password: 'prueba123',
      zona: 'Zona Diferente',
    );
    expect(sesion.profesores.last.zona, 'Zona Centro');
  });

  test('valida duplicados y contraseña mínima', () {
    final sesion = SesionProvider(AuthConfig.test)
      ..iniciarSesion(usuario: 'admin', password: 'cambiar_esto');

    expect(
      sesion.crearProfesor(
        nombre: 'Laura',
        usuario: 'laura',
        password: '123',
        zona: 'Centro',
      ),
      contains('mínimo'),
    );
    sesion.crearProfesor(
      nombre: 'Laura',
      usuario: 'laura',
      password: '123456',
      zona: 'Centro',
    );
    expect(
      sesion.crearProfesor(
        nombre: 'Otra Laura',
        usuario: 'LAURA',
        password: '123456',
        zona: 'Centro',
      ),
      contains('ya está en uso'),
    );
  });
}
