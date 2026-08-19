import 'package:flutter/foundation.dart';

import '../config/auth_config.dart';
import '../models/profesor.dart';
import '../models/evaluacion.dart';
import '../models/configuracion_notas.dart';
import '../models/student_knowledge_draft.dart';
import '../models/student_knowledge_report.dart';
import '../models/usuario_sesion.dart';
import '../models/visita_programada.dart';

class SesionProvider extends ChangeNotifier {
  SesionProvider(this._config);

  final AuthConfig _config;
  final List<Profesor> _profesores = [];
  final List<StudentKnowledgeReport> _reportesConocimiento = [];
  final Map<String, Evaluacion> _borradoresEvaluacion = {};
  final List<VisitaProgramada> _visitas = [];
  StudentKnowledgeDraft? _borradorConocimiento;
  ConfiguracionNotas _configuracionNotas = const ConfiguracionNotas();
  UsuarioSesion? _usuarioActual;

  List<Profesor> get profesores => List.unmodifiable(_profesores);
  List<StudentKnowledgeReport> get reportesConocimiento =>
      List.unmodifiable(_reportesConocimiento);
  UsuarioSesion? get usuarioActual => _usuarioActual;
  bool get estaAutenticado => _usuarioActual != null;
  StudentKnowledgeDraft? get borradorConocimiento => _borradorConocimiento;
  ConfiguracionNotas get configuracionNotas => _configuracionNotas;
  List<VisitaProgramada> get visitas => List.unmodifiable(_visitas);

  String? programarVisita(VisitaProgramada visita) {
    final error = _validarVisita(visita, _visitas);
    if (error != null) return error;
    _visitas.add(visita);
    _ordenarVisitas();
    notifyListeners();
    return null;
  }

  String? programarSerieClases(
    VisitaProgramada inicial, {
    int intervaloDias = 7,
  }) {
    if (inicial.numeroClase == null ||
        inicial.tipo == 'Evaluación por colegio') {
      return 'La programación automática solo está disponible para clases.';
    }
    final total = inicial.tipo == 'Capacitación preescolar' ? 6 : 11;
    if (intervaloDias != 7 && intervaloDias != 14) {
      return 'La frecuencia debe ser cada 8 o cada 15 días.';
    }
    final serie = <VisitaProgramada>[];
    final serieId = inicial.id;
    for (var clase = inicial.numeroClase!; clase <= total; clase++) {
      final visita = VisitaProgramada(
        id: '${inicial.id}-$clase',
        fecha: inicial.fecha.add(
          Duration(days: intervaloDias * (clase - inicial.numeroClase!)),
        ),
        colegio: inicial.colegio,
        tipo: inicial.tipo,
        profesorResponsable: inicial.profesorResponsable,
        numeroClase: clase,
        observacion: inicial.observacion,
        serieId: serieId,
        intervaloDias: intervaloDias,
      );
      final error = _validarVisita(visita, [..._visitas, ...serie]);
      if (error != null) return 'No se pudo crear la serie: $error';
      serie.add(visita);
    }
    _visitas.addAll(serie);
    _ordenarVisitas();
    notifyListeners();
    return null;
  }

  String? _validarVisita(
    VisitaProgramada visita,
    Iterable<VisitaProgramada> existentes,
  ) {
    final colegio = visita.colegio.trim().toLowerCase();
    final duplicada = existentes.any((existente) {
      if (existente.colegio.trim().toLowerCase() != colegio) return false;
      if (visita.periodo != null) {
        return existente.periodo == visita.periodo;
      }
      return visita.numeroClase != null &&
          existente.tipo == visita.tipo &&
          existente.numeroClase == visita.numeroClase;
    });
    if (duplicada) {
      return visita.periodo != null
          ? 'El período ${visita.periodo} ya está programado para este colegio.'
          : 'La clase ${visita.numeroClase} de ${visita.tipo.toLowerCase()} ya está programada para este colegio.';
    }
    final cruceHorario = existentes.any(
      (existente) =>
          !existente.cancelada &&
          existente.fecha.year == visita.fecha.year &&
          existente.fecha.month == visita.fecha.month &&
          existente.fecha.day == visita.fecha.day &&
          existente.fecha.hour == visita.fecha.hour &&
          existente.fecha.minute == visita.fecha.minute,
    );
    if (cruceHorario) {
      return 'Ese día y hora ya están reservados para otra actividad.';
    }
    return null;
  }

  void _ordenarVisitas() {
    _visitas.sort((a, b) => a.fecha.compareTo(b.fecha));
  }

  void alternarVisita(String id) {
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return;
    if (_visitas[index].cancelada) return;
    _visitas[index] = _visitas[index].copyWith(
      completada: !_visitas[index].completada,
    );
    notifyListeners();
  }

  void cancelarVisita(String id, String motivo) {
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return;
    _visitas[index] = _visitas[index].copyWith(
      cancelada: true,
      completada: false,
      motivoCancelacion: motivo.trim(),
      ultimaNovedad: 'Cancelada: ${motivo.trim()}',
    );
    notifyListeners();
  }

