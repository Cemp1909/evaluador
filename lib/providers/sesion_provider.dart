import 'package:flutter/foundation.dart';

import '../config/auth_config.dart';
import '../models/profesor.dart';
import '../models/student_knowledge_report.dart';
import '../models/usuario_sesion.dart';

class SesionProvider extends ChangeNotifier {
  SesionProvider(this._config);

  final AuthConfig _config;
  final List<Profesor> _profesores = [];
  final List<StudentKnowledgeReport> _reportesConocimiento = [];
  UsuarioSesion? _usuarioActual;

  List<Profesor> get profesores => List.unmodifiable(_profesores);
  List<StudentKnowledgeReport> get reportesConocimiento =>
      List.unmodifiable(_reportesConocimiento);
  UsuarioSesion? get usuarioActual => _usuarioActual;
  bool get estaAutenticado => _usuarioActual != null;

  void guardarReporteConocimiento(StudentKnowledgeReport reporte) {
    _reportesConocimiento.add(reporte);
    notifyListeners();
  }

  String? iniciarSesion({required String usuario, required String password}) {
    final usuarioNormalizado = usuario.trim().toLowerCase();
    _usuarioActual = null;

    if (usuarioNormalizado == _config.adminUsername.trim().toLowerCase() &&
        password == _config.adminPassword) {
      _usuarioActual = const UsuarioSesion(
        rol: RolUsuario.administrador,
        nombre: 'Administrador',
      );
      notifyListeners();
      return null;
    }

    if (usuarioNormalizado ==
            _config.coordinadorUsername.trim().toLowerCase() &&
        password == _config.coordinadorPassword) {
      _usuarioActual = UsuarioSesion(
        rol: RolUsuario.coordinador,
        nombre: 'Coordinador de zona',
        zona: _config.coordinadorZona,
      );
      notifyListeners();
      return null;
    }

    Profesor? profesor;
    var existeUsuarioProfesor = false;
    for (final candidato in _profesores) {
      if (candidato.usuario.toLowerCase() == usuarioNormalizado) {
        existeUsuarioProfesor = true;
        if (candidato.password == password) {
          profesor = candidato;
          break;
        }
      }
    }
    if (profesor != null) {
      if (!profesor.aprobado) {
        return 'Tu solicitud está pendiente de aprobación por el administrador.';
      }
      _usuarioActual = UsuarioSesion(
        rol: RolUsuario.profesor,
        nombre: profesor.nombre,
        zona: profesor.zona,
      );
      notifyListeners();
      return null;
    }

    if (existeUsuarioProfesor) {
      return 'La contraseña del profesor es incorrecta.';
    }
    return 'No existe un profesor con ese usuario en esta sesión. Primero debe crearlo un administrador o coordinador.';
  }

  String? crearProfesor({
    required String nombre,
    required String usuario,
    required String password,
    required String zona,
  }) {
    final actual = _usuarioActual;
    if (actual?.rol != RolUsuario.administrador &&
        actual?.rol != RolUsuario.coordinador) {
      return 'No tienes permisos para crear profesores.';
    }
    final zonaLimpia = actual?.rol == RolUsuario.coordinador
        ? (actual?.zona ?? '').trim()
        : zona.trim();

    return _registrarProfesor(
      nombre: nombre,
      usuario: usuario,
      password: password,
      zona: zonaLimpia,
    );
  }

  String? registrarSolicitudProfesor({
    required String nombre,
    required String usuario,
    required String password,
    required String zona,
  }) => _registrarProfesor(
    nombre: nombre,
    usuario: usuario,
    password: password,
    zona: zona,
  );

  String? _registrarProfesor({
    required String nombre,
    required String usuario,
    required String password,
    required String zona,
  }) {
    final nombreLimpio = nombre.trim();
    final usuarioLimpio = usuario.trim();
    final zonaLimpia = zona.trim();

    if (nombreLimpio.isEmpty ||
        usuarioLimpio.isEmpty ||
        password.isEmpty ||
        zonaLimpia.isEmpty) {
      return 'Todos los campos son obligatorios.';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres.';
    }
    final usuarioOcupado = _profesores.any(
      (profesor) =>
          profesor.usuario.toLowerCase() == usuarioLimpio.toLowerCase(),
    );
    final usuarioReservado =
        usuarioLimpio.toLowerCase() ==
            _config.adminUsername.trim().toLowerCase() ||
        usuarioLimpio.toLowerCase() ==
            _config.coordinadorUsername.trim().toLowerCase();
    if (usuarioOcupado || usuarioReservado) {
      return 'Ese nombre de usuario ya está en uso.';
    }

    _profesores.add(
      Profesor(
        nombre: nombreLimpio,
        usuario: usuarioLimpio,
        password: password,
        zona: zonaLimpia,
      ),
    );
    notifyListeners();
    return null;
  }

  String? aprobarProfesor(String usuario) {
    if (_usuarioActual?.rol != RolUsuario.administrador) {
      return 'Solo el administrador puede aprobar profesores.';
    }
    final index = _profesores.indexWhere(
      (profesor) => profesor.usuario.toLowerCase() == usuario.toLowerCase(),
    );
    if (index == -1) return 'No se encontró el profesor.';
    _profesores[index] = _profesores[index].copyWith(aprobado: true);
    notifyListeners();
    return null;
  }

  List<Profesor> profesoresVisibles() {
    final actual = _usuarioActual;
    if (actual?.rol == RolUsuario.administrador) return profesores;
    if (actual?.rol == RolUsuario.coordinador) {
      return _profesores
          .where(
            (profesor) =>
                profesor.zona.toLowerCase() == actual!.zona!.toLowerCase(),
          )
          .toList(growable: false);
    }
    return const [];
  }

  void cerrarSesion() {
    _usuarioActual = null;
    notifyListeners();
  }
}