  void reprogramarVisita(String id, DateTime fecha, {String? motivo}) {
    final index = _visitas.indexWhere((visita) => visita.id == id);
    if (index == -1) return;
    _visitas[index] = _visitas[index].copyWith(
      fecha: fecha,
      cancelada: false,
      completada: false,
      motivoCancelacion: '',
      ultimaNovedad: motivo?.trim().isNotEmpty == true
          ? 'Reprogramada: ${motivo!.trim()}'
          : 'Actividad reprogramada',
    );
    _visitas.sort((a, b) => a.fecha.compareTo(b.fecha));
    notifyListeners();
  }

  void posponerSerieDesde(String id, String motivo) {
    final indiceReferencia = _visitas.indexWhere((visita) => visita.id == id);
    if (indiceReferencia == -1) return;
    final referencia = _visitas[indiceReferencia];
    if (referencia.serieId == null || referencia.numeroClase == null) {
      cancelarVisita(id, motivo);
      return;
    }
    final intervalo = referencia.intervaloDias ?? 7;
    for (var index = 0; index < _visitas.length; index++) {
      final visita = _visitas[index];
      if (visita.serieId != referencia.serieId ||
          visita.numeroClase == null ||
          visita.numeroClase! < referencia.numeroClase!) {
        continue;
      }
      _visitas[index] = visita.copyWith(
        fecha: visita.fecha.add(Duration(days: intervalo)),
        cancelada: false,
        completada: false,
        motivoCancelacion: '',
        ultimaNovedad: visita.id == id
            ? 'Clase pospuesta: ${motivo.trim()}'
            : 'Fecha ajustada por reprogramación de la clase ${referencia.numeroClase}',
      );
    }
    _ordenarVisitas();
    notifyListeners();
  }

  void reprogramarSerieDesde(String id, DateTime nuevaFecha, {String? motivo}) {
    final indiceReferencia = _visitas.indexWhere((visita) => visita.id == id);
    if (indiceReferencia == -1) return;
    final referencia = _visitas[indiceReferencia];
    if (referencia.serieId == null || referencia.numeroClase == null) {
      reprogramarVisita(id, nuevaFecha, motivo: motivo);
      return;
    }
    final diferencia = nuevaFecha.difference(referencia.fecha);
    for (var index = 0; index < _visitas.length; index++) {
      final visita = _visitas[index];
      if (visita.serieId != referencia.serieId ||
          visita.numeroClase == null ||
          visita.numeroClase! < referencia.numeroClase!) {
        continue;
      }
      _visitas[index] = visita.copyWith(
        fecha: visita.fecha.add(diferencia),
        cancelada: false,
        completada: false,
        motivoCancelacion: '',
        ultimaNovedad: visita.id == id
            ? 'Clase reprogramada${motivo?.trim().isNotEmpty == true ? ': ${motivo!.trim()}' : ''}'
            : 'Fecha ajustada por reprogramación de la clase ${referencia.numeroClase}',
      );
    }
    _ordenarVisitas();
    notifyListeners();
  }

  Evaluacion? borradorEvaluacion(String tipo) => _borradoresEvaluacion[tipo];

  void guardarBorradorEvaluacion(Evaluacion evaluacion) {
    _borradoresEvaluacion[evaluacion.evaluadorTipo] = evaluacion;
    notifyListeners();
  }

  void guardarBorradorConocimiento(StudentKnowledgeDraft borrador) {
    _borradorConocimiento = borrador;
    notifyListeners();
  }

  void descartarBorradorConocimiento() {
    _borradorConocimiento = null;
    notifyListeners();
  }

  void actualizarConfiguracionNotas(ConfiguracionNotas configuracion) {
    _configuracionNotas = configuracion;
    notifyListeners();
  }

  List<StudentKnowledgeReport> historialEstudiante(String nombre) {
    final buscado = nombre.trim().toLowerCase();
    return _reportesConocimiento
        .where((reporte) => reporte.profesorEvaluado.toLowerCase() == buscado)
        .toList(growable: false)
      ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
  }

  void guardarReporteConocimiento(StudentKnowledgeReport reporte) {
    _reportesConocimiento.add(reporte);
    notifyListeners();
  }

  String? aprobarReporteConocimiento({
    required String reporteId,
    required String firma,
  }) {
    if (_usuarioActual?.rol != RolUsuario.coordinador) {
      return 'Solo un coordinador puede aprobar este reporte.';
    }
    final index = _reportesConocimiento.indexWhere(
      (reporte) => reporte.id == reporteId,
    );
    if (index == -1) return 'Reporte no encontrado.';
    _reportesConocimiento[index] = _reportesConocimiento[index].copyWith(
      firmaCoordinador: firma,
      nombreCoordinador: _usuarioActual!.nombre,
      fechaAprobacion: DateTime.now(),
    );
    notifyListeners();
    return null;
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
        return 'Tu solicitud está pendiente de aprobación del administrador.';
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
    return 'No existe un profesor con ese usuario en esta sesión. Un administrador o coordinador debe crearlo primero.';
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
      return 'No tienes permiso para crear profesores.';
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
    if (index == -1) return 'Profesor no encontrado.';
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
